# Security and privacy

Status: current as of review round 4 (2026-10-31). Findings are tracked in `docs/review/PROGRESS.md` and the scorecards in `docs/scorecards/`.

## What data the app holds

| Data | Where | Why |
|---|---|---|
| Last known GPS position (`gps_coords`, rounded to ~1 km) | Application.Storage on the watch | Lets the background refresh fetch GPS weather without a live fix |
| Home latitude/longitude | App settings (Properties), set by the user in Garmin Connect | Home weather |
| Place name and the coordinates (rounded to ~1 km) it was looked up for, per location (`gps_place`, `home_place`) | Application.Storage | Avoids repeating the lookup |
| Weather and forecast arrays, place names | Application.Storage | Instant display on launch and in the glance |
| Time of the last successful update, per location (`gps_fetch_time`, `home_fetch_time`) | Application.Storage | Skips refetching fresh data |
| Home coordinates the saved Home weather was fetched for (`home_fetch_for`) | Application.Storage | Fetches Home again after it changes, even while the widget was closed |

No account, name, email, device identifier or analytics are collected. Nothing leaves the watch except the requests below.

## Who receives data

All requests go over HTTPS through the paired phone (Garmin Connect Mobile), which also exposes the phone's IP address to the receiver.

| Service | Company / country | What is sent | When |
|---|---|---|---|
| Open-Meteo `api.open-meteo.com` | OpenMeteo GmbH (Switzerland). Its [terms](https://open-meteo.com/en/terms) say server logs may include IP addresses and coordinates and are deleted after 90 days | GPS and Home coordinates, rounded to 2 decimal places (~1 km) | Each foreground fetch and each background refresh |
| Nominatim `nominatim.openstreetmap.org` | OpenStreetMap Foundation (UK) | GPS and Home coordinates, rounded to 2 decimal places (~1 km), User-Agent with app version and repo contact | Foreground: GPS or Home when it has moved > ~1 km since its last successful lookup. Background: Home only, on the same rule |

## How it is protected

- No secrets: neither service needs an API key, and none is stored in the repo or its history. The Connect IQ developer signing key lives outside the repo and is listed in `.gitignore`.
- HTTPS only; certificate validation is handled by the phone and never disabled.
- No logging (`System.println`) of locations or responses.
- Coordinates sent to third parties are rounded to about 1 km in one place (`Coordinates.mc`).
- Open-Meteo and Nominatim replies and cached weather are validated in `WeatherParser.mc` before use; place names must be text and are capped at 30 characters.
- Positions from the system and from Storage are range-checked (`Coordinates.validOrNull()`); other saved values (`gps_fetch_time`, `home_fetch_time`, `gps_place`, `home_place`, `home_fetch_for`, the background result) are type-checked before use (`Values.mc`, `FetchRules.savedPlaceName()`, `FetchRules.fetchedForHome()`, `BackgroundResult.writes()`, `GlanceRules.isDrawable()`), and the refresh-interval setting is range-checked (`FetchRules.refreshMinutes()`).
- User-entered Home settings are validated (`HomeSettings.mc`) before use or sending: they must be numbers within latitude ±90 and longitude ±180.
- Permissions are limited to Background (scheduled refresh), Communications (web requests) and Positioning (GPS).

## Known remaining risks

| Severity | Risk |
|---|---|
| — | ~~High: `PRIVACY.md` omitted Nominatim and Home coordinates.~~ Fixed 2026-10-29 (B1): both services and both locations are now disclosed. No in-app consent step: the widget's purpose implies sending location to a weather service, and the policy discloses the place-name lookup. |
| — | ~~Medium: coordinates were sent with ~11 m precision.~~ Fixed 2026-10-29 (B3): all outgoing coordinates go through `Coordinates.forRequest()` and are rounded to 2 dp (~1 km). Unit tested. |
| Low | ~~Medium: the default Home coordinates were the developer's own location.~~ Reduced 2026-10-29 (B3): new installs start blank. The old values stay in `HomeSettings.mc` as a "not set" marker for existing installs, and remain in git history and released builds. The owner chose not to rewrite history. |
| — | ~~Medium: Home settings were not validated.~~ Fixed 2026-10-29 (B2): `HomeSettings.mc` rejects non-numeric, out-of-range and half-filled values. Nothing is fetched for them, and the user sees "Check Home settings". Unit tested. |
| — | ~~Medium: Open-Meteo replies were used without checks.~~ Fixed 2026-10-29 (B4): `WeatherParser.mc` type- and length-checks every field, and malformed replies are ignored (previous data kept). Cached Storage arrays are shape-checked before drawing, in both widget and glance. Tested against a recorded real reply and damaged copies. |
| — | ~~Medium (F6): weather icons are GPL-3.0 while the app was "All rights reserved".~~ Fixed 2026-10-31 (round 4): the owner chose to release the app under GPL-3.0 (`LICENSE`); README credits the icons. The source is public on GitHub. |
| Low | Stale `.iq` tracked in git: removal is staged (B5) but takes effect only when the owner commits; it stays in history. |
| — | ~~Low: Nominatim politeness.~~ Fixed (B5, round 4): widget and background reuse a saved place name until the location moves about 1 km; User-Agent has version and contact (`RequestHeaders.mc`). |
| Low | The last GPS position is kept until the widget is removed (now rounded to ~1 km, B5); there is no "clear data" option. |
| — | ~~Low: `.gitignore` gaps.~~ Fixed (B5): `*.der`, `*.pem`, `*.p12`, `.claude/settings.local.json` added. |
| — | ~~Low (N1/N2, round 2): Nominatim replies and some saved values were not type-checked.~~ Fixed 2026-10-30 (B6), with unit tests. |
| — | ~~Low (F11): HTTP errors were ignored silently.~~ Fixed 2026-10-30 (round 3): a failed refresh shows "No connection · <data time>", or "No connection. Press MENU to retry." when there is no data. |
| — | ~~Low (N3, round 3): the glance read saved weather without checking it was a list.~~ Fixed 2026-10-31 (round 4): `GlanceRules.isDrawable()` checks the type first. Unit tested. |
| Low | The store-asset Python script has no pinned dependencies (developer tool only). |
