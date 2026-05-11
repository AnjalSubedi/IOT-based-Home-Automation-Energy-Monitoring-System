/*
 * config.example.h — ESP32 Home Energy Monitor Configuration
 *
 * INSTRUCTIONS:
 *   1. Copy this file and rename it to: config.h
 *   2. Fill in your actual credentials below
 *   3. NEVER commit config.h to Git (it's in .gitignore)
 *
 * ─────────────────────────────────────────────────────────────────────────────
 * ⚠  AC MAINS VOLTAGE SAFETY WARNING
 * ─────────────────────────────────────────────────────────────────────────────
 * This device switches 220V AC mains voltage via relay modules.
 *  - NEVER touch relay terminals while powered from mains
 *  - Use a relay module rated ≥ 10A 250VAC (e.g., SRD-05VDC-SL-C)
 *  - Always add a correctly-rated fuse on the LIVE wire
 *  - Enclose all relay/mains terminals in a non-conductive box
 *  - Use properly rated mains-voltage wire (1.5mm² minimum)
 *  - Test relay switching at LOW VOLTAGE before connecting mains
 *  - Mains wiring must be done by or supervised by a qualified electrician
 *  - This firmware is for PROTOTYPE / DEMONSTRATION purposes only
 * ─────────────────────────────────────────────────────────────────────────────
 */

#ifndef CONFIG_H
#define CONFIG_H

// ─── Wi-Fi Credentials ────────────────────────────────────────────────────────
#define WIFI_SSID       "Your_WiFi_SSID"
#define WIFI_PASSWORD   "Your_WiFi_Password"

// ─── HiveMQ Cloud MQTT (TLS, Port 8883) ──────────────────────────────────────
// Get these from: console.hivemq.cloud → Your Cluster → Overview
#define MQTT_HOST       "navymason-22145bc2.a03.euc1.aws.hivemq.cloud"
#define MQTT_PORT       8883
#define MQTT_USERNAME   "smarthome_user"
#define MQTT_PASSWORD   "SmartHome@2026"

// ─── Device Identity ──────────────────────────────────────────────────────────
// deviceId must match exactly what you registered via POST /api/devices
// deviceSecret is returned only on first device registration — copy it here
#define DEVICE_ID       "esp32-001"
#define DEVICE_SECRET   "paste-your-device-secret-uuid-here"

// User ID (MongoDB _id from registration response)
#define USER_ID         "paste-your-user-id-here"

// MQTT Client ID must be unique — using deviceId + deviceSecret prefix
// Format: "{DEVICE_ID}_{first-8-chars-of-DEVICE_SECRET}"
#define MQTT_CLIENT_ID  "esp32-001_abcd1234"

// ─── 4-Channel Relay GPIO Mapping ────────────────────────────────────────────
// PCB uses BC108 NPN transistor drivers:
//   GPIO HIGH → transistor ON → relay energized → load ON  (ACTIVE HIGH)
// Adjust pins to match your PCB trace routing if needed
#define RELAY_1_PIN     26    // Appliance 1 (e.g., Light)
#define RELAY_2_PIN     27    // Appliance 2 (e.g., Fan)
#define RELAY_3_PIN     14    // Appliance 3 (e.g., Socket)
#define RELAY_4_PIN     12    // Appliance 4 (e.g., Spare)

// Relay logic: HIGH = relay ON (NPN driver — BC108 on your PCB)
#define RELAY_ON        HIGH
#define RELAY_OFF       LOW

// ─── Sensor GPIO Pins ─────────────────────────────────────────────────────────
#define VOLTAGE_PIN     34    // ZMPT101B signal → GPIO34 (ADC1_CH6)
#define CURRENT_PIN     35    // ACS712 signal   → GPIO35 (ADC1_CH7)

// ─── ADC & Sampling Configuration ────────────────────────────────────────────
#define SAMPLES              1000   // Samples per RMS window (1000 × 100µs = 100ms = 5 cycles)
#define SAMPLE_INTERVAL_US    100   // 100µs → 10 kHz sample rate

// ADC midpoint (bias voltage) — ~VCC/2 = ~1862 for 3.3V reference at 12-bit
// Calibrate: with no AC signal, read analogRead(VOLTAGE_PIN) and set this to the average
#define ADC_MIDPOINT        1862

// Raw ADC RMS below this level is treated as zero (floating pin noise floor)
#define NOISE_THRESHOLD       30

// ─── Calibration Constants ───────────────────────────────────────────────────
//
// ZMPT101B Voltage Calibration (VCAL):
//   VCAL = (actual_Vrms_from_multimeter) / (raw_ADC_rms_reading)
//   Start with VCAL = 1.0 and adjust until ESP32 matches your multimeter
//   Increase VCAL if ESP32 reads LOWER than real voltage
//   Decrease VCAL if ESP32 reads HIGHER than real voltage
#define VCAL    110.0f    // Tune with multimeter — typical range: 50–200

//
// ACS712 Current Calibration (ICAL):
//   ACS712-05B:  sensitivity = 185 mV/A → ICAL ≈ 0.185 / (3.3/4096) ≈ some raw units
//   ACS712-20A:  sensitivity = 100 mV/A
//   ACS712-30A:  sensitivity =  66 mV/A
//   Tune ICAL with a clamp meter at the same load
//   Increase ICAL if ESP32 reads LOWER than real current
#define ICAL    0.30f     // Tune with clamp meter

// ─── Telemetry Interval ───────────────────────────────────────────────────────
// How often to publish sensor readings (milliseconds)
#define TELEMETRY_INTERVAL_MS   10000   // 10 seconds

#endif // CONFIG_H
