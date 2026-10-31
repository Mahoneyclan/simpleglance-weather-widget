// WeatherSlots.mc — names for the positions in the cached weather arrays built
// by WeatherParser.mc. Used by the widget, the glance and the background
// refresh, so it is marked :glance and :background (constants only, so it adds
// little to the glance's memory).
//
// The order is stored on installed watches ("gps_weather", "home_forecast", …),
// so it is permanent: add new slots at the end.

import Toybox.Lang;

//! Array slot indexes; layouts are documented in WeatherParser.parseCurrent()
//! and WeatherParser.parseForecastAt().
(:glance, :background)
module WeatherSlots {

    //! Current conditions: temperature °C (Float).
    const CUR_TEMP = 0;
    //! Current conditions: feels-like °C (Float).
    const CUR_FEELS = 1;
    //! Current conditions: wind speed km/h (Float).
    const CUR_WIND = 2;
    //! Current conditions: wind gust km/h (Float).
    const CUR_GUST = 3;
    //! Current conditions: wind direction ° (Float).
    const CUR_WIND_DIR = 4;
    //! Current conditions: location name (String).
    const CUR_NAME = 5;
    //! Current conditions: rain mm (Float).
    const CUR_RAIN = 6;
    //! Current conditions: WMO weather code (Number).
    const CUR_CODE = 7;
    //! Current conditions: 1 by day, 0 by night (Number).
    const CUR_IS_DAY = 8;

    //! Forecast: location name (String).
    const FC_NAME = 0;
    //! Forecast: hour labels ×WeatherParser.HOURS.
    const FC_HOUR_LABELS = 1;
    //! Forecast: hourly temperature °C (Number) ×WeatherParser.HOURS.
    const FC_HOUR_TEMPS = 2;
    //! Forecast: hourly rain probability % (Number) ×WeatherParser.HOURS; null in data from old versions.
    const FC_HOUR_RAIN_PROB = 3;
    //! Forecast: day labels ×WeatherParser.DAYS.
    const FC_DAY_LABELS = 4;
    //! Forecast: daily maximum °C (Number) ×WeatherParser.DAYS.
    const FC_DAY_MAX = 5;
    //! Forecast: daily minimum °C (Number) ×WeatherParser.DAYS.
    const FC_DAY_MIN = 6;
    //! Forecast: daily rain mm (Float) ×WeatherParser.DAYS.
    const FC_DAY_RAIN = 9;
    //! Forecast: daily WMO code (Number) ×WeatherParser.DAYS.
    const FC_DAY_CODE = 10;
    //! Forecast: hourly WMO code (Number) ×WeatherParser.HOURS.
    const FC_HOUR_CODE = 11;
    //! Forecast: hourly rain mm (Float) ×WeatherParser.HOURS.
    const FC_HOUR_RAIN = 12;
    //! Forecast: hourly wind km/h (Float) ×WeatherParser.HOURS.
    const FC_HOUR_WIND = 13;
    //! Forecast: hourly wind direction ° (Number) ×WeatherParser.HOURS.
    const FC_HOUR_WIND_DIR = 14;
}
