// WatchServices.mc — the single doorway from the widget's data code (WeatherData,
// PlaceNames) to the watch: Storage, settings, the clock, web requests, GPS, the
// retry timer and redraws. Runs in the foreground (widget) process only.
//
// Unit tests replace it with a subclass that keeps Storage in memory and records
// requests (source/test/WeatherDataTest.mc), so the fetch, retry and caching
// logic can be tested without a watch, a phone or the network. The background
// and glance processes do not use it, to keep their memory small.

import Toybox.Application;
import Toybox.Lang;
import Toybox.Position;
import Toybox.Time;
import Toybox.Timer;
import Toybox.WatchUi;

//! Watch services used by WeatherData and PlaceNames.
class WatchServices {

    //! One-shot timer for GPS weather retries.
    private var retryTimer as Timer.Timer = new Timer.Timer();

    //! Creates the services; nothing is started until a method is called.
    function initialize() {
    }

    //! @param key A Storage key (WeatherState constants or "gps_coords").
    //! @return The stored value, or null. Untrusted: callers check its type.
    function getValue(key as String) as Object? {
        return Storage.getValue(key);
    }

    //! Side effect: Storage write.
    //! @param key A Storage key.
    //! @param value The value to save.
    function setValue(key as String, value as Application.PropertyValueType) as Void {
        Storage.setValue(key, value);
    }

    //! Side effect: Storage delete.
    //! @param key A Storage key.
    function deleteValue(key as String) as Void {
        Storage.deleteValue(key);
    }

    //! @return The raw refresh_rate setting (checked by FetchRules.refreshMinutes()).
    function refreshSetting() as Object? {
        return Properties.getValue("refresh_rate");
    }

    //! @return HomeSettings.status() of the current settings.
    function homeStatus() as Number {
        return HomeSettings.status();
    }

    //! @return [latitude, longitude] of Home from HomeSettings.lat()/lon(); only
    //!   meaningful when homeStatus() is HomeSettings.STATUS_SET.
    function homeCoords() as Array<Float> {
        return [HomeSettings.lat(), HomeSettings.lon()] as Array<Float>;
    }

    //! Saves new Home settings (MENU → Set Home here). The Garmin Connect app shows
    //! the new values the next time its settings are opened.
    //! Side effect: writes the home_lat and home_lon properties.
    //! @param lat Latitude text, as the settings store it.
    //! @param lon Longitude text.
    function setHomeSettings(lat as String, lon as String) as Void {
        Properties.setValue("home_lat", lat);
        Properties.setValue("home_lon", lon);
    }

    //! @return The current Unix time in seconds.
    function now() as Number {
        return Time.now().value();
    }

    //! Side effect: one web request (WeatherRequests.weather()).
    //! @param lat Latitude in decimal degrees.
    //! @param lon Longitude in decimal degrees.
    //! @param callback Receives (responseCode, data).
    function requestWeather(lat as Float or Double, lon as Float or Double, callback as Method) as Void {
        WeatherRequests.weather(lat, lon, callback);
    }

    //! Side effect: one web request (WeatherRequests.placeName()).
    //! @param lat Latitude in decimal degrees.
    //! @param lon Longitude in decimal degrees.
    //! @param callback Receives (responseCode, data).
    function requestPlaceName(lat as Float or Double, lon as Float or Double, callback as Method) as Void {
        WeatherRequests.placeName(lat, lon, callback);
    }

    //! Side effect: may write "gps_coords" (GpsPosition.find()).
    //! @return [latitude, longitude, isCurrent] of the best known position, or null.
    function findPosition() as Array? {
        return GpsPosition.find();
    }

    //! Starts a one-shot GPS fix. Side effect: turns on GPS until it answers.
    //! @param callback Receives the Position.Info.
    function requestPosition(callback as Method(info as Position.Info) as Void) as Void {
        Position.enableLocationEvents(Position.LOCATION_ONE_SHOT, callback);
    }

    //! Calls callback once after ms milliseconds; replaces any pending retry.
    //! @param callback The retry to run.
    //! @param ms Delay in milliseconds.
    function startRetry(callback as Method() as Void, ms as Number) as Void {
        retryTimer.stop();
        retryTimer.start(callback, ms, false);
    }

    //! Cancels a pending retry, if any.
    function stopRetry() as Void {
        retryTimer.stop();
    }

    //! Asks the system to redraw the widget.
    function redraw() as Void {
        WatchUi.requestUpdate();
    }
}
