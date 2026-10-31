# Privacy Policy — SimpleGlance Weather Widget

**Last updated: 31 October 2026**

## Overview

SimpleGlance Weather Widget ("the app") is a Connect IQ widget that shows weather for two places: your current GPS location and an optional Home location you enter in the app's settings. This policy explains what data the app uses, where it is sent, and what is kept on your watch.

## What the app sends, and to whom

To show weather and place names, the app sends **map coordinates** (latitude and longitude, rounded to 2 decimal places — about 1 kilometre, so not your exact position) to two free online services. Coordinates are sent for:

- your **current GPS location**, and
- your **Home location**, if you have set one in the app's settings.

Requests go over an encrypted connection (HTTPS) through your phone's Garmin Connect app, so each service also sees your phone's internet (IP) address, as with any web request.

| Service | Operated by | Country | What it receives | Why |
|---|---|---|---|---|
| [Open-Meteo](https://open-meteo.com) | OpenMeteo GmbH | Switzerland | Coordinates | To get the weather forecast |
| [Nominatim](https://nominatim.openstreetmap.org) | OpenStreetMap Foundation | United Kingdom | Coordinates | To turn coordinates into a place name (e.g. a suburb or town) |

Requests are made when you open the widget or press MENU (unless the data was refreshed within your chosen interval), when you change the settings (Home only), and automatically in the background at the interval you choose in settings (15, 30 or 60 minutes), even while the widget is closed. A place name is looked up only when a location has moved about 1 kilometre since its last successful lookup.

Neither service requires an account, and the app sends no name, email address, device identifier or other personal details. Each service handles the data it receives under its own policy:

- Open-Meteo: <https://open-meteo.com/en/terms> (its server logs, which may include IP addresses and coordinates, are deleted after 90 days)
- OpenStreetMap Foundation: <https://osmfoundation.org/wiki/Privacy_Policy> (it stores request data, including IP addresses, temporarily in the United Kingdom and the Netherlands)

## What is kept on your watch

The app stores the following on your watch only, using Garmin's Application Storage:

- your last known GPS location, rounded to about 1 kilometre, so weather can refresh in the background without a new GPS fix
- the Home coordinates you entered (in the app's settings)
- the latest weather, forecast and place names, so they show instantly when you open the widget
- for each place name, the coordinates (rounded to about 1 kilometre) it was looked up for, so it is not looked up again
- with the Home weather, the Home coordinates it was fetched for, so a changed Home location is fetched again

This data is not sent anywhere except as described above. It stays on the watch until the widget is removed.

## What the app does not do

The app does **not** collect or send:

- personal identification information
- device identifiers
- usage analytics or tracking data
- any data other than the coordinates described above

## Your choices

- To stop sending your Home location, leave the Home settings blank.
- To stop all data use, remove the widget from your watch.

## Contact

For questions about this privacy policy, open an issue at:
https://github.com/Mahoneyclan/simpleglance-weather-widget/issues
