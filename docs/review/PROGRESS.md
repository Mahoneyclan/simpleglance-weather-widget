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
