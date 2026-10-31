// Units.mc — converts the stored metric values (°C, km/h, mm) to the units the
// watch is set to, at draw time. Used by the full-screen pages and the glance, so
// it is marked :glance; it is kept small for the glance's memory limit.
//
// Values are stored in metric and converted only for display, so a change of
// the watch's unit setting applies at once, without a new fetch. The conversion
// functions take the unit choice as a parameter so they can be unit tested
// (see source/test/DisplayRulesTest.mc).

import Toybox.Lang;
import Toybox.Math;
import Toybox.System;

//! Display-unit conversions.
(:glance)
module Units {

    //! @return true if the watch shows temperatures in °F.
    function fahrenheit() as Boolean {
        return System.getDeviceSettings().temperatureUnits == System.UNIT_STATUTE;
    }

    //! Wind speed and rain follow the watch's distance setting, because Connect IQ
    //! has no separate setting for them.
    //! @return true if the watch uses miles, so wind is shown in mph and rain in inches.
    function statute() as Boolean {
        return System.getDeviceSettings().distanceUnits == System.UNIT_STATUTE;
    }

    //! @param celsius A temperature in °C. Stored temperatures are whole degrees,
    //!   so a °F value can differ from the exact one by up to 1 °F.
    //! @param toFahrenheit true to convert to °F.
    //! @return The temperature rounded to a whole degree in the chosen unit.
    function temperature(celsius as Numeric, toFahrenheit as Boolean) as Number {
        var c = celsius.toFloat();
        return Math.round(toFahrenheit ? c * 9.0f / 5.0f + 32.0f : c).toNumber();
    }

    //! @param kmh A speed in km/h.
    //! @param toMph true to convert to mph.
    //! @return The speed, rounded to a whole number, as text.
    function speedText(kmh as Numeric, toMph as Boolean) as String {
        var v = kmh.toFloat();
        return (toMph ? v / 1.609344f : v).format("%.0f");
    }

    //! Inches get two decimals because 0.1 in is already 2.5 mm, so one decimal
    //! would show most light rain as 0.0.
    //! @param mm A rain amount in mm.
    //! @param toInches true to convert to inches.
    //! @return The amount as text: one decimal for mm, two for inches.
    function rainText(mm as Numeric, toInches as Boolean) as String {
        var v = mm.toFloat();
        return toInches ? (v / 25.4f).format("%.2f") : v.format("%.1f");
    }
}
