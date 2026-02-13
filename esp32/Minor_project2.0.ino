#include <ArduinoJson.h>
#include <HTTPClient.h>
#include <WiFi.h>

const char *ssid = "Radhe Radhe 108";
const char *password = "Radheradhe108";

// Example: http://192.168.1.10:5000/data
const char *serverUrl =
    "http://10.252.192.49:5000/api/readings"; // REPLACED WITH YOUR PC's IP
                                              // ADDRESS

void setup() {
  Serial.begin(115200);

  WiFi.begin(ssid, password);
  Serial.print("Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi connected!");
  Serial.print("ESP32 IP: ");
  Serial.println(WiFi.localIP());

  randomSeed(analogRead(0));
}

void loop() {
  if (WiFi.status() == WL_CONNECTED) {
    HTTPClient http;
    http.begin(serverUrl);
    http.addHeader("Content-Type", "application/json");

    // Generate dummy data
    float voltage = random(2100, 2400) / 10.0;   // 210.0 - 240.0 V
    float current = random(10, 1500) / 100.0;    // 0.10 - 15.00 A
    float power = voltage * current;             // Watts
    float energy = random(100, 5000) / 100.0;    // kWh
    float frequency = random(495, 505) / 10.0;   // 49.5 - 50.5 Hz
    float powerFactor = random(80, 100) / 100.0; // 0.80 - 1.00

    // Build JSON (ArduinoJson v6/v7 compatible)
    // If using v7 replace StaticJsonDocument with JsonDocument
    StaticJsonDocument<512> doc;
    doc["voltage"] = voltage;
    doc["current"] = current;
    doc["power"] = power;
    doc["energy"] = energy;
    doc["frequency"] = frequency;
    doc["powerFactor"] = powerFactor;
    doc["deviceId"] = "esp32-001";

    String requestBody;
    serializeJson(doc, requestBody);

    int httpResponseCode = http.POST(requestBody);

    Serial.print("HTTP Response code: ");
    Serial.println(httpResponseCode);
    Serial.println(requestBody);

    http.end();
  } else {
    Serial.println("WiFi Disconnected");
  }

  delay(5000); // Send data every 5 seconds
}
