# Scorecard: SimpleGlance Weather Widget (round 1)

- **Date:** 2026-10-29
- **Commit:** `ee5993d` (v1.4.2, branch `main`, working tree clean)
- **Rubric:** iOS rubric adapted to Garmin Connect IQ / Monkey C, approved by the owner.
- **Reviewer:** independent review, read-only. No source files were changed. Build output went to a scratch folder outside the repo.
- **Toolchain:** Connect IQ Compiler 8.1.1, target `fenix6pro`.

## Overall

| | Score |
|---|---|
| **Overall** | **38.4 / 100, grade F** (A 85+, B 70–84, C 55–69, D 40–54, F under 40) |
| Code (categories 1–6) | 21.0 / 60 |
| Documentation (categories 7–10) | 17.4 / 40 |
| Build | Passes (`-l 0` and `-l 1`: 0 warnings). `-l 2`: 120 warnings. `-l 3`: fails with 120 errors. No build-failure cap applies. |
| Critical security findings | 0, so no Security cap applies |

| # | Category | Weight | Score /10 | Weighted | Reason |
|---|---|---|---|---|---|
| 1 | Correctness & robustness | 12% | 4 | 4.8 | Builds, and the GPS fallback chain is sensible. But an empty or non-numeric Home lat/lon setting crashes both the app and the background service (the type checker flags this at BS:52 and WV:51). API arrays are indexed with no size or null checks. The retry loop never ends. Rain probability is always 0 after a foreground fetch. A settings change is ignored while cached data is still fresh. |
| 2 | Architecture & structure | 10% | 3 | 3.0 | WeatherView.mc is 839 lines and mixes location, networking, parsing, storage and drawing. About 150 lines of fetch/parse/settings logic are copied between WeatherView and BackgroundService. 5 functions run over 40 lines (one is 117). Data travels as positional arrays with magic indexes (`forecast[11]`). |
| 3 | Monkey C idioms | 8% | 4 | 3.2 | Uses the modern `Application.Properties` and `Storage` APIs and `(:background)`. But 60 warnings come from a wrong `(:glance)` on `wmoIconSm`, 120 warnings at `-l 2`, 120 errors at `-l 3`, 2 untyped parameters, dead code (`windArrow`, `getApp`, 3 unused strings), hardcoded UI strings, no enums, and public mutable fields. |
| 4 | Concurrency & performance | 8% | 5 | 4.0 | Good: the payload is 1,766 bytes (`forecast_hours=6`), a freshness skip, a cached Home geocode in the foreground, and timers stopped in `onHide`. Bad: the 5-second network retry repeats forever, bitmaps reload on every frame, Storage is written from the `onUpdate` path, the background geocodes Home on every run, and a 60-second redraw timer does no useful work. |
| 5 | Security & privacy | 12% | 5 | 6.0 | No secrets anywhere in the 29-commit history, HTTPS only, no logging, and only the permissions it needs. However, PRIVACY.md is materially false (Nominatim is undisclosed: **High**). Coordinates are sent at about 11 m precision, the developer's home coordinates are shipped publicly, settings input is not validated, and API responses are trusted (all **Medium**). |
| 6 | Testing | 10% | 0 | 0.0 | 0 tests and 0 `(:test)` annotations. |
| 7 | Doc-comment coverage | 12% | 5 | 6.0 | 49 of 97 declarations (50.5%) have a `//` comment immediately above. 0 use `//!` or `/** */`. |
| 8 | Doc-comment quality | 10% | 5 | 5.0 | Several good "why" comments (string-typed properties, `deleteTemporalEvent`, glance bitmap limit, arc angles, deferred parsing). No parameter or return documentation, and the process context (foreground/background/glance) is rarely stated. Many comments are stale (see category 9). |
| 9 | Accuracy | 8% | 3 | 2.4 | 30 mismatches, listed below. They include false privacy-policy claims, wrong page/button descriptions, wrong API-parameter comments, and README features that don't exist (direction arrow, daily wind). |
| 10 | Project docs | 10% | 4 | 4.0 | README is good and mostly current, with an architecture section. PRIVACY.md is stale (last updated 16 May, before Nominatim was added on 7 June). There is no ARCHITECTURE.md, SECURITY.md, repo CLAUDE.md, LICENSE or CHANGELOG. |
| | **Total** | 100% | | **38.4** | |

## Key metrics

| Metric | Value | How counted |
|---|---|---|
| Source files | 6 `.mc` | `ls source/*.mc` |
| Lines | 1,424 total: 1,073 code, 199 comment, 152 blank | `wc -l source/*.mc`; per-file `grep -cE '^\s*$'` and `grep -cE '^\s*//'` |
| Files over 300 lines | WeatherView.mc (839), BackgroundService.mc (317) | `wc -l` |
| Functions over 40 lines | WV `drawWeather` 117 (L507), WV `parseForecast` 76 (L394), WV `drawHourlyPage` 76 (L629), WV `drawDailyPage` 58 (L710), BS `parseForecast` 78 (L239) | brace-matching script (appendix) |
| Doc-comment coverage | 49/97 = **50.5%**. Classes 5/5, functions 32/65 (49%), class-level members 12/27 (44%). Structured (`//!`, `/** */`, `@param`): 0 | script (appendix) |
| Tests | 0 tests, 0 run, 0 pass, 0 fail | `grep -rn '(:test)' . --include=*.mc` returns 0 |
| Build | `-l 0` OK 0 warnings; `-l 1` OK 0 warnings; `-l 2` OK **120 warnings**; `-l 3` **FAIL, 120 errors** (same issues as `-l 2`, raised to errors) | `monkeyc -f monkey.jungle -d fenix6pro -o <scratch>/out.prg -y ~/.garmin_dev.der -w -l N` |
| `as` casts | 303 (BS 83, App 17, Delegate 6, Glance 15, Icons 8, View 180) | `grep -o ' as [A-Za-z]' FILE \| wc -l` |
| Dictionary key reads `["…"]` | 61. **0 are inside try/catch** (there are 0 try blocks). In parsing, every `data["current"]`, `hourly[...]` and `daily[...]` array is indexed without a size check. | `grep -oE '\[\"[a-z_0-9]+\"\]' source/*.mc \| wc -l`; `grep -wc try source/*.mc` |
| Storage writes | 26 `Storage.setValue` (View 22, App 4). 8 keys: `gps_coords`, `gps_weather`, `gps_forecast`, `home_weather`, `home_forecast`, `home_lat_cached`, `home_lon_cached`, `last_fetch_time` | `grep -ohE 'Storage\.(get\|set)Value\("[a-z_]+"' … \| sort \| uniq -c` |
| TODO/FIXME/println | 0 / 0 / 0 | `grep -rn "println\|TODO\|FIXME\|XXX\|HACK" source/` |
| Network payload | Open-Meteo response for the app's exact query: **1,766 bytes**. 6 hourly slots, starting at the current hour in the location's time zone. | one `curl` with the app's parameters at a public test coordinate |
| Security findings | Critical 0 · High 1 · Medium 5 · Low 6 | see table below |

## Security findings

Checklist results:
- **Secrets (1):** none in source or history. No key file was ever committed. The owner's key lives outside the repo at `~/.garmin_dev.der`.
- **Storage (2, 3):** see F9.
- **Network (4):** both URLs use HTTPS. See F2 for coordinate precision and F11 for response-code handling.
- **Logging (5):** none.
- **Input (6):** see F4 and F5.
- **WebViews (7):** not applicable. Connect IQ has no WebView.
- **Permissions (8):** all justified by the code.
  - Background: used by `registerForTemporalEvent` (App:76).
  - Communications: used by `makeWebRequest` (BS:114, BS:159, WV:201, WV:285).
  - Positioning: used by `Position.getInfo` and `enableLocationEvents` (WV:112, WV:178).
- **Privacy disclosure (9):** see F1.
- **Dependencies (10):** no barrels. See F6 and F12.
- **Errors (11):** see F11.
- **Debug leftovers (12):** none.

| # | Severity | Location | Issue | What it means in plain English | Suggested fix | Effort |
|---|---|---|---|---|---|---|
| F1 | **High** | PRIVACY.md:14-15, 18, 32-36; code at WV:175, WV:196, WV:309, BS:89 | The privacy policy says coordinates are "never transmitted to any server other than the weather API" and "never shared with third parties", and lists only Open-Meteo. In fact the app sends both GPS and Home coordinates to **Nominatim, run by the OpenStreetMap Foundation (UK)**, and to Open-Meteo, which is also a third party. The policy also omits Home coordinates, the Garmin Weather observation fallback, and the country of each company. It is dated 16 May 2026; Nominatim arrived in commit 7691401 on 7 June 2026. The app has no consent step. | The published policy misstates where users' locations go. That is a store-listing and legal (GDPR/Australian Privacy Act) exposure, and it breaks the owner's own consent rule. | Rewrite PRIVACY.md to list both services with company, country and what is sent. Consider a first-run consent note, or a setting to turn geocoding off. | S (docs), M (consent) |
| F2 | Medium | BS:117-118, BS:162-163; WV:204-205, WV:288-289 | Coordinates are sent at 4 decimal places (about 11 m), together with the phone's IP address, to two providers. Weather only needs about 2 dp (1 km); suburb-level geocoding (zoom 14) needs about 3 dp. | A user's home position is disclosed to roughly house level for every request. | Round to `%.2f` for Open-Meteo and `%.3f` for Nominatim. Update PRIVACY.md to match. | S |
| F3 | Medium | resources/properties.xml:5-6; BS:25-30; WV:24-29; README:44-47 | The default Home coordinates (-27.3705, 152.8691) are described in code as "the developer's own location". They are shipped to every install and published in a public repo and README. README:47 calls them "a sentinel, not a real location". | The owner's own home location (to about 11 m) is publicly disclosed. | Change the defaults to empty strings or `0`, and treat empty as unconfigured. Decide whether the old values in git history matter (a rewrite needs explicit approval). | S (M with history rewrite) |
| F4 | Medium | properties.xml:17-22; BS:34-53; WV:33-52 | Home lat/lon settings are free text (`alphaNumeric`, max 12) and are never validated. `"".toFloat()` or `"abc".toFloat()` returns null, then `null - Float` crashes (`-l 2` reports *"operation 'sub' with invalid types 'Null'"* at BS:52 and WV:51). Out-of-range values such as 999 are sent to the APIs. URL injection is **not** possible, because values pass through `format("%.4f")` and `makeWebRequest` encodes params. | A typo or a cleared field in Garmin Connect makes the widget crash on open, and the background job crash on every run. | Parse with a null check, clamp to ±90 / ±180, treat invalid input as unconfigured, and show "Check Home settings". | S |
| F5 | Medium | BS:213, BS:249-250, BS:274, BS:282-286, BS:306-310; WV:350, WV:403, WV:428, WV:435-439, WV:459-463; Glance:48; WV:508-511 | API responses (untrusted) are indexed with no type, size or null checks. `as` is compile-time only and does no runtime checking. A missing `current`, a short `hourly`/`daily` array, or a null `temperature_2m` leads to a null dereference, `Math.round(null)` or an out-of-bounds read, which crashes the app. 0 try/catch in the codebase. | A change or glitch in an external API response can crash the widget, and also the glance, which reads the cached value. | Validate shape once in one parser: check types and `size()`, then store only clean values. | M |
| F6 | Medium | drawables.xml:5-6; README:82-84 | The weather icons come from BleachDev/Rainy under **GPL-3.0**, but the app is published as "All rights reserved" with no source-availability or licence notice. | A possible licence violation for a store-distributed app. | Get legal advice. Either comply with GPL-3.0 (licence and source offer) or replace the icons with permissively licensed ones. | M |
| F7 | Low | bin/simpleglanceweather.iq (tracked; added 554dc0b, last changed 0c83c1b = v1.3.2) | A signed release package is tracked even though `.gitignore:2` lists `bin/` and `.gitignore:5` lists `*.iq` (`git check-ignore --no-index -v` matches `bin/`). It is two releases stale: the current version is 1.4.2, and the local bin/ holds a newer untracked `SimpleGlanceWeatherWidget.iq`. | Anyone cloning the repo can sideload an outdated build. It is also confusing which build was released, and it adds about 1 MB to history. | `git rm --cached bin/simpleglanceweather.iq` and attach releases to GitHub Releases instead. | S |
| F8 | Low | BS:89, BS:113-128, BS:124; WV:175, WV:211 | Nominatim usage policy: the background job reverse-geocodes Home on **every** temporal event with no cache (up to 96 times a day). The foreground geocodes GPS on every non-fresh fetch. The User-Agent is `SimpleGlanceWeatherWidget/1.0` (stale version, no contact address). | The service may rate-limit or block the app, so place names would stop appearing. | Cache the Home name in the background as the foreground already does (WV:189-197). Geocode GPS only when it has moved more than about 1 km. Use a UA with the version and a contact. | S |
| F9 | Low | WV:116, WV:124, WV:132, WV:307 (`gps_coords` at full double precision); WV:194-195; stored place names | Location history (the last fix plus Home) persists on the watch indefinitely, at full precision. There is no in-app "clear data". Uninstalling the app is the only removal path. Storing it is justified, because background fetches need the last fix. | Minor: someone with the watch could read the last location. | Store rounded coordinates (3 dp). Mention retention in PRIVACY.md. | S |
| F10 | Low | .gitignore | The ignore file doesn't cover generic key files (`*.der`, `*.pem`, `*.p12`) or `.claude/`; only `developer_key` and `developer_key.der` are listed. `.DS_Store` was committed earlier in history (root and `image-generators/`). | A future key with a different name could be committed by accident. | Add `*.der`, `*.pem`, `*.p12` and `.claude/settings.local.json`. | S |
| F11 | Low | WV:330-333, WV:336-345, WV:491-493, WV:631, WV:712 | Non-200 responses (4xx/5xx) are silently ignored. Network failures never reach the user, who sees "Loading weather..." forever. There is no indicator of how old the data is. | The user can't tell stale data, offline mode or a bad setting apart. | Show "No connection · showing data from HH:MM" or "Check Home settings". | M |
| F12 | Low | image-generators/generate_store_assets.py:16-18 | The asset script imports PIL and numpy with no `requirements.txt` or pinned versions. It is a dev-only tool and not shipped. | Builds of store art aren't reproducible. Supply-chain risk is negligible. | Add a pinned `requirements.txt`. | S |

## Documentation gaps per file

Comment counted = a `//` line (or `//!`, `/*`, `*`) directly above the declaration, skipping `(:annotation)` lines. Shared comments (e.g. one comment over both `homeLat` and `homeLon`) only count for the first declaration.

| File | Covered | Undocumented declarations |
|---|---|---|
| BackgroundService.mc | 15/26 (58%) | L30 `DEFAULT_HOME_LON`, L38 `homeLon`, L57-60 `gpsResult`/`homeResult`/`gpsForecast`/`homeForecast`, L63-64 `homeRawCode`/`homeRawData`, L69 `initialize`, L177 `onGpsData`, L192 `checkDone` |
| WeatherApp.mc | 4/12 (33%) | L13 `mainView`, L15 `initialize`, L19 `onStart`, L22 `onStop`, L25 `getInitialView`, L31 `getGlanceView`, L35 `getServiceDelegate`, L80 `getApp` |
| WeatherDelegate.mc | 5/7 (71%) | L10 `view`, L12 `initialize` |
| WeatherGlanceView.mc | 2/5 (40%) | L15 `initialize`, L19 `onUpdate`, L38 `drawColumn` |
| WeatherIcons.mc | 1/2 (50%) | L44 `wmoIconSm` (only covered by the file header) |
| WeatherView.mc | 22/45 (49%) | L29 `DEFAULT_HOME_LON`, L37 `homeLon`, L59-62 the four data caches, L72 `retryCount`, L74 `initialize`, L78 `onLayout`, L89 `onShow`, L93 `onHide`, L98 `onRefreshTimer`, L200 `fetchLocationName`, L238 `onLocationName`, L256 `onGpsLocationName`, L303 `onPosition`, L314 `onGpsResponse`, L336 `onHomeResponse`, L475 `onUpdate`, L629 `drawHourlyPage`, L710 `drawDailyPage`, L795 `drawCentered`, L827 `windDirName` |

Quality gaps that apply across files:
- No parameter, return or "can fail" documentation anywhere.
- The array layouts are documented only partly. WV:374-393 is good. BS:208 and BS:237 are incomplete and wrong.
- Only BackgroundService states which process (foreground, background or glance) the code runs in.
- None of the network callbacks document their response-code handling.

## Inaccurate or misleading comments and doc claims (30)

1. **WV:14-18.** The header says pages are "0 = GPS current, 1 = Home current, 2 = Forecast". The code (WV:483-498) uses 0 = current, 1 = hourly, 2 = daily, with location chosen separately by `locationIndex`.
2. **WV:54.** "Active page: 0=current conditions, 1=forecast". There are 3 pages.
3. **WeatherDelegate:5-6.** "UP/DOWN toggles between current conditions and forecast… (applies to both pages)". The buttons actually cycle 3 pages.
4. **WeatherDelegate:17 and :24.** "UP button… advance" on `onNextPage` and "DOWN button… retreat" on `onPreviousPage`. According to the Toybox `BehaviorDelegate` docs, `onNextPage` is the DOWN key / swipe up and `onPreviousPage` is the UP key. The labels look swapped; confirm on a device.
5. **BS:155-157 and WV:281-283.** "past_days=1 gives yesterday for the history row; forecast_days=4 covers today + 3 ahead". The code sends no `past_days`, uses `forecast_days=5`, and has no history row.
6. **BS:208.** The `parseWeather` doc lists 7 elements. It returns 9 (adds `weatherCode` and `isDay`).
7. **BS:237-238.** The `parseForecast` doc lists 10 elements, one of them "dNames[4]". It returns 15, and the daily arrays have 5 entries.
8. **WV:154-155.** "Retries up to 3 times on network error". `fetchAll()` resets `retryCount = 3` (WV:158) and is itself the retry callback (WV:332), so retries never stop.
9. **WeatherApp:58-60.** "fetchAll() is called so the new coordinates are geocoded immediately". `fetchAll()` returns early if data is fresh (WV:157), so new Home settings wait up to the full refresh interval.
10. **WV:675.** "use current hour's is_day for 'Now', daytime for rest". The code (WV:677) always uses `isDay = true`.
11. **BS:25-28 and WV:24-27** call the defaults "the developer's own location", while **README:47** calls them "a sentinel, not a real location". These contradict each other.
12. **WeatherIcons:5.** "wmoIcon() → 44×44 version (current conditions page, glance)". It is not used in the glance, which can't draw bitmaps (WeatherGlanceView:11).
13. **WeatherIcons:6.** "wmoIconSm() → … (forecast daily rows)". It is also used on the hourly page (WV:678).
14. **WeatherIcons:43.** `(:glance)` on `wmoIconSm` implies glance use. It is not used there, and its `Rez.Drawables` aren't available in glance scope (60 `-l 2` warnings).
15. **WV:826.** `(:glance)` on `windDirName` implies glance use. It is never called from the glance.
16. **WeatherGlanceView:10.** "Each column shows a condition-coloured dot + temperature". It also shows the location name (Glance:51-54).
17. **WV:506 / README:13.** "Bottom-left: rain amount + probability". After any foreground fetch the probability is always 0, because WV:467 stores `null` at index [3]. (This is a code bug, so the doc claim is false in practice.)
18. **README:15.** "Wind speed, gust, **direction arrow** and compass label". No arrow is drawn; `windArrow()` (WV:804) is never called.
19. **README:18.** "Daily forecast — … high/low temperature, **wind** and rain". The daily page (WV:710-767) draws no wind.
20. **README:37.** "two dots at the bottom of the **current-conditions** screen". They are drawn on all three pages (WV:500).
21. **README:69.** Device `fenix6pro_sim` doesn't exist in the SDK device list (0 `_sim` devices installed). The correct id is `fenix6pro`.
22. **README:69/72.** The output name is `simpleglanceweatherwidget.iq`, but the tracked file is `bin/simpleglanceweather.iq`.
23. **manifest.xml:5-8.** The comments "Fenix 5 series", "Fenix 7 series" and "Fenix 8 series" have no products under them. Only 4 Fenix 6 products are declared.
24. **PRIVACY.md:14.** Coordinates are "never transmitted to any server other than the weather API". False: Nominatim.
25. **PRIVACY.md:15.** "Never shared with third parties". False: Open-Meteo and the OpenStreetMap Foundation.
26. **PRIVACY.md:18.** "The only information sent to Open-Meteo is your GPS latitude and longitude". Home coordinates are sent too.
27. **PRIVACY.md:32-36.** The third-party table omits Nominatim/OSMF. The "Last updated: 16 May 2026" date predates the Nominatim addition (7 June 2026).
28. **PRIVACY.md:41.** The contact URL points to repo `simple-garmin-weather-meteo`. The actual remote is `Mahoneyclan/simpleglance-weather-widget`.
29. **BS:124 and WV:211.** The User-Agent `SimpleGlanceWeatherWidget/1.0` doesn't match app version 1.4.2.
30. **strings.xml:4-6.** `NoLocation`, `Loading` and `GpsLocation` are defined but never used (0 `Rez.Strings` references). The same text is hardcoded at WV:22, WV:491, WV:493 and BS:22, so the resources mislead about where the text lives.

## Bugs found outside docs and security (list only)

1. The retry loop never ends while a GPS weather request keeps failing and the widget is open (WV:158 plus WV:332). It fires again every 5 s and also re-fires the Home and geocode requests.
2. The foreground parse drops rain probability (WV:467 stores `null` at [3]), so "prob 0%" shows after any foreground refresh. Background data shows real values.
3. Changing settings doesn't refresh while data is fresh (App:61-66 → WV:157).
4. A background run where Home geocoding fails overwrites the stored Home name with "Home" (BS:62, BS:196, App:51).
5. Hour labels and weekday names use the watch's time zone, not the location's (BS:245, WV:399). They are wrong when Home is in another time zone.
6. The hourly page never shows night icons (WV:677).
7. `getGpsCoords()` is called from `onUpdate` (WV:490) and writes Storage on every redraw while waiting for data (WV:116/124/132).
8. `wmoIcon`/`wmoIconSm` call `loadResource` on every frame: 1 large icon, or 4–5 small icons (WV:575, WV:678, WV:753). Nothing is cached.
9. If Home is configured and only the Home fetch succeeds, `last_fetch_time` is set (WV:342) and GPS data stays stale for the full interval. Background fetches never set `last_fetch_time`, so opening the widget straight after a background refresh fetches again.
10. Cached Storage arrays are used without checking their shape (WV:79-85, WV:633-639, WV:714-719). A schema change in an update could crash old caches.
11. `gps_coords` is used without a size check (BS:95). Activity and Weather positions aren't range-checked (WV:121-134).
12. A real Home within about 1.1 km of the default coordinates can never count as "configured" (0.01° tolerance, BS:52 and WV:51).
13. The 60-second refresh timer (WV:90) redraws with no new data. `onBackgroundData` already calls `requestUpdate`.
14. "Now" in the hourly forecast uses the current temperature in the foreground (WV:426-428) but the hourly temperature in the background (BS:274), so the two paths show different values.
15. Unconfigured Home with no GPS data yet: `fetchAll` copies nothing and Home shows "Loading weather..." until GPS arrives (WV:160-170). This is acceptable but undocumented.

## Evidence appendix

### Commands

```bash
# Repo inventory and sizes
git rev-parse --short HEAD                      # ee5993d
git ls-files
wc -l source/*.mc                               # 1424 total; WV 839; BS 317
ls ARCHITECTURE.md SECURITY.md CLAUDE.md        # all: No such file

# Build (artefacts to scratchpad; key path only, never printed)
for l in 0 1 2 3; do
  monkeyc -f monkey.jungle -d fenix6pro -o $SCRATCH/build/out_l$l.prg -y ~/.garmin_dev.der -w -l $l > $SCRATCH/build/l$l.log 2>&1
  echo "level $l exit=$? warnings=$(grep -c WARNING $SCRATCH/build/l$l.log) errors=$(grep -c ERROR $SCRATCH/build/l$l.log)"
done
# level 0 exit=0 w=0 e=0 | level 1 exit=0 w=0 e=0 | level 2 exit=0 w=120 e=0 | level 3 exit=105 w=0 e=120

# -l 2 warnings by file: WeatherIcons 60, WeatherView 35, WeatherApp 19, BackgroundService 6
# by kind: 73 "not available in all function scopes" (60 WeatherIcons (:glance), 13 WeatherApp),
#   19 poly-type parameter passing (Storage.setValue / makeWebRequest), 5 return-type mismatch (Float? vs Float),
#   4 ':toDegrees' on Null, 4 container access on nullable, 4 container assignment on nullable,
#   2 'sub' with Null (BS:52, WV:51), 2 untyped params (WV:284), 1 undetermined method type

# Tests
grep -rn '(:test)' . --include=*.mc | wc -l     # 0

# Secrets and history
git rev-list --all | wc -l                      # 29 commits
git log -p --all | grep -iE '^\+.*(key|token|secret|password|apikey)'   # only "No API key required" text and .gitignore lines
git log --all --name-only --format='' | sort -u # no developer_key / .der / .pem ever; bin/simpleglanceweather.iq and .DS_Store were committed
git check-ignore --no-index -v bin/simpleglanceweather.iq   # .gitignore:2:bin/
git log --format='%h %ad %s' --date=short -- bin/simpleglanceweather.iq   # 554dc0b, 0c83c1b
git log -S nominatim --format='%h %ad %s' --date=short -- source          # 7691401 2026-06-07
git log --format='%h %ad %s' --date=short -- PRIVACY.md                    # last 051bf2a 2026-05-16

# Logging / leftovers
grep -rn "println\|System.print\|(:debug)\|TODO\|FIXME\|XXX\|HACK" source/   # none

# Counts
grep -o ' as [A-Za-z]' source/X.mc | wc -l      # 303 total
grep -oE '\[\"[a-z_0-9]+\"\]' source/*.mc | wc -l   # 61
grep -wc try source/*.mc                        # 0 everywhere
grep -rn windArrow source; grep -rn getApp source; grep -rn 'Rez.Strings' source   # dead code / unused strings

# Payload
curl -s "https://api.open-meteo.com/v1/forecast?latitude=51.5000&longitude=-0.1200&<app's exact params>" | wc -c   # 1766

# Device ids
ls ~/Library/Application\ Support/Garmin/ConnectIQ/Devices | grep fenix6   # fenix6 fenix6pro fenix6s fenix6spro fenix6xpro (no *_sim)
```

### Doc coverage and function-length script

The script lives in the reviewer's scratch folder (`tools/mcmetrics.py`) and is run with `python3 -I mcmetrics.py source/`. Its logic:
- It matches declarations with `^\s*(private|public|protected|hidden|static\s+)*(class|function|var|const)\s+(\w+)`.
- It counts `var`/`const` only at brace depth 1 inside a class (class-level members).
- It counts a declaration as documented if the nearest non-annotation line above starts with `//`, `/*` or `*`.
- It measures function length by brace matching from the declaration line.

Output: BS 15/26, App 4/12, Delegate 5/7, Glance 2/5, Icons 1/2, View 22/45, for a total of **49/97 (50.5%)**.

### Per-category evidence

1. **Correctness:**
   - `-l 2` independently flags the null crash at BS:52 and WV:51, and nullable `Float` returns at BS:36/40 and WV:35/39.
   - Unchecked indexing is at BS:274, BS:306-310, WV:428 and WV:459-463, with 0 try blocks.
   - The retry bug is WV:158 plus WV:332. The rain-probability bug is WV:467. The settings bug is WV:157.
   - Good: the 4-tier GPS fallback (WV:106-138), the "Waiting for GPS" state (WV:490-491), the cached data shown at launch (WV:79-82), and the null checks on optional hourly/daily fields (BS:275-279, WV:429-432).
2. **Architecture:**
   - Duplicated between BS and WV: `DEFAULT_HOME_*` (BS:29-30 / WV:28-29), `homeLat`/`homeLon`/`homeConfigured` (BS:34-53 / WV:33-52), `fetchWeather` (BS:158-175 / WV:284-301), `fetchLocationName` (BS:113-128 / WV:200-215), Nominatim name parsing (BS:132-153 / WV:218-236), `parseWeather` (BS:209-235 / WV:349-372) and `parseForecast` (BS:239-316 / WV:394-469). That is about 150 lines, and the copies have already diverged (bug 14, and the [3] slot).
   - Also duplicated: `wmoIcon` and `wmoIconSm` (WeatherIcons:21-41 / 44-64); the refresh default of 30 (App:75, WV:149, properties.xml:4); the "GPS Location" string (BS:22, WV:22, strings.xml:6); and Storage keys as string literals in 4 files.
   - Good: the input delegate is separate (43 lines), icon mapping is separate, and the glance is separate.
3. **Idioms:**
   - Modern APIs throughout: `Application.Properties.getValue` (BS:35, WV:34), `Storage`, and `Toybox has :Weather` (WV:128).
   - Problems: wrong `(:glance)` (WeatherIcons:43, WV:826); untyped params (WV:284); public mutable `pageIndex`/`locationIndex` (WV:55-57) mutated by the delegate; no `enum` for pages, locations or array slots; dead code (`windArrow` WV:804, `getApp` App:80, 3 unused strings); hardcoded UI strings; `-l 3` fails.
4. **Performance:**
   - Good: the payload is 1,766 B; the freshness skip (WV:145-151, WV:157); the Home geocode cache (WV:189-197); timers stopped (WV:93-96); background exit is 4 small arrays.
   - Problems: bugs 1, 7, 8, 9 and 13, and F8.
5. **Security:** see the findings table.
6. **Testing:** 0 tests. `.vscode/launch.json` has a "Run Tests" configuration but nothing to run.
7. **Coverage:** see the script output above.
8. **Quality:**
   - Good "why" comments: WV:31-32 and BS:32-33 (string properties), App:69-71 (`deleteTemporalEvent`), Glance:11 (bitmaps), WV:582-584 (arc angles), BS:184-185 (callback ordering), WV:374-393 (array layout).
   - Problems: no parameter or return docs; process context stated only in BS:12-14.
9. **Accuracy:** the 30 items listed above.
10. **Project docs:**
    - Present: README.md (84 lines; features, settings, navigation, architecture and build) and PRIVACY.md (41 lines, stale and inaccurate).
    - Missing: ARCHITECTURE.md, SECURITY.md, repo CLAUDE.md, LICENSE and CHANGELOG.
