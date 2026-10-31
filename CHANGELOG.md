# Changelog

## 1.5.0 (not yet released)

- Clearer status: when a refresh fails, the screen says "No connection" and how old the data shown is, or "No connection. Press MENU to retry." when there is none.
- A new Home setting is fetched straight away instead of after the refresh interval, including one changed while the widget was closed.
- A new Home location shows "Home" until its place name arrives, never the previous Home's name or the GPS name.
- Place names are looked up only when a location has moved about 1 km, in the widget and in the background.
- Retries repeat only the request that failed, and MENU cancels a pending retry.
- Data from a background refresh appears straight away if the widget is open.
- Less battery use: icons are loaded once, the screen no longer redraws every minute with nothing new, and settings are not re-read on every redraw.
- Robustness: damaged replies, settings and saved data are checked before use.
- Privacy policy names both online services (Open-Meteo and Nominatim).
- The app is now open source under GPL-3.0, the same licence as its weather icons.

## 1.4.2

- Home mirrors the GPS location until a Home location is set.

## 1.3.2

- Hourly data request reduced about 20× (`forecast_hours=6`).

## 1.3.1

- Battery: 60 s timer, skip fetches while data is fresh, cache the Home place name.
