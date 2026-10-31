# Changelog

## 1.5.0 (not yet released)

- Clearer status: when a refresh fails, the screen says "No connection" and how old the data shown is, or "No connection. Press MENU to retry." when there is none.
- A new Home setting is fetched straight away instead of after the refresh interval, including one changed while the widget was closed.
- A new Home location shows "Home" until its place name arrives, never the previous Home's name or the GPS name.
- Place names are looked up only when a location has moved about 1 km, in the widget and in the background.
- GPS location: weather is fetched again after a move of about 1 km, even if it is still fresh. The widget prefers a current GPS fix, asks for one when it only has an older position, and uses Garmin Weather's observation station only as a last resort (it could show a suburb many kilometres away).
- Retries repeat only the request that failed, and MENU cancels a pending retry.
- Data from a background refresh appears straight away if the widget is open.
- Less battery use: icons are loaded once, the screen no longer redraws every minute with nothing new, and settings are not re-read on every redraw.
- Robustness: damaged replies, settings and saved data are checked before use.
- MENU opens a menu: Refresh, or **Set Home here**, which saves your current position as Home after a confirmation, no typing needed.
- A Home near the coordinates older versions shipped now works; only the exact old preset counts as "not set".
- Clearer setting titles in Garmin Connect, with examples.
- Place names: a district such as "Samford Valley" is shown instead of the whole city ("Brisbane").
- New installs start with Brisbane CBD as Home (clear both Home settings to mirror GPS instead).
- Follows the watch's units (°C/°F, km/h/mph, mm/inches) and 12/24-hour time.
- Hour and day headings come from when the data was fetched, so old data is never labelled "Now" or "Today".
- Glance: GPS on the left and Home on the right, as on the widget's dots, with a condition word ("Rain") next to the coloured dot.
- Easier to read: light grey instead of dark grey for "--", the glance divider and the inactive location dot.
- Freezing drizzle and freezing rain show rain icons instead of clear sky.
- Privacy policy names both online services (Open-Meteo and Nominatim).
- The app is now open source under GPL-3.0, the same licence as its weather icons.

## 1.4.2

- Home mirrors the GPS location until a Home location is set.

## 1.3.2

- Hourly data request reduced about 20× (`forecast_hours=6`).

## 1.3.1

- Battery: 60 s timer, skip fetches while data is fresh, cache the Home place name.
