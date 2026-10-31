// DisplayRulesTest.mc — unit tests for the widget's label formatting
// (WeatherFormat), unit conversion (Units), icon mapping (WeatherIcons), glance
// rules (GlanceRules) and status message resources. (:test) code is only compiled into unit-test builds
// (monkeyc --unit-test), never into the released app.

import Toybox.Lang;
import Toybox.Test;
import Toybox.WatchUi;

//! Each compass label covers 45° centred on its direction; values wrap.
(:test)
function windDirNameSectors(logger as Logger) as Boolean {
    var cases = [[0.0f, "N"], [22.0f, "N"], [23.0f, "NE"], [90.0f, "E"], [157.0f, "SE"],
                 [180.0f, "S"], [225.0f, "SW"], [292.0f, "W"], [293.0f, "NW"],
                 [337.0f, "NW"], [338.0f, "N"], [359.9f, "N"], [360.0f, "N"],
                 [450.0f, "E"], [-30.0f, "NW"], [-90.0f, "W"]];
    for (var i = 0; i < cases.size(); i++) {
        var c = cases[i] as Array;
        Test.assertEqualMessage(WeatherFormat.windDirName(c[0] as Float), c[1] as String,
            "bearing " + (c[0] as Float).format("%.1f"));
    }
    return true;
}

//! Clock times follow the watch's 12/24-hour setting.
(:test)
function clockTimeFormats(logger as Logger) as Boolean {
    Test.assertEqual(WeatherFormat.clockTime(14, 5, true), "14:05");
    Test.assertEqual(WeatherFormat.clockTime(0, 0, true), "00:00");
    Test.assertEqual(WeatherFormat.clockTime(14, 5, false), "2:05p");
    Test.assertEqual(WeatherFormat.clockTime(0, 30, false), "12:30a");
    Test.assertEqual(WeatherFormat.clockTime(12, 0, false), "12:00p");
    return true;
}

//! Weather codes map to the documented icons, including day/night variants,
//! freezing drizzle and rain shown as rain, and the clear-sky fallback for
//! unknown codes.
(:test)
function iconMapping(logger as Logger) as Boolean {
    Test.assert(WeatherIcons.largeId(0, true) == Rez.Drawables.clearsky_day);
    Test.assert(WeatherIcons.largeId(0, false) == Rez.Drawables.clearsky_night);
    Test.assert(WeatherIcons.largeId(2, false) == Rez.Drawables.partlycloudy_night);
    Test.assert(WeatherIcons.largeId(48, true) == Rez.Drawables.fog);
    Test.assert(WeatherIcons.largeId(55, true) == Rez.Drawables.lightrain);
    Test.assert(WeatherIcons.largeId(85, true) == Rez.Drawables.snow);
    Test.assert(WeatherIcons.largeId(86, true) == Rez.Drawables.heavysnow);
    Test.assert(WeatherIcons.largeId(99, true) == Rez.Drawables.heavyrainandthunder);
    Test.assert(WeatherIcons.largeId(56, true) == Rez.Drawables.lightrain);
    Test.assert(WeatherIcons.largeId(66, true) == Rez.Drawables.rain);
    Test.assert(WeatherIcons.largeId(67, false) == Rez.Drawables.heavyrain);
    Test.assert(WeatherIcons.smallId(57, true) == Rez.Drawables.lightrain_sm);
    Test.assert(WeatherIcons.smallId(67, true) == Rez.Drawables.heavyrain_sm);
    Test.assert(WeatherIcons.smallId(81, false) == Rez.Drawables.rainshowers_night_sm);
    Test.assert(WeatherIcons.smallId(63, true) == Rez.Drawables.rain_sm);
    Test.assert(WeatherIcons.smallId(1000, true) == Rez.Drawables.clearsky_day_sm);
    return true;
}

//! Every code group gets its documented glance colour.
(:test)
function glanceConditionColours(logger as Logger) as Boolean {
    Test.assertEqual(GlanceRules.conditionColor(0), 0xFFCC00);
    Test.assertEqual(GlanceRules.conditionColor(3), 0xAAAAAA);
    Test.assertEqual(GlanceRules.conditionColor(45), 0x888888);
    Test.assertEqual(GlanceRules.conditionColor(61), 0x4488FF);
    Test.assertEqual(GlanceRules.conditionColor(75), 0xCCEEFF);
    Test.assertEqual(GlanceRules.conditionColor(81), 0x2266CC);
    Test.assertEqual(GlanceRules.conditionColor(86), 0xCCEEFF);
    Test.assertEqual(GlanceRules.conditionColor(95), 0x9933CC);
    return true;
}

//! The glance draws only arrays with a numeric temperature, a String name and a
//! Number code; any other saved value, including a non-array, shows "--".
(:test)
function glanceDrawableCheck(logger as Logger) as Boolean {
    Test.assert(GlanceRules.isDrawable([20.5f, 0, 0, 0, 0, "Bondi", 0, 3]));
    Test.assert(GlanceRules.isDrawable([20, 0, 0, 0, 0, "Bondi", 0, 3, 1]));
    Test.assert(!GlanceRules.isDrawable(null));
    Test.assert(!GlanceRules.isDrawable([20.5f, 0, 0, 0, 0, "Bondi", 0]));
    Test.assert(!GlanceRules.isDrawable(["20", 0, 0, 0, 0, "Bondi", 0, 3]));
    Test.assert(!GlanceRules.isDrawable([20.5f, 0, 0, 0, 0, 7, 0, 3]));
    Test.assert(!GlanceRules.isDrawable([20.5f, 0, 0, 0, 0, "Bondi", 0, 3.0f]));
    Test.assert(!GlanceRules.isDrawable("Bondi"));
    Test.assert(!GlanceRules.isDrawable(20));
    Test.assert(!GlanceRules.isDrawable({"temp" => 20}));
    return true;
}

//! Multi-line status messages keep their line breaks after resource compilation.
(:test)
function statusMessagesHaveLineBreaks(logger as Logger) as Boolean {
    var ids = [Rez.Strings.WaitingGps, Rez.Strings.LoadingWeather,
               Rez.Strings.NoConnection, Rez.Strings.CheckHome];
    for (var i = 0; i < ids.size(); i++) {
        var text = WatchUi.loadResource(ids[i] as ResourceId) as String;
        Test.assertMessage(text.find("\n") != null, "no line break in: " + text);
    }
    return true;
}

//! Stored metric values convert to the watch's units: whole degrees, whole
//! speeds, rain with one decimal (mm) or two (inches).
(:test)
function unitConversions(logger as Logger) as Boolean {
    Test.assertEqual(Units.temperature(20, false), 20);
    Test.assertEqual(Units.temperature(21.6f, false), 22);
    Test.assertEqual(Units.temperature(20, true), 68);
    Test.assertEqual(Units.temperature(-40, true), -40);
    Test.assertEqual(Units.temperature(0, true), 32);
    Test.assertEqual(Units.speedText(10, false), "10");
    Test.assertEqual(Units.speedText(16.09344f, true), "10");
    Test.assertEqual(Units.speedText(0, true), "0");
    Test.assertEqual(Units.rainText(1.26f, false), "1.3");
    Test.assertEqual(Units.rainText(25.4f, true), "1.00");
    Test.assertEqual(Units.rainText(0, true), "0.00");
    return true;
}

//! Hourly headings count on from the fetch hour; the first is "Now" only while
//! it is still that hour, and 24-hour watches get "14:00"-style headings.
(:test)
function hourHeadingsFromFetchTime(logger as Logger) as Boolean {
    var h = WeatherFormat.hourHeadings(23, true, false, "Now", 4);
    Test.assertEqual(h.size(), 4);
    Test.assertEqual(h[0], "Now");
    Test.assertEqual(h[1], "12a");
    Test.assertEqual(h[3], "2a");
    h = WeatherFormat.hourHeadings(23, false, true, "Now", 4);
    Test.assertEqual(h[0], "23:00");
    Test.assertEqual(h[1], "00:00");
    return true;
}

//! Every code group gets a condition word, in the same groups as the colours,
//! so the glance never shows the condition by colour alone.
(:test)
function glanceConditionWords(logger as Logger) as Boolean {
    var cases = [[0, Rez.Strings.CondClear], [1, Rez.Strings.CondClear], [3, Rez.Strings.CondCloudy],
                 [45, Rez.Strings.CondFog], [57, Rez.Strings.CondRain], [67, Rez.Strings.CondRain],
                 [75, Rez.Strings.CondSnow], [81, Rez.Strings.CondShowers], [86, Rez.Strings.CondSnow],
                 [95, Rez.Strings.CondStorm], [99, Rez.Strings.CondStorm]];
    for (var i = 0; i < cases.size(); i++) {
        var c = cases[i] as Array;
        Test.assertMessage(GlanceRules.conditionWord(c[0] as Number) == c[1], "code " + c[0]);
    }
    return true;
}

//! The menu shows positions to 2 decimals; Home settings are saved to 5, which
//! never equals the legacy default text, so a Home saved at that spot is set.
(:test)
function homeHereFormats(logger as Logger) as Boolean {
    Test.assertEqual(WeatherFormat.positionText([-27.37052d, 152.86911d] as Array<Double>), "-27.37, 152.87");
    Test.assertEqual(WeatherFormat.settingText(-27.3705d), "-27.37050");
    Test.assertEqual(HomeSettings.homeStatus(WeatherFormat.settingText(-27.3705d),
        WeatherFormat.settingText(152.8691d)), HomeSettings.STATUS_SET);
    return true;
}
