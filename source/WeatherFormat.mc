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

    //! Headings of the hourly columns, counted from the hour the data was fetched.
    //! The first column is "Now" only while the watch is still in that hour, so
    //! older data is never labelled as current.
    //! @param fetchHour Hour 0–23 (watch time) when the data was fetched.
    //! @param stillThatHour true if the watch is still in that hour of that day.
    //! @param is24Hour true when the watch is set to 24-hour time.
    //! @param nowText The word shown for the current hour.
    //! @param count Number of columns.
    //! @return One heading per column.
    function hourHeadings(fetchHour as Number, stillThatHour as Boolean, is24Hour as Boolean,
                          nowText as String, count as Number) as Array<String> {
        var out = new [count] as Array<String>;
        for (var i = 0; i < count; i++) {
            out[i] = (i == 0 && stillThatHour) ? nowText : WeatherParser.hourLabel((fetchHour + i) % 24, is24Hour);
        }
        return out;
    }

    //! Formats a position for the "Set Home here" menu item.
    //! @param pos [latitude, longitude] in decimal degrees.
    //! @return For example "-27.37, 152.80" (2 decimals, about 1 km).
    function positionText(pos as Array<Double>) as String {
        return pos[0].format("%.2f") + ", " + pos[1].format("%.2f");
    }

    //! Formats a coordinate for the Home settings. Five decimals (about 1 m) is
    //! more than enough, and the text can never equal the 4-decimal legacy default
    //! (HomeSettings.LEGACY_DEFAULT_LAT), so a saved Home always counts as set.
    //! @param value Decimal degrees.
    //! @return For example "-27.37052".
    function settingText(value as Double) as String {
        return value.format("%.5f");
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
