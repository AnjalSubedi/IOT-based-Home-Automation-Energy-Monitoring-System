/**
 * config.h — Device Credentials (DO NOT commit this file)
 *
 * SETUP INSTRUCTIONS:
 *  1. Copy this file: copy config.example.h config.h
 *  2. Fill in your actual values below
 *  3. config.h is in .gitignore and will never be committed
 */

#ifndef CONFIG_H
#define CONFIG_H

// ── Wi-Fi ─────────────────────────────────────────────────────────────────────
#define WIFI_SSID       "Your_WiFi_Name"
#define WIFI_PASSWORD   "Your_WiFi_Password"

// ── MQTT Broker (HiveMQ Cloud TLS) ────────────────────────────────────────────
// Get these from: https://www.hivemq.com/mqtt-cloud-broker/
#define MQTT_HOST       "your-cluster.s1.eu.hivemq.cloud"
#define MQTT_PORT       8883
#define MQTT_USERNAME   "your_mqtt_username"
#define MQTT_PASSWORD   "your_mqtt_password"

// ── Device Identity ───────────────────────────────────────────────────────────
// Get DEVICE_ID and USER_ID from your MongoDB after registering in the app
#define DEVICE_ID       "esp32-001"
#define DEVICE_SECRET   "your-device-secret-uuid"
#define USER_ID         "your-mongodb-user-objectid"
#define MQTT_CLIENT_ID  "esp32-001_unique-suffix"

// ── 4-Channel Relay GPIO Pins ─────────────────────────────────────────────────
#define RELAY_1_PIN     4
#define RELAY_2_PIN     16
#define RELAY_3_PIN     17
#define RELAY_4_PIN     5

// Relay logic (BC108 NPN driver — ACTIVE HIGH)
#define RELAY_ON        HIGH
#define RELAY_OFF       LOW

// ── Sensor GPIO Pins ──────────────────────────────────────────────────────────
#define VOLTAGE_PIN     35   // ZMPT101B → ADC pin
#define CURRENT_PIN     34   // ACS712   → ADC pin

// ── ADC & Sampling ────────────────────────────────────────────────────────────
#define SAMPLES               1000
#define SAMPLE_INTERVAL_US     100
#define ADC_MIDPOINT          1862
#define NOISE_THRESHOLD         30

// ── Calibration ───────────────────────────────────────────────────────────────
// Adjust VCAL and ICAL with a multimeter after assembly.
// VCAL = actual_voltage / displayed_voltage * current_VCAL
// ICAL = actual_current / displayed_current * current_ICAL
#define VCAL    0.2344f   // Voltage calibration factor
#define ICAL    0.30f     // Current calibration factor

// ── Telemetry Interval ────────────────────────────────────────────────────────
#define TELEMETRY_INTERVAL_MS   10000   // Send readings every 10 seconds

#endif // CONFIG_H
