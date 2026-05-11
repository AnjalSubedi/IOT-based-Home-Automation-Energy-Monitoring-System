# IoT Home Automation & Energy Monitoring System — Backend

## Phase 1 Complete ✅

Node.js + Express + MongoDB + MQTT (HiveMQ) + Socket.IO backend.

---

## Quick Start

### 1. Install dependencies
```bash
cd server
npm install
```

### 2. Configure environment
```bash
cp .env.example .env
```
Edit `.env` and fill in:
- Your **MongoDB URI** (Atlas or local)
- Your **JWT_SECRET** (any long random string)
- Your **HiveMQ Cloud credentials** (see below)

### 3. Get HiveMQ Cloud credentials
1. Go to https://console.hivemq.cloud and create a free account
2. Create a new cluster (free tier — no credit card needed)
3. Go to **Manage Credentials** → Create a new username/password
4. Copy the **Cluster URL** (e.g., `abc123.s1.eu.hivemq.cloud`)
5. Add to `.env`:
   ```
   MQTT_HOST=abc123.s1.eu.hivemq.cloud
   MQTT_PORT=8883
   MQTT_USERNAME=your_username
   MQTT_PASSWORD=your_password
   ```

### 4. Start the server
```bash
# Development (auto-restart)
npm run dev

# Production
npm start
```

Server starts on `http://localhost:5000`

---

## Testing Without ESP32 (MQTT Simulator)

Run the simulator to publish fake sensor data while the backend is running:

```bash
# First register a user and device via the API, then:
node scripts/mqtt_simulator.js --userId <your_user_id> --deviceId esp32-001

# Custom interval (ms)
node scripts/mqtt_simulator.js --userId <id> --deviceId esp32-001 --interval 3000
```

The simulator will:
- Publish telemetry every 5 seconds (V, I, P, frequency, PF)
- Echo relay commands back as state confirmations
- Publish online/offline status

---

## API Reference

### Authentication
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/register` | Register new user |
| POST | `/api/auth/login` | Login, get JWT token |
| GET | `/api/auth/me` | Get current user |

**Register:**
```json
POST /api/auth/register
{
  "name": "Anjal Subedi",
  "email": "anjal@example.com",
  "password": "password123"
}
```

**Login:**
```json
POST /api/auth/login
{
  "email": "anjal@example.com",
  "password": "password123"
}
```
Returns: `{ "token": "eyJ..." }`

Use the token as: `Authorization: Bearer eyJ...` on all protected routes.

---

### Devices
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/devices` | List all devices |
| POST | `/api/devices` | Register new device |
| GET | `/api/devices/:deviceId` | Get device + relay states |
| PUT | `/api/devices/:deviceId` | Update name/location |
| DELETE | `/api/devices/:deviceId` | Remove device |

**Register Device:**
```json
POST /api/devices
Authorization: Bearer <token>
{
  "deviceId": "esp32-001",
  "name": "Living Room Monitor",
  "location": "Living Room"
}
```
Returns `deviceSecret` — copy this to your ESP32 `config.h`. **It will not be shown again.**

---

### Relay Control
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/devices/:deviceId/relays` | Get all relay states |
| POST | `/api/devices/:deviceId/relays/:relayId/control` | Control relay |

```json
POST /api/devices/esp32-001/relays/1/control
{ "state": true }   // true = ON, false = OFF
```

---

### Energy Data
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/devices/:deviceId/latest` | Latest reading |
| GET | `/api/devices/:deviceId/history` | Historical readings |
| GET | `/api/devices/:deviceId/summary` | Energy summary + cost |
| GET | `/api/devices/:deviceId/graph` | Graph data points |

**Query parameters for history:**
- `from` — ISO date string (e.g. `2026-05-01T00:00:00Z`)
- `to` — ISO date string
- `limit` — max records (default: 100)

**Query parameters for summary:**
- `period` — `today` | `week` | `month`

---

### Alerts
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/devices/:deviceId/alerts` | Device alerts |
| GET | `/api/alerts` | All alerts |
| PUT | `/api/alerts/:id/read` | Mark as read |
| PUT | `/api/alerts/read-all` | Mark all as read |

---

### Schedules
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/devices/:deviceId/schedules` | Add schedule |
| GET | `/api/devices/:deviceId/schedules` | List schedules |
| DELETE | `/api/schedules/:id` | Delete schedule |
| PUT | `/api/schedules/:id/toggle` | Enable/disable |

```json
POST /api/devices/esp32-001/schedules
{
  "relayId": 1,
  "action": "ON",
  "cronExpression": "0 7 * * *",
  "label": "Morning lights"
}
```

---

### Automation Rules
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/devices/:deviceId/rules` | Add rule |
| GET | `/api/devices/:deviceId/rules` | List rules |
| DELETE | `/api/rules/:id` | Delete rule |

```json
POST /api/devices/esp32-001/rules
{
  "label": "Turn off fan if power > 3000W",
  "condition": { "field": "power", "operator": "gt", "value": 3000 },
  "action": { "type": "RELAY_CONTROL", "relayId": 2, "state": false }
}
```

---

### Tariff Settings
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/tariff` | Get current tariff |
| PUT | `/api/tariff` | Update tariff |

```json
PUT /api/tariff
{
  "slabs": [
    { "fromKWh": 0,   "toKWh": 30,   "ratePerKWh": 4.00,  "label": "0–30 units"   },
    { "fromKWh": 30,  "toKWh": 100,  "ratePerKWh": 8.50,  "label": "30–100 units" },
    { "fromKWh": 100, "toKWh": null, "ratePerKWh": 11.00, "label": "100+ units"   }
  ],
  "currency": "NPR",
  "fixedMonthlyCharge": 0
}
```

---

## MQTT Topic Reference

| Topic | Direction | Description |
|-------|-----------|-------------|
| `home/{userId}/{deviceId}/telemetry` | ESP32 → Backend | Sensor readings |
| `home/{userId}/{deviceId}/relay/{n}/set` | Backend → ESP32 | Relay command |
| `home/{userId}/{deviceId}/relay/{n}/state` | ESP32 → Backend | State confirmation |
| `home/{userId}/{deviceId}/status` | ESP32 → Backend | Online/offline |

---

## Socket.IO Events (Flutter receives)

Connect with JWT:
```dart
socket.io.options['auth'] = {'token': jwtToken};
```

| Event | Data | Description |
|-------|------|-------------|
| `live_reading` | `{deviceId, voltage, current, power, ...}` | New telemetry |
| `relay_state` | `{deviceId, relayId, state, changedBy}` | Relay changed |
| `new_alert` | Alert object | New alert triggered |
| `device_status` | `{deviceId, isOnline}` | Online/offline |

---

## Folder Structure

```
server/
  src/
    config/         ← db.js, mqtt.js
    models/         ← 8 MongoDB models
    middleware/     ← auth.js, validate.js
    controllers/    ← 8 controllers
    routes/         ← authRoutes, deviceRoutes, miscRoutes
    mqtt/           ← mqttClient.js, topicHandler.js, handlers/
    sockets/        ← socketManager.js
    services/       ← energyService, automationService, scheduleService
    utils/          ← logger.js, energyCalc.js
    legacy/         ← old HTTP-polling files (unused)
  scripts/
    mqtt_simulator.js
  app.js
  server.js
  .env.example
  package.json
```

---

## ⚠ Safety Notice

This backend controls relay modules connected to mains voltage (220V AC).
- Test with low-voltage loads first
- Ensure all relay wiring is properly insulated and fused
- Do not expose the API to the public internet without HTTPS and rate limiting
