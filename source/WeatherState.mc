// WeatherState.mc — location slot numbers, "no data" reasons, the Storage keys
// per slot, and the pure rules that decide which slot's data is shown. Used by
// WeatherData and WeatherView, and its keys by WeatherApp, BackgroundResult and
// the glance, so it is marked :glance and :background.
//
// The rules take plain values (no Storage or settings access) so they can be unit
// tested (see source/test/StateRulesTest.mc).

import Toybox.Lang;

//! Location slots and the "why is there nothing to show" states.
(:glance, :background)
module WeatherState {
    //! The GPS (current position) location.
    const GPS = 0;
    //! The Home location from settings. Mirrors GPS while Home is not set.
    const HOME = 1;

    //! No data yet and a request is (or will be) in flight.
    const EMPTY_LOADING = 0;
    //! No data and no GPS position from any source yet.
    const EMPTY_WAITING_GPS = 1;
    //! No data and the last attempt failed.
    const EMPTY_NO_CONNECTION = 2;

    //! Storage keys of the current conditions, by slot. Permanent (installed watches).
    const WEATHER_KEYS = ["gps_weather", "home_weather"];
    //! Storage keys of the forecast, by slot. Permanent.
    const FORECAST_KEYS = ["gps_forecast", "home_forecast"];
    //! Storage keys of the Unix time of the last successful weather update, by slot.
    //! They replace "last_fetch_time" (one time for both slots, no longer written).
    const FETCH_TIME_KEYS = ["gps_fetch_time", "home_fetch_time"];
    //! Storage keys of the last successful place-name lookup, by slot:
    //! [latitude, longitude, name] (FetchRules.placeRecord()). They replace
    //! "home_lat_cached" / "home_lon_cached", which are no longer written or read.
    const PLACE_KEYS = ["gps_place", "home_place"];
    //! Storage key of the Home coordinates the saved Home weather was fetched for
    //! (FetchRules.homeFetchRecord()), or [] when it is a copy of the GPS data. Permanent.
    const HOME_FETCH_FOR_KEY = "home_fetch_for";

    //! Which slot's fetches fill a slot: Home shows a copy of GPS unless Home is set,
    //! so the Home page never shows a location the user did not choose.
    //! @param slot GPS or HOME.
    //! @param homeSet true if HomeSettings.status() is STATUS_SET.
    //! @return GPS or HOME.
    function source(slot as Number, homeSet as Boolean) as Number {
        return (slot == HOME && homeSet) ? HOME : GPS;
    }

    //! Why a slot has nothing to show.
    //! @param src The slot's source() slot.
    //! @param lastFailed true if the latest attempt for src failed.
    //! @param hasPosition true if any GPS position is known.
    //! @return EMPTY_NO_CONNECTION, EMPTY_WAITING_GPS or EMPTY_LOADING.
    function emptyReason(src as Number, lastFailed as Boolean, hasPosition as Boolean) as Number {
        if (lastFailed) { return EMPTY_NO_CONNECTION; }
        if (src == GPS && !hasPosition) { return EMPTY_WAITING_GPS; }
        return EMPTY_LOADING;
    }
}
