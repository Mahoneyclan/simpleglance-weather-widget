// HomeSettings.mc — the single place that reads and validates the Home
// latitude/longitude settings. Used by the widget (WeatherData) and the
// background refresh (BackgroundService), so it is marked :background.
//
// Security: settings are typed by the user in Garmin Connect as free text, so
// they are treated as untrusted. Anything that is not a number in range is
// rejected here instead of crashing the caller or being sent to the APIs.

import Toybox.Application;
import Toybox.Lang;

//! Home location settings: parsing, validation and "is Home set?" rules.
(:background)
module HomeSettings {

    //! Home settings are blank or still at the legacy defaults: Home mirrors GPS.
    const STATUS_NOT_SET = 0;
    //! Both values are valid and differ from the legacy defaults: Home is fetched.
    const STATUS_SET = 1;
    //! At least one value is present but not a number in range (or only one is
    //! filled in). Treated like STATUS_NOT_SET for fetching; the Home page shows a
    //! "Check Home settings" message.
    const STATUS_INVALID = 2;

    //! Home latitude text that versions before 1.5.0 shipped in
    //! resources/properties.xml. Watches that installed one of those versions and
    //! never changed it still hold exactly this text, so it keeps meaning "Home not
    //! set" (see homeStatus()). Only the exact text counts: a Home typed or saved
    //! near it (for example by someone who lives there) is a real Home.
    const LEGACY_DEFAULT_LAT = "-27.3705";
    //! Legacy default Home longitude text; see LEGACY_DEFAULT_LAT.
    const LEGACY_DEFAULT_LON = "152.8691";

    //! Default Home of new installs: Brisbane CBD. Must match the home_lat/home_lon
    //! defaults in resources/properties.xml; a public place, not anyone's home.
    const DEFAULT_LAT = "-27.4698";
    //! Default Home longitude; see DEFAULT_LAT.
    const DEFAULT_LON = "153.0251";


    //! Parses one coordinate setting. Properties are strings because Connect IQ
    //! settings only offer alphaNumeric input for decimals; numbers are accepted too.
    //! @param value The raw property value (String, Number, Float, Double or null).
    //! @param limit The allowed magnitude: 90 for latitude, 180 for longitude.
    //! @return The value in decimal degrees, or null if it is missing, not a
    //!   number, or outside -limit…limit.
    function parseCoordinate(value as Object?, limit as Float) as Float? {
        var f = null;
        if (value instanceof String) {
            f = value.toFloat();
        } else if (value instanceof Number || value instanceof Float || value instanceof Double) {
            f = value.toFloat();
        }
        // Written as !(in range) so a NaN result is rejected too.
        if (f == null || !(f >= -limit && f <= limit)) { return null; }
        return f;
    }

    //! Classifies a pair of raw Home settings. Kept free of Properties access so it
    //! can be unit tested (see source/test/HomeSettingsTest.mc).
    //! @param latValue Raw latitude property value.
    //! @param lonValue Raw longitude property value.
    //! @return STATUS_NOT_SET, STATUS_SET or STATUS_INVALID.
    function homeStatus(latValue as Object?, lonValue as Object?) as Number {
        if (isBlank(latValue) && isBlank(lonValue)) { return STATUS_NOT_SET; }
        var lat = parseCoordinate(latValue, 90.0f);
        var lon = parseCoordinate(lonValue, 180.0f);
        if (lat == null || lon == null) { return STATUS_INVALID; }
        var legacy = latValue instanceof String && lonValue instanceof String
            && latValue.equals(LEGACY_DEFAULT_LAT) && lonValue.equals(LEGACY_DEFAULT_LON);
        return legacy ? STATUS_NOT_SET : STATUS_SET;
    }

    //! @return The status of the current Home settings (reads Properties).
    function status() as Number {
        return homeStatus(Application.Properties.getValue("home_lat"),
                          Application.Properties.getValue("home_lon"));
    }

    //! @return true if Home settings are valid and differ from the legacy defaults, so
    //!   Home weather should be fetched.
    function isConfigured() as Boolean {
        return status() == STATUS_SET;
    }

    //! Home latitude for fetching. Only meaningful when isConfigured() is true.
    //! @return Latitude in decimal degrees, or 0 if the setting is not valid. The
    //!   fallback is deliberately not a real home location (privacy).
    function lat() as Float {
        var v = parseCoordinate(Application.Properties.getValue("home_lat"), 90.0f);
        return (v != null) ? v : 0.0f;
    }

    //! Home longitude for fetching. Only meaningful when isConfigured() is true.
    //! @return Longitude in decimal degrees, or 0 if the setting is not valid; see lat().
    function lon() as Float {
        var v = parseCoordinate(Application.Properties.getValue("home_lon"), 180.0f);
        return (v != null) ? v : 0.0f;
    }

    //! @param value A raw property value.
    //! @return true if the value is null or an empty string (the user cleared it).
    function isBlank(value as Object?) as Boolean {
        return value == null || (value instanceof String && value.length() == 0);
    }
}
