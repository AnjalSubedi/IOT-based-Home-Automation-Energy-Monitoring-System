# ESP32 Home Energy Monitor — Firmware Guide

## Required Hardware
| Component | Description |
|---|---|
| ESP32 (30-pin) | Main microcontroller |
| ZMPT101B | AC Voltage sensor → GPIO34 |
| ACS712 (5A/20A/30A) | AC Current sensor → GPIO35 |
| 4-ch Relay Module | BC108 NPN driver → GPIO 26, 27, 14, 12 |
| L7805 regulator | 5V supply for relay module (from PCB) |

---

## Arduino IDE Setup

### 1. Install ESP32 Board Package
1. Open Arduino IDE → **File → Preferences**
2. Add to "Additional board manager URLs":
   ```
   https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json
   ```
3. Go to **Tools → Board → Board Manager** → search "esp32" → Install **"esp32 by Espressif Systems"**

### 2. Install Required Libraries
Go to **Sketch → Include Library → Manage Libraries** and install:

| Library | Author | Search Term |
|---|---|---|
| PubSubClient | Nick O'Leary | `PubSubClient` |
| ArduinoJson | Benoit Blanchon | `ArduinoJson` |

*(WiFiClientSecure is built into the ESP32 board package — no install needed)*

### 3. Board Settings
- **Board**: `ESP32 Dev Module`
- **Upload Speed**: `921600`
- **Flash Size**: `4MB (32Mb)`
- **Partition Scheme**: `Default 4MB`
- **Port**: Select your ESP32 COM port

---

## Configuration

1. Copy `config.example.h` → `config.h` (in the same folder as the .ino file)
2. Fill in these values in `config.h`:

```cpp
#define WIFI_SSID      "YourWiFiName"
#define WIFI_PASSWORD  "YourWiFiPassword"

// From your .env file (already filled in):
#define MQTT_HOST      "navymason-22145bc2.a03.euc1.aws.hivemq.cloud"
#define MQTT_USERNAME  "smarthome_user"
#define MQTT_PASSWORD  "SmartHome@2026"

// From POST /api/devices response:
#define DEVICE_ID      "esp32-001"
#define DEVICE_SECRET  "paste-uuid-from-registration"
#define USER_ID        "paste-mongodb-user-id"
#define MQTT_CLIENT_ID "esp32-001_firstsecretchars"
```

---

## Relay GPIO Mapping (matches your PCB)

| Relay | GPIO | Appliance |
|---|---|---|
| Relay 1 | GPIO 26 | Appliance 1 (Light) |
| Relay 2 | GPIO 27 | Appliance 2 (Fan) |
| Relay 3 | GPIO 14 | Appliance 3 (Socket) |
| Relay 4 | GPIO 12 | Appliance 4 (Spare) |

**Logic**: BC108 NPN transistor driver on your PCB:
- `GPIO HIGH` → transistor ON → relay coil energized → NO contact closes → **Load ON**
- `GPIO LOW` → transistor OFF → relay released → **Load OFF**

---

## Sensor Calibration

### ZMPT101B (Voltage Sensor)
1. Connect a known AC load (e.g., 60W bulb)
2. Measure real voltage with a **certified multimeter** across the same terminals
3. Open Serial Monitor — note the printed voltage value
4. Calculate: `VCAL = actual_voltage / reported_voltage × current_VCAL`
5. Update `#define VCAL` in `config.h` and re-upload
6. Repeat until values match within ±2V

**Midpoint calibration:**
- With no AC signal connected, run `Serial.println(analogRead(VOLTAGE_PIN))` 1000 times
- Average the readings → set as `ADC_MIDPOINT`

### ACS712 (Current Sensor)
1. Connect a known resistive load (100W bulb ≈ 0.45A at 220V)
2. Measure real current with a **clamp meter**
3. Note the printed current value in Serial Monitor
4. Calculate: `ICAL = actual_current / reported_current × current_ICAL`
5. Update `#define ICAL` in `config.h` and re-upload

**ACS712 sensitivity reference:**
| Model | Sensitivity | Typical ICAL range |
|---|---|---|
| ACS712-05B | 185 mV/A | 0.10–0.50 |
| ACS712-20A | 100 mV/A | 0.10–0.50 |
| ACS712-30A | 66 mV/A | 0.05–0.30 |

---

## MQTT Topic Reference

The firmware uses these topic patterns (auto-built from `USER_ID` and `DEVICE_ID`):

| Direction | Topic | Description |
|---|---|---|
| **Publish** | `home/{userId}/{deviceId}/telemetry` | Sensor readings every 10s |
| **Publish** | `home/{userId}/{deviceId}/relay/{n}/state` | Relay state confirmation |
| **Publish** | `home/{userId}/{deviceId}/status` | `"online"` / `"offline"` (LWT) |
| **Subscribe** | `home/{userId}/{deviceId}/relay/{n}/set` | Commands from backend |

---

## Flashing & Testing

1. Upload firmware via Arduino IDE
2. Open **Serial Monitor** at **115200 baud**
3. Verify output:
   ```
   === ESP32 Home Energy Monitor v2.0 ===
   [WiFi] Connected! IP: 192.168.x.x
   [MQTT] Connecting to navymason-22145bc2...
   [MQTT] Connected! Client ID: esp32-001_...
   [MQTT] Subscribed: home/.../relay/1/set
   ...
   [READY] ESP32 is online and monitoring.
   ==============================
   Voltage     : 228.45 V
   Current     : 0.432 A
   Power       : 98.69 W
   Frequency   : 50.0 Hz
   Power Factor: 0.998
   ==============================
   [MQTT] Telemetry published: OK
   ```
4. Check backend logs — you should see:
   ```
   [MQTT] Telemetry stored: esp32-001 → V:228.5 I:0.43 P:98.7W
   ```

---

## ⚠ AC Safety — IMPORTANT

```
220V AC MAINS VOLTAGE IS POTENTIALLY LETHAL.
READ BEFORE WIRING ANYTHING TO MAINS:

✗ NEVER touch relay terminals while powered from mains
✗ NEVER connect mains without a properly rated fuse
✗ NEVER leave live wires uninsulated or exposed

✓ Use relay module rated ≥ 10A 250VAC (SRD-05VDC-SL-C)
✓ Add a fuse (appropriate rating for your load) on the LIVE wire
✓ Enclose all relay/mains terminals in a non-conductive enclosure
✓ Use mains-rated wire (1.5mm² for loads up to 10A)
✓ Test relay ON/OFF at LOW VOLTAGE first (e.g., 12V DC lamp)
✓ Mains wiring must be done by or supervised by a qualified electrician

THIS FIRMWARE IS FOR PROTOTYPE/DEMO USE ONLY.
```

---

## Troubleshooting

| Problem | Cause | Fix |
|---|---|---|
| `[MQTT] Failed (state=-2)` | Network unreachable | Check WiFi credentials, internet connection |
| `[MQTT] Failed (state=5)` | Wrong credentials | Check `MQTT_USERNAME` / `MQTT_PASSWORD` |
| Voltage reads 0 | ZMPT101B not connected | Check GPIO34 wiring and sensor power |
| Current reads 0 | ACS712 not connected | Check GPIO35 wiring |
| Relay doesn't switch | Wrong GPIO or RELAY_ON level | Verify GPIO pins match PCB; BC108 = ACTIVE HIGH |
| Values wildly wrong | VCAL/ICAL incorrect | Recalibrate against multimeter/clamp meter |
