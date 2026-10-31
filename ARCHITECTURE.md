# Architecture

SimpleGlance is a Garmin Connect IQ **widget** written in Monkey C (minimum API level 3.2.0, Fenix 6 family). It shows weather for two locations — the watch's GPS position and a Home location from settings — using Open-Meteo for weather and Nominatim (OpenStreetMap) for place names.

## Processes

Connect IQ runs the same app in up to three separate processes. They do not share memory; **Application.Storage is the only channel between them.**

| Process | Code that runs there | What it does |
|---|---|---|
| Widget (foreground) | `WeatherApp`, `WeatherView`, `WeatherDelegate`, `HomeMenu`, `WeatherData`, `PlaceNames`, `WatchServices`, `GpsPosition`, `CurrentPage`, `ForecastPages`, `WeatherFormat`, `WeatherIcons` (with `ResourceCache`), plus every shared module | Full-screen pages, button input, live fetches |
| Glance | `WeatherApp`, `WeatherGlanceView`, `GlanceRules`, and the small modules marked `:glance`: `Values`, `WeatherState`, `WeatherSlots`, `Units`, `FetchRules` (settings changes reschedule the background) and `BackgroundResult` (background results can arrive here). The condition words are `scope="glance"` string resources | Two-column strip in the glance list; reads Storage only |
| Background | `WeatherApp`, `BackgroundService`, and the shared modules marked `:background`: `HomeSettings`, `Coordinates`, `WeatherParser`, `WeatherRequests`, `RequestHeaders`, plus the `:glance` modules above | Scheduled refresh while the widget is closed |

The glance and background processes have much smaller memory budgets than the widget, which is why the glance draws no bitmaps and the background request asks for only 6 hours of hourly data.

## Files

| File | Responsibility |
|---|---|
| `source/WeatherApp.mc` | Entry point. Creates views, registers the background schedule, saves background results to Storage and tells an open widget to reload, passes settings changes on. |
| `source/WeatherView.mc` | Full-screen view: active page and location, status messages, the "No connection" line and location dots. Draws nothing else itself. |
| `source/WeatherData.mc` | Widget data for both locations: loads the cache, decides what is stale, fetches, retries GPS weather, saves to Storage, mirrors GPS into Home while Home is not set, and tracks failed attempts. |
| `source/WatchServices.mc` | The only way WeatherData and PlaceNames reach the watch: Storage, settings, clock, web requests, GPS, the retry timer and redraws. Tests replace it with `FakeWatch`. Widget only, so the glance and background do not carry it. |
| `source/PlaceNames.mc` | Widget place names: reuses a saved name until the location moves about 1 km, otherwise looks it up and saves it with its coordinates. |
| `source/WeatherState.mc` | Location slot numbers (GPS, Home), "no data" reasons, the Storage keys per slot, and the pure rules for which slot's data is shown and why a slot is empty. Shared. |
| `source/BackgroundResult.mc` | Layout of the background result, and which Storage writes it causes. Shared. |
| `source/Values.mc` | Type checks for untrusted values (numbers, arrays, text). Shared by all three processes. |
| `source/GpsPosition.mc` | Finds the position: current fix → running activity → last known → saved → Garmin Weather's observation station (last resort, can be many km away). Says whether it is a current fix; saves it rounded. `choose()` is the tested rule. |
| `source/CurrentPage.mc` | Draws page 0 (current conditions). |
| `source/ForecastPages.mc` | Draws pages 1 (hourly) and 2 (daily). |
| `source/WeatherFormat.mc` | Compass labels, clock times and the hourly headings (counted from the fetch time). |
| `source/Units.mc` | Converts the stored metric values to the watch's units (°F, mph, inches) at draw time. Shared with the glance. |
| `source/WeatherIcons.mc` | Maps WMO weather codes to 44 px and 22 px icons; `ResourceCache` keeps loaded icons and page text while the widget is open. |
| `source/WeatherDelegate.mc` | Buttons: DOWN/UP change page, SELECT toggles GPS/Home, MENU opens the menu. |
| `source/HomeMenu.mc` | The MENU menu: Refresh, or Set Home here (confirmation, then `HomeHere.apply()` saves the GPS position as the Home settings and fetches Home). |
| `source/WeatherGlanceView.mc` | Glance strip: GPS (left) and Home (right), each with name, temperature, condition word and coloured dot. `GlanceRules` holds its data check, words and colours. |
| `source/BackgroundService.mc` | Background refresh: fetches weather (and the Home place name), parses, returns results via `Background.exit()`. |
| `source/WeatherRequests.mc` | The only builder of the Open-Meteo and Nominatim requests. Shared by widget and background. |
| `source/FetchRules.mc` | Refresh-interval validation, freshness, and the saved place-name records (build, and reuse while within ~1 km). Shared. |
| `source/HomeSettings.mc` | The only reader of the Home latitude/longitude settings: parses, range-checks and classifies them as not set / set / invalid. Shared. |
| `source/WeatherParser.mc` | The only reader of Open-Meteo and Nominatim replies: type- and length-checks every field, builds the stored arrays, picks and length-caps place names, shape-checks cached arrays. Shared. |
| `source/WeatherSlots.mc` | Names for the positions in the stored arrays. Shared, including the glance. |
| `source/Coordinates.mc` | Range-checks positions from the system and Storage, and rounds every coordinate sent off the watch, and the saved GPS position, to 2 dp (~1 km). Shared. |
| `source/RequestHeaders.mc` | User-Agent sent to Nominatim (app name, version, contact). The version must match `manifest.xml`. |
| `LICENSE` | GPL-3.0, for the app and the bundled icons. |
| `source/test/*.mc` | Unit tests (`(:test)`, only in `--unit-test` builds). WeatherParser is tested against a recorded real Open-Meteo reply and damaged copies of it. `WeatherDataTest.mc` drives WeatherData and PlaceNames through `FakeWatch` (in-memory Storage, recorded requests) and plays the recorded reply back. |
| `resources/properties.xml` | Settings: refresh interval, Home latitude/longitude (stored as strings; default Brisbane CBD, blank = not set). |
| `resources/strings/strings.xml` | App name, status messages, page labels, unit names and the glance's condition words. |
| `docs/TESTING.md` | Hand-test script run on a real watch before each release (stands in for UI tests). |
| `resources/drawables/` | Launcher icon and weather icons (Met.no weathericons via BleachDev/Rainy, GPL-3.0 like the app). |
| `image-generators/generate_store_assets.py` | Developer tool for store artwork; not part of the app. |

## Data flow

```
             Open-Meteo (weather)      Nominatim (place names)
                    ▲    │                   ▲    │
   ┌────────────────┘    ▼                   │    ▼
   │  WeatherData + PlaceNames (widget) ──────┘
   │        │ writes
   │        ▼
   │  Application.Storage ◀── WeatherApp.onBackgroundData ◀── BackgroundService
   │        │ reads                                             (scheduled)
   │        ▼
   └─ WeatherView pages         WeatherGlanceView
```

1. **Widget opens:** `WeatherView.onLayout()` has `WeatherData` load the cache from Storage, then `refresh()`.
2. **`refresh()`** fetches each location whose data is missing, older than the refresh interval (its own `*_fetch_time`), or for a place more than about 1 km from where the location is now (`*_fetch_for`). If the best GPS position is not a current fix, a one-shot fix is requested as well, and its arrival fetches again if it shows a move. Its place name is looked up only if the location has moved about 1 km since the last successful lookup (`gps_place` / `home_place`). A GPS weather network error is retried up to 3 times, 5 s apart; only that request is repeated, and MENU cancels a pending retry before starting again. A failure that remains is shown as "No connection · <time of the data>" or, with no data, "No connection. Press MENU to retry."
3. **Settings change:** Home is fetched straight away, even if its data is fresh. Each Home result is saved with the Home coordinates it was fetched for (`home_fetch_for`), so a Home changed while the widget was closed is also fetched when the widget next opens.
4. **Background:** every `refresh_rate` minutes `BackgroundService` fetches Home (if set) and the last saved GPS position. `WeatherApp.onBackgroundData()` writes what `BackgroundResult.writes()` lists (results, fetch times, a new Home place record) and tells an open widget to reload.
5. **Glance** only reads Storage.

Weather is stored in metric (°C, km/h, mm) and converted for display (`Units`), so a change of the watch's units applies at once. Hour and day headings are worked out when drawing, from the time the data was fetched, so older data is never labelled "Now" or "Today"; the labels stored with the data are used only for data saved without a fetch time.

When Home is not set (blank, or still exactly the preset text versions before 1.5.0 shipped) or invalid, both foreground and background copy the GPS data into the Home slot instead of fetching. The copy carries the GPS name and saves an empty `home_fetch_for`, so once Home is set the copy is never taken for Home data: Home is fetched, and its name comes from `home_place`, which copying never touches. When it is invalid, the widget's Home page shows "Check Home settings in Garmin Connect".

## Storage keys

| Key | Written by | Contents |
|---|---|---|
| `gps_coords` | WeatherData, GpsPosition | `[lat, lon]` of the last known position, rounded to ~1 km |
| `gps_weather`, `home_weather` | WeatherData, WeatherApp | 9-item current-conditions array (slots in `WeatherSlots`, layout in `WeatherParser.parseCurrent`) |
| `gps_forecast`, `home_forecast` | WeatherData, WeatherApp | 15-item forecast array (slots in `WeatherSlots`, layout in `WeatherParser.parseForecastAt`) |
| `gps_fetch_time`, `home_fetch_time` | WeatherData, WeatherApp | Unix time of the last successful weather update of that location, from the widget or the background |
| `gps_place`, `home_place` | PlaceNames, WeatherApp (Home only) | `[lat, lon, name]` of the last *successful* place-name lookup of that location; the name is reused while the location is within ~1 km |
| `gps_fetch_for` | WeatherData | `[lat, lon]`, rounded to ~1 km, of the position the saved GPS weather was fetched for. Fresh data from more than ~1 km away is fetched again |
| `home_fetch_for` | WeatherData, WeatherApp | `[lat, lon]` of the Home setting the saved Home weather was fetched for; `[]` (or missing) when it is a copy of the GPS data. Home data that doesn't match the current setting is fetched again |
| `home_lat_cached`, `home_lon_cached` | — | Retired in 1.5.0 (replaced by `home_place`). No longer written or read; do not reuse the names |
| `last_fetch_time` | — | Retired in 1.5.0 (replaced by the two `*_fetch_time` keys). No longer written or read; do not reuse the name |

These keys are permanent identifiers: existing installs already hold them. Add new keys rather than renaming these.

## Compiler warnings

At the strict type-check level (`monkeyc -l 2`) 14 warnings remain, all accepted:
- 12 "not available in all function scopes" in `WeatherApp.mc`. The app class must be marked `:glance` and `:background` because every process loads it, but the views, the background service and the widget's reload calls it uses are deliberately not, to keep those processes small. Each is reached only in the process that has it. Everything else WeatherApp calls (FetchRules, BackgroundResult) is marked `:glance`.
- 2 in `WeatherRequests.mc`: the SDK types the `makeWebRequest` callback more narrowly than a plain `Method`.

## Building and docs

See the README "Building" section. API docs are generated from `//!` comments with `monkeydoc`.
