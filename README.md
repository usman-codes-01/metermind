# ⚡ MeterMind

**Simple electricity meter reading tracker.** Log the cumulative number on your
meter on any date, and MeterMind works out the units used, the per-day usage, and
the days between readings — then charts it over time. Single user, no login.

Full-stack project: **Node.js (Express) API + Flutter app**.

> This is the Flutter app. The Express backend lives in the parent folder (`../server.js`).

---

## ✨ Features

- 📋 **Readings CRUD** — add a reading (pick any date, enter the meter total, optional note), edit, delete
- 🧮 **Auto consumption** — for every reading after the first: `unitsUsed`, `daysGap`, and `perDay`, computed from the previous reading by date (gaps between days are fine)
- ✍️ **Manual override** — set the units used by hand on any row (e.g. after a meter reset), or reset back to auto; recalculates instantly
- 📊 **Calculation summary** — total units used, average per day, and total span across all readings
- 📈 **Graph** — line chart (fl_chart) of per-day usage, with a per-day / per-period toggle
- 🌗 **Dark / light theme**

> No accounts, no passwords — the app opens straight into the tool.

---

## 🧱 Tech Stack

| Layer | Tech |
|-------|------|
| **Backend** | Node.js, Express, CORS — **in-memory store** (no database) |
| **Frontend** | Flutter |
| **State** | `flutter_bloc` (a single `ReadingsCubit`) |
| **Networking / DI** | Dio, get_it |
| **UI** | fl_chart, google_fonts |

> `provider` is present but only powers the `ThemeController`.

### Architecture (frontend)

```
lib/
├── core/            network/ (Dio, ApiClient) · theme/ · widgets/ · utils/ · di/
├── shell/           main_shell.dart  (2-tab bottom nav)
└── features/
    └── readings/    reading.dart · reading_calculator.dart · readings_repository.dart
                     readings_cubit.dart · pages/ (readings, graph) · widgets/
```

The cubit holds the **raw** readings and derives `unitsUsed / daysGap / perDay`
locally via `ReadingCalculator` (which mirrors the backend), so manual overrides
update the UI instantly, then persist via the API.

### The calculation

Sort readings by `date` ascending. For each reading **after the first**:

```
unitsUsed = manualUnits ?? (this.meterReading − previous.meterReading)
daysGap   = max(1, days between this.date and previous.date)
perDay    = unitsUsed / daysGap
```

- The first reading is the **baseline** (`unitsUsed` etc. are `—`).
- "previous" = the most recent reading *before* this one by date.
- If the meter reading goes **down** (negative diff, e.g. a reset), the row is
  flagged invalid and you fix it with a manual override.

Summary: `totalUnitsUsed` = Σ unitsUsed, `totalDays` = days between first and last
reading, `avgPerDay` = totalUnitsUsed / totalDays.

---

## 🔌 API Endpoints

Base URL (local): `http://localhost:8080` — all routes are public (no auth headers).

| Method | Path | Body | Notes |
|--------|------|------|-------|
| `GET`  | `/` | — | health check |
| `GET`  | `/readings` | — | all readings, each with `unitsUsed / daysGap / perDay / invalid` |
| `GET`  | `/readings/summary` | — | `{ totalUnitsUsed, totalDays, avgPerDay }` |
| `POST` | `/readings` | `meterReading, date?, manualUnits?, note?` | create (`date` defaults to today) |
| `GET`  | `/readings/:id` | — | single reading + derived fields |
| `PUT`  | `/readings/:id` | `meterReading, date, manualUnits, note` | full update |
| `PATCH`| `/readings/:id` | any subset (e.g. `manualUnits`) | partial update; send `manualUnits: null` to reset to auto |
| `DELETE`| `/readings/:id` | — | delete |

> The store is in-memory, so readings reset when the server restarts.

---

## 🚀 Setup

### 1. Backend (parent folder)

```bash
cd ..
npm install        # only express + cors
npm start          # → Server running at http://localhost:8080
```

No database or environment setup required.

### 2. Frontend (this folder)

```bash
flutter pub get
flutter run
```

---

## 📡 Connecting a real phone (LAN)

The app talks to the backend over plain HTTP on your local network, so **phone and
PC must be on the same Wi-Fi**.

1. Find your PC's IPv4 address: run `ipconfig` (Windows) → look for `IPv4 Address`
   (e.g. `192.168.100.8`).
2. Set it in **`lib/core/network/api_constants.dart`**:
   ```dart
   static const String _host = '192.168.100.8'; // ← your PC's LAN IP
   static const int    _port = 8080;
   ```
3. Re-run the app (full restart, not hot reload).

| Target | baseUrl |
|--------|---------|
| Physical device | `http://<PC-LAN-IP>:8080` |
| Android emulator | `http://10.0.2.2:8080` |
| iOS sim / web | `http://localhost:8080` |

> ⚠️ **The LAN IP changes when you switch networks (DHCP).** If requests start
> failing with "Cannot reach the server", re-check `ipconfig` and update `_host`.
> Android cleartext HTTP is enabled via `usesCleartextTraffic="true"` for LAN testing.

---

## 📸 Screenshots

> _Add screenshots here._

| Readings | Add reading | Graph |
|----------|-------------|-------|
| _TODO_ | _TODO_ | _TODO_ |

---

## 📝 Notes

- The backend is intentionally minimal (in-memory) — swap the array for a database
  if you need persistence across restarts.
- `usesCleartextTraffic` should be removed (or scoped via a network-security-config)
  once the backend is served over HTTPS.
