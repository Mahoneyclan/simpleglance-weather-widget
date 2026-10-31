// BackgroundResult.mc — the layout of the result a background refresh passes to
// the app, and which Storage values it turns into. Built by BackgroundService in
// the background process and read by WeatherApp.onBackgroundData(), which
// Connect IQ may call in the widget or the glance process, so it is marked
// :glance and :background.
//
// Pure functions with no Storage access, so the round trip can be unit tested
// (see source/test/StateRulesTest.mc).

import Toybox.Application;
import Toybox.Lang;

//! Background refresh result: [gpsWeather, homeWeather, gpsForecast, homeForecast, homePlace, homeFetchFor].
(:glance, :background)
module BackgroundResult {

    //! Position of the GPS current-conditions array (or null).
    const GPS_WEATHER = 0;
    //! Position of the Home current-conditions array (or null).
    const HOME_WEATHER = 1;
    //! Position of the GPS forecast array (or null).
    const GPS_FORECAST = 2;
    //! Position of the Home forecast array (or null).
    const HOME_FORECAST = 3;
    //! Position of the Home place record (FetchRules.placeRecord()) when this run
    //! looked the name up successfully, otherwise null.
    const HOME_PLACE = 4;
    //! Position of the Home coordinates the Home weather was fetched for
    //! (FetchRules.fetchRecord()), or null when the Home weather is a GPS copy.
    const HOME_FETCH_FOR = 5;
    //! Item count of a result. A shorter result (from a run of an older version
    //! that straddled an update) is ignored; the next run replaces it.
    const SIZE = 6;

    //! Builds the value passed to Background.exit().
    //! @param gpsWeather Parsed GPS current conditions, or null.
    //! @param homeWeather Parsed Home current conditions (or the GPS copy), or null.
    //! @param gpsForecast Parsed GPS forecast, or null.
    //! @param homeForecast Parsed Home forecast (or the GPS copy), or null.
    //! @param homePlace Home place record from a successful lookup, or null.
    //! @param homeFetchFor Home coordinates fetched for, or null when homeWeather is a GPS copy.
    //! @return The result array, typed for Background.exit().
    function build(gpsWeather as Array?, homeWeather as Array?, gpsForecast as Array?,
                   homeForecast as Array?, homePlace as Array?, homeFetchFor as Array?) as Array<Application.PropertyValueType> {
        return [gpsWeather, homeWeather, gpsForecast, homeForecast, homePlace, homeFetchFor]
            as Array<Application.PropertyValueType>;
    }

    //! The Storage writes a result causes. A null slot (failed or skipped fetch)
    //! writes nothing, which keeps the last good data on screen; a weather array
    //! also records its fetch time, and Home weather the coordinates it is for
    //! ("home_fetch_for"; [] for a GPS copy, which never counts as Home data).
    //! Security: the value comes from another process, so its shape is checked. The
    //! weather arrays are shape-checked again by their readers before use.
    //! @param data The value passed to WeatherApp.onBackgroundData().
    //! @param now Current Unix time, saved as the fetch time.
    //! @return Storage key to value; empty if data is not a result.
    function writes(data as Object?, now as Number) as Dictionary<String, Application.PropertyValueType> {
        var out = {} as Dictionary<String, Application.PropertyValueType>;
        var r = Values.arrayOrNull(data, SIZE);
        if (r == null) { return out; }
        var slots = [WeatherState.GPS, WeatherState.HOME];
        for (var i = 0; i < 2; i++) {
            var slot = slots[i] as Number;
            var weather  = r[(slot == WeatherState.GPS) ? GPS_WEATHER : HOME_WEATHER];
            var forecast = r[(slot == WeatherState.GPS) ? GPS_FORECAST : HOME_FORECAST];
            if (weather instanceof Array) {
                out[WeatherState.WEATHER_KEYS[slot] as String] = weather as Array<Application.PropertyValueType>;
                out[WeatherState.FETCH_TIME_KEYS[slot] as String] = now;
                if (slot == WeatherState.HOME) {
                    var fetchFor = Values.arrayOrNull(r[HOME_FETCH_FOR], 2);
                    var valid = fetchFor != null && Values.isNumeric(fetchFor[0]) && Values.isNumeric(fetchFor[1]);
                    out[(WeatherState.FETCH_FOR_KEYS[WeatherState.HOME] as String)] = (valid ? fetchFor : []) as Array<Application.PropertyValueType>;
                }
            }
            if (forecast instanceof Array) {
                out[WeatherState.FORECAST_KEYS[slot] as String] = forecast as Array<Application.PropertyValueType>;
            }
        }
        var place = Values.arrayOrNull(r[HOME_PLACE], 3);
        if (place != null && Values.isNumeric(place[0]) && Values.isNumeric(place[1])
                && Values.nonEmptyString(place[2]) != null) {
            out[WeatherState.PLACE_KEYS[WeatherState.HOME] as String] = place as Array<Application.PropertyValueType>;
        }
        return out;
    }
}
