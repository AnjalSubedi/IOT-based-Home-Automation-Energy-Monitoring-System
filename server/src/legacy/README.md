# Legacy Files

These files are from the original HTTP-polling version of the server.
They are kept here for reference only and are NOT used by the new server.

## New Structure
All active code is now in src/ with full MQTT, JWT auth, and Socket.IO support.

## Files
- Reading.js       → replaced by src/models/EnergyReading.js
- RelayCommand.js  → replaced by src/models/Relay.js
- RelayEvent.js    → removed (relay history tracked via Relay model)
- readingRoutes.js → replaced by src/routes/deviceRoutes.js
- relayRoutes.js   → replaced by src/routes/deviceRoutes.js
- db_old.js        → replaced by src/config/db.js
