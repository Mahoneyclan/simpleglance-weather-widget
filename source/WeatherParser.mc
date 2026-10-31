// WeatherParser.mc — the single, validating reader of Open-Meteo weather replies,
// Nominatim place-name replies and the weather arrays cached in Storage. Used by
// the widget (WeatherData) and the background refresh (BackgroundService), so it
// is marked :background. Type checks come from Values.mc.
//
// Security: web responses and Storage contents are untrusted. Every field is
// type- and length-checked here; missing required data makes a parse return
// null (callers keep their previous data) instead of crashing the app.

import Toybox.Lang;
import Toybox.Math;
import Toybox.Time;
import Toybox.Time.Gregorian;

//! Converts Open-Meteo JSON into the compact arrays the app stores and draws.
(:background)
module WeatherParser {

    //! Hourly columns shown: Now + 3 hours. The request asks for forecast_hours=6.
    const HOURS = 4;
    //! Daily rows shown: today + 4 days. The request asks for forecast_days=5.
    const DAYS = 5;
    //! Item count of a current-conditions array (see parseCurrent()).
    const CURRENT_SIZE = 9;
    //! Item count of a forecast array (see parseForecastAt()).
    const FORECAST_SIZE = 15;

    //! Name stored for the GPS location until its place-name lookup succeeds.
    //! Saved inside cached arrays, so changing it changes stored data.
    const GPS_PLACEHOLDER = "GPS Location";
    //! Name stored for Home until its place-name lookup succeeds. Saved inside
    //! cached arrays, so changing it changes stored data.
    const HOME_PLACEHOLDER = "Home";

    // MARK: - Current conditions

    //! Builds the 9-item current-conditions array stored as "gps_weather" / "home_weather":
    //!   [0] temperature °C (Float)      [1] feels-like °C (Float)
    //!   [2] wind speed km/h (Float)     [3] wind gust km/h (Float; speed if not reported)
    //!   [4] wind direction ° (Float)    [5] location name (String)
    //!   [6] rain mm (Float)             [7] WMO weather code (Number)
    //!   [8] is_day 1/0 (Number)
    //! Temperature, feels-like and wind speed are required; other fields default.
    //! @param data Parsed JSON body of a 200 response, or null.
    //! @param name Location name stored at index 5.
    //! @return The array, or null if the required fields are missing or not numbers.
    function parseCurrent(data as Dictionary?, name as String) as Array? {
        if (data == null) { return null; }
        var raw = data["current"];
        if (!(raw instanceof Dictionary)) { return null; }
        var cur = raw as Dictionary<String, Object?>;
        var temp  = cur["temperature_2m"];
        var feels = cur["apparent_temperature"];
        var speed = cur["wind_speed_10m"];
        if (!Values.isNumeric(temp) || !Values.isNumeric(feels) || !Values.isNumeric(speed)) { return null; }
        var gust = cur["wind_gusts_10m"];
        if (!Values.isNumeric(gust)) { gust = speed; }
        return [
            Values.toFloatOr(temp, 0.0f),
            Values.toFloatOr(feels, 0.0f),
            Values.toFloatOr(speed, 0.0f),
            Values.toFloatOr(gust, 0.0f),
            Values.toFloatOr(cur["wind_direction_10m"], 0.0f),
            name,
            Values.toFloatOr(cur["precipitation"], 0.0f),
            Values.toNumberOr(cur["weather_code"], 0),
            Values.toNumberOr(cur["is_day"], 1)
        ] as Array;
    }

    // MARK: - Forecast

    //! Builds the forecast array using the watch's current clock for labels.
    //! See parseForecastAt() for the layout and rules.
    //! @param data Parsed JSON body of a 200 response, or null.
    //! @param name Location name stored at index 0.
    //! @param current The matching parseCurrent() result, used for the "Now" temperature; may be null.
    //! @return The array, or null if required data is missing.
    function parseForecast(data as Dictionary?, name as String, current as Array?) as Array? {
        var info = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        return parseForecastAt(data, name, current, info.hour as Number, info.day_of_week as Number);
    }

    //! Builds the 15-item forecast array stored as "gps_forecast" / "home_forecast":
    //!   [0]  name String                    [1]  hour labels ("Now", "10p", …) ×4
    //!   [2]  hourly temp °C (Number) ×4     [3]  hourly rain probability % (Number) ×4
    //!   [4]  day labels ("Today", "Fri", …) ×5
    //!   [5]  daily max °C (Number) ×5       [6]  daily min °C (Number) ×5
    //!   [7]  daily max wind km/h (Float) ×5 [8]  daily wind direction ° (Number) ×5
    //!   [9]  daily rain mm (Float) ×5       [10] daily WMO code (Number) ×5
    //!   [11] hourly WMO code (Number) ×4    [12] hourly rain mm (Float) ×4
    //!   [13] hourly wind km/h (Float) ×4    [14] hourly wind direction ° (Number) ×4
    //! Required: hourly temperature (≥4 values) and daily max/min (≥5 values). Other
    //! series are optional; missing or short ones, and non-numeric values, become 0.
    //! Labels use the watch's clock, not the location's time zone.
    //! @param data Parsed JSON body of a 200 response, or null.
    //! @param name Location name stored at index 0.
    //! @param current parseCurrent() result; when valid, its temperature is used for "Now"
    //!   so the hourly page agrees with the current-conditions page.
    //! @param hour Current hour 0–23 on the watch.
    //! @param dayOfWeek Today's day of week, 1 = Sunday … 7 = Saturday (Gregorian.info).
    //! @return The array, or null if required data is missing.
    function parseForecastAt(data as Dictionary?, name as String, current as Array?,
                             hour as Number, dayOfWeek as Number) as Array? {
        if (data == null) { return null; }
        var rawHourly = data["hourly"];
        var rawDaily  = data["daily"];
        if (!(rawHourly instanceof Dictionary) || !(rawDaily instanceof Dictionary)) { return null; }
        var hourly = rawHourly as Dictionary<String, Object?>;
        var daily  = rawDaily as Dictionary<String, Object?>;
        var hTemps = Values.arrayOrNull(hourly["temperature_2m"], HOURS);
        var dMax   = Values.arrayOrNull(daily["temperature_2m_max"], DAYS);
        var dMin   = Values.arrayOrNull(daily["temperature_2m_min"], DAYS);
        if (hTemps == null || dMax == null || dMin == null) { return null; }
        var h = parseHourly(hourly, hTemps, hour, current);
        var d = parseDaily(daily, dMax, dMin, dayOfWeek);
        return [name, h[0], h[1], h[2], d[0], d[1], d[2], d[3], d[4], d[5], d[6],
                h[3], h[4], h[5], h[6]] as Array;
    }

    //! Builds the seven hourly series for parseForecastAt().
    //! @param hourly The response's "hourly" block.
    //! @param temps Hourly temperatures, already checked to hold at least HOURS items.
    //! @param hour Current hour 0–23 on the watch.
    //! @param current parseCurrent() result for the "Now" temperature; may be null.
    //! @return [labels, temps, rainProb, weatherCode, precip, windSpeed, windDir], each HOURS long.
    function parseHourly(hourly as Dictionary<String, Object?>, temps as Array<Object?>,
                         hour as Number, current as Array?) as Array {
        var rainP  = Values.arrayOrNull(hourly["precipitation_probability"], HOURS);
        var wcode  = Values.arrayOrNull(hourly["weather_code"], HOURS);
        var precip = Values.arrayOrNull(hourly["precipitation"], HOURS);
        var wspd   = Values.arrayOrNull(hourly["wind_speed_10m"], HOURS);
        var wdir   = Values.arrayOrNull(hourly["wind_direction_10m"], HOURS);
        var nowTemp = isValidCurrent(current) ? (current as Array<Object?>)[WeatherSlots.CUR_TEMP] : null;
        var out = [new [HOURS], new [HOURS], new [HOURS], new [HOURS],
                   new [HOURS], new [HOURS], new [HOURS]];
        for (var i = 0; i < HOURS; i++) {
            out[0][i] = hourLabel(hour, i);
            out[1][i] = roundOr((i == 0 && nowTemp != null) ? nowTemp : temps[i], 0);
            out[2][i] = Values.toNumberOr(elementAt(rainP, i), 0);
            out[3][i] = Values.toNumberOr(elementAt(wcode, i), 0);
            out[4][i] = Values.toFloatOr(elementAt(precip, i), 0.0f);
            out[5][i] = Values.toFloatOr(elementAt(wspd, i), 0.0f);
            out[6][i] = Values.toNumberOr(elementAt(wdir, i), 0);
        }
        return out;
    }

    //! Builds the seven daily series for parseForecastAt().
    //! @param daily The response's "daily" block.
    //! @param maxT Daily maximum temperatures, already checked to hold at least DAYS items.
    //! @param minT Daily minimum temperatures, already checked to hold at least DAYS items.
    //! @param dayOfWeek Today's day of week, 1 = Sunday … 7 = Saturday.
    //! @return [dayNames, maxT, minT, wind, windDir, rain, weatherCode], each DAYS long.
    function parseDaily(daily as Dictionary<String, Object?>, maxT as Array<Object?>,
                        minT as Array<Object?>, dayOfWeek as Number) as Array {
        var wind = Values.arrayOrNull(daily["wind_speed_10m_max"], DAYS);
        var dir  = Values.arrayOrNull(daily["wind_direction_10m_dominant"], DAYS);
        var rain = Values.arrayOrNull(daily["precipitation_sum"], DAYS);
        var cond = Values.arrayOrNull(daily["weather_code"], DAYS);
        var dayAbbr = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
        var out = [new [DAYS], new [DAYS], new [DAYS], new [DAYS],
                   new [DAYS], new [DAYS], new [DAYS]];
        for (var i = 0; i < DAYS; i++) {
            out[0][i] = (i == 0) ? "Today" : dayAbbr[(dayOfWeek + i - 1) % 7];
            out[1][i] = roundOr(maxT[i], 0);
            out[2][i] = roundOr(minT[i], 0);
            out[3][i] = Values.toFloatOr(elementAt(wind, i), 0.0f);
            out[4][i] = Values.toNumberOr(elementAt(dir, i), 0);
            out[5][i] = Values.toFloatOr(elementAt(rain, i), 0.0f);
            out[6][i] = Values.toNumberOr(elementAt(cond, i), 0);
        }
        return out;
    }

    //! @param hour Current hour 0–23.
    //! @param offset Hours ahead (0 = now).
    //! @return "Now" for offset 0, otherwise a 12-hour label such as "10p" or "12a".
    function hourLabel(hour as Number, offset as Number) as String {
        if (offset == 0) { return "Now"; }
        var hr  = (hour + offset) % 24;
        var h12 = hr % 12;
        if (h12 == 0) { h12 = 12; }
        return h12.format("%d") + (hr < 12 ? "a" : "p");
    }

    // MARK: - Place names

    //! Longest place name kept. The name is drawn in one line across the top of a
    //! 260 px round screen, so anything longer would not fit anyway; the cap also
    //! bounds memory if a reply contains an unexpectedly long string.
    const MAX_NAME_LENGTH = 30;

    //! Picks the most specific place name from a Nominatim reverse-geocoding reply:
    //! the "suburb", "town", "city", "village" or "hamlet" address field, else the first comma-separated
    //! part of display_name. Only non-empty Strings are accepted (security: the reply
    //! is untrusted), and the result is cut to MAX_NAME_LENGTH characters.
    //! @param data Parsed JSON body of a 200 response, or null.
    //! @return The name, or null if none is usable.
    function parsePlaceName(data as Dictionary?) as String? {
        if (data == null) { return null; }
        var name = null;
        var addr = data["address"];
        if (addr instanceof Dictionary) {
            var a = addr as Dictionary<String, Object?>;
            var keys = ["suburb", "town", "city", "village", "hamlet"];
            for (var i = 0; i < keys.size() && name == null; i++) {
                name = Values.nonEmptyString(a[keys[i] as String]);
            }
        }
        if (name == null) {
            var display = Values.nonEmptyString(data["display_name"] as Object?);
            if (display != null) {
                var comma = display.find(",");
                name = Values.nonEmptyString((comma != null) ? display.substring(0, comma) : display);
            }
        }
        if (name != null && name.length() > MAX_NAME_LENGTH) {
            name = name.substring(0, MAX_NAME_LENGTH);
        }
        return name;
    }

    // MARK: - Cache validation

    //! Checks a cached current-conditions array before it is drawn. Arrays written
    //! by older app versions with fewer items are rejected (treated as no data).
    //! @param value A value read from Storage.
    //! @return true if it has 9 items with numbers at 0–4 and 6, a String name at 5
    //!   and Numbers at 7–8.
    function isValidCurrent(value as Object?) as Boolean {
        var a = Values.arrayOrNull(value, CURRENT_SIZE);
        if (a == null) { return false; }
        for (var i = 0; i <= 6; i++) {
            if (i != 5 && !Values.isNumeric(a[i])) { return false; }
        }
        if (a[5] instanceof String && a[7] instanceof Number && a[8] instanceof Number) { return true; }
        return false;
    }

    //! Checks the shape of a cached forecast array before it is drawn: the name, and
    //! that every series is an array of the right length. Index 3 may be null, as
    //! written by older versions. Element types are not re-checked; every app
    //! version filled them through its own parser with numeric defaults.
    //! @param value A value read from Storage.
    //! @return true if it is safe to index as documented in parseForecastAt().
    function isValidForecast(value as Object?) as Boolean {
        var a = Values.arrayOrNull(value, FORECAST_SIZE);
        if (a == null || !(a[0] instanceof String)) { return false; }
        var hourlyIdx = [1, 2, 11, 12, 13, 14];
        var dailyIdx  = [4, 5, 6, 7, 8, 9, 10];
        for (var i = 0; i < hourlyIdx.size(); i++) {
            if (Values.arrayOrNull(a[hourlyIdx[i] as Number], HOURS) == null) { return false; }
        }
        for (var i = 0; i < dailyIdx.size(); i++) {
            if (Values.arrayOrNull(a[dailyIdx[i] as Number], DAYS) == null) { return false; }
        }
        return a[3] == null || Values.arrayOrNull(a[3], HOURS) != null;
    }

    // MARK: - Helpers

    //! @param value Any value from a response or Storage.
    //! @param fallback Returned when the value is not numeric.
    //! @return The value rounded to the nearest Number, or the fallback if it is not numeric.
    function roundOr(value as Object?, fallback as Number) as Number {
        return Values.isNumeric(value) ? Math.round((value as Numeric).toFloat()).toNumber() : fallback;
    }

    //! @param arr An array from Values.arrayOrNull(), or null.
    //! @param i The index to read.
    //! @return arr[i], or null when arr is null. Callers pass arrays from Values.arrayOrNull(),
    //!   so i is always in range.
    function elementAt(arr as Array<Object?>?, i as Number) as Object? {
        return (arr != null) ? arr[i] : null;
    }
}
