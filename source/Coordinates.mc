// Coordinates.mc — reduces coordinate precision for web requests and for the
// position saved on the watch, and range-checks positions. Used by the widget
// (WeatherRequests, WeatherData, GpsPosition) and the background refresh
// (WeatherRequests, BackgroundService), so it is marked :background.
//
// Security: every coordinate that leaves the watch goes through forRequest(),
// and the saved GPS position goes through rounded(), so the precision kept and
// shared is set in one place.

import Toybox.Application;
import Toybox.Lang;
import Toybox.Math;

//! Coordinate rounding for requests and storage.
(:background)
module Coordinates {

    //! Format for coordinates sent to Open-Meteo and Nominatim: 2 decimal places,
    //! about 1.1 km. That is finer than Open-Meteo's weather grid and enough for
    //! suburb-level place names, without revealing an exact position (privacy).
    const REQUEST_FORMAT = "%.2f";

    //! Formats a latitude or longitude for a request URL.
    //! @param value Decimal degrees.
    //! @return The value rounded to 2 decimal places, e.g. "-27.37".
    function forRequest(value as Float or Double) as String {
        return value.format(REQUEST_FORMAT);
    }

    //! Checks a position read from Storage or a system API before it is used or sent.
    //! Security: Storage contents are untrusted, and positions from Activity or
    //! Weather are not range-checked by the system.
    //! @param value Any value, normally [latitude, longitude].
    //! @return [latitude, longitude] as Doubles if both are numbers within ±90 / ±180,
    //!   otherwise null.
    function validOrNull(value as Object?) as Array<Double>? {
        var a = Values.arrayOrNull(value, 2);
        if (a == null || !Values.isNumeric(a[0]) || !Values.isNumeric(a[1])) { return null; }
        var lat = (a[0] as Numeric).toDouble();
        var lon = (a[1] as Numeric).toDouble();
        if (!(lat >= -90.0d && lat <= 90.0d && lon >= -180.0d && lon <= 180.0d)) { return null; }
        return [lat, lon] as Array<Double>;
    }

    //! Rounds a position to 2 decimal places (about 1.1 km) before it is saved to
    //! Storage, so the watch never keeps an exact location (privacy). Requests are
    //! rounded to the same precision, so nothing visible changes.
    //! @param pos [latitude, longitude] in decimal degrees.
    //! @return A new [latitude, longitude] array of Doubles, each rounded to 0.01°.
    //!   Typed as an array of Storage values so it can be passed straight to
    //!   Storage.setValue().
    function rounded(pos as Array<Double>) as Array<Application.PropertyValueType> {
        return [Math.round(pos[0] * 100.0d) / 100.0d,
                Math.round(pos[1] * 100.0d) / 100.0d] as Array<Application.PropertyValueType>;
    }
}
