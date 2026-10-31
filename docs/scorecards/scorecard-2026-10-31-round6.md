# Scorecard: SimpleGlance Weather Widget (round 6)

- **Date:** 2026-10-31
- **Commit:** `afa9309` (branch `main`) with uncommitted round-6 changes (21 paths, including the new `source/Units.mc` and `docs/TESTING.md`). The working tree is what was scored. Manifest version 1.5.0.
- **Rubric:** the same adapted rubric as rounds 1–5 (10 categories, same weights and grade bands).
- **Reviewer:** the same session that made the changes, so this is a self-review. Treat close calls with that in mind. The hand-test script has not been run on a watch yet; if it finds problems, Correctness and Testing drop.
- **Toolchain:** Connect IQ SDK 8.1.1.

## Overall

| | Score |
|---|---|
| **Overall** | **89.2 / 100, grade A** (round 4: 85.2) |
| Code (categories 1–6) | 52.0 / 60 |
| Documentation (categories 7–10) | 37.2 / 40 |
| Build | 4 devices, 0 warnings. `-l 2`: 14 warnings (the accepted kinds, ARCHITECTURE.md "Compiler warnings"). `-l 3` still fails. |
| Tests | **45 distinct tests, 173 results, `PASSED (passed=173, failed=0, errors=0)`**; `monkeydo` exit code 1 (known quirk). |
| Security | Critical 0 · High 0 · Medium 0 · Low 3 (F3 accepted, F9 accepted, F12). |

| # | Category | Weight | Score /10 | Weighted | Reason |
|---|---|---|---|---|---|
| 1 | Correctness & robustness | 12% | 9 | 10.8 | Bug K is fixed (Home data saved with the coordinates it was fetched for; `FetchRules.fetchedForHome()`). Old data is no longer labelled "Now"/"Today" (headings from the fetch time, ForecastPages.mc `hourLabels`/`dayLabels`). Freezing codes show rain icons. Units follow the watch. Still open: watch time zone for labels, day-only hourly icons, legacy-default dead zone, bug J, °F up to 1° off (documented). The new layouts are not yet checked on a watch. |
| 2 | Architecture & structure | 10% | 9 | 9.0 | No file over 300 lines (WeatherData 299, right at the limit), no function over 40. Display units have one home (`Units`), text and icons one cache (`ResourceCache`). Left: `"gps_coords"` spelt out 5 times; WeatherData/PlaceNames still use Storage directly; `FetchRules` (marked `:glance`) now carries widget-only rules (`needsFetch`, `gpsReplyAction`), a little more code in the glance's memory. |
| 3 | Monkey C idioms | 8% | 9 | 7.2 | UI words, units and "Now"/"Today" are string resources; glance text uses `scope="glance"` as the SDK documents; day names come from `Gregorian` (localised). Left: English fallback labels in WeatherParser (shown only for data saved without a fetch time), `-l 3` fails. |
| 4 | Concurrency & performance | 8% | 9 | 7.2 | Page text is cached with the icons, so status and label strings are no longer loaded on every redraw. Minor: `Units.fahrenheit()`/`statute()` read device settings on each call (up to 3 times per frame); the glance loads its condition word on each redraw. |
| 5 | Security & privacy | 12% | 9 | 10.8 | F7 closed by commit `afa9309` (the stale `.iq` is out of the tree; history keeps it). F9 accepted as an owner decision, recorded `(deliberate)` in CLAUDE.md, with removal of the widget documented in PRIVACY.md. New Storage key `home_fetch_for` holds only the Home coordinates the user entered, on the watch, and is type-checked. |
| 6 | Testing | 10% | 7 | 7.0 | 45 tests. Every rule, parser and calculation is tested, including the new units, headings, glance words, needsFetch and retry rules. `docs/TESTING.md` is an 8-section hand-test script in place of UI tests (Connect IQ has none). Coverage is about 52% of non-UI functions, against 80%: the fetch/callback code in WeatherData, PlaceNames and BackgroundService is untested because it uses Storage, Properties and web requests directly. |
| 7 | Doc-comment coverage | 12% | 10 | 12.0 | 272/272 declarations documented; the script's 4 `@param` flags are false positives (Method and generic parameter types). monkeydoc 0 warnings. |
| 8 | Doc-comment quality | 10% | 9 | 9.0 | The why is explained: decorative lines kept dark grey, two decimals for inches, noon for day labels across daylight saving, `scope="glance"`, ±1 °F. |
| 9 | Accuracy | 8% | 9 | 7.2 | No mismatches found in README, ARCHITECTURE, SECURITY, PRIVACY, CHANGELOG, CLAUDE.md or TESTING.md against the code. TESTING.md's "Home settings without the store" (simulator `.SET` file) is marked as unconfirmed. |
| 10 | Project docs | 10% | 9 | 9.0 | All project docs present and current, plus the new TESTING.md. The doc-coverage script is still not in the repo, so counts depend on a scratch copy. |
| | **Total** | 100% | | **89.2** | |

## Change since round 4

| # | Category | R4 | R6 | Delta |
|---|---|---|---|---|
| 1 | Correctness & robustness | 8 | 9 | +1 |
| 2 | Architecture & structure | 9 | 9 | 0 |
| 3 | Monkey C idioms | 8 | 9 | +1 |
| 4 | Concurrency & performance | 9 | 9 | 0 |
| 5 | Security & privacy | 8 | 9 | +1 |
| 6 | Testing | 7 | 7 | 0 |
| 7 | Doc-comment coverage | 10 | 10 | 0 |
| 8 | Doc-comment quality | 9 | 9 | 0 |
| 9 | Accuracy | 8 | 9 | +1 |
| 10 | Project docs | 9 | 9 | 0 |
| | **Overall** | **85.2** | **89.2** | **+4.0** |

No category is below 7. Round 5 (the bug K fix) was not scored separately.

## Gaps against the Public store standard

1. **Hand test on a real watch** (`docs/TESTING.md`): not run yet. Needed before release.
2. **Coverage 52% vs 80%.** Closing it needs the Storage/Properties/requests used by WeatherData, PlaceNames and BackgroundService put behind small interfaces that tests can replace. That is a restructure of about four files, with some risk to the background process's memory limit. Owner decision.
3. **Glance memory:** the glance now loads `Units` and a larger `FetchRules`. Not measured; watch for a glance crash during the hand test (the simulator's memory view would show the peak).

## Evidence

```bash
# all wrapped in perl alarm; busy check: scratchpad/busy.sh (real build processes only)
monkeyc -d {fenix6,fenix6pro,fenix6s,fenix6spro} -w        # exit 0, 0 warnings each
monkeyc -d fenix6pro -w -l 2                                # 14 warnings
monkeydoc -c private -f api.mir ...                         # 0 warnings
monkeyc -d fenix6pro -r -o bin/SGWEATHR.prg                 # 0 warnings (watch build for the hand test)
monkeydo test.prg fenix6pro -t                              # Ran 173 tests, PASSED (173/0/0), exit 1
mcmetrics.py source                                         # 272/272 documented, no function > 40 lines
wc -l source/*.mc                                           # largest: WeatherData 299, WeatherParser 279
```
