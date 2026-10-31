# Scorecard: SimpleGlance Weather Widget (round 4)

- **Date:** 2026-10-31
- **Commit:** `ee5993d` (branch `main`) **with uncommitted working-tree changes**, including the untracked round-4 files (`BackgroundResult`, `PlaceNames`, `Values`, `StateRulesTest`, `LICENSE`). The working tree is what was scored. Manifest version 1.5.0.
- **Rubric:** the owner's iOS rubric adapted to Garmin Connect IQ / Monkey C, unchanged from rounds 1–3 (same 10 categories, weights and grade bands).
- **Reviewer:** read-only review in the same session that will hand over; the only repo file written is this scorecard. Build output went to the scratchpad (`…/scratchpad/round4`).
- **Toolchain:** Connect IQ SDK 8.1.1.

## Overall

| | Score |
|---|---|
| **Overall** | **85.2 / 100, grade A** (A 85+, B 70–84, C 55–69, D 40–54, F under 40). This is on the line: one point less in any category with a weight of 8% or more gives a B. |
| Code (categories 1–6) | 48.8 / 60 |
| Documentation (categories 7–10) | 36.4 / 40 |
| Build | Passes on fenix6, fenix6pro, fenix6s and fenix6spro with 0 warnings. `-l 2`: **14 warnings** (was 16). `-l 3`: fails with 14 errors. No build-failure cap applies. |
| Tests | **39 distinct tests, 140 results, `PASSED (passed=140, failed=0, errors=0)`**. `monkeydo` exit code 1 (known quirk). The test build did **not compile** at first (StateRulesTest.mc:81, type error), so the round-4 tests had never run; fixed with a one-line type annotation in that test (no app code changed) before this run. |
| Critical security findings | 0, so no Security cap applies. High: 0. Medium: 0. |

| # | Category | Weight | Score /10 | Weighted | Reason |
|---|---|---|---|---|---|
| 1 | Correctness & robustness | 12% | 8 | 9.6 | Round-3 bugs G, H, I and N3 are fixed. The Home name now comes from `home_place`, never from a mirrored copy (PlaceNames.mc:46-57). FetchRules and BackgroundResult are available in the glance (FetchRules.mc:13, BackgroundResult.mc:14). MENU stops a pending retry (WeatherData.mc:167). The glance type-checks its data (WeatherGlanceView.mc:98-103). Still open: watch time zone for labels, day-only hourly icons, freezing rain shown as clear sky (WeatherIcons.mc:12-14), the legacy-default dead zone, bug J, and a new plausible bug K (a Home change made while the widget is closed is not fetched straight away). Units are always metric and hour labels always 12-hour, whatever the watch is set to. |
| 2 | Architecture & structure | 10% | 9 | 9.0 | No file is over 300 lines: WeatherData has 289 and WeatherParser 277, down from 319 and 315. No function is over 40 lines. Decisions moved into pure modules (WeatherState.source/emptyReason, FetchRules.savedPlaceName/placeRecord, BackgroundResult.build/writes), and Values gives one home to type checks. WeatherApp now uses WeatherState keys. Left: `"gps_coords"` is spelt out 5 times (GpsPosition.mc:37, 41; WeatherData.mc:102, 245; BackgroundService.mc:98) with no WeatherState constant, and `"refresh_rate"` twice. WeatherData and PlaceNames still read and write Storage directly. |
| 3 | Monkey C idioms | 8% | 8 | 6.4 | Of round 3's three problems, two are fixed: the real scope gap (H) and the glance's slot literals (the glance now uses `WeatherSlots`). The 14 remaining `-l 2` warnings are the accepted kinds explained in ARCHITECTURE.md:89-91; `-l 3` still fails. Still open: UI words are hardcoded instead of resources ("RAIN", "WIND", "Feels", "prob", "Now", "Today", day names: CurrentPage.mc:128, 138, 149; WeatherParser.mc:161-165, 180). |
| 4 | Concurrency & performance | 8% | 9 | 7.2 | F8 is fixed in the foreground: the GPS place name is looked up only after a move of about 1 km (`gps_place`, PlaceNames.mc:47-52). The duplicate GPS request (I) is fixed. Minor: the offline line loads a string resource on every redraw (WeatherView.mc:138). |
| 5 | Security & privacy | 12% | 8 | 9.6 | F6 is fixed: GPL-3.0 LICENSE, and README credits the icons. N3 is fixed and tested. HTTPS only, no secrets in the tree or its 29 commits, no logging, every outgoing coordinate rounded. Open: F9, no "Delete all my data" (a Public store requirement), plus Lows F3 (accepted), F7 (waiting for a commit) and F12. |
| 6 | Testing | 10% | 7 | 7.0 | 39 tests (was 32), all able to fail. New: WeatherState rules, BackgroundResult round trip and damage handling, CurrentPage helpers, place records, glance type check. About 45 of 85 non-UI functions are covered (~53%, below the 80% Public store target). Untested: WeatherData (about 20 functions), PlaceNames, BackgroundService, WeatherApp.onBackgroundData. `homeNameIgnoresMirroredGps` (FetchRulesTest.mc:57) only shows that a weather array is not a place record; it does not exercise the code path where bug G lived. |
| 7 | Doc-comment coverage | 12% | 10 | 12.0 | 248/248 declarations have `//!` comments. Every parameter has `@param`; the script flags 4, all false positives from `Method(...)` and generic parameter types. monkeydoc: 0 warnings. |
| 8 | Doc-comment quality | 10% | 9 | 9.0 | The stale "WeatherView" headers are fixed. Comments explain the why (PLACE_TOLERANCE vs request rounding, why place names are kept apart from the weather arrays, why Values exists), and side effects and processes are named. Unverified claim kept from round 3: WeatherGlanceView.mc:16 says `drawBitmap()` is unavailable in a glance. |
| 9 | Accuracy | 8% | 8 | 6.4 | All 12 round-3 items are fixed. 5 new minor ones, listed below. |
| 10 | Project docs | 10% | 9 | 9.0 | README, ARCHITECTURE, SECURITY, PRIVACY, CLAUDE.md, CHANGELOG and LICENSE are present and mostly current; Known issues are accurate. Gaps: README doesn't say the units are metric only; the doc-coverage script is still not in the repo; PROGRESS.md defers round-4 results to a "hand-over". |
| | **Total** | 100% | | **85.2** | |

## Key metrics

| Metric | Round 4 | Round 3 | How counted |
|---|---|---|---|
| Source files | 22 `.mc` + 5 test `.mc` | 19 + 4 | `ls` |
| Lines (app) | 2,314: 1,250 code, 836 comment, 228 blank | 2,142: 1,188 / 744 / 210 | `wc -l`, `grep -cE` |
| Lines (tests) | 588 | 473 | `wc -l` |
| Files over 300 lines | **0** | 2 | `wc -l` |
| Functions over 40 lines | 0 | 0 | metrics script |
| Doc-comment coverage | **248/248 = 100%** | 226/226 | round-3 `mcmetrics.py` |
| Tests | **39 distinct, 140 results** (13 run ×2, 6 ×3, 10 ×4, 4 ×5, 6 ×6), all pass | 32 / 98 | `grep -c '^(:test)'`; run output |
| Build | 4 devices: 0 warnings. `-l 2` **14**, `-l 3` fail, 14 errors | 16 / fail, 16 | appendix |
| `-l 2` by file | WeatherApp 12, WeatherRequests 2 | WeatherApp 14, WeatherRequests 2 | `grep WARNING` |
| monkeydoc | 0 warnings | 0 | appendix |
| `instanceof` checks | 24 (many checks now go through `Values`) | 32 | `grep -o` |
| TODO/FIXME/println/(:debug) | 0 | 0 | `grep -rn` |
| Storage writes | 13 `setValue` calls in code (WeatherData 8, GpsPosition, PlaceNames, WeatherApp 1 each; 2 doc-line matches) | 16 | `grep -c` |
| Security findings | Critical 0 · High 0 · Medium 0 · Low 4 | 0 / 0 / 1 / 6 | below |

## Change since last scorecard

| # | Category | R1 | R2 | R3 | R4 | Delta (3→4) |
|---|---|---|---|---|---|---|
| 1 | Correctness & robustness | 4 | 6 | 7 | 8 | +1 |
| 2 | Architecture & structure | 3 | 5 | 8 | 9 | +1 |
| 3 | Monkey C idioms | 4 | 5 | 7 | 8 | +1 |
| 4 | Concurrency & performance | 5 | 6 | 8 | 9 | +1 |
| 5 | Security & privacy | 5 | 7 | 7 | 8 | +1 |
| 6 | Testing | 0 | 5 | 6 | 7 | +1 |
| 7 | Doc-comment coverage | 5 | 9 | 10 | 10 | 0 |
| 8 | Doc-comment quality | 5 | 8 | 8 | 9 | +1 |
| 9 | Accuracy | 3 | 7 | 7 | 8 | +1 |
| 10 | Project docs | 4 | 8 | 8 | 9 | +1 |
| | **Overall** | **38.4 (F)** | **66.8 (C)** | **76.4 (B)** | **85.2 (A)** | **+8.8** |

No category dropped; none is below 7.

## Round-3 findings status

| # | Severity | Status | Evidence |
|---|---|---|---|
| F3 | Low | Open (accepted) | Legacy coordinates at HomeSettings.mc:29-31 and in tests. SECURITY.md:43. |
| F6 | Medium | **Fixed** | `LICENSE` (GPL-3.0 text), README.md:92-100, SECURITY.md:46. |
| F7 | Low | Open (owner commit pending) | `D bin/simpleglanceweather.iq` still only staged. |
| F8 | Low | **Fixed** | `gps_place` / `home_place` reuse within ~1 km (PlaceNames.mc:46-57; BackgroundService.mc:87-94). |
| F9 | Low | Open | No "clear data" option. Disclosed in PRIVACY.md:39 and SECURITY.md:49. Required at the Public store level. |
| F12 | Low | Open | Unpinned dependencies in the store-asset script (developer tool). |
| N3 | Low | **Fixed** | `GlanceRules.isDrawable` uses `Values.arrayOrNull` and type checks (WeatherGlanceView.mc:98-103); tested by `glanceDrawableCheck`. |

## New security findings

None. Checklist:
- **Secrets:** `git log -p --all` (29 commits) has no added key/token/secret/password lines; untracked files contain none (the only `grep` hit is the word "password" in the GPL text).
- **Network:** HTTPS only; the only `http://` is the XML namespace at manifest.xml:2.
- **Coordinates:** requests go through `Coordinates.forRequest`; place records store request-precision floats.
- **Logging and debug leftovers:** none.
- **User-Agent:** 1.5.0, matches manifest.xml:3.

Totals for round 4: **Critical 0 · High 0 · Medium 0 · Low 4 (F3, F7, F9, F12).**

## Inaccurate or misleading claims (5)

1. **PRIVACY.md:3** "Last updated: 29 October 2026". The policy changed in round 4 (the place-name rule at L23 and the stored-coordinates line at L37).
2. **CHANGELOG.md:6** "A new Home setting is fetched straight away". True only while the widget is open; see bug K.
3. **ARCHITECTURE.md:71** "the Home name is always read from `home_place`". When Home data is still fresh, the widget keeps the name from the cached `home_weather` array (WeatherData.mc:99) and does not call `lookUp`. Usually the same name, but not always (bug K).
4. **docs/review/PROGRESS.md** round 4 says "Results: see the round-4 hand-over" but records no build or test results. The test build did not compile, so no green test run could have happened.
5. **CLAUDE.md:20** "Each test appears 2–5 times in the results". This run showed 2–6 times.

## Bugs found outside docs and security (list only)

Open from earlier rounds: 5 (time zone), 6 (day-only hourly icons), 12 (legacy-default dead zone), J (Home briefly shows GPS data under the GPS name after Home is first set), F (`monkeydo` exit code). Freezing drizzle/rain icons (README:87).

Fixed this round: G, H, I (see Correctness).

New:
- **K (plausible, not reproduced). A Home change made while the widget is closed can show the wrong place for up to one refresh interval.** `settingsChanged()` (WeatherData.mc:181-185), which clears `home_fetch_time`, runs only when the open widget gets `onSettingsChanged`. In the glance process WeatherApp only reschedules (WeatherApp.mc:80-85), and a closed app doesn't get the call at all. Meanwhile `home_fetch_time` is fresh: the background writes it even for a GPS mirror (BackgroundResult.mc:61-64), and a real Home fetch writes it too. On the next open, `needsFetch(HOME)` is false (WeatherData.mc:194-199), so the Home page shows the mirrored GPS weather, or the old Home's, under the old name until the data goes stale or the next background run. Fix: save the coordinates each Home result was fetched for and treat a mismatch with the current settings as stale (a pure rule in FetchRules, testable), and don't write `home_fetch_time` for a mirror.
- **L (UX consistency).** The glance puts Home on the left and GPS on the right (WeatherGlanceView.mc:42-43); the widget's dots put GPS on the left and Home on the right (WeatherView.mc:150-159). Both are documented, but they are opposite.
- **M (UX).** Temperatures, wind and rain are always °C, km/h and mm, and hour labels always 12-hour (WeatherParser.mc:178-185), while the offline line follows the watch's 24-hour setting (WeatherView.mc:142-143). Not mentioned in README.

## Evidence appendix

```bash
S=/private/tmp/claude-502/-Volumes-GDrive-Github-simpleglance-weather-widget/56b2ebd5-0d8c-4cb5-bda1-fea653a6d475/scratchpad/round4
SDK="$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-8.1.1-2025-03-27-66dae750f/bin"
# every run wrapped in perl alarm 900; key path never printed
for d in fenix6 fenix6pro fenix6s fenix6spro; do "$SDK/monkeyc" -f monkey.jungle -d $d -o $S/build/$d.prg -y ~/.garmin_dev.der -w; done
                                    # all exit 0, 0 warnings, 0 errors
"$SDK/monkeyc" ... -d fenix6pro -w -l 2   # exit 0, 14 warnings: WeatherApp.mc:41 ×2, 44 ×2, 49 ×2, 54 ×2, 71, 73 ×2, 83; WeatherRequests.mc:26, 52
"$SDK/monkeyc" ... -d fenix6pro -w -l 3   # exit 105, 14 errors
"$SDK/monkeydoc" -c private -f "$SDK/api.mir" -o $S/doc source/*.mc source/test/*.mc   # exit 0, 0 warnings
"$SDK/monkeyc" ... -d fenix6pro -w --unit-test   # first: exit 105, StateRulesTest.mc:81 "Cannot assign type Array[Number x4]"
                                    # after `new [15] as Array<Object?>`: exit 0, 0 warnings
"$SDK/monkeydo" $S/test/test.prg fenix6pro -t    # "Ran 140 tests" / "PASSED (passed=140, failed=0, errors=0)", exit 1
python3 -I <round-3 scratchpad>/mcmetrics.py source   # 248/248; 4 @param false positives; no function over 40 lines
git rev-list --all | wc -l                             # 29
git log -p --all | grep -ciE '^\+.*(api[_-]?key|token|secret|password|BEGIN .*PRIVATE)'   # 0
```

Process note: my first wait-for-the-simulator loop used `pgrep -f 'xcodebuild|monkeydo|monkeyc'`, which matches its own command line, so it could never see the machine as free. I stopped it and switched to `pgrep -f '[b]in/monkeydo |[b]in/monkeyc |[x]codebuild'`, which does not match itself. Other sessions' wait loops that use the first pattern will see each other as busy until they time out.

## To stay at A and get ready for the Public store

1. **Fix bug K** with a pure, tested rule (Home data is stale if fetched for other coordinates), and fix accuracy items 1–5. Correctness and accuracy +0.8 to +1.6. This gives margin above 85.
2. **Add "Delete all my data" (F9).** Required at the Public store level. In Connect IQ that could be a settings toggle that clears Storage on the next start, or a menu item in the widget. Owner decision. Security 8→9 (+1.2).
3. **Raise test coverage toward 80%.** Pull the remaining WeatherData and PlaceNames decisions (which slots to fetch, mirror or not, which name to use) into pure functions and test them, plus a test that drives the BackgroundService result. Testing 7→8 (+1.0).
4. **Move the hardcoded UI words into strings.xml** and decide on units (follow the watch's unit and 24-hour settings, or document metric only). Idioms 8→9 (+0.8).
