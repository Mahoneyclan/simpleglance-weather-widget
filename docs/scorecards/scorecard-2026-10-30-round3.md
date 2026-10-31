# Scorecard: SimpleGlance Weather Widget (round 3)

- **Date:** 2026-10-30
- **Commit:** `ee5993d` (branch `main`) **with uncommitted working-tree changes** (37 paths in `git status --short`). The working tree is what was scored, including the untracked restructure files (`WeatherData`, `WeatherState`, `GpsPosition`, `CurrentPage`, `ForecastPages`, `WeatherFormat`, `WeatherRequests`, `FetchRules`, `WeatherSlots`, the two new test files) and CHANGELOG.md. Manifest version 1.5.0.
- **Rubric:** the owner's iOS rubric adapted to Garmin Connect IQ / Monkey C, unchanged from rounds 1 and 2 (same 10 categories, weights and grade bands).
- **Reviewer:** independent review, read-only. The only file written in the repo is this scorecard. Build output went to the scratchpad (`…/scratchpad/round3`).
- **Toolchain:** Connect IQ SDK 8.1.1.

## Overall

| | Score |
|---|---|
| **Overall** | **76.4 / 100, grade B** (A 85+, B 70–84, C 55–69, D 40–54, F under 40) |
| Code (categories 1–6) | 42.8 / 60 |
| Documentation (categories 7–10) | 33.6 / 40 |
| Build | Passes on fenix6, fenix6pro, fenix6s and fenix6spro with 0 warnings. `-l 2`: **16 warnings** (was 109). `-l 3`: fails with 16 errors. No build-failure cap applies. |
| Tests | **32 distinct tests, 98 results, `PASSED (passed=98, failed=0, errors=0)`**. `monkeydo` exit code 1 (known quirk). |
| Critical security findings | 0, so no Security cap applies. High: 0. |

| # | Category | Weight | Score /10 | Weighted | Reason |
|---|---|---|---|---|---|
| 1 | Correctness & robustness | 12% | 7 | 8.4 | Most round-2 bugs are fixed: settings changes fetch Home at once (WeatherData.mc:181-185), per-location fetch times replace `last_fetch_time`, the Home name is only cached after a successful lookup (WD:212, 312-318), mirrors are copies (WD:134-135), retries repeat only GPS weather (WD:236-241, 274), failures show "No connection" (WeatherView.mc:110, 137-148). Still open: watch time zone for labels, day-only hourly icons, the legacy-default dead zone, a new Home-name bug (G), a possible glance-process crash path via `FetchRules` (H), and an unchecked glance Storage read (N3). |
| 2 | Architecture & structure | 10% | 8 | 8.0 | Big step: WeatherView is 169 lines and draws nothing but status; data, position, pages and formatting are split; requests are built once (WeatherRequests.mc) and fetch rules are pure and tested (FetchRules.mc). No function is over 40 lines. Two files are just over ~300 lines (WeatherData 319, WeatherParser 315). Small duplications remain: WeatherApp.mc:70, 76-77 and WeatherData.mc:136-138 spell the Storage keys as literals instead of `WeatherState` keys; WeatherData uses Storage/Properties directly, so its state logic cannot be unit tested. |
| 3 | Monkey C idioms | 8% | 7 | 5.6 | `-l 2` warnings down from 109 to 16, all in WeatherApp (14) and WeatherRequests (2); `-l 3` still fails. Good use of `module`/`const`, slot constants, `instanceof`, `(:background)`/`(:glance)` scoping, `IconCache`. Problems: one of the "accepted" warnings is a real scope gap (`FetchRules` at WeatherApp.mc:105, see H); UI words are hardcoded rather than resources ("RAIN", "WIND", "Feels", "Now", "Today", day names: CurrentPage.mc:138, 149, 128; WeatherParser.mc:160-164, 179); the glance uses slot literals 0/5/7 (documented trade-off). |
| 4 | Concurrency & performance | 8% | 8 | 6.4 | Icons load once per show (WeatherIcons.mc:81-104), the idle 60 s redraw timer is gone, settings are read in `refresh()` not every frame (WD:30, 168), retries are GPS-only, and the background reuses the Home name and reports the looked-up coordinates (BackgroundService.mc:87-93, 190-194). Remaining: the GPS place name is re-requested on every GPS fetch (WD:225, 255; README:89); MENU during a retry wait starts a new request without stopping the pending retry timer (WD:167-176, 274), so a duplicate GPS request is possible; the offline line reads Storage and a resource on every redraw (WV:138-139, minor). |
| 5 | Security & privacy | 12% | 7 | 8.4 | N1 (Nominatim fields) and N2 (Storage reads) are fixed and tested (WeatherParser.mc:199-228, Coordinates.mc:35-42, FetchRules.mc:51-68). F11 (silent errors) is fixed. HTTPS only, no secrets in tree or 29-commit history, no logging. Still open: the Medium licence finding (F6), no "Delete all my data" (F9, a Public store requirement), and 4 more Lows plus 1 new Low (N3). |
| 6 | Testing | 10% | 6 | 6.0 | 32 real tests (was 19), all passing, all able to fail. New: FetchRules (3), WeatherFormat, icon mapping, glance rules, status strings (6), plus place-name and position tests. About 30 of about 68 non-UI functions are covered (~44%, below 80%). Untested: the whole WeatherData state machine (refresh/needsFetch/source/emptyReason/mirror/rename and every callback: 24 functions), BackgroundService run/merge logic, `WeatherApp.onBackgroundData`, `CurrentPage.highLow`/`rainProbability`. The new bug G lives in exactly that untested code. |
| 7 | Doc-comment coverage | 12% | 10 | 12.0 | 226/226 declarations (classes, modules, functions, members and module constants) have `//!` comments; every function parameter has `@param` (the round-2 gap of 8 is closed). Test functions are all documented (their `logger` parameter has no `@param`; not counted, as in round 2). monkeydoc: 0 warnings. |
| 8 | Doc-comment quality | 10% | 8 | 8.0 | Strong "why" comments (PLACE_TOLERANCE vs request rounding, MIN_REFRESH_MINUTES, arc angles, `%` sign handling, Security: notes at each validation point), and side effects listed per function. Docked for the stale file headers that still name WeatherView as the user of shared modules (Accuracy items 1–6) and for ARCHITECTURE's warning explanation (item 7). |
| 9 | Accuracy | 8% | 7 | 5.6 | 12 mismatches, all minor: 6 stale "WeatherView" references after the split, the ARCHITECTURE explanation of the accepted `-l 2` warnings, SECURITY.md status and "Time of last fetch" rows, CLAUDE.md's test repeat count, PROGRESS.md not recording the round-3 restructure, and one CHANGELOG claim undercut by bug G. |
| 10 | Project docs | 10% | 8 | 8.0 | README, ARCHITECTURE, SECURITY, PRIVACY, CLAUDE.md and a new CHANGELOG are present and mostly current; README Known issues is accurate (7 items checked). No LICENSE file, the GPL-3.0 icon question is still unresolved (README:94), and PROGRESS.md stops before this round's work. |
| | **Total** | 100% | | **76.4** | |

## Key metrics

| Metric | Round 3 | Round 2 | How counted |
|---|---|---|---|
| Source files | 19 `.mc` + 4 test `.mc` | 10 + 2 | `ls source/*.mc source/test/*.mc` |
| Lines (app) | 2,142 total: 1,188 code, 744 comment, 210 blank | 1,821: 1,112 / 530 / 179 | `wc -l`, `grep -cE '^\s*$'`, `grep -cE '^\s*//'` |
| Lines (tests) | 473 (WeatherParserTest 245, DisplayRulesTest 92, HomeSettingsTest 91, FetchRulesTest 45) | 288 | `wc -l` |
| Files over 300 lines | WeatherData.mc (319), WeatherParser.mc (315) | WeatherView.mc (819) | `wc -l` |
| Functions over 40 lines | **0** | 3 (118 / 76 / 58) | metrics script (appendix) |
| Doc-comment coverage | **226/226 = 100%**, 0 functions missing `@param`. Tests: 32/32 test functions documented | 110/110, 8 missing `@param` | metrics script. The round-2 script was not in the repo; I rewrote it. Mine also counts module constants and `module` declarations, which round 2 checked by hand, so totals are not directly comparable |
| Tests | **32 distinct, 98 results** (13 run ×2, 10 ×3, 3 ×4, 6 ×5), 98 pass, 0 fail, 0 errors; exit code 1 | 19 / 48 | `grep -c '^(:test)'` (33 lines, 1 is the fixtures module); run output |
| Build | 4 devices: exit 0, 0 warnings. `-l 2` **16 warnings**, `-l 3` **FAIL, 16 errors** | 109 / fail with 109 | appendix |
| `-l 2` by file | WeatherApp 14, WeatherRequests 2 | Icons 60, View 27, App 19, BS 3 | `grep WARNING` |
| monkeydoc | 0 warnings (with `-f api.mir`) | 0 | appendix |
| `as` casts | 433 | 313 | `grep -o ' as [A-Za-z]'` (more files, more typed declarations) |
| Dictionary key reads `["…"]` | 25, all in WeatherParser and all `instanceof`/`isNumeric`-checked | 37, 14 unchecked | `grep -oE '\["[a-z_0-9]+"\]'` |
| `instanceof` checks | 32 | 12 | `grep -o instanceof` |
| try/catch | 0 | 0 | `grep -w try` |
| TODO/FIXME/println/(:debug) | 0 | 0 | `grep -rn` |
| Storage writes | 16 `Storage.setValue` calls (WeatherData 10, WeatherApp 5, GpsPosition 1) plus 1 `deleteValue`; `grep` also matches 1 doc line in Coordinates.mc. 10 keys (2 new: `gps_fetch_time`, `home_fetch_time`; `last_fetch_time` retired, not reused) | 26 calls, 8 keys | `grep -ohE 'Storage\.(get\|set\|delete)Value'` |
| Security findings | Critical 0 · High 0 · Medium 1 · Low 6 | 0 / 0 / 1 / 8 | below |

## Change since last scorecard

| # | Category | Round 1 | Round 2 | Round 3 | Delta (2→3) |
|---|---|---|---|---|---|
| 1 | Correctness & robustness | 4 | 6 | 7 | +1 |
| 2 | Architecture & structure | 3 | 5 | 8 | +3 |
| 3 | Monkey C idioms | 4 | 5 | 7 | +2 |
| 4 | Concurrency & performance | 5 | 6 | 8 | +2 |
| 5 | Security & privacy | 5 | 7 | 7 | 0 |
| 6 | Testing | 0 | 5 | 6 | +1 |
| 7 | Doc-comment coverage | 5 | 9 | 10 | +1 |
| 8 | Doc-comment quality | 5 | 8 | 8 | 0 |
| 9 | Accuracy | 3 | 7 | 7 | 0 |
| 10 | Project docs | 4 | 8 | 8 | 0 |
| | **Overall** | **38.4 (F)** | **66.8 (C)** | **76.4 (B)** | **+9.6** |
| | Code /60 | 21.0 | 34.4 | 42.8 | +8.4 |
| | Docs /40 | 17.4 | 32.4 | 33.6 | +1.2 |

No category dropped. Security stays at 7: two Lows closed, one new Low, but the Medium (F6) and the missing data-deletion option (F9) are unchanged. Accuracy stays at 7: the 13 round-2 items are fixed, but the restructure introduced 12 new minor ones.

## Round-2 findings status

| # | Severity | Status | Evidence |
|---|---|---|---|
| F3 | Low | **Open (accepted)** | Legacy coordinates remain at HomeSettings.mc:29-31, in HomeSettingsTest.mc:27-35, 80, and as the doc example at Coordinates.mc:24 (`"-27.37"`). SECURITY.md:43. |
| F6 | Medium | **Open** | GPL-3.0 icons (WeatherIcons.mc:5, ARCHITECTURE.md:43) vs README.md:94 "All rights reserved". No LICENSE file. SECURITY.md:46. |
| F7 | Low | **Open (owner commit pending)** | `D bin/simpleglanceweather.iq` is still only staged; HEAD and history keep it. SECURITY.md:47 is accurate. |
| F8 | Low | **Partly fixed** | Background: fixed. It reuses the saved Home name and returns the looked-up coordinates so the app records them (BS:87-93, 190-194; WeatherApp.mc:78-81). Foreground: GPS is still reverse-geocoded on every GPS fetch (WD:225, 255), as README:89 says. |
| F9 | Low | **Open** | No "clear data" option. PRIVACY.md:38 and SECURITY.md:49 disclose this. The Public store standard requires "Delete all my data". |
| F11 | Low | **Fixed** | "No connection · 14:05" line (WV:110, 137-148) and "No connection. Press MENU to retry." (WV:118, strings.xml:7). Failed background refreshes are not shown; README:90 says so. |
| F12 | Low | **Open** | No pinned dependencies for `image-generators/generate_store_assets.py`. SECURITY.md:53. |
| N1 | Low | **Fixed** | `WeatherParser.parsePlaceName` accepts only non-empty Strings and caps them at 30 characters (WeatherParser.mc:191-228). 3 tests. |
| N2 | Low | **Fixed** | `gps_coords` goes through `Coordinates.validOrNull` (GpsPosition.mc:41, BS:97, WD:107). Fetch times and `home_*_cached` go through `isNumeric` (WD:80, FetchRules.mc:52, 65). Activity/Weather positions are range-checked (GpsPosition.mc:24-33). Tested (`positionValidation`, `isFreshBoundaries`, `placeNameReuse`). |

## New security findings

Checklist results:
- **Secrets:** none. `git log -p --all` (29 commits), `git grep`, and `git diff HEAD` of the working tree show only prose ("No API keys…"). No key file was ever committed; the untracked files contain no secrets.
- **Network:** HTTPS only: WeatherRequests.mc:27 and :53 are the only URLs; the only `http://` is the XML namespace at manifest.xml:2.
- **Coordinates:** every request goes through `Coordinates.forRequest` (WeatherRequests.mc:29-30, 55-56); the saved position goes through `Coordinates.rounded` (WD:252, GpsPosition.mc:37).
- **Logging, debug leftovers:** none.
- **Permissions:** Background, Communications, Positioning: all used.
- **User-Agent:** version 1.5.0 matches manifest.xml:3 (RequestHeaders.mc:12).

| # | Severity | Location | Issue | What it means in plain English | Fix | Effort |
|---|---|---|---|---|---|---|
| N3 | Low | WeatherGlanceView.mc:35-36, 95-96 | The glance casts `Storage.getValue(...) as Array?` and `GlanceRules.isDrawable` calls `data.size()` without an `instanceof Array` check. `as` is not checked at run time, so a non-array value under `home_weather`/`gps_weather` would crash the glance. No current version writes one, so this is unlikely. | A damaged saved value could crash the glance strip. | Start `isDrawable` with `if (!(data instanceof Array)) { return false; }`, take `Object?`, and add a test case with a String and a Number. | XS |

Totals for round 3: **Critical 0 · High 0 · Medium 1 (F6) · Low 6 (F3, F7, F8, F9, F12, N3).**

## Documentation gaps

- No LICENSE file; the GPL-3.0 icon licence still conflicts with README.md:94.
- docs/review/PROGRESS.md ends at round-2 B8 and says "Waiting on B9, then round-3 scoring" (L112). The restructure, the "No connection" status and the 9 new tests are not logged, although SECURITY.md:52 refers to a "round 3" fix.
- The coverage counting script used in rounds 1–2 (`tools/mcmetrics.py`) is not in the repo, so counts can't be reproduced exactly. A copy in `tools/` would keep the method fixed.
- Test functions have no `@param logger`. That's trivial, but it is the only `@param` gap.

## Inaccurate or misleading comments and doc claims (12)

1. **BackgroundService.mc:22.** "the GPS place name last saved by WeatherView". It is saved by WeatherData (`rename`, WD:146-159).
2. **BackgroundService.mc:72.** "the last coordinates WeatherView saved to Storage". `gps_coords` is written by GpsPosition (L37) and WeatherData (WD:252).
3. **Coordinates.mc:2.** "Used by the widget (WeatherView)". The users are now WeatherRequests, GpsPosition and WeatherData.
4. **HomeSettings.mc:2.** "Used by the widget (WeatherView)". The user is WeatherData (WD:97, 168, 206-207).
5. **WeatherParser.mc:1-2.** "Used by the widget (WeatherView)", and it is called "the reader of Open-Meteo responses and of the weather arrays", but it also reads Nominatim replies (L199). ARCHITECTURE.md:36 has this right.
6. **RequestHeaders.mc:1-2.** "shared by the widget (WeatherView) and the background refresh (BackgroundService)". Its only user is WeatherRequests.mc:62.
7. **ARCHITECTURE.md:84-86.** The 14 accepted WeatherApp warnings are explained as "the views and the background service it creates are deliberately not [annotated]". Two of them (WeatherApp.mc:105) are `FetchRules.refreshMinutes`, a shared rule module that isn't available in the glance process. That's a real scope gap (bug H), not a deliberate choice. ARCHITECTURE.md:12 likewise lists only WeatherApp, WeatherGlanceView and GlanceRules for the glance process.
8. **SECURITY.md:3.** "Status: first draft (review round 1, 2026-10-29)". The file has since been updated through round 3 (L51-52).
9. **SECURITY.md:13.** "Time of last fetch" is listed as one value. There are now two per-location keys (`gps_fetch_time`, `home_fetch_time`; ARCHITECTURE.md:76).
10. **CLAUDE.md:20.** "Each test appears 2–3 times in the results". This run showed 2–5 times (13 ×2, 10 ×3, 3 ×4, 6 ×5).
11. **docs/review/PROGRESS.md:112.** The status is stale; see Documentation gaps.
12. **CHANGELOG.md:7.** "A new Home location shows 'Home' until its place name arrives, never the previous Home's name." That holds for a brand-new Home, but when Home returns to coordinates looked up earlier, the GPS place name can be used for Home (bug G).

Not counted (I couldn't verify them offline): WeatherGlanceView.mc:16, "dc.drawBitmap() is not available in glance context" (I believe newer devices allow bitmaps in glances, but I couldn't confirm it for the Fenix 6 at API 3.2); README:16 "Rainfall (mm, current hour)"; and the third-party retention claims in PRIVACY.md:27-28.

## Bugs found outside docs and security (list only)

Status of the round-1 and round-2 bugs:
1. Endless retry: **fixed** (round 2).
2. Rain probability 0: **fixed** (round 2).
3. A settings change isn't fetched while data is fresh: **fixed** (WD:181-185 deletes `home_fetch_time`, then `refresh()`).
4. Home name saved as "Home" after a failed background lookup: **by design now**. The placeholder is saved, and the background (BS:129) and widget (WD:209) both look it up again. README:84.
5. Watch time zone used for labels: **open** (WeatherParser.mc:79-80). README:85.
6. Hourly page has no night icons: **open** (ForecastPages.mc:55). README:86.
7. `getGpsCoords()` wrote Storage from `onUpdate`: **fixed**. `onUpdate` (WV:88-113) reads no Storage except the offline-line time.
8. Bitmaps loaded on every frame: **fixed** (`IconCache`).
9. `last_fetch_time` semantics: **fixed** (per-location keys, WD:122; WeatherApp.mc:76-77).
10. Cached arrays not shape-checked: **fixed** (round 2).
11. `gps_coords` and positions unchecked: **fixed** (N2).
12. Legacy-default dead zone: **open** (HomeSettings.mc:64-66). README:88.
13. 60 s timer redraws with no new data: **fixed** (the timer is removed).
14. "Now" temperature mismatch: **fixed** (round 2).
15. Unconfigured Home with no GPS showed "Loading": **fixed**. It now shows "Waiting for GPS location..." (WD:69-74, WV:119).
- A. Stale Home name after a Home change: **fixed** for new coordinates (`pendingHome`, WD:209-214, 312-318), but see G.
- B. Shared array aliasing: **fixed** (`slice` copies, WD:134-135).
- C. Retries re-sent everything: **fixed** (WD:236-241, 274).
- D. Background re-geocoded after a Home change: **fixed** (BS:190-194 → WeatherApp.mc:78-81).
- E. Properties read on every redraw: **fixed** (WD:30, 168).
- F. `monkeydo -t` exits 1 on PASSED: **open** (SDK quirk, documented in CLAUDE.md:20).

New:
- G. **The GPS place name can be saved as the Home name.** While Home is not set *or invalid*, both the widget (WD:173, `mirrorGps`) and the background (BS:179-180) overwrite `home_weather` with the GPS data, including the GPS name. `home_lat_cached`/`home_lon_cached` are left as they were. If Home is then set back to coordinates within 0.01° of the last successful lookup (for example after editing one field at a time, which makes Home briefly "invalid"), `placeNameIsCurrent` is true. The widget then keeps `names[HOME]` from the mirrored cache (WD:104, 209-214), and the background's `cachedHomeName` returns the mirrored GPS name (BS:126-129). Home weather is saved under the GPS place name until Home moves more than ~1 km. Fix: clear `home_lat_cached`/`home_lon_cached` when mirroring, or cache the Home name under its own key. Add a unit test once the decision is pulled out of WeatherData.
- H. **Possible glance-process crash on a settings change.** `WeatherApp` is loaded in the glance process, and `onSettingsChanged()` → `scheduleBackground()` calls `FetchRules.refreshMinutes` (WeatherApp.mc:92-93, 105). FetchRules is marked only `(:background)`, so the compiler warns it is "not available in all function scopes" (`-l 2`). If Connect IQ delivers `onSettingsChanged` while only the glance is running, that call would fail with "Symbol not found". In round 2 this line read Properties inline, so this is new with the restructure. Not reproduced on a device. Fix: mark FetchRules `(:glance, :background)` (it is small), or don't reschedule from the glance.
- I. **MENU during a retry wait can send a duplicate GPS request.** `refresh()` resets `retriesLeft` and calls `fetchGps()` without `retryTimer.stop()` (WD:167-176), so the pending retry still fires (WD:274). Low impact.
- J. While Home is changing from not set to set, the Home page shows the mirrored GPS data under the GPS name until the first Home reply arrives (WD:85-88, 181-185). It's brief and honest about the data, but can confuse.

## Evidence appendix

### Commands

```bash
S=/private/tmp/claude-502/-Volumes-GDrive-Github-simpleglance-weather-widget/d70ccc79-7349-48f4-b50d-f671ad9699cf/scratchpad/round3
SDK="$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-8.1.1-2025-03-27-66dae750f/bin"
git rev-parse --short HEAD          # ee5993d
git status --short | wc -l          # 37
pgrep -fl 'xcodebuild|monkeydo'     # none before builds

# Builds (key path only, never printed); every run wrapped in perl alarm 900
for d in fenix6 fenix6pro fenix6s fenix6spro; do
  perl -e 'alarm 900; exec @ARGV' "$SDK/monkeyc" -f monkey.jungle -d $d -o $S/build/$d.prg -y ~/.garmin_dev.der -w
done                                # all exit=0, WARNING=0, ERROR=0
perl -e 'alarm 900; exec @ARGV' "$SDK/monkeyc" ... -d fenix6pro -w -l 2   # exit 0, 16 warnings
perl -e 'alarm 900; exec @ARGV' "$SDK/monkeyc" ... -d fenix6pro -w -l 3   # exit 105, 16 errors
# -l 2 by kind: 14 "not available in all function scopes" (WeatherApp.mc:41 ×2, 44 ×2, 49 ×2, 54 ×2,
#   83, 85 ×2, 95, 105 ×2 — the last two are FetchRules), 2 poly-type Method callback (WeatherRequests.mc:26, 52)

# Docs
perl -e 'alarm 900; exec @ARGV' "$SDK/monkeydoc" -c private -f "$SDK/api.mir" -o $S/doc source/*.mc source/test/*.mc
                                    # exit 0, 0 warnings

# Tests (simulator already running, port 1234 listening — checked with lsof)
perl -e 'alarm 900; exec @ARGV' "$SDK/monkeyc" -f monkey.jungle -d fenix6pro -o $S/test/test.prg -y ~/.garmin_dev.der -w --unit-test
                                    # BUILD SUCCESSFUL, 0 warnings
perl -e 'alarm 300; exec @ARGV' "$SDK/monkeydo" $S/test/test.prg fenix6pro -t > $S/test/run.txt
                                    # "Ran 98 tests" / "PASSED (passed=98, failed=0, errors=0)", exit 1
grep '^Executing test' $S/test/run.txt | sort -u | wc -l     # 32
```

Note for honesty: the `pgrep` check just before `monkeydo` showed another session's `monkeydo` (a release `.prg` from `…/scratchpad/rel`) that had started a moment earlier. My test run had already been chained to that check, so the two overlapped. The test run still completed and printed PASSED. Next time, the check should gate the run instead of only being printed.

```bash
# Metrics
python3 -I $S/mcmetrics.py source        # 226/226 documented; @param gaps: 0 real (2 false positives
                                         #   from generic Dictionary<String, Object?> parameters); >40-line functions: none
python3 -I $S/mcmetrics.py source/test   # 32/32 test functions documented (locals miscounted by the script, ignored)
wc -l source/*.mc source/test/*.mc
grep -o ' as [A-Za-z]' source/*.mc | wc -l          # 433
grep -oE '\["[a-z_0-9]+"\]' source/*.mc | wc -l     # 25 (all WeatherParser)
grep -o instanceof source/*.mc | wc -l              # 32
grep -rn "println\|System.print\|(:debug)\|TODO\|FIXME\|XXX\|HACK" source/   # none
grep -o 'Storage\.setValue(' source/*.mc | wc -l    # 17 (1 is a doc line in Coordinates.mc)

# Security
git rev-list --all | wc -l                          # 29
git log -p --all | grep -iE '^\+.*(api[_-]?key|token|secret|password|BEGIN .*PRIVATE)'   # none
git grep -nIiE 'api[_-]?key|token|secret|password|BEGIN .*PRIVATE'   # prose only (CLAUDE.md, SECURITY.md, scorecards)
grep -rnIiE 'api[_-]?key|token|secret|password' CHANGELOG.md source/   # none (untracked files)
git diff HEAD | grep -iE '^\+.*(api[_-]?key|token|secret|password|PRIVATE KEY)'   # prose only
git log --all --name-only --format='' | sort -u | grep -iE '\.der|\.pem|\.p12|key'   # monkey.jungle only (name match)
grep -rn 'http://' source resources manifest.xml    # only the XML namespace
grep -rn '27\.37\|152\.86' source                   # HomeSettings.mc:29,31, Coordinates.mc:24 (doc example), tests
ls LICENSE*                                         # none
```

### Per-category evidence

1. **Correctness:** the fixes and open items are listed under Bugs. Crash-safety of cached data: WD:96-108, WeatherParser.mc:237-265.
2. **Architecture:**
   - File sizes: WeatherView 169, WeatherData 319, WeatherParser 315, BackgroundService 195, CurrentPage 171, ForecastPages 111, WeatherIcons 105, HomeSettings 103, FetchRules 69, WeatherRequests 67, WeatherSlots 61, Coordinates 55, WeatherDelegate 55, GpsPosition 43, WeatherFormat 38, WeatherState 28, RequestHeaders 13.
   - Single sources: requests (WeatherRequests), parsing (WeatherParser), fetch rules (FetchRules), slots (WeatherSlots), keys per slot (WeatherState).
   - Literal keys remain at WeatherApp.mc:70, 76-77 and WD:136, 138.
3. **Idioms:** see the `-l 2` breakdown. Hardcoded UI text: CurrentPage.mc:128, 138, 149; WeatherParser.mc:160, 164, 179.
4. **Performance:** IconCache (WeatherIcons.mc:81-104, cleared in WV:48-51); no Timer in WeatherView; WD:168 reads settings once per refresh.
5. **Security:** see the findings tables.
6. **Testing:**
   - HomeSettingsTest has 10 tests, WeatherParserTest 13, FetchRulesTest 3 and DisplayRulesTest 6.
   - Covered: HomeSettings 3/7, Coordinates 3/3, WeatherParser 15/16, FetchRules 3/3, WeatherFormat 2/2, WeatherIcons 2/2, GlanceRules 2/2.
   - Uncovered: CurrentPage 0/2 pure helpers, WeatherData 0/24, BackgroundService 0/~8, WeatherApp 0/2, GpsPosition 0/1. That gives ~30/68, about 44%.
7. **Coverage:** script output above. The module constants (e.g. FetchRules.mc:15-28, WeatherSlots.mc:16-60) are all documented.
8. **Quality:** good examples are FetchRules.mc:18-28, WeatherFormat.mc:20-22, CurrentPage.mc:119-121, WD:126-129 and BS:43-47.
9. **Accuracy:** the 12 items above.
10. **Project docs:**
    - Present: README.md (94 lines), ARCHITECTURE.md (90), SECURITY.md (53), PRIVACY.md (57), CLAUDE.md (42) and CHANGELOG.md (25).
    - Missing: LICENSE.

## Quickest wins to reach 85 (+8.6 needed)

1. **Fix the 12 accuracy items** (stale "WeatherView" headers, the ARCHITECTURE warning note, SECURITY status and fetch-time rows, CLAUDE.md test count, PROGRESS.md, CHANGELOG). This is docs only, under an hour. Accuracy 7→9 (+1.6) and doc quality 8→9 (+1.0).
2. **Resolve the licence (F6).** It's an owner decision: add a LICENSE file and credit the GPL-3.0 icons, or replace them. Security 7→8 (+1.2) and project docs 8→9 (+1.0).
3. **Close bug H and N3.** Mark FetchRules `(:glance, :background)` and add an `instanceof Array` guard plus test in `GlanceRules.isDrawable`. This removes 2 `-l 2` warnings. Correctness 7→8 (+1.2).
4. **Fix bug G and move WeatherData's decisions into a pure module with tests.** Candidates: which slot feeds which (`source`), `emptyReason`, which Home name to use, and when to look up a place name. Add tests for `CurrentPage.highLow`/`rainProbability` and the BackgroundService result merge. Testing 6→7 or 8 (+1 to +2).
5. **Look up the GPS place name only when the position has moved** (reuse `FetchRules.placeNameIsCurrent` with a saved GPS lookup position), and stop the retry timer in `refresh()` (bug I). Performance 8→9 (+0.8) and closes most of F8.

Items 1–4 add about +8.0 to +9.0, which reaches 84–85. Item 5 makes 85 reliable.
