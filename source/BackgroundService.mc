// BackgroundService.mc — scheduled weather refresh while the widget is closed.
// Runs in the Connect IQ background process, which has a very small memory
// budget and no access to the screen. It fetches weather (and the Home place
// name), parses each response into compact arrays, and hands them to
// WeatherApp.onBackgroundData() via Background.exit().
//
// Requests are built by WeatherRequests.mc, replies parsed by WeatherParser.mc
// and the result laid out by BackgroundResult.mc, all shared with the widget.

import Toybox.Activity;
import Toybox.Application;
import Toybox.Background;
import Toybox.Lang;
import Toybox.Position;
import Toybox.System;

//! Background refresh delegate. One instance runs per scheduled event and is
//! discarded after Background.exit().
(:background)
class BackgroundService extends Toybox.System.ServiceDelegate {

    //! Reads the GPS place name last saved by the widget (WeatherData), so the background does
    //! not spend a request (and memory) reverse-geocoding the GPS position.
    //! @return The cached name, or WeatherParser.GPS_PLACEHOLDER if none is cached.
    private function gpsStoredName() as String {
        var w = Storage.getValue(WeatherState.WEATHER_KEYS[WeatherState.GPS] as String);
        if (WeatherParser.isValidCurrent(w)) { return (w as Array)[WeatherSlots.CUR_NAME] as String; }
        return WeatherParser.GPS_PLACEHOLDER;
    }

    // MARK: - Per-run state

    //! Number of HTTP requests still outstanding; Background.exit() is called when it reaches 0.
    private var pending           as Number      = 0;
    //! Parsed GPS current conditions, or null if not fetched or failed.
    private var gpsResult         as Array?      = null;
    //! Parsed Home current conditions (or a copy of gpsResult when Home is not set).
    private var homeResult        as Array?      = null;
    //! Parsed GPS forecast, or null if not fetched or failed.
    private var gpsForecast       as Array?      = null;
    //! Parsed Home forecast (or a copy of gpsForecast when Home is not set).
    private var homeForecast      as Array?      = null;
    //! Home place name from Nominatim. Parsing of the Home weather is deferred
    //! until this is known, because the name is stored inside the parsed arrays.
    //! Stays WeatherParser.HOME_PLACEHOLDER if the lookup fails, and that value is
    //! then saved; the widget looks the name up again on its next Home fetch.
    private var homeLocationName  as String      = WeatherParser.HOME_PLACEHOLDER;
    //! Home coordinates of this run, returned with the name after a successful
    //! place-name lookup so the app can save them as "home_place".
    private var homeCoords        as Array<Float> = [0.0f, 0.0f] as Array<Float>;
    //! Set when this run's place-name lookup succeeded.
    private var homeNamed         as Boolean     = false;
    //! Raw Home weather HTTP status, held until checkDone().
    private var homeRawCode       as Number      = 0;
    //! Raw Home weather response, held until checkDone().
    private var homeRawData       as Dictionary? = null;
    //! HomeSettings.isConfigured() captured at the start of the run, so checkDone() knows
    //! whether to parse a real Home fetch or mirror the GPS result.
    private var homeConfiguredFlag as Boolean    = true;

    //! Creates the delegate; per-run state is reset in onTemporalEvent().
    function initialize() {
        System.ServiceDelegate.initialize();
    }

    // MARK: - Requests and callbacks

    //! Entry point for each scheduled refresh (interval from the refresh_rate setting).
    //!
    //! - Home set: fetches Home weather. The place name is reused from "home_place"
    //!   when Home has not moved (FetchRules.savedPlaceName()); otherwise Nominatim is asked.
    //! - GPS: fetches weather for the last position the widget saved ("gps_coords");
    //!   if there are none, the GPS slot is null so the widget keeps its last data.
    //! - Home not set or invalid: no Home requests; checkDone() copies the GPS result into the Home slot.
    //!
    //! Side effects: up to three web requests; ends with Background.exit() (finish()).
    function onTemporalEvent() as Void {
        homeConfiguredFlag = HomeSettings.isConfigured();
        pending = 0;

        if (homeConfiguredFlag) {
            var lat = HomeSettings.lat();
            var lon = HomeSettings.lon();
            homeCoords = [lat, lon] as Array<Float>;
            WeatherRequests.weather(lat, lon, method(:onHomeData));
            pending += 1; // home weather
            var cachedName = FetchRules.savedPlaceName(lat, lon,
                Storage.getValue(WeatherState.PLACE_KEYS[WeatherState.HOME] as String));
            if (cachedName != null) {
                homeLocationName = cachedName;
            } else {
                WeatherRequests.placeName(lat, lon, method(:onLocationName));
                pending += 1; // geocoding
            }
        }

        // Security: the saved position is untrusted; validOrNull() range-checks it.
        var stored = Coordinates.validOrNull(Storage.getValue("gps_coords"));
        if (stored != null) {
            WeatherRequests.weather(stored[0], stored[1], method(:onGpsData));
            pending += 1; // GPS weather
        } else {
            gpsResult   = null;
            gpsForecast = null;
        }

        if (pending == 0) {
            // Nothing to fetch (Home not set, no saved GPS position): exit at once
            // with empty slots, so the widget keeps its last known data.
            finish();
        }
    }

    //! Nominatim callback. The name is read with WeatherParser.parsePlaceName(),
    //! which accepts only non-empty text and caps its length.
    //! @param responseCode HTTP status, or a negative Connect IQ error code.
    //! @param data Parsed JSON body, or null.
    function onLocationName(responseCode as Number, data as Dictionary?) as Void {
        var name = (responseCode == 200) ? WeatherParser.parsePlaceName(data) : null;
        if (name != null) {
            homeLocationName = name;
            homeNamed = true;
        }
        checkDone();
    }

    //! GPS weather callback. Parses straight away (WeatherParser) using the cached
    //! GPS name. A failed or malformed reply leaves the GPS slot null, so
    //! WeatherApp keeps the previously stored data.
    //! @param responseCode HTTP status, or a negative Connect IQ error code.
    //! @param data Parsed JSON body, or null.
    function onGpsData(responseCode as Number, data as Dictionary?) as Void {
        var name    = gpsStoredName();
        gpsResult   = (responseCode == 200) ? WeatherParser.parseCurrent(data, name) : null;
        gpsForecast = (responseCode == 200) ? WeatherParser.parseForecast(data, name, gpsResult) : null;
        checkDone();
    }

    //! Home weather callback. Only stores the raw response: parsing waits for
    //! checkDone(), because the place-name callback may arrive later.
    //! @param responseCode HTTP status, or a negative Connect IQ error code.
    //! @param data Parsed JSON body, or null.
    function onHomeData(responseCode as Number, data as Dictionary?) as Void {
        homeRawCode = responseCode;
        homeRawData = data;
        checkDone();
    }

    //! Called by every request callback. When the last one has arrived, parses
    //! the Home data (or mirrors GPS) and ends the run with finish().
    private function checkDone() as Void {
        pending--;
        if (pending > 0) { return; }
        if (homeConfiguredFlag) {
            var ok = (homeRawCode == 200);
            homeResult   = ok ? WeatherParser.parseCurrent(homeRawData, homeLocationName) : null;
            homeForecast = ok ? WeatherParser.parseForecast(homeRawData, homeLocationName, homeResult) : null;
        } else {
            // Home isn't configured (or is invalid) — mirror GPS instead
            // of fetching a location the user didn't choose.
            homeResult   = gpsResult;
            homeForecast = gpsForecast;
        }
        finish();
    }

    //! Ends the run by passing the results to WeatherApp.onBackgroundData() in the
    //! BackgroundResult layout. The Home place record is included only when this
    //! run looked the name up successfully and the Home weather parsed; the Home
    //! coordinates fetched for only when Home was fetched (not mirrored). The
    //! background process does not write Storage itself; the app does, when it
    //! receives this.
    private function finish() as Void {
        var place = (homeNamed && homeResult != null)
            ? FetchRules.placeRecord(homeCoords[0], homeCoords[1], homeLocationName) : null;
        var fetchFor = homeConfiguredFlag ? FetchRules.homeFetchRecord(homeCoords[0], homeCoords[1]) : null;
        Background.exit(BackgroundResult.build(gpsResult, homeResult, gpsForecast, homeForecast, place, fetchFor));
    }
}
