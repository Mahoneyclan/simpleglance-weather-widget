# SimpleGlance Weather Widget — repo conventions
## Standards level: Public store
This repo follows the owner's engineering standards (~/.claude/engineering-standards.md)
at the Public store level. The rules below are only what's specific to this project.


Garmin Connect IQ widget in **Monkey C** (not Swift). Read `ARCHITECTURE.md` first, then `SECURITY.md`.

## Build and check

```bash
monkeyc -f monkey.jungle -d fenix6pro -o <outside-repo>/out.prg -y ~/.garmin_dev.der -w
monkeydoc -c private -f "<sdk>/bin/api.mir" -o <outside-repo>/doc source/*.mc source/test/*.mc   # must report 0 warnings (without -f it reports ~146 unresolved-link warnings)

# Unit tests: start the simulator first (connectiq &), then
monkeyc -f monkey.jungle -d fenix6pro -o <outside-repo>/test.prg -y ~/.garmin_dev.der -w --unit-test
monkeydo <outside-repo>/test.prg fenix6pro -t   # must end PASSED
```

- Tests live in `source/test/` as `(:test)` functions; they are only compiled with `--unit-test`. Each test appears 2–6 times in the results and `monkeydo` exits with code 1 even when it prints PASSED (SDK test-runner quirks); judge by the PASSED/FAILED line. The simulator can hang on a second consecutive run: restart it first.
- New parsing or validation logic goes in a plain function or module with no Properties/Storage access, so it can be unit tested.
- Build output goes outside the repo (`bin/` is ignored). Never commit `.prg`, `.iq` or key files.
- The developer key lives at `~/.garmin_dev.der`. Never copy it into the repo or print it.

## Code rules

- Three processes (widget, glance, background) share nothing but `Application.Storage`. Mark code needed by the glance or background with `(:glance)` / `(:background)`, and only that code: those processes have tight memory limits.
- All web requests are built in `WeatherRequests.mc` and all replies parsed in `WeatherParser.mc`, both shared by the widget and the background. Test parser changes against the recorded reply in `source/test/WeatherParserTest.mc`. Refer to array positions with `WeatherSlots` constants, not numbers, and to Storage keys with `WeatherState` constants where one exists.
- WeatherData and PlaceNames reach the watch only through `WatchServices` (Storage, settings, clock, requests, GPS, timer, redraw); test changes to them in `source/test/WeatherDataTest.mc` with `FakeWatch`. BackgroundService does not use it (background memory).
- Fetch timing and place-name reuse rules live in `FetchRules.mc` and take raw values as parameters, so they stay testable. Type checks of untrusted values use `Values.mc`.
- The glance process can run `WeatherApp.onSettingsChanged()` and `onBackgroundData()`, so everything they call must be marked `:glance` too. Keep `:glance` modules small (no parser, no bitmaps).
- On release, bump the version in both `manifest.xml` and `RequestHeaders.USER_AGENT`.
- Storage keys and property IDs are permanent (installed watches hold them). Add new ones; never rename.
- Treat every web response, Storage value and setting as untrusted: check for null and type before use. Home settings are read only through `HomeSettings`.
- Every coordinate sent off the watch goes through `Coordinates.forRequest()` (about 1 km precision). Update PRIVACY.md if what is sent changes.
- No `System.println` of coordinates or responses in release code.
- (deliberate) No in-app "Delete all my data": all data stays on the watch, and removing the widget deletes it (PRIVACY.md says so). Decided by the owner 2026-10-31.
- Show values in the watch's units through `Units.mc`; store metric only. UI words go in `strings.xml`, and anything the glance draws needs `scope="glance"`.

## Documentation rules

- Every file starts with a `//` header: purpose and which process runs it.
- Every class, function and member gets a `//!` doc comment with `@param` / `@return` where relevant, side effects (Storage writes, web requests), and the *why* behind limits and magic numbers.
- Comments describe what the code does now. Update them in the same change; open bugs go in README "Known issues", not in TODO comments.
- Keep README, ARCHITECTURE.md, SECURITY.md and PRIVACY.md current with behaviour changes, especially any new data sent off the watch.
