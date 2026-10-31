# Testing

Two kinds of tests: unit tests, which run in the simulator on every change, and
this hand-test script, which stands in for UI tests (Connect IQ has no UI-test
tool). The unit tests include the widget's fetch, retry and caching logic
(`WeatherDataTest.mc`), but not timing on a real watch, which this script covers. Run the whole script on a real watch before every store release, and the
sections for any screen you changed.

## Unit tests

See README "Building". The run must end with `PASSED`; `monkeydo` exits with
code 1 even then (SDK quirk).

## Hand-test script

Section 4 steps 5–8 work on any install, including one copied over USB.

Record the date, version, watch model and result of each step in the release
notes or the PR. A step fails if what you see differs from "Expect".

### Install

A widget copied over USB cannot get settings from the Garmin Connect app, so
the Home steps (section 4) need either the Connect IQ store beta version or a
settings file from the simulator (see "Home settings without the store" below).

1. Remove the store version from the watch (Garmin Connect → My Device → Apps & Widgets).
2. Build for the watch (`monkeyc -d fenix6pro -r -o bin/SGWEATHR.prg …`), connect the watch by USB,
   and copy the `.prg` into `GARMIN/APPS/` with OpenMTP or Android File Transfer.
3. Unplug. **Expect:** SimpleGlance appears in the widget loop and the glance list.

### 1. First run

1. Open the widget with the phone connected, outdoors or with a recent GPS fix.
   **Expect:** "Waiting for GPS location..." or "Loading weather...", then the
   current conditions with a place name, within about 30 seconds.
2. Press SELECT. **Expect:** the right-hand dot fills; on a new install the Home
   page shows Brisbane CBD (the default Home), labelled "Home" until its place
   name arrives.

### 2. Pages and buttons

1. Press DOWN twice and UP twice. **Expect:** Current → Hourly → Daily → back,
   wrapping round.
2. On the hourly page. **Expect:** the first column says "Now", then the next
   three hours. Each column shows an icon, temperature, rain, wind and direction.
3. On the daily page. **Expect:** "Today" and the next four weekdays, each with
   an icon, high/low and rain.
4. Press MENU. **Expect:** nothing changes if the data is newer than the refresh
   interval (no flicker, no "Loading").

### 3. Units and time format

1. On the watch, set Settings → System → Units → Temperature to °F, and
   Distance to Statute. Open the widget. **Expect:** °F on every page and in the
   glance, wind in mph, rain in inches with two decimals ("0.04in").
2. Set System → Time → Format to 24 Hour. **Expect:** hourly headings "14:00",
   all four visible without overlapping.
3. Set everything back to metric and 12-hour. **Expect:** °C, km/h, mm, "2p".

### 4. Home location

1. Set Home to a place at least 50 km away (for example -33.8688, 151.2093).
   With the widget **open**. **Expect:** the Home page changes to that place's
   weather within a few seconds, labelled "Home" until its name arrives.
2. Close the widget. Change Home to another place. Open the widget and go to
   Home. **Expect:** the new place's weather, not the previous Home's (round-4 bug K).
3. Set Home latitude to "abc". **Expect:** the Home page says "Check Home
   settings in Garmin Connect"; GPS still works.
4. Clear both Home values. **Expect:** Home mirrors GPS again.
5. On the watch, press MENU. **Expect:** a menu with Refresh and Set Home here,
   the latter showing your position ("-27.37, 152.87") or "No GPS position yet".
6. Choose Set Home here, then No. **Expect:** back on the widget, Home unchanged.
7. Choose Set Home here, then Yes. **Expect:** the Home page opens and shows
   your current place within a few seconds. In the Garmin Connect app, the Home
   settings now hold your position (5 decimals).
8. Press MENU, choose Refresh. **Expect:** the menu closes; no change if the
   data is fresh.

### 5. Place names

1. Note the GPS place name, travel more than 1 km, and reopen the widget.
   **Expect:** a new place name.
2. Reopen without moving. **Expect:** the same name, shown straight away.

### 5a. Moving

1. Open the widget at home and note the place name. Close it, travel more
   than 2 km, and open it again within the refresh interval. **Expect:** new
   weather and a new place name within about 30 seconds, without pressing MENU.
2. Indoors with no recent GPS fix, open the widget. **Expect:** weather for the
   last known area straight away; after the watch gets a fix (step outside),
   the place updates if you are more than about 1 km from it.

### 6. No connection

1. Turn off the phone's Bluetooth. Open the widget and press MENU after the
   refresh interval has passed (or after changing Home). **Expect:** within
   about 20 seconds, "No connection · <time>" above the dots, with the old data
   still shown.
2. Turn Bluetooth back on and press MENU. **Expect:** fresh data; the "No
   connection" line disappears.
3. On a watch with no saved data (fresh install) and Bluetooth off. **Expect:**
   "No connection. Press MENU to retry."

### 7. Glance

1. Scroll to the glance list. **Expect:** GPS on the left, Home on the right
   (same order as the widget's dots), each with a name, temperature, a word such
   as "Rain", and a coloured dot when it fits.
2. With no saved data. **Expect:** "--" in light grey in each column.

### 8. Memory (simulator)

1. Run the release `.prg` in the simulator (`monkeydo bin/SGWEATHR.prg fenix6pro`),
   open the full widget, and page through every page for both locations.
2. Open File → View Memory. **Expect:** peak memory well below the limit shown.
3. Repeat for the glance. Compare with the previous release's numbers; a large
   jump needs explaining before release.

### 9. Background refresh

1. Close the widget and wait for one refresh interval (15 minutes at the
   shortest setting) with the phone connected. **Expect:** the glance
   temperature or condition updates without opening the widget.

## Home settings without the store

1. Start the simulator, run the widget (`monkeydo bin/SGWEATHR.prg fenix6pro`)
   and use File → Edit Application Properties to set Home.
2. The simulator saves the settings as a `.SET` file in its temporary folder.
   Copy it to the watch's `GARMIN/APPS/SETTINGS/` with the same base name as the
   `.prg`.

This route is not confirmed against Garmin's documentation; if the watch
ignores the file, use a store beta upload instead.
