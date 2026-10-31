// StateRulesTest.mc — unit tests for the widget's state rules (WeatherState),
// the background result round trip (BackgroundResult) and the current-page
// helpers (CurrentPage). (:test) code is only compiled into unit-test builds
// (monkeyc --unit-test), never into the released app.

import Toybox.Lang;
import Toybox.Test;

//! Home shows its own data only when Home is set; GPS always shows its own.
(:test)
function sourceFollowsHomeSetting(logger as Logger) as Boolean {
    Test.assertEqual(WeatherState.source(WeatherState.HOME, true), WeatherState.HOME);
    Test.assertEqual(WeatherState.source(WeatherState.HOME, false), WeatherState.GPS);
    Test.assertEqual(WeatherState.source(WeatherState.GPS, true), WeatherState.GPS);
    Test.assertEqual(WeatherState.source(WeatherState.GPS, false), WeatherState.GPS);
    return true;
}

//! A failure wins over "waiting for GPS"; only the GPS source waits for a position.
(:test)
function emptyReasonOrder(logger as Logger) as Boolean {
    Test.assertEqual(WeatherState.emptyReason(WeatherState.GPS, true, false), WeatherState.EMPTY_NO_CONNECTION);
    Test.assertEqual(WeatherState.emptyReason(WeatherState.GPS, false, false), WeatherState.EMPTY_WAITING_GPS);
    Test.assertEqual(WeatherState.emptyReason(WeatherState.GPS, false, true), WeatherState.EMPTY_LOADING);
    Test.assertEqual(WeatherState.emptyReason(WeatherState.HOME, false, false), WeatherState.EMPTY_LOADING);
    Test.assertEqual(WeatherState.emptyReason(WeatherState.HOME, true, true), WeatherState.EMPTY_NO_CONNECTION);
    return true;
}

//! A full background result writes every slot, both fetch times, the Home place
//! and the Home coordinates the weather is for.
(:test)
function backgroundResultWritesAll(logger as Logger) as Boolean {
    var gps = [1];
    var home = [2];
    var gpsFc = [3];
    var homeFc = [4];
    var place = FetchRules.placeRecord(-27.47f, 153.02f, "Brisbane City");
    var fetchFor = FetchRules.homeFetchRecord(-27.47f, 153.02f);
    var w = BackgroundResult.writes(BackgroundResult.build(gps, home, gpsFc, homeFc, place, fetchFor), 1000);
    Test.assertEqual(w.size(), 8);
    Test.assert(w["home_fetch_for"] == fetchFor);
    Test.assert(w["gps_weather"] == gps);
    Test.assert(w["home_weather"] == home);
    Test.assert(w["gps_forecast"] == gpsFc);
    Test.assert(w["home_forecast"] == homeFc);
    Test.assertEqual(w["gps_fetch_time"], 1000);
    Test.assertEqual(w["home_fetch_time"], 1000);
    Test.assert(w["home_place"] == place);
    return true;
}

//! Failed slots write nothing (the last good data stays), and a fetch time is
//! only written with its weather. Home weather without fetch coordinates is a GPS
//! copy, so it saves the empty "home_fetch_for" record that never matches Home.
(:test)
function backgroundResultSkipsFailedSlots(logger as Logger) as Boolean {
    var w = BackgroundResult.writes(BackgroundResult.build(null, [2], [3], null, null, null), 1000);
    Test.assertEqual(w.size(), 4);
    Test.assertEqual((w["home_fetch_for"] as Array).size(), 0);
    Test.assert(w.hasKey("home_weather") && w.hasKey("home_fetch_time") && w.hasKey("gps_forecast"));
    Test.assert(!w.hasKey("gps_weather") && !w.hasKey("gps_fetch_time") && !w.hasKey("home_place"));
    return true;
}

//! Anything that is not a full result, and a damaged place record, writes nothing;
//! damaged fetch coordinates are saved as the never-matching empty record.
(:test)
function backgroundResultRejectsDamage(logger as Logger) as Boolean {
    Test.assertEqual(BackgroundResult.writes(null, 1000).size(), 0);
    Test.assertEqual(BackgroundResult.writes("x", 1000).size(), 0);
    Test.assertEqual(BackgroundResult.writes([[1], [2], [3], [4]], 1000).size(), 0);
    Test.assertEqual(BackgroundResult.writes([null, null, null, null, null], 1000).size(), 0);
    var w = BackgroundResult.writes([null, null, null, null, [1.0f, 2.0f, ""], null], 1000);
    Test.assertEqual(w.size(), 0);
    w = BackgroundResult.writes(["a", 5, null, null, [1.0f, "2", "Bondi"], null], 1000);
    Test.assertEqual(w.size(), 0);
    w = BackgroundResult.writes([null, [2], null, null, null, [1.0f, "2"]], 1000);
    Test.assertEqual((w["home_fetch_for"] as Array).size(), 0);
    return true;
}

//! Today's high/low come from the forecast, else the current temperature; rain
//! probability is this hour's, or 0 when old cached data has none.
(:test)
function currentPageHelpers(logger as Logger) as Boolean {
    var fc = new [15] as Array<Object?>;
    fc[WeatherSlots.FC_DAY_MAX] = [24, 25, 26, 27, 28];
    fc[WeatherSlots.FC_DAY_MIN] = [12, 13, 14, 15, 16];
    fc[WeatherSlots.FC_HOUR_RAIN_PROB] = [40, 50, 60, 70];
    var hiLo = CurrentPage.highLow(fc, 20);
    Test.assertEqual(hiLo[0], 24);
    Test.assertEqual(hiLo[1], 12);
    hiLo = CurrentPage.highLow(null, 20);
    Test.assertEqual(hiLo[0], 20);
    Test.assertEqual(hiLo[1], 20);
    Test.assertEqual(CurrentPage.rainProbability(fc), 40);
    Test.assertEqual(CurrentPage.rainProbability(null), 0);
    fc[WeatherSlots.FC_HOUR_RAIN_PROB] = null;
    Test.assertEqual(CurrentPage.rainProbability(fc), 0);
    return true;
}
