// WeatherIcons.mc — maps Open-Meteo WMO weather codes to bundled icon bitmaps,
// and keeps loaded icons and page text so they are not reloaded on every redraw.
// Used by the full-screen widget only.
//
// Icon set: Met.no weathericons, sourced from BleachDev/Rainy (GPL-3.0).
//
// WMO codes used by Open-Meteo:
//   0        Clear sky
//   1/2/3    Mainly clear / partly cloudy / overcast
//   45/48    Fog / rime fog
//   51/53/55 Drizzle light/moderate/dense
//   56/57    Freezing drizzle            (shown as light rain; no freezing icon in the set)
//   61/63/65 Rain light/moderate/heavy
//   66/67    Freezing rain light/heavy   (shown as rain / heavy rain)
//   71/73/75 Snow light/moderate/heavy
//   77       Snow grains
//   80/81/82 Rain showers light/moderate/heavy
//   85/86    Snow showers light/heavy
//   95       Thunderstorm
//   96/99    Thunderstorm with hail

import Toybox.Lang;
import Toybox.WatchUi;

//! Weather-code-to-resource mapping. Kept separate from loading so it can be
//! unit tested (see source/test/DisplayRulesTest.mc).
module WeatherIcons {

    //! The 44×44 icon for a weather code, used in the centre of the
    //! current-conditions page. Any code not listed falls back to clear sky.
    //! @param code WMO weather code from Open-Meteo.
    //! @param isDay true for the day variant, false for night (only some icons differ).
    //! @return The drawable resource ID.
    function largeId(code as Number, isDay as Boolean) as ResourceId {
        if (code == 1)  { return isDay ? Rez.Drawables.fair_day : Rez.Drawables.fair_night; }
        if (code == 2)  { return isDay ? Rez.Drawables.partlycloudy_day : Rez.Drawables.partlycloudy_night; }
        if (code == 3)  { return Rez.Drawables.cloudy; }
        if (code == 45 || code == 48) { return Rez.Drawables.fog; }
        if (code == 51 || code == 53 || code == 55 || code == 56 || code == 57 || code == 61) { return Rez.Drawables.lightrain; }
        if (code == 63 || code == 66) { return Rez.Drawables.rain; }
        if (code == 65 || code == 67) { return Rez.Drawables.heavyrain; }
        if (code == 71 || code == 77) { return Rez.Drawables.lightsnow; }
        if (code == 73 || code == 85) { return Rez.Drawables.snow; }
        if (code == 75 || code == 86) { return Rez.Drawables.heavysnow; }
        if (code == 80) { return isDay ? Rez.Drawables.lightrainshowers_day : Rez.Drawables.lightrainshowers_night; }
        if (code == 81) { return isDay ? Rez.Drawables.rainshowers_day : Rez.Drawables.rainshowers_night; }
        if (code == 82) { return isDay ? Rez.Drawables.heavyrainshowers_day : Rez.Drawables.heavyrainshowers_night; }
        if (code == 95) { return Rez.Drawables.rainandthunder; }
        if (code == 96 || code == 99) { return Rez.Drawables.heavyrainandthunder; }
        return isDay ? Rez.Drawables.clearsky_day : Rez.Drawables.clearsky_night;
    }

    //! The 22×22 icon for a weather code, used on the hourly and daily pages.
    //! Same mapping and fallback as largeId().
    //! @param code WMO weather code from Open-Meteo.
    //! @param isDay true for the day variant, false for night.
    //! @return The drawable resource ID.
    function smallId(code as Number, isDay as Boolean) as ResourceId {
        if (code == 1)  { return isDay ? Rez.Drawables.fair_day_sm : Rez.Drawables.fair_night_sm; }
        if (code == 2)  { return isDay ? Rez.Drawables.partlycloudy_day_sm : Rez.Drawables.partlycloudy_night_sm; }
        if (code == 3)  { return Rez.Drawables.cloudy_sm; }
        if (code == 45 || code == 48) { return Rez.Drawables.fog_sm; }
        if (code == 51 || code == 53 || code == 55 || code == 56 || code == 57 || code == 61) { return Rez.Drawables.lightrain_sm; }
        if (code == 63 || code == 66) { return Rez.Drawables.rain_sm; }
        if (code == 65 || code == 67) { return Rez.Drawables.heavyrain_sm; }
        if (code == 71 || code == 77) { return Rez.Drawables.lightsnow_sm; }
        if (code == 73 || code == 85) { return Rez.Drawables.snow_sm; }
        if (code == 75 || code == 86) { return Rez.Drawables.heavysnow_sm; }
        if (code == 80) { return isDay ? Rez.Drawables.lightrainshowers_day_sm : Rez.Drawables.lightrainshowers_night_sm; }
        if (code == 81) { return isDay ? Rez.Drawables.rainshowers_day_sm : Rez.Drawables.rainshowers_night_sm; }
        if (code == 82) { return isDay ? Rez.Drawables.heavyrainshowers_day_sm : Rez.Drawables.heavyrainshowers_night_sm; }
        if (code == 95) { return Rez.Drawables.rainandthunder_sm; }
        if (code == 96 || code == 99) { return Rez.Drawables.heavyrainandthunder_sm; }
        return isDay ? Rez.Drawables.clearsky_day_sm : Rez.Drawables.clearsky_night_sm;
    }
}

//! Loads icon bitmaps and page text once and keeps them while the widget is on
//! screen. A page shows at most 9 icons of a few hundred bytes each and a few
//! short strings, so the cache stays small; WeatherView clears it in onHide().
class ResourceCache {

    //! Loaded resources by resource ID.
    private var loaded as Dictionary<ResourceId, Object> = {} as Dictionary<ResourceId, Object>;

    //! Creates an empty cache.
    function initialize() {
    }

    //! @param id A drawable resource ID from WeatherIcons.
    //! @return The bitmap, loaded from resources on first use.
    function bitmap(id as ResourceId) as WatchUi.BitmapResource {
        return load(id) as WatchUi.BitmapResource;
    }

    //! @param id A string resource ID (Rez.Strings).
    //! @return The text, loaded from resources on first use.
    function text(id as ResourceId) as String {
        return load(id) as String;
    }

    //! Drops every loaded resource.
    function clear() as Void {
        loaded = {} as Dictionary<ResourceId, Object>;
    }

    //! @param id Any resource ID.
    //! @return The resource, loaded on first use.
    private function load(id as ResourceId) as Object {
        var value = loaded[id];
        if (value == null) {
            value = WatchUi.loadResource(id) as Object;
            loaded[id] = value;
        }
        return value;
    }
}
