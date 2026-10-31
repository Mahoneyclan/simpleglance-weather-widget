// FetchRules.mc — when to fetch: refresh interval, data freshness, whether saved
// Home weather is for the current Home setting, and whether a saved place name
// still applies to a position. Used by the widget (WeatherData),
// the app (WeatherApp, which can run in the glance process) and the background
// refresh (BackgroundService), so it is marked :glance and :background.
//
// Kept free of Storage, Properties and clock access so every rule can be unit
// tested (see source/test/FetchRulesTest.mc); callers pass the raw values in.

import Toybox.Application;
import Toybox.Lang;

//! Fetch timing and place-name reuse rules.
(:glance, :background)
module FetchRules {

    //! Refresh interval used when the setting is missing or unusable. Must match
    //! the refresh_rate default in resources/properties.xml.
    const DEFAULT_REFRESH_MINUTES = 30;
    //! Shortest interval accepted. Connect IQ cannot run a background event more
    //! often than every 5 minutes, and registering a shorter one is an error.
    const MIN_REFRESH_MINUTES = 5;
    //! Longest interval accepted (one day). The settings list offers at most 60.
    const MAX_REFRESH_MINUTES = 1440;

    //! A saved place name is reused while the coordinates are within this many
    //! degrees (about 1.1 km) of those it was looked up for. That matches the
    //! 2-decimal rounding of requests (Coordinates.REQUEST_FORMAT), so a smaller
    //! move would send Nominatim the same request again.
    const PLACE_TOLERANCE = 0.01f;

    //! Reads the refresh interval setting.
    //! Security: settings are untrusted; anything that is not a number in range
    //! falls back to the default instead of breaking the background schedule.
    //! @param raw The raw refresh_rate property value.
    //! @return Minutes between refreshes, MIN_REFRESH_MINUTES…MAX_REFRESH_MINUTES.
    function refreshMinutes(raw as Object?) as Number {
        if (!(raw instanceof Number)) { return DEFAULT_REFRESH_MINUTES; }
        var minutes = raw as Number;
        if (minutes < MIN_REFRESH_MINUTES || minutes > MAX_REFRESH_MINUTES) {
            return DEFAULT_REFRESH_MINUTES;
        }
        return minutes;
    }

    //! Whether data fetched at lastFetch is still within the refresh interval.
    //! A time in the future (the watch clock was set back) counts as stale, so a
    //! clock change cannot stop fetching.
    //! @param lastFetch The raw Storage value: Unix time of the last successful fetch, or null.
    //! @param now The current Unix time.
    //! @param minutes The refresh interval from refreshMinutes().
    //! @return true if lastFetch is a number and less than `minutes` old.
    function isFresh(lastFetch as Object?, now as Number, minutes as Number) as Boolean {
        if (!Values.isNumeric(lastFetch)) { return false; }
        var age = now - Values.toNumberOr(lastFetch, 0);
        return age >= 0 && age < minutes * 60;
    }

    //! Whether a location's weather should be fetched again.
    //! @param hasData true if the location has weather to show.
    //! @param lastFetch The raw Storage value of its fetch time (see isFresh()).
    //! @param now The current Unix time.
    //! @param minutes The refresh interval from refreshMinutes().
    //! @param forCurrentPlace true if the data is for the location as it is now set
    //!   (always true for GPS; fetchedFor() for Home).
    //! @return true if there is no data, it is for another place, or it is stale.
    function needsFetch(hasData as Boolean, lastFetch as Object?, now as Number, minutes as Number,
                        forCurrentPlace as Boolean) as Boolean {
        return !hasData || !forCurrentPlace || !isFresh(lastFetch, now, minutes);
    }

    //! gpsReplyAction(): the reply was parsed; save it.
    const REPLY_SAVE = 0;
    //! gpsReplyAction(): network error with retries left; try again after a pause.
    const REPLY_RETRY = 1;
    //! gpsReplyAction(): give up; keep the old data and show "No connection".
    const REPLY_FAILED = 2;

    //! What to do with a GPS weather reply. Only network-level errors (code <= 0,
    //! for example no phone connection) are retried: an HTTP error or a damaged
    //! reply would most likely fail the same way again.
    //! @param parsed true if the reply was a 200 and parsed into weather.
    //! @param responseCode HTTP status, or a negative Connect IQ error code.
    //! @param retriesLeft Retries left in this refresh.
    //! @return REPLY_SAVE, REPLY_RETRY or REPLY_FAILED.
    function gpsReplyAction(parsed as Boolean, responseCode as Number, retriesLeft as Number) as Number {
        if (parsed) { return REPLY_SAVE; }
        if (responseCode <= 0 && retriesLeft > 0) { return REPLY_RETRY; }
        return REPLY_FAILED;
    }

    //! Builds the record saved as "gps_place" / "home_place" after a successful
    //! place-name lookup. It keeps the name apart from the weather arrays, because
    //! the Home weather array holds a copy of the GPS data while Home is not set.
    //! @param lat Latitude the name was looked up for.
    //! @param lon Longitude the name was looked up for.
    //! @param name The name from WeatherParser.parsePlaceName().
    //! @return [latitude, longitude, name], typed for Storage.setValue().
    function placeRecord(lat as Numeric, lon as Numeric, name as String) as Array<Application.PropertyValueType> {
        return [lat.toFloat(), lon.toFloat(), name] as Array<Application.PropertyValueType>;
    }

    //! The saved place name, if it was looked up for a position within
    //! PLACE_TOLERANCE of (lat, lon) on both axes. Reusing it saves a Nominatim
    //! request (Nominatim usage policy; less data sent).
    //! Security: the record comes from Storage, so its shape and types are checked.
    //! @param lat Current latitude.
    //! @param lon Current longitude.
    //! @param saved Raw Storage value of "gps_place" or "home_place" (see placeRecord()).
    //! @return The saved name, or null if there is no usable record or it is for another place.
    function savedPlaceName(lat as Numeric, lon as Numeric, saved as Object?) as String? {
        var a = Values.arrayOrNull(saved, 3);
        return (a != null && isNear(lat, lon, a)) ? Values.nonEmptyString(a[2]) : null;
    }

    //! Builds the "gps_fetch_for" / "home_fetch_for" record saved with each
    //! weather result.
    //! @param lat Latitude the weather was requested for.
    //! @param lon Longitude the weather was requested for.
    //! @return [latitude, longitude], typed for Storage.setValue().
    function fetchRecord(lat as Numeric, lon as Numeric) as Array<Application.PropertyValueType> {
        return [lat.toFloat(), lon.toFloat()] as Array<Application.PropertyValueType>;
    }

    //! Whether saved weather was fetched for the current position: within about
    //! 1 km of the watch (GPS), or of the Home setting (Home). Fresh data for
    //! somewhere else is fetched again: the watch has moved, or Home was changed
    //! while the widget was closed (no settingsChanged() call reaches it then).
    //! A copy of the GPS data saves an empty Home record and never matches.
    //! Security: the record comes from Storage, so its shape and types are checked.
    //! @param lat Current latitude of the slot.
    //! @param lon Current longitude of the slot.
    //! @param saved Raw Storage value of "gps_fetch_for" / "home_fetch_for" (see fetchRecord()).
    //! @return true if the record is within PLACE_TOLERANCE of (lat, lon) on both axes.
    function fetchedFor(lat as Numeric, lon as Numeric, saved as Object?) as Boolean {
        var a = Values.arrayOrNull(saved, 2);
        return a != null && isNear(lat, lon, a);
    }

    //! @param lat Latitude to compare.
    //! @param lon Longitude to compare.
    //! @param a A record whose first two items should be its latitude and longitude.
    //! @return true if both items are numbers within PLACE_TOLERANCE of (lat, lon).
    function isNear(lat as Numeric, lon as Numeric, a as Array<Object?>) as Boolean {
        if (!Values.isNumeric(a[0]) || !Values.isNumeric(a[1])) { return false; }
        return (lat.toFloat() - Values.toFloatOr(a[0], 0.0f)).abs() <= PLACE_TOLERANCE
            && (lon.toFloat() - Values.toFloatOr(a[1], 0.0f)).abs() <= PLACE_TOLERANCE;
    }
}
