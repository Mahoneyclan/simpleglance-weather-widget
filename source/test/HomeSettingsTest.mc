// HomeSettingsTest.mc — unit tests for HomeSettings parsing and validation,
// and for the rounding of coordinates sent off the watch (Coordinates).
// (:test) code is only compiled into unit-test builds (monkeyc --unit-test),
// never into the released app. Run with: monkeydo <test.prg> fenix6pro -t

import Toybox.Lang;
import Toybox.Test;

//! A valid pair away from the defaults counts as set.
(:test)
function homeStatusValidPairIsSet(logger as Logger) as Boolean {
    Test.assertEqual(HomeSettings.homeStatus("-33.8688", "151.2093"), HomeSettings.STATUS_SET);
    return true;
}

//! The default Home of new installs (Brisbane CBD) is a real, set Home.
(:test)
function defaultHomeIsSet(logger as Logger) as Boolean {
    Test.assertEqual(HomeSettings.homeStatus(HomeSettings.DEFAULT_LAT, HomeSettings.DEFAULT_LON), HomeSettings.STATUS_SET);
    return true;
}

//! Both values blank (cleared by the user, or missing) counts as not set.
(:test)
function homeStatusBlankIsNotSet(logger as Logger) as Boolean {
    Test.assertEqual(HomeSettings.homeStatus("", ""), HomeSettings.STATUS_NOT_SET);
    Test.assertEqual(HomeSettings.homeStatus(null, null), HomeSettings.STATUS_NOT_SET);
    return true;
}

//! Only the exact legacy default text (shipped by versions before 1.5.0) counts
//! as not set; a Home near it, or the same place written differently, is set.
(:test)
function homeStatusDefaultsAreNotSet(logger as Logger) as Boolean {
    Test.assertEqual(HomeSettings.homeStatus("-27.3705", "152.8691"), HomeSettings.STATUS_NOT_SET);
    Test.assertEqual(HomeSettings.homeStatus("-27.375", "152.865"), HomeSettings.STATUS_SET);
    Test.assertEqual(HomeSettings.homeStatus("-27.37050", "152.86910"), HomeSettings.STATUS_SET);
    Test.assertEqual(HomeSettings.homeStatus("-27.3705", "152.87"), HomeSettings.STATUS_SET);
    return true;
}

//! Changing either value away from the legacy default counts as set.
(:test)
function homeStatusOneValueChangedIsSet(logger as Logger) as Boolean {
    Test.assertEqual(HomeSettings.homeStatus("-27.3705", "153.0"), HomeSettings.STATUS_SET);
    return true;
}

//! Text that is not a number is invalid (this used to crash the widget).
(:test)
function homeStatusTextIsInvalid(logger as Logger) as Boolean {
    Test.assertEqual(HomeSettings.homeStatus("abc", "151.2"), HomeSettings.STATUS_INVALID);
    Test.assertEqual(HomeSettings.homeStatus("-33.8", "east"), HomeSettings.STATUS_INVALID);
    return true;
}

//! Only one value filled in is invalid: a location needs both.
(:test)
function homeStatusOneBlankIsInvalid(logger as Logger) as Boolean {
    Test.assertEqual(HomeSettings.homeStatus("-33.8688", ""), HomeSettings.STATUS_INVALID);
    Test.assertEqual(HomeSettings.homeStatus("", "151.2093"), HomeSettings.STATUS_INVALID);
    return true;
}

//! Out-of-range values are invalid, and the range limits themselves are accepted.
(:test)
function homeStatusOutOfRangeIsInvalid(logger as Logger) as Boolean {
    Test.assertEqual(HomeSettings.homeStatus("91", "151.2"), HomeSettings.STATUS_INVALID);
    Test.assertEqual(HomeSettings.homeStatus("-33.8", "-180.5"), HomeSettings.STATUS_INVALID);
    Test.assertEqual(HomeSettings.homeStatus("90", "-180"), HomeSettings.STATUS_SET);
    return true;
}

//! parseCoordinate accepts numbers as well as strings, and rejects other types.
(:test)
function parseCoordinateTypes(logger as Logger) as Boolean {
    Test.assertEqual(HomeSettings.parseCoordinate(45, 90.0f), 45.0f);
    Test.assertEqual(HomeSettings.parseCoordinate(-12.5f, 90.0f), -12.5f);
    Test.assertEqual(HomeSettings.parseCoordinate("12.25", 90.0f), 12.25f);
    Test.assert(HomeSettings.parseCoordinate(true, 90.0f) == null);
    Test.assert(HomeSettings.parseCoordinate(null, 90.0f) == null);
    return true;
}

//! Coordinates sent to the web services are rounded to 2 decimal places (~1 km).
(:test)
function coordinatesAreRoundedForRequests(logger as Logger) as Boolean {
    Test.assertEqual(Coordinates.forRequest(-33.8688f), "-33.87");
    Test.assertEqual(Coordinates.forRequest(151.2093d), "151.21");
    Test.assertEqual(Coordinates.forRequest(-27.3705f), "-27.37");
    return true;
}

//! The saved GPS position is rounded to 2 decimal places (~1 km).
(:test)
function savedPositionIsRounded(logger as Logger) as Boolean {
    var r = Coordinates.rounded([-33.86882d, 151.20929d] as Array<Double>);
    Test.assertEqual((r[0] as Double).format("%.4f"), "-33.8700");
    Test.assertEqual((r[1] as Double).format("%.4f"), "151.2100");
    return true;
}
