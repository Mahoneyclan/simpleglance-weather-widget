// WeatherParserTest.mc — unit tests for WeatherParser against a recorded
// Open-Meteo response and damaged copies of it.
// (:test) code is only compiled into unit-test builds (monkeyc --unit-test).

import Toybox.Lang;
import Toybox.Test;

//! Test fixtures. (:test) keeps this module out of release builds.
(:test)
module WeatherParserFixtures {

    //! A real Open-Meteo reply recorded on 2026-10-29 for central Sydney
    //! (-33.87, 151.21) with the app's exact request parameters. The "time"
    //! arrays are omitted because the parser does not read them.
    //! A new Dictionary is built on each call so tests can damage their copy.
    //! @return The parsed JSON body as makeWebRequest delivers it.
    function sample() as Dictionary {
        return {
            "current" => {
                "temperature_2m" => 17.5, "apparent_temperature" => 18.0,
                "wind_speed_10m" => 3.5, "wind_direction_10m" => 129,
                "wind_gusts_10m" => 11.5, "precipitation" => 0.0,
                "weather_code" => 0, "is_day" => 0
            },
            "hourly" => {
                "temperature_2m" => [17.8, 17.3, 17.3, 17.1, 16.5, 15.5],
                "precipitation_probability" => [0, 0, 0, 0, 0, 0],
                "weather_code" => [0, 0, 2, 1, 0, 1],
                "precipitation" => [0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
                "wind_speed_10m" => [4.6, 2.4, 1.2, 0.4, 0.5, 2.7],
                "wind_direction_10m" => [129, 132, 153, 117, 315, 323]
            },
            "daily" => {
                "temperature_2m_max" => [21.6, 22.6, 27.4, 22.8, 23.2],
                "temperature_2m_min" => [10.9, 13.3, 15.4, 17.9, 16.1],
                "wind_speed_10m_max" => [19.2, 25.4, 18.4, 19.6, 19.1],
                "wind_direction_10m_dominant" => [162, 39, 12, 46, 37],
                "precipitation_sum" => [0.0, 0.0, 6.2, 3.3, 2.6],
                "weather_code" => [45, 3, 95, 95, 55]
            }
        };
    }

    //! Parses the sample forecast at 21:00 on a Thursday (day_of_week 5), the
    //! time the sample was recorded.
    //! @param data The response to parse.
    //! @return The forecast array, or null.
    function forecastOf(data as Dictionary) as Array? {
        var current = WeatherParser.parseCurrent(data, "Sydney");
        return WeatherParser.parseForecastAt(data, "Sydney", current, 21, 5);
    }
}

// MARK: - Current conditions

//! The recorded reply parses into the documented 9-item layout.
(:test)
function parseCurrentReadsRealReply(logger as Logger) as Boolean {
    var w = WeatherParser.parseCurrent(WeatherParserFixtures.sample(), "Sydney") as Array;
    Test.assertEqual(w.size(), 9);
    Test.assertEqual(w[0], 17.5f);
    Test.assertEqual(w[3], 11.5f);
    Test.assertEqual(w[4], 129.0f);
    Test.assertEqual(w[5], "Sydney");
    Test.assertEqual(w[7], 0);
    Test.assertEqual(w[8], 0);
    Test.assert(WeatherParser.isValidCurrent(w));
    return true;
}

//! Missing or wrongly typed required data returns null instead of crashing.
(:test)
function parseCurrentRejectsDamagedReplies(logger as Logger) as Boolean {
    Test.assert(WeatherParser.parseCurrent(null, "X") == null);
    Test.assert(WeatherParser.parseCurrent({}, "X") == null);
    Test.assert(WeatherParser.parseCurrent({ "current" => "oops" }, "X") == null);
    var d = WeatherParserFixtures.sample();
    var current1 = d["current"] as Dictionary;
    current1["temperature_2m"] = null;
    Test.assert(WeatherParser.parseCurrent(d, "X") == null);
    d = WeatherParserFixtures.sample();
    var current2 = d["current"] as Dictionary;
    current2["wind_speed_10m"] = "fast";
    Test.assert(WeatherParser.parseCurrent(d, "X") == null);
    return true;
}

//! Optional fields fall back: gust to wind speed, others to their defaults.
(:test)
function parseCurrentDefaultsOptionalFields(logger as Logger) as Boolean {
    var d = WeatherParserFixtures.sample();
    var cur = d["current"] as Dictionary;
    cur.remove("wind_gusts_10m");
    cur["weather_code"] = "abc";
    cur.remove("is_day");
    var w = WeatherParser.parseCurrent(d, "X") as Array;
    Test.assertEqual(w[3], 3.5f);
    Test.assertEqual(w[7], 0);
    Test.assertEqual(w[8], 1);
    return true;
}

// MARK: - Forecast

//! The recorded reply parses into the documented 15-item layout, with rain
//! probability filled in and "Now" taken from current conditions.
(:test)
function parseForecastReadsRealReply(logger as Logger) as Boolean {
    var f = WeatherParserFixtures.forecastOf(WeatherParserFixtures.sample()) as Array;
    Test.assertEqual(f.size(), 15);
    var labels = f[1] as Array;
    Test.assertEqual(labels[0], "Now");
    Test.assertEqual(labels[1], "10p");
    Test.assertEqual(labels[3], "12a");
    Test.assertEqual((f[2] as Array)[0], 18);   // current 17.5 rounded, not hourly 17.8
    Test.assertEqual((f[2] as Array)[1], 17);
    Test.assert(f[3] != null);                   // rain probability is filled in
    Test.assertEqual((f[4] as Array)[0], "Today");
    Test.assertEqual((f[4] as Array)[1], "Fri");
    Test.assertEqual((f[5] as Array)[2], 27);
    Test.assertEqual((f[6] as Array)[0], 11);
    Test.assertEqual((f[9] as Array)[2], 6.2f);
    Test.assertEqual((f[10] as Array)[4], 55);
    Test.assertEqual((f[11] as Array)[2], 2);
    Test.assert(WeatherParser.isValidForecast(f));
    return true;
}

//! Missing or short required series return null instead of crashing.
(:test)
function parseForecastRejectsDamagedReplies(logger as Logger) as Boolean {
    var d = WeatherParserFixtures.sample();
    var hourly3 = d["hourly"] as Dictionary;
    hourly3["temperature_2m"] = [17.8, 17.3];
    Test.assert(WeatherParserFixtures.forecastOf(d) == null);
    d = WeatherParserFixtures.sample();
    (d["daily"] as Dictionary).remove("temperature_2m_min");
    Test.assert(WeatherParserFixtures.forecastOf(d) == null);
    d = WeatherParserFixtures.sample();
    d["hourly"] = [1, 2, 3];
    Test.assert(WeatherParserFixtures.forecastOf(d) == null);
    Test.assert(WeatherParser.parseForecastAt(null, "X", null, 0, 1) == null);
    return true;
}

//! Missing, short or non-numeric optional series become zeros.
(:test)
function parseForecastDefaultsOptionalSeries(logger as Logger) as Boolean {
    var d = WeatherParserFixtures.sample();
    var hourly = d["hourly"] as Dictionary;
    hourly.remove("weather_code");
    hourly["wind_speed_10m"] = [1.0];
    var daily4 = d["daily"] as Dictionary;
    daily4["precipitation_sum"] = ["a", null, 1, 2, 3];
    var f = WeatherParserFixtures.forecastOf(d) as Array;
    Test.assertEqual((f[11] as Array)[2], 0);
    Test.assertEqual((f[13] as Array)[0], 0.0f);
    Test.assertEqual((f[9] as Array)[0], 0.0f);
    Test.assertEqual((f[9] as Array)[2], 1.0f);
    return true;
}

//! Hour labels in 12-hour ("12a", "11p") and 24-hour ("14:00") style.
(:test)
function hourLabelsWrap(logger as Logger) as Boolean {
    Test.assertEqual(WeatherParser.hourLabel(0, false), "12a");
    Test.assertEqual(WeatherParser.hourLabel(12, false), "12p");
    Test.assertEqual(WeatherParser.hourLabel(3, false), "3a");
    Test.assertEqual(WeatherParser.hourLabel(23, false), "11p");
    Test.assertEqual(WeatherParser.hourLabel(0, true), "00:00");
    Test.assertEqual(WeatherParser.hourLabel(14, true), "14:00");
    return true;
}

// MARK: - Cache validation

//! Cached arrays from older versions or damaged Storage are rejected.
(:test)
function cacheValidationRejectsBadShapes(logger as Logger) as Boolean {
    Test.assert(!WeatherParser.isValidCurrent(null));
    Test.assert(!WeatherParser.isValidCurrent("text"));
    Test.assert(!WeatherParser.isValidCurrent([17.5, 18.0, 3.5, 11.5, 129, "X", 0.0]));
    Test.assert(!WeatherParser.isValidCurrent([17.5, 18.0, 3.5, 11.5, 129, 42, 0.0, 0, 1]));
    Test.assert(!WeatherParser.isValidForecast(null));
    Test.assert(!WeatherParser.isValidForecast([1, 2, 3]));
    return true;
}

//! A forecast with index 3 = null (as older versions stored) is still accepted,
//! but a missing daily series is not.
(:test)
function cacheValidationForecastRules(logger as Logger) as Boolean {
    var f = WeatherParserFixtures.forecastOf(WeatherParserFixtures.sample()) as Array;
    f[3] = null;
    Test.assert(WeatherParser.isValidForecast(f));
    f[9] = [1.0, 2.0];
    Test.assert(!WeatherParser.isValidForecast(f));
    return true;
}

// MARK: - Place names and positions

//! The most specific address field wins; display_name is the fallback.
(:test)
function placeNamePicksMostSpecific(logger as Logger) as Boolean {
    var reply = { "address" => { "suburb" => "Surry Hills", "city" => "Sydney" },
                  "display_name" => "Surry Hills, Sydney, NSW" };
    Test.assertEqual(WeatherParser.parsePlaceName(reply), "Surry Hills");
    Test.assertEqual(WeatherParser.parsePlaceName({ "address" => { "town" => "Bowral" } }), "Bowral");
    Test.assertEqual(WeatherParser.parsePlaceName({ "display_name" => "Lord Howe Island, NSW" }), "Lord Howe Island");
    return true;
}

//! Non-text, empty or missing names are rejected instead of crashing.
(:test)
function placeNameRejectsBadValues(logger as Logger) as Boolean {
    Test.assert(WeatherParser.parsePlaceName(null) == null);
    Test.assert(WeatherParser.parsePlaceName({}) == null);
    Test.assert(WeatherParser.parsePlaceName({ "address" => "oops", "display_name" => 42 }) == null);
    Test.assert(WeatherParser.parsePlaceName({ "address" => { "suburb" => 7 } }) == null);
    Test.assertEqual(WeatherParser.parsePlaceName({ "address" => { "suburb" => "", "town" => "Bowral" } }), "Bowral");
    Test.assert(WeatherParser.parsePlaceName({ "display_name" => ", NSW" }) == null);
    return true;
}

//! Very long names are cut to MAX_NAME_LENGTH characters.
(:test)
function placeNameIsCapped(logger as Logger) as Boolean {
    var longName = "Llanfairpwllgwyngyllgogerychwyrndrobwllllantysiliogogogoch";
    var name = WeatherParser.parsePlaceName({ "address" => { "village" => longName } }) as String;
    Test.assertEqual(name.length(), WeatherParser.MAX_NAME_LENGTH);
    return true;
}

//! Saved or system positions must be two in-range numbers.
(:test)
function positionValidation(logger as Logger) as Boolean {
    var ok = Coordinates.validOrNull([-33.87d, 151.21d]) as Array<Double>;
    Test.assertEqual(ok[0].format("%.2f"), "-33.87");
    Test.assert(Coordinates.validOrNull([-33.87, 151]) != null);
    Test.assert(Coordinates.validOrNull(null) == null);
    Test.assert(Coordinates.validOrNull([1.0d]) == null);
    Test.assert(Coordinates.validOrNull(["a", "b"]) == null);
    Test.assert(Coordinates.validOrNull([180.0d, 180.0d]) == null);
    Test.assert(Coordinates.validOrNull([10.0d, -181.0d]) == null);
    return true;
}
