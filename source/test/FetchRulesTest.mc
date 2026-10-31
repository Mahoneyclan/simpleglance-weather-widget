// FetchRulesTest.mc — unit tests for FetchRules: refresh interval, freshness and
// place-name reuse. (:test) code is only compiled into unit-test builds
// (monkeyc --unit-test), never into the released app.

import Toybox.Lang;
import Toybox.Test;

//! The settings list values are used as they are; anything else falls back to 30.
(:test)
function refreshMinutesValidatesSetting(logger as Logger) as Boolean {
    Test.assertEqual(FetchRules.refreshMinutes(15), 15);
    Test.assertEqual(FetchRules.refreshMinutes(60), 60);
    Test.assertEqual(FetchRules.refreshMinutes(null), FetchRules.DEFAULT_REFRESH_MINUTES);
    Test.assertEqual(FetchRules.refreshMinutes("15"), FetchRules.DEFAULT_REFRESH_MINUTES);
    Test.assertEqual(FetchRules.refreshMinutes(4), FetchRules.DEFAULT_REFRESH_MINUTES);
    Test.assertEqual(FetchRules.refreshMinutes(0), FetchRules.DEFAULT_REFRESH_MINUTES);
    Test.assertEqual(FetchRules.refreshMinutes(-30), FetchRules.DEFAULT_REFRESH_MINUTES);
    Test.assertEqual(FetchRules.refreshMinutes(1441), FetchRules.DEFAULT_REFRESH_MINUTES);
    return true;
}

//! Data is fresh for exactly the interval; missing, damaged or future times are stale.
(:test)
function isFreshBoundaries(logger as Logger) as Boolean {
    var now = 1000000;
    Test.assert(FetchRules.isFresh(now, now, 30));
    Test.assert(FetchRules.isFresh(now - 30 * 60 + 1, now, 30));
    Test.assert(!FetchRules.isFresh(now - 30 * 60, now, 30));
    Test.assert(!FetchRules.isFresh(null, now, 30));
    Test.assert(!FetchRules.isFresh("999999", now, 30));
    Test.assert(!FetchRules.isFresh(now + 60, now, 30));
    return true;
}

//! A saved name is reused within 0.01° on both axes, and not otherwise; damaged
//! records are ignored.
(:test)
function savedPlaceNameReuse(logger as Logger) as Boolean {
    var saved = FetchRules.placeRecord(-33.86f, 151.20f, "Bondi");
    Test.assertEqual(FetchRules.savedPlaceName(-33.86f, 151.20f, saved), "Bondi");
    Test.assertEqual(FetchRules.savedPlaceName(-33.865d, 151.205d, saved), "Bondi");
    Test.assert(FetchRules.savedPlaceName(-33.88f, 151.20f, saved) == null);
    Test.assert(FetchRules.savedPlaceName(-33.86f, 151.22f, saved) == null);
    Test.assert(FetchRules.savedPlaceName(-33.86f, 151.20f, null) == null);
    Test.assert(FetchRules.savedPlaceName(-33.86f, 151.20f, [-33.86f, 151.20f]) == null);
    Test.assert(FetchRules.savedPlaceName(-33.86f, 151.20f, ["-33.86", 151.20f, "Bondi"]) == null);
    Test.assert(FetchRules.savedPlaceName(-33.86f, 151.20f, [-33.86f, 151.20f, ""]) == null);
    Test.assert(FetchRules.savedPlaceName(-33.86f, 151.20f, [-33.86f, 151.20f, 7]) == null);
    Test.assert(FetchRules.savedPlaceName(-33.86f, 151.20f, "Bondi") == null);
    return true;
}

//! Home returning to a place looked up earlier gets that place's own name, not
//! the GPS name held in the mirrored Home weather (round-3 bug G): the name is
//! read from the Home place record, which mirroring never writes.
(:test)
function homeNameIgnoresMirroredGps(logger as Logger) as Boolean {
    var mirroredHomeWeather = [20.0f, 19.0f, 5.0f, 5.0f, 0.0f, "Paddington", 0.0f, 0, 1];
    var homePlace = FetchRules.placeRecord(-27.47f, 153.02f, "Brisbane City");
    Test.assertEqual(FetchRules.savedPlaceName(-27.47f, 153.02f, homePlace), "Brisbane City");
    Test.assert(FetchRules.savedPlaceName(-27.47f, 153.02f, mirroredHomeWeather) == null);
    return true;
}

//! Saved Home weather counts as Home data only when it was fetched within 0.01°
//! of the current Home setting; a GPS copy ([]), a missing or damaged record does
//! not (round-4 bug K: Home changed while the widget was closed).
(:test)
function homeFetchedForCurrentSetting(logger as Logger) as Boolean {
    var saved = FetchRules.homeFetchRecord(-27.47f, 153.02f);
    Test.assert(FetchRules.fetchedForHome(-27.47f, 153.02f, saved));
    Test.assert(FetchRules.fetchedForHome(-27.475f, 153.025f, saved));
    Test.assert(!FetchRules.fetchedForHome(-33.87f, 151.21f, saved));
    Test.assert(!FetchRules.fetchedForHome(-27.47f, 153.04f, saved));
    Test.assert(!FetchRules.fetchedForHome(-27.47f, 153.02f, []));
    Test.assert(!FetchRules.fetchedForHome(-27.47f, 153.02f, null));
    Test.assert(!FetchRules.fetchedForHome(-27.47f, 153.02f, ["-27.47", 153.02f]));
    Test.assert(!FetchRules.fetchedForHome(-27.47f, 153.02f, "x"));
    return true;
}
