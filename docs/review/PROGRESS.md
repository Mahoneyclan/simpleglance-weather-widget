# Review progress

Loop: SCORE → PLAN → (approval) → FIX DOCS → FIX SECURITY → RE-SCORE.
Rubric: the owner's iOS rubric, adapted to Garmin Connect IQ / Monkey C (approved 2026-10-29).
Monkey C unit tests may be proposed (approved 2026-10-29).

Targets: overall ≥ 85, documentation ≥ 34/40, no open Critical/High security findings, build + tests green.
Stop early after 3 rounds, or when a round gains < 3 points.

## Scores by round

| Round | Date | Commit | Overall | Grade | Code /60 | Docs /40 | Crit/High/Med/Low | Scorecard |
|---|---|---|---|---|---|---|---|---|
| 1 | 2026-10-29 | ee5993d | 38.4 | F | 21.0 | 17.4 | 0 / 1 / 5 / 6 | [round 1](../scorecards/scorecard-2026-10-29-round1.md) |
| 2 | 2026-10-29 | ee5993d + working tree | 66.8 | C | 34.4 | 32.4 | 0 / 0 / 1 / 8 | [round 2](../scorecards/scorecard-2026-10-29-round2.md) |
| 3 | 2026-10-30 | ee5993d + working tree | 76.4 | B | 42.8 | 33.6 | 0 / 0 / 1 / 6 | [round 3](../scorecards/scorecard-2026-10-30-round3.md) |
| 4 | 2026-10-31 | ee5993d + working tree | 85.2 | A | 48.8 | 36.4 | 0 / 0 / 0 / 4 | [round 4](../scorecards/scorecard-2026-10-31-round4.md) |
| 6 | 2026-10-31 | afa9309 + working tree | 89.2 | A | 52.0 | 37.2 | 0 / 0 / 0 / 3 | [round 6](../scorecards/scorecard-2026-10-31-round6.md) (self-review) |

## Round 1

Status: complete. Round 2 scored +28.4.

Decisions taken on the owner's go-ahead (my recommendations):
- Decision 4: comments describe current behaviour; bugs are listed in README "Known issues".
- Decision 5: README claims for unbuilt features were removed.

Part A — documentation (done 2026-10-29):
- `//!` doc comments with `@param` and `@return` on every class, function, member and constant (93 of 106 declarations matched by the counting script; the 13 unmatched were the 4 constructors, since documented, and 9 local variables the regex wrongly matched). Notes say which process runs each piece and what it writes to Storage.
- File headers on all 6 source files, and `// MARK: -` sections in WeatherView and BackgroundService.
- Fixed inaccurate comments:
  - page count and page names
  - UP/DOWN mapping, checked against the SDK's BehaviorDelegate docs
  - `past_days` / `forecast_days`
  - array item counts
  - retry behaviour
  - "geocoded immediately"
  - night icons
  - wmoIcon / wmoIconSm usage
  - the `(:glance)` notes
  - the glance header
  - the windArrow note (it's unused)
- README:
  - removed the wind arrow and daily-wind claims
  - corrected the dots, defaults and "both values" wording
  - fixed the build commands (fenix6pro)
  - added the monkeydoc command and a Known issues section
  - moved the architecture section to ARCHITECTURE.md
- manifest.xml: removed the misleading Fenix 5/7/8 comments.
- New files:
  - ARCHITECTURE.md (processes, files, data flow, Storage keys, duplication)
  - SECURITY.md (first draft; Open-Meteo company and country checked against its terms page)
  - CLAUDE.md
- Checks:
  - Comment-stripped code is identical in all 6 files; the only git-visible move is 2 import lines in WeatherIcons.mc.
  - Build passes with 0 warnings.
  - monkeydoc reports 0 warnings.
  - There are no tests yet; they arrive with B2.

Part B:
- **B1 (High, F1) — done 2026-10-29.** The owner chose to disclose Nominatim (decision 1a). Rewrote PRIVACY.md:
  - both services, with operator and country (checked against each service's terms or privacy page)
  - both GPS and Home coordinates, at 4 dp (~11 m)
  - IP-address visibility
  - when requests happen
  - what's stored on the watch
  - user choices
  - correct contact repo and date

  SECURITY.md updated. No code change. Decision recorded: no in-app consent screen.
- **B2 (Medium, F4) — done 2026-10-29.** Approved as described.
  - New `source/HomeSettings.mc` is the single reader of the Home settings, replacing the duplicate code in WeatherView and BackgroundService. It rejects non-numeric, out-of-range and half-filled values, and blank counts as "not set".
  - When Home is invalid and selected, the widget shows "Check Home settings in Garmin Connect".
  - First unit tests: `source/test/HomeSettingsTest.mc` (8 tests; the SDK runs each twice, so 16 results) all PASS.
  - Release build passes for fenix6 / 6pro / 6s / 6spro with 0 warnings. `-l 2` type warnings down from 120 to 114. monkeydoc reports 0 warnings.
  - README, ARCHITECTURE, SECURITY and CLAUDE.md updated.
  - Hand test on the watch is pending (owner).
- **B3 (Medium F3 + F2) — done 2026-10-29.** Owner chose blank defaults with the old values kept as a marker, no history rewrite, and 2 dp rounding for both services.
  - `properties.xml`: Home defaults are now blank.
  - HomeSettings: constants renamed LEGACY_DEFAULT_* (internal names only; no stored identifiers changed). The lat()/lon() fallback is now 0 instead of the legacy location.
  - New `source/Coordinates.mc`: every outgoing coordinate is rounded to 2 dp (~1 km). New test `coordinatesAreRoundedForRequests`.
  - 9 tests, 18 results, all PASS. 4 device builds pass with 0 warnings; `-l 2` warnings at 114; monkeydoc reports 0 warnings.
  - PRIVACY, SECURITY, README, ARCHITECTURE and CLAUDE.md updated.
  - Accepted residual risk: the old coordinates remain in `HomeSettings.mc`, git history and released builds.
- **B4 (Medium, F5) — done 2026-10-29.** Owner chose one shared, checked reader.
  - New `source/WeatherParser.mc` replaces both duplicated parsers (removed from WeatherView and BackgroundService). It type- and length-checks every field; a malformed reply returns null, and the previous data is kept.
  - Cached Storage arrays are shape-checked before drawing in WeatherView, and inline in WeatherGlanceView, which stays parser-free to save glance memory.
  - Behaviour changes (approved): rain probability is now filled in by foreground fetches too (fixes the "0%" bug), and the hourly "Now" temperature uses current conditions in both paths.
  - New `source/test/WeatherParserTest.mc` covers 9 tests against a recorded real Open-Meteo reply (Sydney, 2026-10-29) and damaged copies.
  - Results: 18 tests in total, all PASS (the SDK runner repeats each 2–3×: 45 results). The test runner (`monkeydo -t`) exited with code 1 despite "PASSED" and no error output; cause not identified.
  - 4 device builds pass with 0 warnings. `-l 2` warnings at 109, below the 113 baseline. monkeydoc reports 0 warnings.
  - README Known issues, ARCHITECTURE, SECURITY and CLAUDE.md updated.
- **B5 (Low items + retry bug) — code done 2026-10-29.**
  - Repo hygiene: the stale `bin/simpleglanceweather.iq` is untracked (staged deletion), and `.gitignore` now covers key files.
  - Nominatim politeness: new `RequestHeaders.mc` holds the User-Agent (version + contact); the background reuses the cached Home name.
  - GPS position is stored rounded (`Coordinates.rounded()`, with a test).
  - Endless retry fixed: retries go through `onRetryTimer()`, at most 3.
  - 4 device builds pass with 0 warnings; `-l 2` warnings at 109.
  - Tests: 19 (an earlier note said 20; one of the 20 `(:test)` blocks is the fixture module), all PASS (48 results; `monkeydo` exit code 1 again, no error output).
  - monkeydoc: 0 warnings. ARCHITECTURE, PRIVACY, SECURITY and CLAUDE.md updated for B5.

Deferred: none so far.

Open decisions for the owner:

1. Nominatim (place-name lookup): disclose it in PRIVACY.md, or remove it.
2. Default Home coordinates (the developer's own location): blank them? Leave git history as is?
3. GPL-3.0 weather icons vs the "All rights reserved" licence.
4. Comments describing buggy behaviour: document what the code does now, or fix the bug.
5. README features that aren't built (wind arrow, wind on the daily page): remove the claim, or build them.
6. Reaching 85 needs restructuring (shared parser, splitting WeatherView), which is outside docs/security scope.

## Round 2

Status: Part A and B6–B8 done (owner said "proceed" to the B6–B9 gate; B9 was optional and is asked separately). Waiting on B9, then round-3 scoring.

Part A — documentation (done 2026-10-29):
- Fixed the scorer's 13 accuracy items, except #10 (unused strings in strings.xml), a resource change left for B8.
  - comments on fetchAll, retry and getGpsCoords
  - when `home_lat_cached` is written (WeatherView, BackgroundService, ARCHITECTURE)
  - `last_fetch_time` meaning
  - widget-process module list
  - PRIVACY "MENU" wording
  - the monkeydoc command now includes `-f api.mir`
  - test-runner quirks noted in CLAUDE.md
  - SECURITY `.iq` status
  - "preset" wording
  - PROGRESS typos
- `@param` added to the 8 WeatherParser helpers.
- README Known issues completed (5 more items).
- Checks: comment-stripped code identical in all 13 files; build passes; monkeydoc reports 0 warnings.

Loop check:
- Targets not met: overall 66.8 < 85; docs 32.4 < 34.
- Gain: +28.4 (≥ 3).
- Rounds done: 2 of 3, so the loop continues.

Verified scorer claims:
- 19 tests, not 20.
- The README/CLAUDE.md monkeydoc command lacks `-f api.mir` and gives 146 warnings.
- Bug A is real: `home_lat_cached` is written before the lookup succeeds.

Open decisions for the owner:
1. GPL-3.0 icons vs "All rights reserved" (the only open Medium).
2. Commit the staged `.iq` deletion (owner commits).
3. Approve code-quality and bug work beyond docs/security: needed to approach 85.
4. Plain-language error/offline message (F11).

Part B:
- **B6 (Low N1 + N2) — done 2026-10-30.**
  - `WeatherParser.parsePlaceName()` replaces the two duplicate name pickers. It accepts only non-empty text and caps names at 30 characters.
  - `Coordinates.validOrNull()` range-checks positions from Position, Activity, Weather and Storage.
  - `last_fetch_time` and `home_*_cached` are type-checked before use, and BackgroundService's `gpsStoredName()` uses `isValidCurrent()`.
  - 4 new tests.
- **B7 (bug A + bug B) — done.**
  - `home_lat_cached` / `home_lon_cached` are written only after a successful lookup (`pendingHomeLat/Lon`), and a new Home is labelled "Home" until its name arrives.
  - Home mirrors of GPS data are now copies (`copyOf()`), not shared arrays.
  - No unit test: the logic lives in the view and depends on Storage and callbacks; it needs a hand test.
- **B8 (code quality) — done.**
  - Removed the wrong `(:glance)` from `wmoIconSm` and `windDirName`.
  - Deleted dead `windArrow()` and `getApp()`, and the 3 unused strings (closes accuracy item #10).
- Results:
  - 4 device builds pass with 0 warnings.
  - `-l 2` warnings went from 109 to 49 (one extra instance of the existing "Array to Storage.setValue" warning type).
  - 23 tests, all PASS (56 results; `monkeydo` exit code 1 as before).
  - monkeydoc reports 0 warnings.
  - README, ARCHITECTURE and SECURITY updated.

## Round 3

Status: done 2026-10-30. Scored 76.4 (B), see `docs/scorecards/scorecard-2026-10-30-round3.md`.

- **Step 1 (architecture):** WeatherView.mc (786 lines) split into WeatherData (fetch, retry, cache), WeatherState, GpsPosition, CurrentPage, ForecastPages and a thin WeatherView (169 lines). Request builders exist once, in WeatherRequests (shared with BackgroundService). Repeated constants have one home: FetchRules (refresh default, 0.01° tolerance), WeatherParser (placeholder names), WeatherSlots (array positions).
- **Step 2 (bugs):**
  - settings change fetches Home at once (bug 3)
  - retries repeat only GPS weather (C)
  - background returns the looked-up Home coordinates, so it stops re-geocoding (D)
  - no Storage writes or Properties reads in onUpdate (7, E)
  - IconCache (8)
  - per-location fetch times replace last_fetch_time (9)
  - background results reload an open widget, and the idle 60 s timer is gone (13)
  - unset Home with no GPS shows "Waiting for GPS" (15)
- **Step 3 (F11):** "No connection · <time>" line, and "No connection. Press MENU to retry." when there is no data. The status line is shorter than the proposed wording so it fits one line on a round screen.
- **Step 4 (tests):** FetchRulesTest and DisplayRulesTest (wind labels, clock times, icon mapping, glance rules, string line breaks).
- **Step 5 (idioms):** `-l 2` warnings 49 → 16 (remaining ones explained in ARCHITECTURE.md); UI messages in strings.xml; WeatherSlots constants instead of numbers; WeatherView state is private behind methods.
- **Step 6 (docs):** CHANGELOG.md added; README, ARCHITECTURE, SECURITY, PRIVACY and CLAUDE.md updated.
- Results:
  - 4 device builds pass with 0 warnings.
  - Tests: 98 results, all PASS.
  - monkeydoc reports 0 warnings.
- Needs a hand test on the watch (fetch flow and screens changed).

## Round 4

Status: done 2026-10-31. The owner approved items 1–4 of the round-3 quickest wins and chose licence option (a), GPL-3.0. Round 4 scored 85.2 (A), see `docs/scorecards/scorecard-2026-10-31-round4.md`.

- **Item 1 (accuracy):** the 12 round-3 items are fixed:
  - stale "WeatherView" file headers in BackgroundService, Coordinates, HomeSettings, WeatherParser and RequestHeaders
  - ARCHITECTURE's warning note and process table
  - SECURITY status and data rows
  - CLAUDE.md test repeat count
  - this log
  - CHANGELOG
- **Item 2 (bug H, N3):** FetchRules, WeatherState, WeatherSlots and the new Values and BackgroundResult modules are marked `:glance`, so a settings change or background result in the glance process finds every symbol. `GlanceRules.isDrawable()` type-checks the saved value. Tested.
- **Item 3 (bug G, testability):**
  - Place names are saved apart from the weather, as `gps_place` / `home_place` = [lat, lon, name], replacing `home_lat_cached` / `home_lon_cached`. Copying GPS into Home can no longer give Home the GPS name.
  - New pure rules (`WeatherState.source()`, `emptyReason()`, `FetchRules.savedPlaceName()`, `BackgroundResult.build()` / `writes()`) are tested, together with the `CurrentPage` helpers.
  - Place-name handling moved from WeatherData into PlaceNames, and the numeric checks from WeatherParser into Values, so both files are under 300 lines.
- **Item 4 (F8, bug I):** the widget looks up the GPS place name only after a move of about 1 km. MENU stops a pending retry.
- **Licence (F6):** GPL-3.0 `LICENSE` added (official text from gnu.org); README credits the icons.
- Results (checked during round-4 scoring):
  - 4 device builds pass with 0 warnings; `-l 2` warnings 16 → 14; monkeydoc reports 0 warnings.
  - The unit-test build first failed to compile (type error at StateRulesTest.mc:81), so the round-4 tests had not run. Fixed with a one-line type annotation in the test.
  - Tests: 39 distinct, 140 results, all PASS (`monkeydo` exit code 1 as before).
- Needs a hand test on the watch (place names and retries changed).

## Round 5

Status: done 2026-10-31. The owner approved item 1 of the round-4 next steps. "Delete all my data" (F9) waits for an owner decision.

- **Bug K:** a Home changed while the widget was closed is now fetched when the widget opens.
  - Each Home result is saved with the Home coordinates it was fetched for (new Storage key `home_fetch_for`, written by WeatherData and, from the background result, by WeatherApp).
  - A GPS copy saves no coordinates (widget) or `[]` (background), so it never counts as Home data.
  - New pure rule `FetchRules.fetchedForHome()`, used by `WeatherData.needsFetch()`; the background result has a sixth item for the coordinates.
  - Tests: new `homeFetchedForCurrentSetting`; the BackgroundResult tests cover the new item, the GPS-copy marker and damaged values.
- **Accuracy items 1–5 from the round-4 scorecard:** PRIVACY date and stored-data list, CHANGELOG Home line, ARCHITECTURE Home-name explanation and Storage keys, CLAUDE.md test repeat count, this log.
- Results:
  - 4 device builds pass with 0 warnings; `-l 2` warnings unchanged at 14; monkeydoc reports 0 warnings.
  - Tests: 40 distinct, 145 results, all PASS (`monkeydo` exit code 1 as before).
  - The builds overlapped with another session's Xcode build: the busy check printed it but did not stop. The test run was gated properly.
- Needs a hand test on the watch: change Home in Garmin Connect while the widget is closed, then open it.

## Round 6

Status: done 2026-10-31. Scored 89.2 (A), see `docs/scorecards/scorecard-2026-10-31-round6.md`. Hand test pending. The owner asked for the testing items and usability items d–i, and chose not to build "Delete all my data" (recorded as `(deliberate)` in CLAUDE.md and accepted in SECURITY.md). For units, the recommended option was taken: follow the watch's settings.

- **d (colour alone):** the glance shows a condition word (glance-scoped string resources) next to the temperature; the coloured dot is drawn only when it fits.
- **e (contrast):** "--", the glance divider and the inactive location dot use light grey. The clock-sector lines and the forecast header rule are decorative and stay dark grey.
- **f (units):** new `Units.mc` converts stored metric values to °F / mph / inches from the watch's temperature and distance settings. Hour headings follow the 12/24-hour setting. Hour and day headings are now worked out from the fetch time, so old data is no longer labelled "Now" or "Today".
- **g (order):** the glance shows GPS left and Home right, like the widget's dots.
- **h (icons):** freezing drizzle and rain (56, 57, 66, 67) use the rain icons.
- **i (text):** page labels, units and "Now"/"Today" are in strings.xml; day names come from the system (localised). `IconCache` became `ResourceCache` (icons and text). The labels stored with the forecast stay English; they are shown only for data saved without a fetch time.
- **Testing:** `docs/TESTING.md` hand-test script (stands in for UI tests). New pure rules `FetchRules.needsFetch()` and `gpsReplyAction()` replace logic in WeatherData. New tests: unit conversion, hour headings, glance words, freezing icons, needsFetch, gpsReplyAction.
- Results:
  - 4 device builds pass with 0 warnings; `-l 2` warnings unchanged at 14; monkeydoc reports 0 warnings.
  - Tests: 45 distinct, 173 results, all PASS (`monkeydo` exit code 1 as before).
  - Coverage: every rule, parser and calculation is tested; overall about 52% of non-UI functions. The rest (WeatherData, PlaceNames, BackgroundService fetch/callback code) needs fake Storage and requests to test: not done, owner decision.
- Busy check for builds now matches only real build processes (`scratchpad/busy.sh`), not other sessions' wait loops.
- The glance column drawing was split in two to stay under 40 lines per function (found while scoring).
- Needs the hand-test script on the watch (`bin/SGWEATHR.prg`), especially the glance layout and 24-hour headings, which can't be checked by unit tests.

## Round 7

Status: done 2026-10-31 (testability, widget side only). The owner chose the lower-risk version: the background code is unchanged.

- New `source/WatchServices.mc`: the only way WeatherData and PlaceNames reach the watch (Storage, settings, clock, requests, GPS, retry timer, redraws). No behaviour change.
- New `source/test/WeatherDataTest.mc` with `FakeWatch` (in-memory Storage, recorded requests): 10 tests covering the GPS fetch and mirror, retries and "No connection", HTTP errors, fresh data, bug K, the "Home" placeholder and `home_fetch_for`, settings changes, failed place lookups, the one-shot GPS fix, damaged cache and invalid Home.
- Checked that a test can fail: with the bug K fix broken in a scratch copy, `homeChangedWhileClosedIsFetched` fails and the rest pass.
- Results:
  - 4 device builds pass with 0 warnings; `-l 2` unchanged at 14; monkeydoc 0 warnings; 290/290 declarations documented; no function over 40 lines; WeatherData 298 lines.
  - Tests: 55 distinct, 235 results, all PASS (`monkeydo` exit code 1 as before).
  - Release build 90,924 → 91,564 bytes (+640, widget only). Peak memory not measured: a scratch run with a memory printout gave no output (the simulator likely started the glance). Added as TESTING.md section 8.
  - Coverage: WeatherData 19/21 and PlaceNames 7/7 functions now tested; about 70% of non-UI functions overall (rough count). Still untested: BackgroundService, WeatherApp's background and settings hooks, `onPosition`, and thin system wrappers (WatchServices itself, request builders, settings readers).

## Round 8

Status: code and docs done 2026-10-31; hand test pending. Found by the owner on the watch: the GPS place showed "Grange" (about 20 km away) instead of Highvale/Samford, and a walk did not change it.

- Cause (from the code; not confirmed on the watch): GpsPosition took the first position available, including an old last-known one or Garmin Weather's observation station, and only asked for a GPS fix when there was none. And fresh GPS data was never refetched after a move, so MENU did nothing.
- Fix:
  - `GpsPosition.choose()` (tested): current fix → running activity → last known → saved → weather station last; reports whether the position is a current fix.
  - WeatherData asks for a one-shot fix whenever the position is not current, and refetches when the fix shows a move.
  - New Storage key `gps_fetch_for` (rounded to ~1 km). `FetchRules.fetchedForHome()`/`homeFetchRecord()` became `fetchedFor()`/`fetchRecord()`, used by both slots; `WeatherState.HOME_FETCH_FOR_KEY` became `FETCH_FOR_KEYS` (stored key names unchanged).
- Tests: `movedWhileDataFreshIsFetched` (the Grange/Highvale case), `oldPositionAsksForFix`, `positionSourceOrder`; `freshDataIsNotFetched` updated.
- Docs: README (MENU), PRIVACY (requests and stored data), SECURITY, ARCHITECTURE, CHANGELOG, TESTING.md section 5a.

## Round 9

Status: code and docs done 2026-10-31; build, tests and hand test next. The owner asked for (1) Highvale to work as Home and (2) Home to be easy to change (option 3: watch menu and clearer settings), and earlier for Brisbane CBD as the default Home.

- **Default Home:** Brisbane CBD (-27.4698, 153.0251) in properties.xml, mirrored in `HomeSettings.DEFAULT_LAT/LON` and tested. Applies to new installs only.
- **Legacy dead zone removed:** only the exact old preset text ("-27.3705", "152.8691") counts as "not set"; anything else, even nearby, is a real Home. README known issue removed.
- **MENU menu** (`HomeMenu.mc`): Refresh, or Set Home here (shows the position, asks for confirmation, then `HomeHere.apply()` saves it as the Home settings to 5 decimals and fetches Home). Works on USB-installed copies, where Garmin Connect settings may be missing. New `WatchServices.setHomeSettings()`.
- **Settings titles** in Garmin Connect now come from strings.xml, with examples and how to use GPS instead.
- Tests: `setHomeHereSavesAndFetches`, `homeHereFormats`, `defaultHomeIsSet`; `homeStatusDefaultsAreNotSet` updated for the exact-match rule.
