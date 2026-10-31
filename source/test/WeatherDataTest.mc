// WeatherDataTest.mc — unit tests for the widget's fetch, retry and caching
// logic (WeatherData) and place names (PlaceNames), driven through FakeWatch,
// a stand-in for WatchServices with in-memory Storage and recorded requests.
// Replies are played back from the recorded Open-Meteo sample. (:test) code is
// only compiled into unit-test builds (monkeyc --unit-test), never into the app.

import Toybox.Application;
import Toybox.Lang;
import Toybox.Position;
import Toybox.Test;

//! WatchServices stand-in: Storage is a Dictionary, settings and the clock are
//! fields, and requests, GPS fixes, retries and redraws are recorded so a test
//! can answer them.
(:test)
class FakeWatch extends WatchServices {

    //! In-memory Storage.
    var store as Dictionary<String, Object?> = {} as Dictionary<String, Object?>;
    //! Raw refresh_rate setting.
    var refresh as Object? = 30;
    //! HomeSettings status to report.
    var status as Number = HomeSettings.STATUS_NOT_SET;
    //! Home coordinates to report.
    var home as Array<Float> = [0.0f, 0.0f] as Array<Float>;
    //! Current Unix time.
    var clock as Number = 1000000;
    //! [lat, lon, isCurrent] that findPosition() returns, or null.
    var position as Array? = null;
    //! Weather requests made: [lat, lon, callback] each.
    var weatherCalls as Array<Array> = [] as Array<Array>;
    //! Place-name requests made: [lat, lon, callback] each.
    var placeCalls as Array<Array> = [] as Array<Array>;
    //! One-shot GPS fixes requested.
    var fixRequests as Number = 0;
    //! The last fix callback, or null.
    var fix as Method? = null;
    //! Retry callback pending, or null.
    var retry as Method? = null;
    //! Retries scheduled so far.
    var retriesStarted as Number = 0;
    //! Times a pending retry was cancelled.
    var retryStops as Number = 0;
    //! [lat, lon] text saved by setHomeSettings(), or null.
    var homeSettings as Array? = null;

    //! Creates an empty fake.
    function initialize() {
        WatchServices.initialize();
    }

    //! @param key Storage key.
    //! @return The stored value, or null.
    function getValue(key as String) as Object? { return store[key]; }

    //! @param key Storage key.
    //! @param value Value to store.
    function setValue(key as String, value as Application.PropertyValueType) as Void { store[key] = value; }

    //! @param key Storage key.
    function deleteValue(key as String) as Void { store.remove(key); }

    //! @return The refresh field.
    function refreshSetting() as Object? { return refresh; }

    //! @return The status field.
    function homeStatus() as Number { return status; }

    //! @return The home field.
    function homeCoords() as Array<Float> { return home; }

    //! @return The clock field.
    function now() as Number { return clock; }

    //! Records the settings and, like the real ones, makes Home set.
    //! @param lat Latitude text.
    //! @param lon Longitude text.
    function setHomeSettings(lat as String, lon as String) as Void {
        homeSettings = [lat, lon];
        status = HomeSettings.homeStatus(lat, lon);
        home = [lat.toFloat(), lon.toFloat()] as Array<Float>;
    }

    //! Records the request.
    //! @param lat Latitude.
    //! @param lon Longitude.
    //! @param callback Reply callback.
    function requestWeather(lat as Float or Double, lon as Float or Double, callback as Method) as Void {
        weatherCalls.add([lat, lon, callback]);
    }

    //! Records the request.
    //! @param lat Latitude.
    //! @param lon Longitude.
    //! @param callback Reply callback.
    function requestPlaceName(lat as Float or Double, lon as Float or Double, callback as Method) as Void {
        placeCalls.add([lat, lon, callback]);
    }

    //! @return The position field.
    function findPosition() as Array? { return position; }

    //! Counts the request; the fix never arrives unless a test calls the callback.
    //! @param callback Fix callback.
    function requestPosition(callback as Method(info as Position.Info) as Void) as Void {
        fixRequests++;
        fix = callback;
    }

    //! Records the retry instead of starting a timer.
    //! @param callback The retry.
    //! @param ms Delay (unused).
    function startRetry(callback as Method() as Void, ms as Number) as Void {
        retry = callback;
        retriesStarted++;
    }

    //! Cancels the recorded retry.
    function stopRetry() as Void {
        if (retry != null) { retryStops++; }
        retry = null;
    }

    //! Ignored: tests read state, not the screen.
    function redraw() as Void {}

    //! Answers the last weather request.
    //! @param code HTTP status or negative error code.
    //! @param data Reply body, or null.
    function answerWeather(code as Number, data as Dictionary?) as Void {
        var call = weatherCalls[weatherCalls.size() - 1];
        (call[2] as Method).invoke(code, data);
    }

    //! Runs the pending retry, as the timer would.
    function fireRetry() as Void {
        var r = retry;
        retry = null;
        if (r != null) { r.invoke(); }
    }
}

//! Shared test helpers.
(:test)
module WeatherDataFixtures {

    //! Where the GPS fake says the watch is (Paddington, Brisbane), as a current fix.
    const GPS = [-27.46d, 153.00d, true];

    //! @param w The fake.
    //! @return A WeatherData that has loaded w's Storage.
    function dataFor(w as FakeWatch) as WeatherData {
        var d = new WeatherData(w);
        d.loadCache();
        return d;
    }

    //! @param name Place name to put in the reply.
    //! @return A Nominatim reply body.
    function placeReply(name as String) as Dictionary {
        return { "address" => { "suburb" => name } };
    }

    //! @param name Place name stored in the array.
    //! @return Valid current conditions, as saved by the app.
    function savedCurrent(name as String) as Array {
        return WeatherParser.parseCurrent(WeatherParserFixtures.sample(), name) as Array;
    }
}

//! Home not set: a refresh fetches GPS weather and its place name, saves both,
//! and copies the GPS data to Home without a "home_fetch_for" record.
(:test)
function gpsFetchSavesAndMirrors(logger as Logger) as Boolean {
    var w = new FakeWatch();
    w.position = WeatherDataFixtures.GPS as Array;
    var d = WeatherDataFixtures.dataFor(w);
    d.refresh();
    Test.assertEqual(w.weatherCalls.size(), 1);
    Test.assertEqual(w.placeCalls.size(), 1);
    ((w.placeCalls[0] as Array)[2] as Method).invoke(200, WeatherDataFixtures.placeReply("Paddington"));
    w.answerWeather(200, WeatherParserFixtures.sample());
    Test.assertEqual(w.store["gps_fetch_time"], w.clock);
    Test.assertEqual((w.store["gps_weather"] as Array)[WeatherSlots.CUR_NAME], "Paddington");
    Test.assertEqual((w.store["home_weather"] as Array)[WeatherSlots.CUR_NAME], "Paddington");
    Test.assert(!w.store.hasKey("home_fetch_for"));
    Test.assertEqual((w.store["gps_place"] as Array)[2], "Paddington");
    Test.assert(d.currentFor(WeatherState.HOME) != null && d.forecastFor(WeatherState.GPS) != null);
    Test.assert(!d.lastAttemptFailed(WeatherState.GPS));
    return true;
}

//! A network error is retried three times, then the slot is marked as failed and
//! the screen says "No connection"; MENU during a wait cancels the retry.
(:test)
function gpsRetriesThenFails(logger as Logger) as Boolean {
    var w = new FakeWatch();
    w.position = WeatherDataFixtures.GPS as Array;
    var d = WeatherDataFixtures.dataFor(w);
    d.refresh();
    for (var i = 0; i < 3; i++) {
        w.answerWeather(-104, null);
        Test.assert(w.retry != null);
        w.fireRetry();
    }
    Test.assertEqual(w.weatherCalls.size(), 4);
    w.answerWeather(-104, null);
    Test.assertEqual(w.retriesStarted, 3);
    Test.assert(w.retry == null);
    Test.assert(d.lastAttemptFailed(WeatherState.GPS));
    Test.assertEqual(d.emptyReason(WeatherState.GPS), WeatherState.EMPTY_NO_CONNECTION);
    d.refresh();                    // MENU after giving up: nothing to cancel
    Test.assertEqual(w.retryStops, 0);
    w.answerWeather(-104, null);    // a retry is now waiting
    d.refresh();                    // MENU during the wait cancels it
    Test.assertEqual(w.retryStops, 1);
    return true;
}

//! An HTTP error is not retried.
(:test)
function gpsHttpErrorIsNotRetried(logger as Logger) as Boolean {
    var w = new FakeWatch();
    w.position = WeatherDataFixtures.GPS as Array;
    var d = WeatherDataFixtures.dataFor(w);
    d.refresh();
    w.answerWeather(500, null);
    Test.assertEqual(w.retriesStarted, 0);
    Test.assert(d.lastAttemptFailed(WeatherState.GPS));
    return true;
}

//! Fresh GPS data fetched here and a saved place name for this position cause
//! no requests; once stale, only the weather is fetched.
(:test)
function freshDataIsNotFetched(logger as Logger) as Boolean {
    var w = new FakeWatch();
    w.position = WeatherDataFixtures.GPS as Array;
    w.store["gps_weather"] = WeatherDataFixtures.savedCurrent("Paddington");
    w.store["gps_fetch_time"] = w.clock - 60;
    w.store["gps_fetch_for"] = [-27.46d, 153.00d];
    var d = WeatherDataFixtures.dataFor(w);
    d.refresh();
    Test.assertEqual(w.weatherCalls.size(), 0);
    Test.assertEqual(w.fixRequests, 0);
    w.clock += 31 * 60;
    w.store["gps_place"] = FetchRules.placeRecord(-27.46f, 153.00f, "Paddington");
    d.refresh();
    Test.assertEqual(w.weatherCalls.size(), 1);
    Test.assertEqual(w.placeCalls.size(), 0);
    return true;
}

//! Round-4 bug K: fresh Home data fetched for other coordinates (Home changed
//! while the widget was closed) is fetched again; data for these coordinates is not.
(:test)
function homeChangedWhileClosedIsFetched(logger as Logger) as Boolean {
    var w = new FakeWatch();
    w.status = HomeSettings.STATUS_SET;
    w.home = [-33.87f, 151.21f] as Array<Float>;
    w.store["home_weather"] = WeatherDataFixtures.savedCurrent("Brisbane City");
    w.store["home_fetch_time"] = w.clock - 60;
    w.store["home_fetch_for"] = FetchRules.fetchRecord(-27.47f, 153.02f);
    var d = WeatherDataFixtures.dataFor(w);
    d.refresh();
    Test.assertEqual(w.weatherCalls.size(), 1);
    Test.assertEqual(((w.weatherCalls[0] as Array)[0] as Numeric).toFloat(), -33.87f);

    var w2 = new FakeWatch();
    w2.status = HomeSettings.STATUS_SET;
    w2.home = [-33.87f, 151.21f] as Array<Float>;
    w2.store["home_weather"] = WeatherDataFixtures.savedCurrent("Sydney");
    w2.store["home_fetch_time"] = w2.clock - 60;
    w2.store["home_fetch_for"] = FetchRules.fetchRecord(-33.87f, 151.21f);
    WeatherDataFixtures.dataFor(w2).refresh();
    Test.assertEqual(w2.weatherCalls.size(), 0);
    return true;
}

//! A new Home is labelled "Home" until its name arrives, and its reply saves
//! the coordinates it was fetched for.
(:test)
function newHomeIsLabelledHome(logger as Logger) as Boolean {
    var w = new FakeWatch();
    w.status = HomeSettings.STATUS_SET;
    w.home = [-33.87f, 151.21f] as Array<Float>;
    w.store["home_weather"] = WeatherDataFixtures.savedCurrent("Paddington");
    var d = WeatherDataFixtures.dataFor(w);
    d.refresh();
    Test.assertEqual(w.placeCalls.size(), 1);
    w.answerWeather(200, WeatherParserFixtures.sample());
    Test.assertEqual((w.store["home_weather"] as Array)[WeatherSlots.CUR_NAME], WeatherParser.HOME_PLACEHOLDER);
    var fetchFor = w.store["home_fetch_for"] as Array;
    Test.assertEqual(fetchFor[0], -33.87f);
    Test.assertEqual(fetchFor[1], 151.21f);
    ((w.placeCalls[0] as Array)[2] as Method).invoke(200, WeatherDataFixtures.placeReply("Sydney"));
    Test.assertEqual((w.store["home_weather"] as Array)[WeatherSlots.CUR_NAME], "Sydney");
    Test.assertEqual((w.store["home_place"] as Array)[2], "Sydney");
    return true;
}

//! A settings change fetches Home even when its data is fresh and for this place.
(:test)
function settingsChangeFetchesHome(logger as Logger) as Boolean {
    var w = new FakeWatch();
    w.status = HomeSettings.STATUS_SET;
    w.home = [-33.87f, 151.21f] as Array<Float>;
    w.store["home_weather"] = WeatherDataFixtures.savedCurrent("Sydney");
    w.store["home_fetch_time"] = w.clock - 60;
    w.store["home_fetch_for"] = FetchRules.fetchRecord(-33.87f, 151.21f);
    var d = WeatherDataFixtures.dataFor(w);
    d.settingsChanged();
    Test.assert(!w.store.hasKey("home_fetch_time"));
    Test.assertEqual(w.weatherCalls.size(), 1);
    return true;
}

//! A failed place-name lookup saves nothing, so it is tried again next time.
(:test)
function failedPlaceLookupSavesNothing(logger as Logger) as Boolean {
    var w = new FakeWatch();
    w.position = WeatherDataFixtures.GPS as Array;
    WeatherDataFixtures.dataFor(w).refresh();
    ((w.placeCalls[0] as Array)[2] as Method).invoke(500, null);
    ((w.placeCalls[0] as Array)[2] as Method).invoke(200, {});
    Test.assert(!w.store.hasKey("gps_place"));
    return true;
}

//! With no position anywhere, one GPS fix is requested; a refresh while it is
//! pending clears the flag instead, so the next refresh can ask again.
(:test)
function noPositionRequestsOneFix(logger as Logger) as Boolean {
    var w = new FakeWatch();
    var d = WeatherDataFixtures.dataFor(w);
    d.refresh();
    Test.assertEqual(w.fixRequests, 1);
    Test.assertEqual(d.emptyReason(WeatherState.GPS), WeatherState.EMPTY_WAITING_GPS);
    d.refresh();
    Test.assertEqual(w.fixRequests, 1);
    d.refresh();
    Test.assertEqual(w.fixRequests, 2);
    Test.assertEqual(w.weatherCalls.size(), 0);
    return true;
}

//! Damaged Storage is treated as no data; invalid Home settings fetch nothing
//! for Home and are reported for the "Check Home settings" message.
(:test)
function damagedCacheAndInvalidHome(logger as Logger) as Boolean {
    var w = new FakeWatch();
    w.status = HomeSettings.STATUS_INVALID;
    w.store["gps_weather"] = "junk";
    w.store["home_forecast"] = [1, 2, 3];
    w.store["gps_coords"] = [999.0d, 0.0d];
    var d = WeatherDataFixtures.dataFor(w);
    Test.assert(d.currentFor(WeatherState.GPS) == null && d.forecastFor(WeatherState.HOME) == null);
    Test.assertEqual(d.emptyReason(WeatherState.GPS), WeatherState.EMPTY_WAITING_GPS);
    Test.assert(d.homeInvalid());
    Test.assert(d.fetchTime(WeatherState.GPS) == null);
    w.position = WeatherDataFixtures.GPS as Array;
    d.refresh();
    Test.assertEqual(w.weatherCalls.size(), 1);
    return true;
}

//! The owner's case: fresh data saved for Grange while the watch is at Highvale
//! (about 20 km away) is fetched again, and the new reply records where it is for.
(:test)
function movedWhileDataFreshIsFetched(logger as Logger) as Boolean {
    var w = new FakeWatch();
    w.position = [-27.37d, 152.80d, true];
    w.store["gps_weather"] = WeatherDataFixtures.savedCurrent("Grange");
    w.store["gps_fetch_time"] = w.clock - 60;
    w.store["gps_fetch_for"] = [-27.42d, 153.02d];
    var d = WeatherDataFixtures.dataFor(w);
    d.refresh();
    Test.assertEqual(w.weatherCalls.size(), 1);
    Test.assertEqual(w.placeCalls.size(), 1);
    w.answerWeather(200, WeatherParserFixtures.sample());
    var fetchFor = w.store["gps_fetch_for"] as Array;
    Test.assertEqual(fetchFor[0], -27.37d);
    Test.assertEqual(fetchFor[1], 152.80d);
    return true;
}

//! A position that is not a current fix (last known, saved or weather station)
//! is used straight away, a fix is requested too, and a fix showing a move of
//! more than about 1 km fetches again; one nearby does not.
(:test)
function oldPositionAsksForFix(logger as Logger) as Boolean {
    var w = new FakeWatch();
    w.position = [-27.42d, 153.02d, false];
    var d = WeatherDataFixtures.dataFor(w);
    d.refresh();
    Test.assertEqual(w.weatherCalls.size(), 1);
    Test.assertEqual(w.fixRequests, 1);
    w.answerWeather(200, WeatherParserFixtures.sample());
    var info = new Position.Info();
    info.position = new Position.Location({ :latitude => -27.4205d, :longitude => 153.0205d, :format => :degrees });
    (w.fix as Method).invoke(info);
    Test.assertEqual(w.weatherCalls.size(), 1);
    info.position = new Position.Location({ :latitude => -27.37d, :longitude => 152.80d, :format => :degrees });
    (w.fix as Method).invoke(info);
    Test.assertEqual(w.weatherCalls.size(), 2);
    return true;
}

//! A current fix wins, then a running activity, then the last known position,
//! the saved one, and the weather station last; only the first two are current.
(:test)
function positionSourceOrder(logger as Logger) as Boolean {
    var live = [1.0d, 1.0d] as Array<Double>;
    var act = [2.0d, 2.0d] as Array<Double>;
    var saved = [3.0d, 3.0d] as Array<Double>;
    var station = [4.0d, 4.0d] as Array<Double>;
    var p = GpsPosition.choose(live, Position.QUALITY_GOOD, act, saved, station) as Array;
    Test.assert(p[0] == 1.0d && p[GpsPosition.CURRENT] == true);
    p = GpsPosition.choose(live, Position.QUALITY_LAST_KNOWN, act, saved, station) as Array;
    Test.assert(p[0] == 2.0d && p[GpsPosition.CURRENT] == true);
    p = GpsPosition.choose(live, Position.QUALITY_LAST_KNOWN, null, saved, station) as Array;
    Test.assert(p[0] == 1.0d && p[GpsPosition.CURRENT] == false);
    p = GpsPosition.choose(null, Position.QUALITY_NOT_AVAILABLE, null, saved, station) as Array;
    Test.assert(p[0] == 3.0d && p[GpsPosition.CURRENT] == false);
    p = GpsPosition.choose(null, Position.QUALITY_NOT_AVAILABLE, null, null, station) as Array;
    Test.assert(p[0] == 4.0d && p[GpsPosition.CURRENT] == false);
    Test.assert(GpsPosition.choose(null, Position.QUALITY_GOOD, null, null, null) == null);
    return true;
}

//! MENU → Set Home here saves the GPS position as Home settings (5 decimals),
//! makes Home set and fetches it at once; with no position nothing changes.
(:test)
function setHomeHereSavesAndFetches(logger as Logger) as Boolean {
    var w = new FakeWatch();
    var d = WeatherDataFixtures.dataFor(w);
    Test.assert(!HomeHere.apply(w, d));
    Test.assert(w.homeSettings == null);

    w.position = [-27.37052d, 152.86911d, true];
    d.refresh();
    var before = w.weatherCalls.size();
    Test.assert(HomeHere.apply(w, d));
    Test.assertEqual((w.homeSettings as Array)[0], "-27.37052");
    Test.assertEqual((w.homeSettings as Array)[1], "152.86911");
    Test.assertEqual(w.status, HomeSettings.STATUS_SET);
    var last = w.weatherCalls[w.weatherCalls.size() - 1] as Array;
    Test.assert(w.weatherCalls.size() > before);
    Test.assertEqual((last[0] as Numeric).toFloat(), -27.37052f);
    return true;
}
