// WeatherData.mc — the full-screen widget's weather data for both locations:
// loading the cache, finding the GPS position, fetching, retrying and saving.
// Runs in the foreground (widget) process only; WeatherView draws what it holds.
//
// Storage keys written here: gps_coords, gps_weather, gps_forecast,
// home_weather, home_forecast, gps_fetch_time, home_fetch_time, home_fetch_for.
// Place names are handled by PlaceNames.mc.

import Toybox.Application;
import Toybox.Lang;
import Toybox.Position;
import Toybox.Time;
import Toybox.Timer;
import Toybox.WatchUi;

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
    //! One-shot timer for GPS weather retries.
    private var retryTimer as Timer.Timer = new Timer.Timer();
    //! Retries left in this refresh.
    private var retriesLeft as Number = 0;
    //! "home_fetch_for" record of the Home request in flight, saved if it succeeds.
    private var homeRequestedFor as Array<Application.PropertyValueType> = [] as Array<Application.PropertyValueType>;

    //! Creates an empty holder; call loadCache() before drawing.
    function initialize() {
        places = new PlaceNames(method(:rename));
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
        var raw = Storage.getValue(WeatherState.FETCH_TIME_KEYS[source(slot)] as String);
        return Values.isNumeric(raw) ? Values.toNumberOr(raw, 0) : null;
    }

    //! @param slot WeatherState.GPS or WeatherState.HOME.
    //! @return The slot whose fetches fill it (WeatherState.source()).
    private function source(slot as Number) as Number {
        return WeatherState.source(slot, homeStatus == HomeSettings.STATUS_SET);
    }

    // MARK: - Cache

    //! Loads both slots, their names and the saved GPS position from Storage.
    //! Called on start and after a background refresh has written new data.
    //! Security: cached data may come from an older app version or be damaged, so
    //! it is shape-checked and anything unexpected is treated as "no data".
    function loadCache() as Void {
        homeStatus = HomeSettings.status();
        for (var slot = 0; slot < 2; slot++) {
            var cur = Storage.getValue(WeatherState.WEATHER_KEYS[slot] as String);
            var fc  = Storage.getValue(WeatherState.FORECAST_KEYS[slot] as String);
            current[slot]  = WeatherParser.isValidCurrent(cur) ? cur as Array : null;
            forecast[slot] = WeatherParser.isValidForecast(fc) ? fc as Array : null;
            if (current[slot] != null) {
                places.setCached(slot, (current[slot] as Array)[WeatherSlots.CUR_NAME] as String);
            }
        }
        gpsCoords = Coordinates.validOrNull(Storage.getValue("gps_coords"));
    }

    //! Saves a successful weather reply for a slot and records the time.
    //! Side effects: Storage writes; clears the slot's failure flag.
    //! @param slot WeatherState.GPS or WeatherState.HOME.
    //! @param cur Parsed current conditions.
    //! @param fc Parsed forecast, or null to keep the previous one.
    private function store(slot as Number, cur as Array, fc as Array?) as Void {
        current[slot] = cur;
        Storage.setValue(WeatherState.WEATHER_KEYS[slot] as String, cur as Array<Application.PropertyValueType>);
        if (fc != null) {
            forecast[slot] = fc;
            Storage.setValue(WeatherState.FORECAST_KEYS[slot] as String, fc as Array<Application.PropertyValueType>);
        }
        Storage.setValue(WeatherState.FETCH_TIME_KEYS[slot] as String, Time.now().value());
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
        Storage.setValue(WeatherState.WEATHER_KEYS[WeatherState.HOME] as String,
            current[WeatherState.HOME] as Array<Application.PropertyValueType>);
        Storage.deleteValue(WeatherState.HOME_FETCH_FOR_KEY);
        if (fc != null) {
            Storage.setValue(WeatherState.FORECAST_KEYS[WeatherState.HOME] as String,
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
            Storage.setValue(WeatherState.WEATHER_KEYS[slot] as String, cur as Array<Application.PropertyValueType>);
        }
        if (fc != null) {
            fc[WeatherSlots.FC_NAME] = name;
            Storage.setValue(WeatherState.FORECAST_KEYS[slot] as String, fc as Array<Application.PropertyValueType>);
        }
        if (slot == WeatherState.GPS && homeStatus != HomeSettings.STATUS_SET) { mirrorGps(); }
        WatchUi.requestUpdate();
    }

    // MARK: - Fetching

    //! Fetches each location whose data is missing or older than the refresh
    //! interval; fresh data is not fetched again, to save battery and radio use.
    //! Called on start and by the MENU button. A pending retry is cancelled, so
    //! MENU during a retry wait does not send the GPS request twice.
    //! Side effects: up to four web requests, or a one-shot GPS request.
    function refresh() as Void {
        retryTimer.stop();
        homeStatus = HomeSettings.status();
        retriesLeft = MAX_RETRIES;
        if (homeStatus == HomeSettings.STATUS_SET) {
            if (needsFetch(WeatherState.HOME)) { fetchHome(); }
        } else {
            mirrorGps();
        }
        if (needsFetch(WeatherState.GPS)) { fetchGps(); }
    }

    //! Settings changed in Garmin Connect: Home is fetched straight away, even if
    //! the data shown is still fresh, because it may be for the old Home.
    //! Side effects: deletes "home_fetch_time"; see refresh().
    function settingsChanged() as Void {
        Storage.deleteValue(WeatherState.FETCH_TIME_KEYS[WeatherState.HOME] as String);
        failed[WeatherState.HOME] = false;
        refresh();
    }

    //! Stops the retry timer while the widget is off screen.
    function stop() as Void {
        retryTimer.stop();
    }

    //! @param slot WeatherState.GPS or WeatherState.HOME.
    //! @return true if the slot has no data, it is older than the refresh interval,
    //!   or (Home) it was not fetched for the current Home setting.
    private function needsFetch(slot as Number) as Boolean {
        if (current[slot] == null) { return true; }
        if (slot == WeatherState.HOME && !FetchRules.fetchedForHome(HomeSettings.lat(), HomeSettings.lon(),
                Storage.getValue(WeatherState.HOME_FETCH_FOR_KEY))) { return true; }
        var minutes = FetchRules.refreshMinutes(Properties.getValue("refresh_rate"));
        return !FetchRules.isFresh(Storage.getValue(WeatherState.FETCH_TIME_KEYS[slot] as String),
                                   Time.now().value(), minutes);
    }

    //! Fetches Home weather and, unless its saved place name still applies,
    //! its place name (PlaceNames.lookUp()).
    private function fetchHome() as Void {
        var lat = HomeSettings.lat();
        var lon = HomeSettings.lon();
        homeRequestedFor = FetchRules.homeFetchRecord(lat, lon);
        WeatherRequests.weather(lat, lon, method(:onHomeWeather));
        places.lookUp(WeatherState.HOME, lat, lon);
    }

    //! Fetches GPS weather and place name, or starts a one-shot GPS request when no
    //! position is known. If a one-shot request is already pending, clears the flag
    //! instead, so the next refresh can start a new one if that request never answers.
    private function fetchGps() as Void {
        var coords = GpsPosition.find();
        if (coords != null) {
            gpsCoords = coords;
            requestGpsWeather();
            places.lookUp(WeatherState.GPS, coords[0], coords[1]);
        } else if (!gpsRequested) {
            gpsRequested = true;
            Position.enableLocationEvents(Position.LOCATION_ONE_SHOT, method(:onPosition));
        } else {
            gpsRequested = false;
        }
    }

    //! Requests GPS weather for gpsCoords. Also the retry timer's callback, so a
    //! retry repeats only the request that failed.
    function requestGpsWeather() as Void {
        var coords = gpsCoords;
        if (coords != null) {
            WeatherRequests.weather(coords[0], coords[1], method(:onGpsWeather));
        }
    }

    // MARK: - Callbacks

    //! One-shot GPS callback. Saves the fix and fetches weather and place name for it.
    //! @param info Position info from the system.
    function onPosition(info as Position.Info) as Void {
        gpsRequested = false;
        var pos = (info.position != null)
            ? Coordinates.validOrNull((info.position as Position.Location).toDegrees()) : null;
        if (pos != null) {
            Storage.setValue("gps_coords", Coordinates.rounded(pos));
            gpsCoords = pos;
            requestGpsWeather();
            places.lookUp(WeatherState.GPS, pos[0], pos[1]);
        }
        WatchUi.requestUpdate();
    }

    //! GPS weather callback. On success saves the data (and mirrors it to Home when
    //! Home is not set). A network-level error (code <= 0) is retried after
    //! RETRY_DELAY_MS, up to MAX_RETRIES times per refresh; any other failure, or
    //! running out of retries, marks the slot as failed and keeps the old data.
    //! @param responseCode HTTP status, or a negative Connect IQ error code.
    //! @param data Parsed JSON body, or null.
    function onGpsWeather(responseCode as Number, data as Dictionary?) as Void {
        var name = places.name(WeatherState.GPS);
        var cur = (responseCode == 200) ? WeatherParser.parseCurrent(data, name) : null;
        if (cur != null) {
            store(WeatherState.GPS, cur, WeatherParser.parseForecast(data, name, cur));
            if (homeStatus != HomeSettings.STATUS_SET) { mirrorGps(); }
        } else if (responseCode <= 0 && retriesLeft > 0) {
            retriesLeft--;
            retryTimer.start(method(:requestGpsWeather), RETRY_DELAY_MS, false);
            return;
        } else {
            failed[WeatherState.GPS] = true;
        }
        WatchUi.requestUpdate();
    }

    //! Home weather callback. On success saves the data and the Home coordinates
    //! it is for ("home_fetch_for"); otherwise marks Home as failed and keeps the
    //! old data (no retry).
    //! @param responseCode HTTP status, or a negative Connect IQ error code.
    //! @param data Parsed JSON body, or null.
    function onHomeWeather(responseCode as Number, data as Dictionary?) as Void {
        var name = places.name(WeatherState.HOME);
        var cur = (responseCode == 200) ? WeatherParser.parseCurrent(data, name) : null;
        if (cur != null) {
            store(WeatherState.HOME, cur, WeatherParser.parseForecast(data, name, cur));
            Storage.setValue(WeatherState.HOME_FETCH_FOR_KEY, homeRequestedFor);
        } else {
            failed[WeatherState.HOME] = true;
        }
        WatchUi.requestUpdate();
    }
}
