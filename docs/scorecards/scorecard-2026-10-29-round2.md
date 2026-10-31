# Scorecard: SimpleGlance Weather Widget (round 2)

- **Date:** 2026-10-29
- **Commit:** `ee5993d` (v1.4.2, branch `main`) **with uncommitted working-tree changes**. The working tree is what was scored, including the new untracked files (`source/HomeSettings.mc`, `Coordinates.mc`, `RequestHeaders.mc`, `WeatherParser.mc`, `source/test/`, ARCHITECTURE.md, SECURITY.md, CLAUDE.md) and the staged deletion of `bin/simpleglanceweather.iq`.
- **Rubric:** the owner's iOS rubric adapted to Garmin Connect IQ / Monkey C. It is identical to round 1, and the counting methods are reused unchanged so the numbers can be compared.
- **Reviewer:** independent review, read-only. The only file written is this scorecard. Build output went to the scratchpad (`…/scratchpad/round2`).
- **Toolchain:** Connect IQ SDK 8.1.1.

## Overall

| | Score |
|---|---|
| **Overall** | **66.8 / 100, grade C** (A 85+, B 70–84, C 55–69, D 40–54, F under 40) |
| Code (categories 1–6) | 34.4 / 60 |
| Documentation (categories 7–10) | 32.4 / 40 |
| Build | Passes on fenix6, fenix6pro, fenix6s and fenix6spro with 0 warnings. `-l 2`: 109 warnings. `-l 3`: fails with 109 errors. No build-failure cap applies. |
| Tests | 19 distinct tests, 48 results, `PASSED (passed=48, failed=0, errors=0)`. `monkeydo` exit code is 1. |
| Critical security findings | 0, so no Security cap applies. High: 0. |

| # | Category | Weight | Score /10 | Weighted | Reason |
|---|---|---|---|---|---|
| 1 | Correctness & robustness | 12% | 6 | 7.2 | The round-1 crash paths are closed: invalid Home settings and malformed Open-Meteo replies or caches no longer crash. The retry loop is bounded, and rain probability and "Now" are fixed. Still open: a settings change isn't fetched while data is fresh; the Home place name can go stale after Home changes (new bug A); Nominatim replies and `gps_coords` are read unchecked; there's a `homeData`/`gpsData` aliasing bug; labels use the watch time zone; and HTTP errors are silent. |
| 2 | Architecture & structure | 10% | 5 | 5.0 | Parsing, settings and coordinate rules are now single, shared, testable modules. But WeatherView.mc is still 819 lines, 3 drawing functions are over 40 lines (118/76/58), and the request builders and Nominatim name-picking are still copied between WeatherView and BackgroundService. Constants are also duplicated (refresh default 30, 0.01° tolerance ×3, "GPS Location" ×3), and data still travels as positional arrays. |
| 3 | Monkey C idioms | 8% | 5 | 4.0 | Good `module`s with `const`s, `instanceof` validation, typed signatures, `(:background)`/`(:test)` scoping, and modern Properties/Storage APIs. Problems: 109 `-l 2` warnings (60 still from the wrong `(:glance)` on `wmoIconSm`); `-l 3` fails; untyped params at WV:328; dead code (`windArrow`, `getApp`, 3 unused strings); hardcoded UI strings; public mutable `pageIndex`/`locationIndex`; no enums for array slots. |
| 4 | Concurrency & performance | 8% | 6 | 4.8 | Retries are capped at 3, the background reuses the cached Home name, and the payload stays small. Still: bitmaps load on every frame, Storage is written from `onUpdate` (via `getGpsCoords`), Properties are read on every frame (WV:428), the 60 s redraw timer does no work, each retry re-sends Home weather and both geocodes, and the background re-geocodes on every run until the widget is opened after a Home change. |
| 5 | Security & privacy | 12% | 7 | 8.4 | The High finding (PRIVACY.md) is fixed. Coordinates are rounded to 2 dp for requests and storage, settings are validated, and Open-Meteo replies and caches are validated. No secrets are in the tree or the 29-commit history. One Medium remains open (GPL-3.0 icons vs "All rights reserved"). Low findings: 6 carried over or partly fixed, plus 2 new (unchecked Nominatim fields; unchecked Storage reads). |
| 6 | Testing | 10% | 5 | 5.0 | 19 real `(:test)` tests, all passing, built on a recorded reply plus damaged copies. The assertions can fail. But only the pure modules are covered (HomeSettings, Coordinates, WeatherParser): about 18 of about 45 non-UI functions (~40%, under the 80% standard). Untested: BackgroundService flow, `cachedHomeName`, Nominatim name parsing, fetch/retry/freshness logic, glance `isDrawable`, `windDirName`, `conditionColor` and the icon mapping. The runner's exit code 1 is unexplained. |
| 7 | Doc-comment coverage | 12% | 9 | 10.8 | 110/110 declarations (100%) by the round-1 script, all `//!`. 21/21 in tests. Every module constant is also documented (checked by hand). Not 10 because 8 WeatherParser functions have parameters with no `@param`. |
| 8 | Doc-comment quality | 10% | 8 | 8.0 | Strong: the process context, Storage side effects, the "why" behind limits (Nominatim policy, 0.01°, deleteTemporalEvent, glance memory), and the array layouts in one place. Security decisions are marked "Security:". Gaps: helper functions are missing `@param`, and a few comments are stale (see Accuracy). |
| 9 | Accuracy | 8% | 7 | 5.6 | Down from 30 mismatches to 13, all minor. The worst are the documented `monkeydoc` command (146 warnings, not the claimed 0), stale `fetchAll` comments about the retry path, and ARCHITECTURE's descriptions of `home_lat_cached` and `last_fetch_time`. |
| 10 | Project docs | 10% | 8 | 8.0 | README, ARCHITECTURE, SECURITY, PRIVACY and CLAUDE.md are present and largely current. No LICENSE file or CHANGELOG, the GPL licence question is unresolved, and README "Known issues" is accurate but incomplete. |
| | **Total** | 100% | | **66.8** | |

## Key metrics

| Metric | Round 2 | Round 1 | How counted |
|---|---|---|---|
| Source files | 10 `.mc` + 2 test `.mc` | 6 | `ls source/*.mc source/test/*.mc` |
| Lines (app) | 1,821 total: 1,112 code, 530 comment, 179 blank | 1,424: 1,073 / 199 / 152 | `wc -l`, `grep -cE '^\s*$'`, `grep -cE '^\s*//'` |
| Lines (tests) | 288 (HomeSettingsTest 91, WeatherParserTest 197) | 0 | `wc -l` |
| Files over 300 lines | WeatherView.mc (819) | WV 839, BS 317 | `wc -l` |
| Functions over 40 lines | WV `drawWeather` 118 (L462), `drawHourlyPage` 76 (L589), `drawDailyPage` 58 (L673) | 5 | round-1 script |
| Doc-comment coverage | **110/110 = 100%**: classes 5/5, functions 82/82, class members 23/23. Tests 21/21. Functions missing `@param` for some parameters: 8 (all in WeatherParser) | 49/97 = 50.5% | round-1 script (`tools/mcmetrics.py`), unchanged |
| Tests | **19 distinct, 48 results (10 run ×3, 9 run ×2), 48 pass, 0 fail, 0 errors**; `monkeydo` exit code 1 | 0 | `grep -c '^(:test)'` (20 lines, 1 is the fixtures module); run output |
| Build | 4 devices: exit 0, 0 warnings. `-l 0` 0, `-l 1` 0, `-l 2` **109 warnings**, `-l 3` **FAIL, 109 errors** | 120 / fail with 120 | commands in appendix |
| `-l 2` by file | WeatherIcons 60, WeatherView 27, WeatherApp 19, BackgroundService 3 | Icons 60, View 35, App 19, BS 6 | `grep WARNING` |
| monkeydoc | 0 warnings (with `-f api.mir`) | n/a | appendix |
| `as` casts | 313 (WV 136, Parser 64, BS 41, Glance 19, App 18, Home 14, Icons 9, Delegate 6, Coord 6) | 303 | `grep -o ' as [A-Za-z]'` |
| Dictionary key reads `["…"]` | 37 (Parser 23, BS 7, WV 7). The 23 parser reads are all `instanceof`/`isNumeric`-checked. The 14 Nominatim reads (BS:159-169, WV:250-260) are **not** type-checked. | 61, 0 checked | `grep -oE '\["[a-z_0-9]+"\]'` |
| `instanceof` checks | 12 | 0 | `grep -c instanceof` |
| try/catch | 0 | 0 | `grep -wc try` |
| TODO/FIXME/println/(:debug) | 0 | 0 | `grep -rn` |
| Storage writes | 26 `Storage.setValue` calls (WV 22, App 4). `grep -c` also matches 1 doc-comment line in Coordinates.mc, which is not a call. 8 keys, unchanged | 26 | `grep -ohE 'Storage\.(get\|set)Value\("…"'` |
| Security findings | Critical 0 · High 0 · Medium 1 · Low 8 | 0 / 1 / 5 / 6 | below |

## Change since last scorecard

| # | Category | Round 1 | Round 2 | Delta |
|---|---|---|---|---|
| 1 | Correctness & robustness | 4 | 6 | +2 |
| 2 | Architecture & structure | 3 | 5 | +2 |
| 3 | Monkey C idioms | 4 | 5 | +1 |
| 4 | Concurrency & performance | 5 | 6 | +1 |
| 5 | Security & privacy | 5 | 7 | +2 |
| 6 | Testing | 0 | 5 | +5 |
| 7 | Doc-comment coverage | 5 | 9 | +4 |
| 8 | Doc-comment quality | 5 | 8 | +3 |
| 9 | Accuracy | 3 | 7 | +4 |
| 10 | Project docs | 4 | 8 | +4 |
| | **Overall** | **38.4 (F)** | **66.8 (C)** | **+28.4** |
| | Code /60 | 21.0 | 34.4 | +13.4 |
| | Docs /40 | 17.4 | 32.4 | +15.0 |

No category dropped.

## Round-1 findings status

| # | Round-1 severity | Status | Evidence |
|---|---|---|---|
| F1 | High | **Fixed** | PRIVACY.md:11-28 names Open-Meteo (OpenMeteo GmbH, Switzerland) and Nominatim (OSMF, UK), covers GPS and Home coordinates, the 2 dp rounding, IP visibility and the timing, and is dated 29 Oct 2026 with the correct repo (L57). The owner chose no in-app consent (SECURITY.md:40). Minor wording issue: accuracy item 7. I did not check the third-party policy claims (PRIVACY:27-28) against those sites. |
| F2 | Medium | **Fixed** | Every request goes through `Coordinates.forRequest` (`"%.2f"`, Coordinates.mc:20-27) at BS:139-140, BS:192-193, WV:232-233 and WV:332-333. Tested (`coordinatesAreRoundedForRequests`). |
| F3 | Medium | **Partly fixed (now Low)** | properties.xml:7-8 defaults are blank. The old coordinates remain in source as `LEGACY_DEFAULT_LAT/LON` (HomeSettings.mc:29-31), in tests (HomeSettingsTest:27-35), in git history and in released builds. The owner accepted this (SECURITY.md:42). |
| F4 | Medium | **Fixed** | HomeSettings.mc:42-102 is the only reader. It checks type, rejects NaN and out-of-range values, and treats a half-filled pair as invalid. The UI message is at WV:428-431. 8 tests. |
| F5 | Medium | **Partly fixed** | Open-Meteo replies are fully type- and length-checked (WeatherParser.mc:39-243), and caches are shape-checked (WV:74-81, Glance:89-95). Still unchecked: Nominatim fields (new N1) and some Storage reads (new N2). |
| F6 | Medium | **Open** | resources/drawables are GPL-3.0 (WeatherIcons.mc:4, ARCHITECTURE.md:33), but README:92 says "All rights reserved". There is no LICENSE file. Listed as open in SECURITY.md:45. |
| F7 | Low | **Fixed in the index, not yet committed** | `git diff --cached --name-status` shows `D bin/simpleglanceweather.iq`, and `git ls-files bin` is empty. HEAD `ee5993d` still contains the file until a commit, and it stays in history. SECURITY.md:46 says "Untracked". |
| F8 | Low | **Partly fixed** | The User-Agent now has the version and a contact (RequestHeaders.mc:12, matching manifest 1.4.2). The background reuses the cached Home name (BS:81-87, 116-128). Still: the foreground geocodes GPS on every non-fresh fetch and on every retry (WV:195, WV:171-172). The background re-geocodes Home on every run after a Home change until the widget is opened, because only WeatherView writes `home_lat_cached` (WV:216-217). |
| F9 | Low | **Partly fixed** | `gps_coords` is stored rounded (WV:120/128/136/354 via `Coordinates.rounded`, tested). Retention is disclosed (PRIVACY:38). There is still no in-app "clear data". `home_lat_cached/lon_cached` hold the Home setting at full precision (it is the user's own setting, already on the watch). |
| F10 | Low | **Fixed** | .gitignore:23-28 adds `*.der`, `*.pem`, `*.p12` and `.claude/settings.local.json`. |
| F11 | Low | **Open** | HTTP errors are still ignored (WV:365, WV:395-396; BS:214-215). The user sees "Loading weather..." with no reason or age (WV:438-443). Listed in SECURITY.md:50. |
| F12 | Low | **Open** | There is still no `requirements.txt` for `image-generators/generate_store_assets.py`. Listed in SECURITY.md:51. |

## New security findings

Checklist results:
- **Secrets:** none. `git log -p --all` (29 commits) and `git grep` show only prose such as "No API key required". No key, `.der`, `.pem` or `.p12` file has ever been committed. The new untracked files contain no secrets.
- **Storage:** 8 keys, unchanged. Coordinates are rounded.
- **Network:** HTTPS only. The only `http://` is the XML namespace in manifest.xml:2.
- **Logging:** none.
- **Permissions:** Background, Communications and Positioning, all used.
- **Debug leftovers:** none.
- **Dependencies:** no barrels.
- **`bin/`:** see F7.

| # | Severity | Location | Issue | What it means in plain English | Fix | Effort |
|---|---|---|---|---|---|---|
| N1 | Low | WV:249-266, BS:157-178 | Nominatim replies are cast without type checks. `addr["suburb"]` etc. are assumed to be Strings, and `data["display_name"] as String?` is then `.find()`-ed. A non-String value (for example a number or array from a changed or hostile response) would crash `display.find` or a later `drawText`. In the background it would make `isValidCurrent` reject the Home data. Names also have no length limit. | An unexpected reply from the place-name service could crash the widget or blank the Home data. Unlikely with today's API. | Move the name-picking into one shared `(:background)` function that accepts only `String`s, truncates them (e.g. 24 chars), and is unit tested. This also removes the duplication. | S |
| N2 | Low | WV:141 and WV:192-195; BS:90-92; WV:211-215; WV:151-155 | Some Storage reads are still trusted. `gps_coords` is indexed `[0]`/`[1]` with no size or type check. `home_lat_cached`/`home_lon_cached` are cast `as Float?` and used in subtraction (BackgroundService checks the same keys with `isNumeric`). `last_fetch_time` is cast `as Number?`. Activity and Weather positions aren't range-checked (WV:126-137). | A damaged or old cache could crash the widget or the background job. That conflicts with the CLAUDE.md:27 rule. | Validate with the existing `WeatherParser.arrayOrNull`/`isNumeric` helpers. | S |

Totals for round 2: **Critical 0 · High 0 · Medium 1 (F6) · Low 8 (F3, F7, F8, F9, F11, F12, N1, N2).**

## Documentation gaps

- WeatherParser.mc has 8 functions with parameters but no `@param`: `parseHourly` (L114), `parseDaily` (L137), `isNumeric` (L209), `toFloatOr` (L218), `toNumberOr` (L223), `roundOr` (L228), `arrayOrNull` (L233) and `elementAt` (L240).
- There is no LICENSE file or CHANGELOG, and the GPL-3.0 icon licence is not reconciled with README:92.
- README "Known issues" (L82-88) is accurate: all 5 items were checked against code. But it omits these open issues: silent HTTP errors and endless "Loading…"; `last_fetch_time` semantics (bug 9); the stale Home name after a Home change (new bug A); the 1.1 km "legacy default" dead zone (bug 12); and that each retry also re-sends Home and geocode requests (new bug C).
- The coverage script counts only class-level members. Module constants and the `module` declarations themselves (14 items) are outside the count, but I checked them by hand and all are documented.

## Inaccurate or misleading comments and doc claims (13)

1. **WV:161.** `fetchAll` says "A GPS weather network error schedules this function again after 5 s". It schedules `onRetryTimer` (WV:390), which calls `fetchOnce`, not `fetchAll`.
2. **WV:164.** "Called from onLayout(), the MENU button, settings changes and the retry timer". The retry timer doesn't call `fetchAll` (WV:171-173).
3. **WV:113.** `getGpsCoords` "also runs from onUpdate() when GPS data is missing". Only on page 0 with GPS selected (WV:437-439).
4. **ARCHITECTURE.md:65 and BS:109-110.** `home_lat_cached` is described as "Home coordinates at the last place-name lookup". It is written when a lookup is *started*, before and regardless of success (WV:216-218).
5. **ARCHITECTURE.md:66.** `last_fetch_time` is "Unix time of the last successful foreground fetch". When Home is set, a successful GPS fetch does not set it (WV:378-386; only WV:409 does). The WV:147-148 comment is correct, so the two contradict each other.
6. **ARCHITECTURE.md:11.** The widget-process row lists only WeatherApp, WeatherView, WeatherDelegate and WeatherIcons. HomeSettings, WeatherParser, Coordinates and RequestHeaders run there too.
7. **PRIVACY.md:23.** "Requests are made when you open the widget, when you press MENU…". Both are skipped while data is newer than the refresh interval (WV:178; README:35 says so correctly). A settings change can also trigger requests.
8. **CLAUDE.md:9 and README:72.** The documented command `monkeydoc -c private -o … source/*.mc` produces **146 warnings** (`Unknown type 'Float'` etc.). CLAUDE.md says it "must report 0 warnings". It reports 0 only with `-f <SDK>/bin/api.mir`.
9. **CLAUDE.md:16.** "Each test currently appears twice". The actual run listed 10 tests three times and 9 tests twice (48 results).
10. **strings.xml:4-6.** `NoLocation`, `Loading` and `GpsLocation` are still unused (0 `Rez.Strings` references). The same text is hardcoded at WV:31, WV:440, WV:442 and BS:29. This is round-1 item 30, still open.
11. **SECURITY.md:46.** The `.iq` is described as "Untracked". It is only a staged deletion; HEAD still contains it and history keeps it.
12. **README:47** calls the old defaults "placeholder coordinates", while **SECURITY.md:42** says they were "the developer's own location". The README wording understates what they were.
13. **docs/review/PROGRESS.md (B5).** "Tests: 20". There are 19 distinct tests (10 + 9). B4 says "monkeydo reports 0 warnings" where monkeydoc is meant.

Not counted (I couldn't verify them offline): README:16 "Rainfall (mm, current hour)", which depends on Open-Meteo's definition of `current.precipitation`; and the third-party data-retention statements in PRIVACY:27-28 and SECURITY:23.

## Bugs found outside docs and security (list only)

Status of the round-1 bugs:
1. Endless retry: **fixed** (WV:165-173, WV:388-391).
2. Rain probability 0: **fixed** (WeatherParser:127; tested).
3. A settings change isn't fetched while data is fresh: **open** (WV:178). Listed in Known issues.
4. Home name saved as "Home" after a failed background lookup: **open** (BS:47). Listed in Known issues.
5. Watch time zone used for labels: **open** (WeatherParser:72, 87). Listed in Known issues.
6. Hourly page has no night icons: **open** (WV:635-637). Listed in Known issues.
7. `getGpsCoords()` writes Storage from `onUpdate`: **open** (WV:439 → WV:120/128/136). Not in Known issues.
8. Bitmaps load on every frame: **open** (WV:531, 638, 716). Documented in WeatherIcons:26, not in Known issues.
9. `last_fetch_time` set only by Home success when Home is set, never by the background: **open** (WV:378-386, 409). Not in Known issues.
10. Cached arrays not shape-checked: **fixed** (WV:74-81, Glance:89-95).
11. `gps_coords` unchecked, Activity/Weather positions not range-checked: **open** (N2).
12. A real Home within ~1.1 km of the legacy default can't be "set": **open** (HomeSettings:34, 64-66). Not in Known issues.
13. The 60 s timer redraws with no new data: **open** (WV:90). Documented in code.
14. "Now" temperature differs between the foreground and background paths: **fixed** (WeatherParser:121, 126).
15. Unconfigured Home with no GPS shows "Loading" until GPS arrives: **open** (WV:180-190).

New:
- A. **Stale Home place name after a Home change.** `fetchHome` writes `home_lat_cached` before the lookup (WV:216-218). If that one lookup fails, `homeLocationName` keeps the previous Home's name (seeded at WV:84), and `onHomeResponse` stores it (WV:400). `BackgroundService.cachedHomeName` (BS:116-128) then trusts it. The wrong name persists until Home moves more than 0.01° again.
- B. **Shared array aliasing.** `homeData = gpsData` and `homeForecast = gpsForecast` (WV:186-187, 309-310, 381-382) share one object. If Home is then set in the same session, `onLocationName` writes the Home name into it (WV:279, 282), so the GPS page can show the Home name until the next GPS reply.
- C. **Retries do more than GPS.** Each retry re-runs `fetchOnce`, which re-sends Home weather and both Nominatim requests (WV:177-201). If Home succeeded in the meantime, `dataIsFresh()` makes the GPS retry quietly do nothing.
- D. **Background re-geocodes after a Home change.** The background never updates `home_lat_cached`, so after a Home change it re-geocodes Home on every run until the widget is opened (BS:85, 116-123).
- E. `HomeSettings.status()` reads Properties on every redraw (WV:428).
- F. `monkeydo -t` exits 1 even when the run ends `PASSED (passed=48, failed=0, errors=0)`. The first run, started before the simulator was listening on port 1234, printed nothing and also exited 1.

## Evidence appendix

### Commands

```bash
S=/private/tmp/claude-502/-Volumes-GDrive-Github-simpleglance-weather-widget/157ca090-87dc-4e0e-b9a2-2f8730ff9cb0/scratchpad/round2
SDK="$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-8.1.1-2025-03-27-66dae750f"
git rev-parse --short HEAD                       # ee5993d
git status --short                               # 11 modified, 1 staged delete, 9 untracked paths

# Builds (key path only, never printed)
for d in fenix6 fenix6pro fenix6s fenix6spro; do
  monkeyc -f monkey.jungle -d $d -o $S/build/$d.prg -y ~/.garmin_dev.der -w > $S/build/$d.log 2>&1
done                                             # all exit=0, WARNING=0, ERROR=0
for l in 0 1 2 3; do
  monkeyc -f monkey.jungle -d fenix6pro -o $S/build/l$l.prg -y ~/.garmin_dev.der -w -l $l > $S/build/l$l.log 2>&1
done
# l0 exit 0 w0 | l1 exit 0 w0 | l2 exit 0 w109 | l3 exit 105 e109
# -l 2 by kind: 73 "not available in all function scopes" (60 WeatherIcons (:glance), 13 WeatherApp),
#   25 poly-type parameter passing, 4 ':toDegrees' on Null (WV:118,127,135,353),
#   4 container assignment on nullable (WV:279,282,301,304), 2 untyped params (WV:328),
#   1 non-poly param (App:43), 1 return-type mismatch (App:43)

# Docs
monkeydoc -c private -f "$SDK/bin/api.mir" -o $S/doc source/*.mc source/test/*.mc   # exit 0, 0 warnings
monkeydoc -c private -o $S/doc2 source/*.mc      # README/CLAUDE.md form: 146 warnings

# Tests
pkill -f monkeydo; pkill -f "MacOS/simulator"; (connectiq >/dev/null 2>&1 &)
# busy-wait until pgrep -f MacOS/simulator succeeds
monkeyc -f monkey.jungle -d fenix6pro -o $S/test/test.prg -y ~/.garmin_dev.der -w --unit-test   # BUILD SUCCESSFUL
monkeydo $S/test/test.prg fenix6pro -t > $S/run.txt 2>&1      # empty output, exit 1: simulator process up but not yet listening
lsof -iTCP -sTCP:LISTEN | grep simulator                      # *:1234 LISTEN confirmed
monkeydo $S/test/test.prg fenix6pro -t > $S/run2.txt 2>&1     # "Ran 48 tests" / "PASSED (passed=48, failed=0, errors=0)", exit 1
grep '^Executing test' $S/run2.txt | sort -u | wc -l          # 19

# Metrics
python3 -I tools/mcmetrics.py source/        # 110/110; >40-line functions: drawWeather 118, drawHourlyPage 76, drawDailyPage 58
python3 -I tools/mcmetrics.py source/test/   # 21/21
wc -l source/*.mc source/test/*.mc
grep -o ' as [A-Za-z]' source/*.mc | wc -l      # 313
grep -oE '\["[a-z_0-9]+"\]' source/*.mc | wc -l # 37
grep -wc try source/*.mc                        # 0
grep -rn "println\|System.print\|(:debug)\|TODO\|FIXME\|XXX\|HACK" source/   # none
grep -rn 'Rez.Strings' source                   # none (3 unused strings)

# Security
git rev-list --all | wc -l                      # 29
git log -p --all | grep -iE '^\+.*(api[_-]?key|token|secret|password|BEGIN .*PRIVATE)'   # none
git grep -nIiE 'api[_-]?key|token|secret|password'   # prose only (CLAUDE.md:28, SECURITY.md:28)
git log --all --name-only --format='' | sort -u | grep -iE '\.der|\.pem|\.p12|key'   # none
git ls-files bin                                # (empty: staged deletion)
git diff --cached --name-status                 # D bin/simpleglanceweather.iq
grep -rn 'http://' source resources manifest.xml   # only the XML namespace
grep -rn '27\.37\|152\.86' source               # HomeSettings.mc:29,31 and tests
```

### Per-category evidence

1. **Correctness:** fixed crash paths are at HomeSettings:42-69 and WeatherParser:39-61, 95-111, 176-204, with the retry cap at WV:57-59, 165-173 and 388-391. The open items are listed under Bugs.
2. **Architecture:**
   - WV is 819 lines. The shared modules are HomeSettings (103 lines), WeatherParser (243), Coordinates (40) and RequestHeaders (13).
   - Remaining duplication: `fetchWeather` (BS:188-205 / WV:328-345), `fetchLocationName` (BS:135-150 / WV:228-243), Nominatim name-picking (BS:158-176 / WV:249-267), and `wmoIcon`/`wmoIconSm` (WeatherIcons:30-50 / 60-80).
   - Duplicated constants: refresh default 30 (App:96, WV:154, properties.xml:4); the 0.01° tolerance (BS:120, WV:214, HomeSettings:34); "GPS Location" (BS:29, WV:31, strings.xml:6).
3. **Idioms:**
   - Wrong `(:glance)`: WeatherIcons:59 and WV:806.
   - Untyped parameters: WV:328.
   - Dead code: `windArrow` WV:779 and `getApp` App:103, plus the unused strings.
   - Public mutable fields: WV:36-38.
   - Good: the `module`/`const` design, `instanceof` checks, and test fixtures scoped `(:test)`.
4. **Performance:** see the round-1 bugs 7, 8, 13 and new bugs C, D and E.
5. **Security:** see the findings tables.
6. **Testing:**
   - HomeSettingsTest has 10 tests: homeStatus ×7, parseCoordinate, and Coordinates ×2.
   - WeatherParserTest has 9 tests, using a recorded reply and damaged copies.
   - Tests cover about 18 of about 45 non-UI functions (my own count of the HomeSettings, Coordinates, WeatherParser, BackgroundService, WeatherApp, glance and WeatherView non-drawing functions).
7. **Coverage:** script output: BS 20/20, Coordinates 2/2, HomeSettings 7/7, App 12/12, Delegate 7/7, Glance 6/6, Icons 2/2, Parser 14/14, View 40/40.
8. **Quality:** good examples are BS:44-47, BS:108-115, App:89-92, WV:146-149, Glance:83-86 and HomeSettings:25-28. For the `@param` gaps, see Documentation gaps.
9. **Accuracy:** the 13 items above.
10. **Project docs:**
    - Present: README.md (92 lines), ARCHITECTURE.md (76), SECURITY.md (51), PRIVACY.md (57) and CLAUDE.md (37).
    - Missing: LICENSE and CHANGELOG.
