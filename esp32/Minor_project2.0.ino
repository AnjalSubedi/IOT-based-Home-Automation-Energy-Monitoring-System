
#include <ArduinoJson.h>
#include <HTTPClient.h>
#include <WiFi.h>
#include <math.h>

// ─── WiFi Credentials ────────────────────────────────────────────────────────
const char *ssid     = "Nigger!";
const char *password = "1234567890";

// ─── Server Endpoints ─────────────────────────────────────────────────────────
const char *serverUrl = "http://10.138.109.49:5000/api/readings";
const char *relayUrl  = "http://10.138.109.49:5000/api/relay/";

// ─── Relay ────────────────────────────────────────────────────────────────────
#define RELAY_PIN  26
#define RELAY_ON   LOW
#define RELAY_OFF  HIGH

// ─── Sensor Pins (must be ADC-capable: 32-39) ────────────────────────────────
#define VOLTAGE_PIN 34   // ZMPT101B signal output → GPIO 34
#define CURRENT_PIN 35   // SCT-013 signal output  → GPIO 35

// ─── Sampling Config ─────────────────────────────────────────────────────────
#define SAMPLES              1000   // samples per RMS window
#define SAMPLE_INTERVAL_US    100   // 100µs → 10 kHz sample rate
#define ADC_MIDPOINT         1862   // ~VCC/2 bias point (tune if needed)
#define NOISE_THRESHOLD        30   // Raw ADC RMS below this = treat as 0 (floating pin noise)

// ─── Calibration (tune with a multimeter / clamp meter) ──────────────────────
// Increase VCAL if sensor reads LOWER than real voltage, decrease if HIGHER
#define VCAL   110.0   // Adjust until Serial Monitor voltage matches multimeter
// Increase ICAL if sensor reads LOWER than real current, decrease if HIGHER
#define ICAL     0.30  // Adjust until Serial Monitor current matches clamp meter

// ─── Device ID ────────────────────────────────────────────────────────────────
String deviceId = "esp32-001";

// ─── Energy Accumulator ───────────────────────────────────────────────────────
float          totalEnergy   = 0.0;   // kWh
unsigned long  lastEnergyMs  = 0;

// ─────────────────────────────────────────────────────────────────────────────
//  readVoltageRMS()
//  ZMPT101B outputs a sinusoidal AC signal biased around ADC_MIDPOINT.
//  We accumulate sum-of-squares, take sqrt, then multiply by VCAL.
// ─────────────────────────────────────────────────────────────────────────────
float readVoltageRMS() {
  long sumSq = 0;
  for (int i = 0; i < SAMPLES; i++) {
    int centered = analogRead(VOLTAGE_PIN) - ADC_MIDPOINT;
    sumSq += (long)centered * centered;
    delayMicroseconds(SAMPLE_INTERVAL_US);
  }
  float rms = sqrt((float)sumSq / SAMPLES);
  if (rms < NOISE_THRESHOLD) return 0.0f;  // Floating pin / no sensor
  return rms * VCAL;
}

// ─────────────────────────────────────────────────────────────────────────────
//  readCurrentRMS()
//  SCT-013 with burden resistor outputs a biased AC signal.
//  Same RMS approach, multiplied by ICAL.
// ─────────────────────────────────────────────────────────────────────────────
float readCurrentRMS() {
  long sumSq = 0;
  for (int i = 0; i < SAMPLES; i++) {
    int centered = analogRead(CURRENT_PIN) - ADC_MIDPOINT;
    sumSq += (long)centered * centered;
    delayMicroseconds(SAMPLE_INTERVAL_US);
  }
  float rms = sqrt((float)sumSq / SAMPLES);
  if (rms < NOISE_THRESHOLD) return 0.0f;  // Floating pin / no sensor
  return rms * ICAL;
}

// ─────────────────────────────────────────────────────────────────────────────
//  measureFrequency()
//  Counts zero-crossings of the voltage waveform over 200 ms,
//  then extrapolates to Hz (×5).
// ─────────────────────────────────────────────────────────────────────────────
float measureFrequency() {
  int  crossings = 0;
  bool lastAbove = (analogRead(VOLTAGE_PIN) > ADC_MIDPOINT);
  unsigned long start = millis();

  while (millis() - start < 200) {        // measure for 200 ms
    bool nowAbove = (analogRead(VOLTAGE_PIN) > ADC_MIDPOINT);
    if (nowAbove != lastAbove) {
      crossings++;
      lastAbove = nowAbove;
    }
    delayMicroseconds(50);
  }
  // 2 crossings = 1 full cycle; measured over 0.2 s → ×5 gives Hz
  return (crossings / 2.0f) * 5.0f;
}

// ─────────────────────────────────────────────────────────────────────────────
//  measurePowerFactor()
//  Samples V and I simultaneously and computes:
//    PF = (mean of V×I) / (Vrms × Irms)
//  which equals cos(φ) for sinusoidal signals.
// ─────────────────────────────────────────────────────────────────────────────
float measurePowerFactor() {
  long sumVI = 0, sumV2 = 0, sumI2 = 0;

  for (int i = 0; i < SAMPLES; i++) {
    int v = analogRead(VOLTAGE_PIN) - ADC_MIDPOINT;
    int c = analogRead(CURRENT_PIN)  - ADC_MIDPOINT;
    sumVI += (long)v * c;
    sumV2 += (long)v * v;
    sumI2 += (long)c * c;
    delayMicroseconds(SAMPLE_INTERVAL_US);
  }

  float apparent = sqrt((float)sumV2 / SAMPLES) * sqrt((float)sumI2 / SAMPLES);
  if (apparent == 0) return 0.0f;

  float pf = abs((float)sumVI / SAMPLES) / apparent;
  return constrain(pf, 0.0f, 1.0f);
}

// ─────────────────────────────────────────────────────────────────────────────
//  setup()
// ─────────────────────────────────────────────────────────────────────────────
void setup() {
  Serial.begin(115200);

  // Configure ADC: 12-bit resolution, 0–3.3 V range
  analogReadResolution(12);
  analogSetPinAttenuation(VOLTAGE_PIN, ADC_11db);
  analogSetPinAttenuation(CURRENT_PIN, ADC_11db);

  // Connect to WiFi
  WiFi.begin(ssid, password);
  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi connected!");
  Serial.print("ESP32 IP: ");
  Serial.println(WiFi.localIP());

  // Relay default OFF
  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, RELAY_OFF);

  lastEnergyMs = millis();
}

// ─────────────────────────────────────────────────────────────────────────────
//  loop()
// ─────────────────────────────────────────────────────────────────────────────
void loop() {
  if (WiFi.status() == WL_CONNECTED) {

    // ── 1. Read all sensors ───────────────────────────────────────────────
    float voltage     = readVoltageRMS();
    float current     = readCurrentRMS();
    float powerFactor = measurePowerFactor();
    float frequency   = measureFrequency();
    float power       = voltage * current * powerFactor;  // Real power (W)

    // ── 2. Accumulate energy (kWh) ────────────────────────────────────────
    unsigned long now    = millis();
    float deltaHours     = (now - lastEnergyMs) / 3600000.0f;
    totalEnergy         += (power * deltaHours) / 1000.0f;  // W → kW
    lastEnergyMs         = now;

    // ── 3. Print to Serial Monitor ────────────────────────────────────────
    Serial.println("==============================");
    Serial.printf("Voltage     : %.2f V\n",    voltage);
    Serial.printf("Current     : %.3f A\n",    current);
    Serial.printf("Power       : %.2f W\n",    power);
    Serial.printf("Energy      : %.4f kWh\n",  totalEnergy);
    Serial.printf("Frequency   : %.1f Hz\n",   frequency);
    Serial.printf("Power Factor: %.2f\n",       powerFactor);
    Serial.println("==============================");

    // ── 4. Validate readings (guard against NaN/Inf from bad ADC) ──────────
    if (isnan(voltage) || isinf(voltage)) voltage = 0.0f;
    if (isnan(current) || isinf(current)) current = 0.0f;
    if (isnan(power)   || isinf(power))   power   = 0.0f;
    if (isnan(powerFactor) || isinf(powerFactor)) powerFactor = 0.0f;
    if (isnan(frequency)   || isinf(frequency))   frequency   = 0.0f;

    // ── 5. POST sensor data to server ────────────────────────────────────
    HTTPClient http;
    http.begin(serverUrl);
    http.addHeader("Content-Type", "application/json");

    StaticJsonDocument<512> doc;
    doc["voltage"]     = voltage;
    doc["current"]     = current;
    doc["power"]       = power;
    doc["energy"]      = totalEnergy;
    doc["frequency"]   = frequency;
    doc["powerFactor"] = powerFactor;
    doc["deviceId"]    = deviceId;

    String requestBody;
    serializeJson(doc, requestBody);

    int httpResponseCode = http.POST(requestBody);
    Serial.printf("POST Response: %d\n", httpResponseCode);
    http.end();

    // ── 5. Poll relay command from server ────────────────────────────────
    HTTPClient httpRelay;
    String relayEndpoint = relayUrl + deviceId;
    httpRelay.begin(relayEndpoint);
    httpRelay.setTimeout(5000);
    int httpRelayCode = httpRelay.GET();

    if (httpRelayCode > 0) {
      String payload = httpRelay.getString();
      Serial.println("Relay Payload: " + payload);

      StaticJsonDocument<200> relayDoc;
      DeserializationError error = deserializeJson(relayDoc, payload);

      if (!error) {
        int relayState = relayDoc["relay1"];
        if (relayState == 1) {
          digitalWrite(RELAY_PIN, RELAY_ON);
          Serial.println("→ Relay ON");
        } else {
          digitalWrite(RELAY_PIN, RELAY_OFF);
          Serial.println("→ Relay OFF");
        }
      } else {
        Serial.print("JSON parse failed: ");
        Serial.println(error.c_str());
      }
    } else {
      Serial.printf("Relay request error: %d\n", httpRelayCode);
    }
    httpRelay.end();

  } else {
    Serial.println("WiFi Disconnected — retrying...");
    WiFi.reconnect();
  }

  delay(5000);  // Send every 5 seconds
}
