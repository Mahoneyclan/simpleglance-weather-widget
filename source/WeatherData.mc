// WeatherData.mc — the widget's weather for both locations: cache, GPS position,
// fetching, retries and saving. Widget process only. Storage keys written: gps_coords
// and gps_/home_ weather, forecast, fetch_time, fetch_for (names: PlaceNames.mc).
// All watch access goes through WatchServices, so tests can replace it.

import Toybox.Application;
import Toybox.Lang;
import Toybox.Position;

//! Holds, fetches and caches the weather for both locations.
class WeatherData {

    //! Retries after a GPS weather network error, per refresh().
    private const MAX_RETRIES = 3;
    //! Wait before each retry, in milliseconds.
    private const RETRY_DELAY_MS = 5000;

    //! Current conditions by slot (layout in WeatherParser.parseCurrent()), or null.
    private var current as Array<Array?> = [null, null] as Array<Array?>;
    //! Forecast by slot (layout in WeatherParser.parseForecastAt()), or null.
    private var forecast as Array<Array?> = [null, null] as Array<Array?>;
    //! Whether the last weather attempt for each slot failed (in memory only).
    private var failed as Array<Boolean> = [false, false] as Array<Boolean>;
    //! HomeSettings.status(), read in refresh() rather than on every redraw.
    private var homeStatus as Number = HomeSettings.STATUS_NOT_SET;
    //! Place names used when parsing new replies, by slot.
    private var places as PlaceNames;
    //! Last known GPS position (rounded), or null if no source has one yet.
    private var gpsCoords as Array<Double>? = null;
    //! Set while a one-shot GPS request is pending, so refresh() does not start a second one.
    private var gpsRequested as Boolean = false;
    //! Storage, settings, clock, requests, GPS, timer and redraws.
    private var watch as WatchServices;
    //! Retries left in this refresh.
    private var retriesLeft as Number = 0;
    //! Fetch-for record (FetchRules.fetchRecord()) of each slot's request in flight, saved with its reply.
    private var requestedFor as Array<Array> = [[], []] as Array<Array>;

    //! Creates an empty holder; call loadCache() before drawing.
    //! @param services The watch services (a test double in unit tests).
    function initialize(services as WatchServices) {
        watch = services;
        places = new PlaceNames(services, method(:rename));
    }

    // MARK: - Reading

    //! @param slot WeatherState.GPS or WeatherState.HOME.
    //! @return The slot's current conditions, or null.
    function currentFor(slot as Number) as Array? { return current[slot]; }

    //! @param slot WeatherState.GPS or WeatherState.HOME.
    //! @return The slot's forecast, or null.
    function forecastFor(slot as Number) as Array? { return forecast[slot]; }

    //! @return true if the Home settings are filled in but unusable.
    function homeInvalid() as Boolean { return homeStatus == HomeSettings.STATUS_INVALID; }

    //! @return The best known GPS position [latitude, longitude], or null.
    function position() as Array<Double>? { return gpsCoords; }

    //! @param slot WeatherState.GPS or WeatherState.HOME.
    //! @return true if the latest attempt for the data shown in this slot failed.
    function lastAttemptFailed(slot as Number) as Boolean { return failed[source(slot)]; }

    //! @param slot WeatherState.GPS or WeatherState.HOME.
    //! @return Why the slot has no data: one of the WeatherState.EMPTY_* values.
    function emptyReason(slot as Number) as Number {
        var src = source(slot);
        return WeatherState.emptyReason(src, failed[src], gpsCoords != null);
    }

    //! @param slot WeatherState.GPS or WeatherState.HOME.
    //! @return Unix time of the last successful update of the slot's data, or null if unknown.
    function fetchTime(slot as Number) as Number? {
        var raw = watch.getValue(WeatherState.FETCH_TIME_KEYS[source(slot)] as String);
        return Values.isNumeric(raw) ? Values.toNumberOr(raw, 0) : null;
    }

    //! @param slot WeatherState.GPS or WeatherState.HOME.
    //! @return The slot whose fetches fill it (WeatherState.source()).
    private function source(slot as Number) as Number { return WeatherState.source(slot, homeStatus == HomeSettings.STATUS_SET); }

    // MARK: - Cache

    //! Loads both slots, their names and the saved GPS position from Storage.
    //! Called on start and after a background refresh has written new data.
    //! Security: cached data may come from an older app version or be damaged, so
    //! it is shape-checked and anything unexpected is treated as "no data".
    function loadCache() as Void {
        homeStatus = watch.homeStatus();
        for (var slot = 0; slot < 2; slot++) {
            var cur = watch.getValue(WeatherState.WEATHER_KEYS[slot] as String);
            var fc  = watch.getValue(WeatherState.FORECAST_KEYS[slot] as String);
            current[slot]  = WeatherParser.isValidCurrent(cur) ? cur as Array : null;
            forecast[slot] = WeatherParser.isValidForecast(fc) ? fc as Array : null;
            if (current[slot] != null) {
                places.setCached(slot, (current[slot] as Array)[WeatherSlots.CUR_NAME] as String);
            }
        }
        gpsCoords = Coordinates.validOrNull(watch.getValue("gps_coords"));
    }

    //! Saves a successful weather reply for a slot with its time and place.
    //! Side effects: Storage writes; clears the slot's failure flag.
    //! @param slot WeatherState.GPS or WeatherState.HOME.
    //! @param cur Parsed current conditions.
    //! @param fc Parsed forecast, or null to keep the previous one.
    private function store(slot as Number, cur as Array, fc as Array?) as Void {
        current[slot] = cur;
        watch.setValue(WeatherState.WEATHER_KEYS[slot] as String, cur as Array<Application.PropertyValueType>);
        if (fc != null) {
            forecast[slot] = fc;
            watch.setValue(WeatherState.FORECAST_KEYS[slot] as String, fc as Array<Application.PropertyValueType>);
        }
        watch.setValue(WeatherState.FETCH_TIME_KEYS[slot] as String, watch.now());
        watch.setValue(WeatherState.FETCH_FOR_KEYS[slot] as String, requestedFor[slot] as Array<Application.PropertyValueType>);
        failed[slot] = false;
    }

    //! Copies the GPS data into the Home slot while Home is not set, so the Home
    //! page never shows a location the user did not choose. Copies (not shared
    //! arrays) because rename() edits arrays in place. Deletes "home_fetch_for",
    //! so the copy is never taken for Home data once Home is set.
    //! Side effect: Storage writes.
    private function mirrorGps() as Void {
        var cur = current[WeatherState.GPS];
        if (cur == null) { return; }
        var fc = forecast[WeatherState.GPS];
        current[WeatherState.HOME]  = cur.slice(0, null);
        forecast[WeatherState.HOME] = (fc != null) ? fc.slice(0, null) : null;
        watch.setValue(WeatherState.WEATHER_KEYS[WeatherState.HOME] as String,
            current[WeatherState.HOME] as Array<Application.PropertyValueType>);
        watch.deleteValue(WeatherState.FETCH_FOR_KEYS[WeatherState.HOME] as String);
        if (fc != null) {
            watch.setValue(WeatherState.FORECAST_KEYS[WeatherState.HOME] as String,
                forecast[WeatherState.HOME] as Array<Application.PropertyValueType>);
        }
    }

    //! PlaceNames callback: writes a new place name into a slot's cached arrays,
    //! and copies a new GPS name to Home while Home is not set.
    //! Side effects: Storage writes; requests a redraw.
    //! @param slot WeatherState.GPS or WeatherState.HOME.
    //! @param name The new name.
    function rename(slot as Number, name as String) as Void {
        var cur = current[slot];
        var fc  = forecast[slot];
        if (cur != null) {
            cur[WeatherSlots.CUR_NAME] = name;
            watch.setValue(WeatherState.WEATHER_KEYS[slot] as String, cur as Array<Application.PropertyValueType>);
        }
        if (fc != null) {
            fc[WeatherSlots.FC_NAME] = name;
            watch.setValue(WeatherState.FORECAST_KEYS[slot] as String, fc as Array<Application.PropertyValueType>);
        }
        if (slot == WeatherState.GPS && homeStatus != HomeSettings.STATUS_SET) { mirrorGps(); }
        watch.redraw();
    }

    // MARK: - Fetching

    //! Fetches each location whose data is missing, older than the refresh interval,
    //! or for another place (FetchRules.needsFetch()); fresh data for the same place
    //! is not fetched again, to save battery and radio use. Called on start and by
    //! MENU. A pending retry is cancelled, so MENU cannot send the GPS request twice.
    //! Side effects: up to four web requests and possibly a one-shot GPS request.
    function refresh() as Void {
        watch.stopRetry();
        homeStatus = watch.homeStatus();
        retriesLeft = MAX_RETRIES;
        if (homeStatus == HomeSettings.STATUS_SET) {
            if (needsFetch(WeatherState.HOME)) { fetchHome(); }
        } else {
            mirrorGps();
        }
        locate();
        if (needsFetch(WeatherState.GPS)) { fetchGps(); }
    }

    //! Settings changed in Garmin Connect: Home is fetched straight away, even if
    //! the data shown is still fresh, because it may be for the old Home.
    //! Side effects: deletes "home_fetch_time"; see refresh().
    function settingsChanged() as Void {
        watch.deleteValue(WeatherState.FETCH_TIME_KEYS[WeatherState.HOME] as String);
        failed[WeatherState.HOME] = false;
        refresh();
    }

    //! Stops the retry timer while the widget is off screen.
    function stop() as Void { watch.stopRetry(); }

    //! @param slot WeatherState.GPS or WeatherState.HOME.
    //! @return true if the slot has no data, it is older than the refresh interval,
    //!   or it was fetched for another place (the watch moved, or Home changed).
    private function needsFetch(slot as Number) as Boolean {
        var at = (slot == WeatherState.HOME) ? watch.homeCoords() as Array : gpsCoords;
        var forCurrentPlace = at != null
            && FetchRules.fetchedFor(at[0] as Numeric, at[1] as Numeric, watch.getValue(WeatherState.FETCH_FOR_KEYS[slot] as String));
        return FetchRules.needsFetch(current[slot] != null,
            watch.getValue(WeatherState.FETCH_TIME_KEYS[slot] as String), watch.now(),
            FetchRules.refreshMinutes(watch.refreshSetting()), forCurrentPlace);
    }

    //! Fetches Home weather and, unless its saved place name still applies,
    //! its place name (PlaceNames.lookUp()).
    private function fetchHome() as Void {
        var home = watch.homeCoords();
        var lat = home[0];
        var lon = home[1];
        requestedFor[WeatherState.HOME] = FetchRules.fetchRecord(lat, lon);
        watch.requestWeather(lat, lon, method(:onHomeWeather));
        places.lookUp(WeatherState.HOME, lat, lon);
    }

    //! Updates gpsCoords with the best position (GpsPosition.choose()). Unless it
    //! is a current fix, also asks for one; onPosition() refetches if the fix shows
    //! a move. If a request is already pending, clears the flag instead, so the next
    //! refresh can ask again if that request never answers.
    private function locate() as Void {
        var found = watch.findPosition();
        if (found != null) { gpsCoords = [found[0], found[1]] as Array<Double>; }
        if (found != null && found[GpsPosition.CURRENT] as Boolean) { return; }
        gpsRequested = !gpsRequested;
        if (gpsRequested) { watch.requestPosition(method(:onPosition)); }
    }

    //! Fetches GPS weather and, unless its saved name still applies, the place name.
    private function fetchGps() as Void {
        var coords = gpsCoords;
        if (coords == null) { return; }
        requestGpsWeather();
        places.lookUp(WeatherState.GPS, coords[0], coords[1]);
    }

    //! Requests GPS weather for gpsCoords. Also the retry timer's callback, so a
    //! retry repeats only the request that failed.
    function requestGpsWeather() as Void {
        var coords = gpsCoords;
        if (coords != null) {
            requestedFor[WeatherState.GPS] = Coordinates.rounded(coords);   // privacy: ~1 km
            watch.requestWeather(coords[0], coords[1], method(:onGpsWeather));
        }
    }

    // MARK: - Callbacks

    //! One-shot GPS callback. Saves the fix, and fetches weather and place name for
    //! it if the GPS data is missing, stale or for somewhere else (needsFetch()).
    //! @param info Position info from the system.
    function onPosition(info as Position.Info) as Void {
        gpsRequested = false;
        var pos = (info.position != null)
            ? Coordinates.validOrNull((info.position as Position.Location).toDegrees()) : null;
        if (pos != null) {
            watch.setValue("gps_coords", Coordinates.rounded(pos));
            gpsCoords = pos;
            if (needsFetch(WeatherState.GPS)) { fetchGps(); }
        }
        watch.redraw();
    }

    //! GPS weather callback. On success saves the data (and mirrors it to Home when
    //! Home is not set). FetchRules.gpsReplyAction() decides the rest: a network
    //! error is retried after RETRY_DELAY_MS, up to MAX_RETRIES times per refresh;
    //! otherwise the slot is marked as failed and the old data kept.
    //! @param responseCode HTTP status, or a negative Connect IQ error code.
    //! @param data Parsed JSON body, or null.
    function onGpsWeather(responseCode as Number, data as Dictionary?) as Void {
        var name = places.name(WeatherState.GPS);
        var cur = (responseCode == 200) ? WeatherParser.parseCurrent(data, name) : null;
        var action = FetchRules.gpsReplyAction(cur != null, responseCode, retriesLeft);
        if (action == FetchRules.REPLY_SAVE) {
            store(WeatherState.GPS, cur as Array, WeatherParser.parseForecast(data, name, cur));
            if (homeStatus != HomeSettings.STATUS_SET) { mirrorGps(); }
        } else if (action == FetchRules.REPLY_RETRY) {
            retriesLeft--;
            watch.startRetry(method(:requestGpsWeather), RETRY_DELAY_MS);
            return;
        } else {
            failed[WeatherState.GPS] = true;
        }
        watch.redraw();
    }

    //! Home weather callback. On success saves the data (store()); otherwise marks
    //! Home as failed and keeps the old data (no retry).
    //! @param responseCode HTTP status, or a negative Connect IQ error code.
    //! @param data Parsed JSON body, or null.
    function onHomeWeather(responseCode as Number, data as Dictionary?) as Void {
        var name = places.name(WeatherState.HOME);
        var cur = (responseCode == 200) ? WeatherParser.parseCurrent(data, name) : null;
        if (cur != null) {
            store(WeatherState.HOME, cur, WeatherParser.parseForecast(data, name, cur));
        } else {
            failed[WeatherState.HOME] = true;
        }
        watch.redraw();
    }
}
