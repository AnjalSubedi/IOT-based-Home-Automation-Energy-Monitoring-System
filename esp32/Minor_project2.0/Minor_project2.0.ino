/*
 * esp32_home_energy_monitor.ino
 *
 * IoT Home Automation & Energy Monitoring System — ESP32 Firmware
 * Phase 2: MQTT over TLS + FreeRTOS Dual-Core Architecture
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * ⚠  SAFETY: This firmware controls relays connected to 220V AC mains.
 *    See config.example.h for full safety warnings before wiring hardware.
 * ─────────────────────────────────────────────────────────────────────────────
 *
 * DUAL-CORE ARCHITECTURE (FreeRTOS):
 * ┌─────────────────────────────────────────────────────┐
 * │  Core 1 — sensorTask                               │
 * │  Reads ZMPT101B + ACS712 every 1 second            │
 * │  Writes to shared SensorData struct (mutex-locked) │
 * └─────────────────────────────────────────────────────┘
 *          ↕  Mutex (dataMutex) protects shared data
 * ┌─────────────────────────────────────────────────────┐
 * │  Core 0 — networkTask (same core as WiFi stack)    │
 * │  Handles WiFi + MQTT connection + reconnect        │
 * │  Reads shared SensorData (mutex-locked)            │
 * │  Publishes telemetry to HiveMQ every 10 seconds    │
 * │  Handles incoming relay commands                   │
 * └─────────────────────────────────────────────────────┘
 *
 * WHY DUAL-CORE:
 *   - ADC sampling (1000 samples × 100µs = 100ms) would block MQTT if on same core
 *   - WiFi stack on Core 0 can interfere with ADC timing on the same core
 *   - Separating concerns gives more accurate readings and stable connectivity
 *
 * HARDWARE:
 *   - ESP32 (30-pin)
 *   - ZMPT101B voltage sensor → GPIO34 (ADC1_CH6 — works with WiFi active)
 *   - ACS712 current sensor   → GPIO35 (ADC1_CH7 — works with WiFi active)
 *   - 4-channel relay module  → GPIO26, 27, 14, 12
 *     (BC108 NPN driver — ACTIVE HIGH: GPIO HIGH = relay ON)
 *
 * NOTE: Only ADC1 pins (GPIO32–39) work reliably when WiFi is active.
 *       Never use ADC2 pins (GPIO0,2,4,12-15,25-27) for sensors.
 *
 * REQUIRED LIBRARIES (Arduino IDE Library Manager):
 *   - PubSubClient  by Nick O'Leary    → search "PubSubClient"
 *   - ArduinoJson   by Benoit Blanchon → search "ArduinoJson"
 *   (WiFiClientSecure is built into ESP32 board package)
 */

#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>
#include <math.h>
#include "config.h"   // ← Copy config.example.h → config.h and fill in credentials

// ─────────────────────────────────────────────────────────────────────────────
//  Shared Sensor Data — protected by dataMutex
// ─────────────────────────────────────────────────────────────────────────────
struct SensorData {
  float voltage;
  float current;
  float power;
  float frequency;
  float powerFactor;
  bool  isValid;      // false until first successful reading
};

SensorData latestReading = { 0, 0, 0, 50.0f, 1.0f, false };

// FreeRTOS mutex — must be taken before reading/writing latestReading
SemaphoreHandle_t dataMutex = NULL;

// ─────────────────────────────────────────────────────────────────────────────
//  Relay State
// ─────────────────────────────────────────────────────────────────────────────
const int RELAY_PINS[4] = { RELAY_1_PIN, RELAY_2_PIN, RELAY_3_PIN, RELAY_4_PIN };
bool relayStates[4]     = { false, false, false, false };

// Mutex for relay state — accessed from both MQTT callback and networkTask
SemaphoreHandle_t relayMutex = NULL;

// ─────────────────────────────────────────────────────────────────────────────
//  MQTT Client (must only be used from Core 0 / networkTask)
// ─────────────────────────────────────────────────────────────────────────────
WiFiClientSecure espClient;
PubSubClient mqttClient(espClient);

// ─────────────────────────────────────────────────────────────────────────────
//  MQTT Topic Strings (built once in setup)
// ─────────────────────────────────────────────────────────────────────────────
String topicTelemetry;
String topicStatus;
String topicRelaySet[4];
String topicRelayState[4];

// ─────────────────────────────────────────────────────────────────────────────
//  Sensor Reading Functions
//  These are only called from sensorTask (Core 1) — no mutex needed here.
// ─────────────────────────────────────────────────────────────────────────────

float readVoltageRMS() {
  long sumSq = 0;
  for (int i = 0; i < SAMPLES; i++) {
    int centered = analogRead(VOLTAGE_PIN) - ADC_MIDPOINT;
    sumSq += (long)centered * centered;
    delayMicroseconds(SAMPLE_INTERVAL_US);
  }
  float rms = sqrt((float)sumSq / SAMPLES);
  if (rms < NOISE_THRESHOLD) return 0.0f;
  return rms * VCAL;
}

float readCurrentRMS() {
  long sumSq = 0;
  for (int i = 0; i < SAMPLES; i++) {
    int centered = analogRead(CURRENT_PIN) - ADC_MIDPOINT;
    sumSq += (long)centered * centered;
    delayMicroseconds(SAMPLE_INTERVAL_US);
  }
  float rms = sqrt((float)sumSq / SAMPLES);
  if (rms < NOISE_THRESHOLD) return 0.0f;
  return rms * ICAL;
}

float measureFrequency() {
  // ── Step 1: Auto-detect real DC midpoint (bias voltage of ZMPT101B) ─────────
  // Read 100 samples rapidly — with no AC crossing, this gives us the DC offset.
  // This avoids depending on the hardcoded ADC_MIDPOINT for zero-crossing logic.
  long midSum = 0;
  for (int j = 0; j < 100; j++) {
    midSum += analogRead(VOLTAGE_PIN);
    delayMicroseconds(20);
  }
  int midpoint = (int)(midSum / 100);

  // ── Step 2: Count zero-crossings over 500ms using micros() ──────────────────
  // At 50 Hz: 25 full cycles × 2 crossings = 50 crossings expected.
  // Using micros() avoids FreeRTOS tick jitter that can affect millis().
  int crossings = 0;
  bool lastAbove = (analogRead(VOLTAGE_PIN) > midpoint);
  unsigned long startUs = micros();

  while ((micros() - startUs) < 500000UL) {   // 500 ms window
    bool nowAbove = (analogRead(VOLTAGE_PIN) > midpoint);
    if (nowAbove != lastAbove) {
      crossings++;
      lastAbove = nowAbove;
    }
    delayMicroseconds(50);   // 20 kHz sampling — more than enough for 50 Hz
  }

  // ── Step 3: Convert crossings → Hz ──────────────────────────────────────────
  // crossings / 2 = full cycles in 500 ms
  // × 2 = cycles per second (Hz)
  if (crossings < 4) return 0.0f;   // too few crossings → noise, return 0
  return (crossings / 2.0f) * 2.0f;
}


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
  if (apparent == 0.0f) return 1.0f;
  return constrain(abs((float)sumVI / SAMPLES) / apparent, 0.0f, 1.0f);
}

// ─────────────────────────────────────────────────────────────────────────────
//  sensorTask — runs on Core 1
//  Reads all sensors, validates results, then locks mutex and updates
//  the shared SensorData struct. Network task reads from this struct.
// ─────────────────────────────────────────────────────────────────────────────
void sensorTask(void* param) {
  Serial.printf("[SensorTask] Started on Core %d\n", xPortGetCoreID());

  while (true) {
    // ── Read sensors (blocking ADC — safe on Core 1, away from WiFi stack) ──
    float v   = readVoltageRMS();
    float i   = readCurrentRMS();
    float pf  = measurePowerFactor();
    float hz  = measureFrequency();
    float p   = v * i * pf;

    // ── Validate ─────────────────────────────────────────────────────────────
    if (!isfinite(v))  v  = 0.0f;
    if (!isfinite(i))  i  = 0.0f;
    if (!isfinite(p))  p  = 0.0f;
    if (!isfinite(pf)) pf = 1.0f;
    if (!isfinite(hz)) hz = 50.0f;

    // ── Serial debug ──────────────────────────────────────────────────────────
    Serial.println("──── Sensor Reading (Core 1) ────");
    Serial.printf("  Voltage     : %.2f V\n",  v);
    Serial.printf("  Current     : %.3f A\n",  i);
    Serial.printf("  Power       : %.2f W\n",  p);
    Serial.printf("  Frequency   : %.1f Hz\n", hz);
    Serial.printf("  Power Factor: %.3f\n",    pf);
    Serial.println("─────────────────────────────────");

    // ── Lock mutex → update shared struct → release mutex ────────────────────
    // xSemaphoreTake blocks until mutex is available (max 100ms wait)
    if (xSemaphoreTake(dataMutex, pdMS_TO_TICKS(100)) == pdTRUE) {
      latestReading.voltage     = v;
      latestReading.current     = i;
      latestReading.power       = p;
      latestReading.frequency   = hz;
      latestReading.powerFactor = pf;
      latestReading.isValid     = true;
      xSemaphoreGive(dataMutex);  // Release mutex immediately after write
    } else {
      Serial.println("[SensorTask] WARNING: Could not acquire dataMutex");
    }

    // ── Wait 1 second before next reading ─────────────────────────────────────
    // vTaskDelay is FreeRTOS-aware — yields to other tasks during the wait
    vTaskDelay(pdMS_TO_TICKS(1000));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Relay Control (called from networkTask Core 0 — from MQTT callback)
// ─────────────────────────────────────────────────────────────────────────────
void setRelay(int relayIndex, bool state) {
  if (relayIndex < 0 || relayIndex > 3) return;

  if (xSemaphoreTake(relayMutex, pdMS_TO_TICKS(100)) == pdTRUE) {
    relayStates[relayIndex] = state;
    // BC108 NPN: HIGH → transistor conducts → relay ON
    digitalWrite(RELAY_PINS[relayIndex], state ? RELAY_ON : RELAY_OFF);
    xSemaphoreGive(relayMutex);
  }

  Serial.printf("[Relay] %d → %s (GPIO%d)\n",
                relayIndex + 1, state ? "ON" : "OFF", RELAY_PINS[relayIndex]);
}

void publishRelayState(int relayIndex) {
  StaticJsonDocument<128> doc;
  doc["relayId"] = relayIndex + 1;
  if (xSemaphoreTake(relayMutex, pdMS_TO_TICKS(50)) == pdTRUE) {
    doc["state"] = relayStates[relayIndex];
    xSemaphoreGive(relayMutex);
  }
  char buf[128];
  serializeJson(doc, buf);
  mqttClient.publish(topicRelayState[relayIndex].c_str(), buf, true);
  Serial.printf("[MQTT] Relay %d state published\n", relayIndex + 1);
}

// ─────────────────────────────────────────────────────────────────────────────
//  MQTT Callback — called from mqttClient.loop() inside networkTask (Core 0)
// ─────────────────────────────────────────────────────────────────────────────
void mqttCallback(char* topic, byte* payload, unsigned int length) {
  String topicStr = String(topic);

  StaticJsonDocument<256> doc;
  if (deserializeJson(doc, payload, length) != DeserializationError::Ok) {
    Serial.println("[MQTT] JSON parse error in callback");
    return;
  }

  for (int i = 0; i < 4; i++) {
    if (topicStr == topicRelaySet[i]) {
      bool newState = doc["state"].as<bool>();
      setRelay(i, newState);
      publishRelayState(i);
      return;
    }
  }
  Serial.printf("[MQTT] Unhandled topic: %s\n", topic);
}

// ─────────────────────────────────────────────────────────────────────────────
//  WiFi + MQTT Connection Helpers (called from networkTask — Core 0)
// ─────────────────────────────────────────────────────────────────────────────
void connectWiFi() {
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.printf("[WiFi] Connecting to %s", WIFI_SSID);
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED) {
    vTaskDelay(pdMS_TO_TICKS(500));
    Serial.print(".");
    if (++attempts > 40) { Serial.println("\n[WiFi] Timeout — restarting"); ESP.restart(); }
  }
  Serial.printf("\n[WiFi] Connected! IP: %s\n", WiFi.localIP().toString().c_str());
}

void connectMQTT() {
  // setInsecure(): skips CA verification — suitable for prototype
  // Production: replace with espClient.setCACert(hivemq_root_ca_pem)
  espClient.setInsecure();
  mqttClient.setServer(MQTT_HOST, MQTT_PORT);
  mqttClient.setCallback(mqttCallback);
  mqttClient.setBufferSize(1024);

  while (!mqttClient.connected()) {
    Serial.printf("[MQTT] Connecting to %s...\n", MQTT_HOST);
    bool ok = mqttClient.connect(
      MQTT_CLIENT_ID,
      MQTT_USERNAME,
      MQTT_PASSWORD,
      topicStatus.c_str(),  // LWT topic
      1, true, "offline"    // LWT QoS, retain, message
    );

    if (ok) {
      Serial.printf("[MQTT] Connected! ClientID: %s\n", MQTT_CLIENT_ID);
      for (int i = 0; i < 4; i++) {
        mqttClient.subscribe(topicRelaySet[i].c_str(), 1);
        Serial.printf("[MQTT] Subscribed: %s\n", topicRelaySet[i].c_str());
      }
      mqttClient.publish(topicStatus.c_str(), "online", true);
    } else {
      Serial.printf("[MQTT] Failed (state=%d) — retry in 5s\n", mqttClient.state());
      vTaskDelay(pdMS_TO_TICKS(5000));
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  networkTask — runs on Core 0 (same core as WiFi stack)
//  Handles: WiFi connection, MQTT connection/reconnect, telemetry publishing,
//           processing incoming relay command messages.
// ─────────────────────────────────────────────────────────────────────────────
void networkTask(void* param) {
  Serial.printf("[NetworkTask] Started on Core %d\n", xPortGetCoreID());

  connectWiFi();
  connectMQTT();

  unsigned long lastPublishMs = 0;

  while (true) {
    // ── Maintain WiFi ─────────────────────────────────────────────────────────
    if (WiFi.status() != WL_CONNECTED) {
      Serial.println("[WiFi] Lost connection — reconnecting...");
      connectWiFi();
    }

    // ── Maintain MQTT ─────────────────────────────────────────────────────────
    if (!mqttClient.connected()) {
      Serial.println("[MQTT] Lost connection — reconnecting...");
      connectMQTT();
    }

    // ── Process incoming MQTT messages (relay commands) ────────────────────────
    mqttClient.loop();

    // ── Publish telemetry every TELEMETRY_INTERVAL_MS ─────────────────────────
    unsigned long now = millis();
    if (now - lastPublishMs >= TELEMETRY_INTERVAL_MS) {
      lastPublishMs = now;

      // Read shared sensor data with mutex lock
      SensorData reading;
      bool hasData = false;

      if (xSemaphoreTake(dataMutex, pdMS_TO_TICKS(200)) == pdTRUE) {
        reading = latestReading;   // Copy struct atomically
        hasData = reading.isValid;
        xSemaphoreGive(dataMutex); // Release immediately
      }

      if (!hasData) {
        Serial.println("[NetworkTask] Waiting for first sensor reading...");
        vTaskDelay(pdMS_TO_TICKS(10));
        continue;
      }

      // ── Build and publish telemetry JSON ──────────────────────────────────
      StaticJsonDocument<512> doc;
      doc["deviceId"]    = DEVICE_ID;
      doc["voltage"]     = round(reading.voltage     * 100) / 100.0;
      doc["current"]     = round(reading.current     * 1000) / 1000.0;
      doc["power"]       = round(reading.power       * 100) / 100.0;
      doc["frequency"]   = round(reading.frequency   * 10) / 10.0;
      doc["powerFactor"] = round(reading.powerFactor * 1000) / 1000.0;
      // Note: energyKWh NOT sent — backend calculates it from consecutive readings

      char buf[512];
      serializeJson(doc, buf);
      bool ok = mqttClient.publish(topicTelemetry.c_str(), buf, false);
      Serial.printf("[MQTT] Telemetry → %s\n", ok ? "OK" : "FAILED");
    }

    // Yield for 10ms — allows MQTT callback to be called promptly
    vTaskDelay(pdMS_TO_TICKS(10));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  buildTopics() — called once in setup()
// ─────────────────────────────────────────────────────────────────────────────
void buildTopics() {
  String base = "home/" + String(USER_ID) + "/" + String(DEVICE_ID);
  topicTelemetry = base + "/telemetry";
  topicStatus    = base + "/status";
  for (int i = 0; i < 4; i++) {
    topicRelaySet[i]   = base + "/relay/" + String(i + 1) + "/set";
    topicRelayState[i] = base + "/relay/" + String(i + 1) + "/state";
  }
  Serial.println("[Topics] MQTT topics built:");
  Serial.println("  " + topicTelemetry);
  Serial.println("  " + topicStatus);
}

// ─────────────────────────────────────────────────────────────────────────────
//  setup()
// ─────────────────────────────────────────────────────────────────────────────
void setup() {
  Serial.begin(115200);
  delay(500);
  Serial.println("\n=== ESP32 Home Energy Monitor v2.0 ===");
  Serial.println("=== Dual-Core FreeRTOS + MQTT/TLS  ===\n");

  // ── ADC Configuration ─────────────────────────────────────────────────────
  analogReadResolution(12);
  analogSetPinAttenuation(VOLTAGE_PIN, ADC_11db);  // 0–3.3V range
  analogSetPinAttenuation(CURRENT_PIN, ADC_11db);

  // ── Relay Pins — all OFF at startup ──────────────────────────────────────
  for (int i = 0; i < 4; i++) {
    pinMode(RELAY_PINS[i], OUTPUT);
    digitalWrite(RELAY_PINS[i], RELAY_OFF);  // BC108: LOW = relay off
  }
  Serial.println("[Relay] All 4 relays initialized OFF");

  // ── Build MQTT topic strings ──────────────────────────────────────────────
  buildTopics();

  // ── Create FreeRTOS mutexes ───────────────────────────────────────────────
  dataMutex  = xSemaphoreCreateMutex();
  relayMutex = xSemaphoreCreateMutex();

  if (dataMutex == NULL || relayMutex == NULL) {
    Serial.println("[FATAL] Failed to create mutexes — halting");
    while (true) { delay(1000); }
  }
  Serial.println("[RTOS] Mutexes created");

  // ── Create FreeRTOS Tasks ─────────────────────────────────────────────────
  //
  // sensorTask: Core 1, priority 2 (higher = runs when both want CPU)
  //   Stack: 4096 bytes (enough for float math + ArduinoJson)
  xTaskCreatePinnedToCore(
    sensorTask,     // Task function
    "SensorTask",   // Task name (for debugging)
    4096,           // Stack size in bytes
    NULL,           // Parameter
    2,              // Priority (higher than networkTask so readings don't lag)
    NULL,           // Task handle (not needed)
    1               // Core 1
  );

  // networkTask: Core 0, priority 1
  //   Stack: 8192 bytes (WiFi + MQTT + JSON parsing need more stack)
  xTaskCreatePinnedToCore(
    networkTask,
    "NetworkTask",
    8192,
    NULL,
    1,
    NULL,
    0               // Core 0 — same as WiFi stack
  );

  Serial.println("[RTOS] Tasks created:");
  Serial.println("  SensorTask  → Core 1, Priority 2");
  Serial.println("  NetworkTask → Core 0, Priority 1");
  Serial.println("[READY] ESP32 running.\n");
}

// ─────────────────────────────────────────────────────────────────────────────
//  loop() — runs on Core 1 (Arduino default)
//  All real work is in FreeRTOS tasks. loop() just idles.
// ─────────────────────────────────────────────────────────────────────────────
void loop() {
  // Nothing here — FreeRTOS tasks handle everything
  vTaskDelay(pdMS_TO_TICKS(1000));
}
