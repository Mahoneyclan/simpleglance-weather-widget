// RequestHeaders.mc — the User-Agent sent with place-name requests. Used by
// WeatherRequests.mc, which the widget and the background refresh share, so it
// is marked :background.

import Toybox.Lang;

//! Identity sent with outgoing requests.
(:background)
module RequestHeaders {

    //! User-Agent for Nominatim. Its usage policy requires an application name and
    //! a contact. The version must match manifest.xml; update both on release.
    const USER_AGENT = "SimpleGlanceWeatherWidget/1.5.0 (+https://github.com/Mahoneyclan/simpleglance-weather-widget)";
}
