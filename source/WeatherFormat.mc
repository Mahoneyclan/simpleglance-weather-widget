// WeatherFormat.mc — text formatting for the full-screen widget: compass labels
// and clock times. Runs in the foreground (widget) process only.
//
// Pure functions with no system access, so they can be unit tested
// (see source/test/DisplayRulesTest.mc).

import Toybox.Lang;

//! Label formatting shared by the widget pages.
module WeatherFormat {

    //! 8-point compass labels, clockwise from north; each covers 45°.
    const COMPASS = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"];

    //! Converts a wind bearing to an 8-point compass label, each covering 45°
    //! centred on its direction (N is 337.5°–22.5°).
    //! @param deg Bearing in degrees the wind blows from; any value, wrapped to 0–360.
    //! @return The compass label.
    function windDirName(deg as Float) as String {
        // Shift by half a sector (22.5°) so each label's range starts at 0, then
        // wrap; Monkey C's % keeps the sign of the dividend, hence the +360.
        var d = ((deg + 22.5f).toNumber() % 360 + 360) % 360;
        return COMPASS[d / 45] as String;
    }

    //! Formats a time of day for the "No connection" status line, in the watch's
    //! 12- or 24-hour style. The 12-hour form matches the hourly page ("10p").
    //! @param hour Hour 0–23.
    //! @param minute Minute 0–59.
    //! @param is24Hour true when the watch is set to 24-hour time.
    //! @return For example "14:05" or "2:05p".
    function clockTime(hour as Number, minute as Number, is24Hour as Boolean) as String {
        if (is24Hour) { return hour.format("%02d") + ":" + minute.format("%02d"); }
        var h12 = hour % 12;
        if (h12 == 0) { h12 = 12; }
        return h12.format("%d") + ":" + minute.format("%02d") + (hour < 12 ? "a" : "p");
    }
}
