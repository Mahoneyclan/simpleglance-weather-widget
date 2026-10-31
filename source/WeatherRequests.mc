// WeatherRequests.mc — the two web requests the app makes: Open-Meteo weather
// and Nominatim place names. Used by the widget (WeatherData) and the background
// refresh (BackgroundService), so it is marked :background. Replies are parsed
// by WeatherParser.mc.
//
// Security: HTTPS only, and every coordinate goes through
// Coordinates.forRequest() (about 1 km). PRIVACY.md lists what is sent; update
// it if these requests change.

import Toybox.Communications;
import Toybox.Lang;

//! Request builders for both services.
(:background)
module WeatherRequests {

    //! Starts an Open-Meteo forecast request. forecast_days=5 gives today plus 4
    //! days. forecast_hours=6 limits the hourly arrays to 6 entries starting at the
    //! current hour (the parser uses the first 4) instead of whole days, which
    //! keeps the response small enough for the background process.
    //! Side effect: one web request.
    //! @param lat Latitude in decimal degrees.
    //! @param lon Longitude in decimal degrees.
    //! @param callback Receives (responseCode, data).
    function weather(lat as Float or Double, lon as Float or Double, callback as Method) as Void {
        Communications.makeWebRequest(
            "https://api.open-meteo.com/v1/forecast",
            {
                "latitude"        => Coordinates.forRequest(lat),
                "longitude"       => Coordinates.forRequest(lon),
                "current"         => "temperature_2m,apparent_temperature,wind_speed_10m,wind_direction_10m,wind_gusts_10m,precipitation,weather_code,is_day",
                "hourly"          => "temperature_2m,precipitation_probability,weather_code,precipitation,wind_speed_10m,wind_direction_10m",
                "daily"           => "temperature_2m_max,temperature_2m_min,wind_speed_10m_max,wind_direction_10m_dominant,precipitation_sum,weather_code",
                "wind_speed_unit" => "kmh",
                "forecast_days"   => "5",
                "forecast_hours"  => "6",
                "timezone"        => "auto"
            },
            { :method => Communications.HTTP_REQUEST_METHOD_GET },
            callback
        );
    }

    //! Starts a Nominatim (OpenStreetMap) reverse-geocode. zoom=14 asks for
    //! suburb-level detail. Nominatim's usage policy requires an identifying
    //! User-Agent (RequestHeaders.USER_AGENT).
    //! Side effect: one web request.
    //! @param lat Latitude in decimal degrees.
    //! @param lon Longitude in decimal degrees.
    //! @param callback Receives (responseCode, data).
    function placeName(lat as Float or Double, lon as Float or Double, callback as Method) as Void {
        Communications.makeWebRequest(
            "https://nominatim.openstreetmap.org/reverse",
            {
                "lat"    => Coordinates.forRequest(lat),
                "lon"    => Coordinates.forRequest(lon),
                "format" => "json",
                "zoom"   => "14"
            },
            {
                :method  => Communications.HTTP_REQUEST_METHOD_GET,
                :headers => { "User-Agent" => RequestHeaders.USER_AGENT }
            },
            callback
        );
    }
}
