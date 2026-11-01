# Store listing: SimpleGlance Weather Widget

The single source of truth for this app's public text. The Connect IQ Store listing is
pasted from here, and the public support repo (`simpleglance-weather-widget-support`)
copies "About" and the privacy policy from here. Edit here first, never in the portal or
the support repo alone.

Captured from the Connect IQ developer dashboard on 2026-11-01 (read only).

## Store record

| Field | Value now (2026-11-01) | Should be |
|---|---|---|
| Store | Garmin Connect IQ Store | |
| App ID | `bfdd2573-a006-4027-852b-78e1f22d3c56` (manifest `c7a4f8e2-3b1d-4f9a-8c6e-2d5b7a9f1e3c`) | |
| Title | SimpleGlance Weather Widget | |
| Type | Widget | |
| Price | Free | |
| Version | 1.5 (internal 8), released 2026-10-31; first release 2026-05-18 | |
| Compatible devices | fēnix 6 family (6, 6S, 6 Pro, Solar, Dual Power) and quatix 6 | |
| Permissions | Communication & Data Transmission; Background Activity; Location & Tracking | |
| "Does your app collect user data?" | No | **Owner to decide**: the widget sends the watch's location (rounded to about 1 km) to Open-Meteo. "Yes" plus the privacy policy link is the safer answer. |
| Privacy policy link | None (not required while the answer above is "No") | `https://github.com/Mahoneyclan/simpleglance-weather-widget-support/blob/main/PRIVACY.md` |
| Public contact email | `mahoneyclanapps+simpleglance_weatherwidget@gmail.com` (fixed by the owner 2026-11-01) | ✓ |
| Source Code URL | `https://github.com/Mahoneyclan/simpleglance-weather-widget` (restored 2026-11-02) | ✓ The app is GPL-3.0 (its icons are GPL), so the code repo stays public and this link must point to it. |

A separate listing, **"Weather Widget BETA"** (`67a09ce3-b12d-47f0-be5c-f606cdb9429c`, status Pending, description is just its title), now has no contact email (the personal address was removed 2026-11-01).

## About (3–4 bullets; copied to the support repo)

SimpleGlance Weather is a clean, minimal weather widget for Garmin fenix watches.

- Live conditions for two places, where you are and a home location you set, switched with one button.
- Temperature, feels-like, high and low, rain and wind, plus an hourly and a 4-day forecast.
- A glance view showing both places at once, refreshed in the background.
- Weather from Open-Meteo; no account or key needed. Available in the Garmin Connect IQ Store.

## Description (as listed, updated 2026-11-01)

A clean, minimal weather widget for Garmin Fenix watches.

Features
- Radial watch face layout — temperature (top), rain (bottom-left), wind (bottom-right)
- Temperature and feels-like temperature
- Wind speed, gust, direction arrow and compass label
- Rainfall (mm, current hour)
- Hourly forecast: Now + 3 hours ahead (weather icon, temperature, rain mm, wind speed and direction)
- Daily forecast: Today + 4 days ahead (weather icon, high/low temperature, wind, rain)
- Two-location toggle (GPS ↔ Home) with indicator dots showing active location
- Background refresh on a configurable interval (15 / 30 / 60 min)
- Glance view showing both Home and GPS locations side by side — condition indicator and current temperature for each
- Offline cache — last known data shown instantly on launch
- No API key required — powered by Open-Meteo (free, no sign-up)

Navigation
UP / DOWN — Cycle through pages: Current Conditions → Hourly Forecast → Daily Forecast
SELECT — Toggle between GPS location and home location
MENU — Force refresh weather data

The two dots at the bottom of the current-conditions screen indicate the active location: left dot GPS, right dot Home.

I'm a novice developer and make this app as a hobby, in my spare time. I'm happy to help and I read every message, but replies and fixes may take a while, and some problems may be beyond what I can fix.

### Out of date against v1.5 (README)
- "Rainfall (mm …)" and "rain mm": v1.5 follows the watch's units (mm or inches).
- Missing: today's high/low on the main page, "Set Home here" on the watch, Brisbane CBD default Home, plain-word conditions in the glance, "No connection · time" line.

## What's New (as listed now, newest first)

- v1.5.0 shows weather in your watch's units, keeps your location up to date as you move (with the right suburb name), adds "Set Home here" on the watch, makes Brisbane CBD the default Home, and puts plain-word conditions in the glance.
- v1.4.2 — Home now mirrors your GPS location until you set real coordinates, instead of showing the developer's default hometown
- v1.4.0 & 1.4.1 — battery usage improvements (older entries collapsed in the store; not captured)

## Privacy policy

Source: `PRIVACY.md` in this repo; published copy in the support repo.
