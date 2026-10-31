// WeatherGlanceView.mc — the compact strip shown in the watch's glance list.
// Runs in the glance process, which has a much smaller memory budget than the
// widget. It only reads Storage written by the widget or background refresh;
// it never fetches data itself.

import Toybox.Application;
import Toybox.Application.Storage;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

//! Glance strip: two columns separated by a vertical divider.
//! Left = GPS location, right = Home, the same order as the widget's location
//! dots. Each column shows the location name, the current temperature in the
//! watch's unit and a condition word, with a condition-coloured dot when it fits.
//! The word is there so the condition is never shown by colour alone.
//! Draws no bitmaps, to stay within the glance's small memory budget.
(:glance)
class WeatherGlanceView extends WatchUi.GlanceView {

    //! Creates the glance view; it holds no state of its own.
    function initialize() {
        GlanceView.initialize();
    }

    //! Draws both columns from the cached "home_weather" and "gps_weather" Storage entries.
    //! @param dc The drawing context for the glance area.
    function onUpdate(dc as Dc) as Void {
        GlanceView.onUpdate(dc);
        var W = dc.getWidth();
        var H = dc.getHeight();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        var home = Storage.getValue(WeatherState.WEATHER_KEYS[WeatherState.HOME] as String);
        var gps  = Storage.getValue(WeatherState.WEATHER_KEYS[WeatherState.GPS] as String);

        // Vertical centre divider
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(W / 2, 0, W / 2, H);

        drawColumn(dc, W, H, gps,  W / 4);      // left: GPS
        drawColumn(dc, W, H, home, W * 3 / 4);  // right: Home
    }

    //! Draws one location column, or "--" when there is no usable cached data.
    //! @param dc The drawing context.
    //! @param W Glance width in pixels.
    //! @param H Glance height in pixels.
    //! @param data The raw Storage value: normally a current-conditions array
    //!   (layout in WeatherParser.parseCurrent()), but checked before use.
    //! @param cx Horizontal centre of the column in pixels.
    private function drawColumn(dc as Dc, W as Number, H as Number,
                                data as Object?, cx as Number) as Void {
        if (!GlanceRules.isDrawable(data)) {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, H / 2, Graphics.FONT_XTINY, "--",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            return;
        }

        var w     = data as Array;
        var wcode = w[WeatherSlots.CUR_CODE] as Number;
        var temp  = Units.temperature(w[WeatherSlots.CUR_TEMP] as Numeric, Units.fahrenheit()).format("%d") + "°";
        var word  = WatchUi.loadResource(GlanceRules.conditionWord(wcode)) as String;
        var name  = w[WeatherSlots.CUR_NAME] as String;

        // Location name — centred, upper third
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, (H * 0.22).toNumber(), Graphics.FONT_XTINY, name,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        drawConditionLine(dc, W, H, cx, temp, word, wcode);
    }

    //! Draws the lower line, centred as a group: [dot] temperature word. The dot
    //! is dropped when the group would not fit the column; the word stays.
    //! @param dc The drawing context.
    //! @param W Glance width in pixels.
    //! @param H Glance height in pixels.
    //! @param cx Horizontal centre of the column in pixels.
    //! @param temp Temperature text, for example "21°".
    //! @param word Condition word, for example "Rain".
    //! @param wcode WMO weather code, for the dot colour.
    private function drawConditionLine(dc as Dc, W as Number, H as Number, cx as Number,
                                       temp as String, word as String, wcode as Number) as Void {
        var y = (H * 0.65).toNumber();
        var gap = 4;
        var dotR = H / 6;
        var tempW = dc.getTextWidthInPixels(temp, Graphics.FONT_SMALL);
        var wordW = dc.getTextWidthInPixels(word, Graphics.FONT_XTINY);
        var textW = tempW + gap + wordW;
        var withDot = textW + 2 * dotR + gap <= W / 2 - 2 * gap;
        var x = cx - (withDot ? textW + 2 * dotR + gap : textW) / 2;
        if (withDot) {
            dc.setColor(GlanceRules.conditionColor(wcode), Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(x + dotR, y, dotR);
            x += 2 * dotR + gap;
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, Graphics.FONT_SMALL, temp, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x + tempW + gap, y, Graphics.FONT_XTINY, word,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}

//! Pure rules for the glance, kept apart from drawing so they can be unit
//! tested (see source/test/DisplayRulesTest.mc).
(:glance)
module GlanceRules {

    //! Checks the fields this view reads from a cached value. Done here rather
    //! than with WeatherParser.isValidCurrent() so the glance process does not
    //! have to load the parser (the glance memory budget is small).
    //! Security: Storage contents are untrusted and `as` casts are not checked at
    //! run time, so the type is tested before anything is read.
    //! @param data The raw Storage value, of any type.
    //! @return true if it is an array whose temperature is a number, name a String
    //!   and weather code a Number.
    function isDrawable(data as Object?) as Boolean {
        var a = Values.arrayOrNull(data, WeatherSlots.CUR_CODE + 1);
        if (a == null || !Values.isNumeric(a[WeatherSlots.CUR_TEMP])) { return false; }
        if (a[WeatherSlots.CUR_NAME] instanceof String && a[WeatherSlots.CUR_CODE] instanceof Number) { return true; }
        return false;
    }

    //! Maps a WMO weather code to a short condition word, using the same groups
    //! as conditionColor(), so the word and the dot always agree.
    //! @param code WMO weather code from Open-Meteo.
    //! @return A glance-scoped string resource (Rez.Strings.Cond*).
    function conditionWord(code as Number) as ResourceId {
        if (code <= 1)  { return Rez.Strings.CondClear; }
        if (code <= 3)  { return Rez.Strings.CondCloudy; }
        if (code <= 48) { return Rez.Strings.CondFog; }
        if (code <= 67) { return Rez.Strings.CondRain; }
        if (code <= 77) { return Rez.Strings.CondSnow; }
        if (code <= 82) { return Rez.Strings.CondShowers; }
        if (code <= 86) { return Rez.Strings.CondSnow; }
        return Rez.Strings.CondStorm;
    }

    //! Maps a WMO weather code to a dot colour. Ranges follow the WMO code groups
    //! listed in WeatherIcons.mc.
    //! @param code WMO weather code from Open-Meteo.
    //! @return An RGB colour.
    function conditionColor(code as Number) as Number {
        if (code <= 1)                          { return 0xFFCC00; }  // clear — yellow
        if (code <= 3)                          { return 0xAAAAAA; }  // cloudy — grey
        if (code <= 48)                         { return 0x888888; }  // fog — dark grey
        if (code <= 67)                         { return 0x4488FF; }  // rain/drizzle — blue
        if (code <= 77)                         { return 0xCCEEFF; }  // snow — light blue
        if (code <= 82)                         { return 0x2266CC; }  // showers — deep blue
        if (code <= 86)                         { return 0xCCEEFF; }  // snow showers — light blue
        return 0x9933CC;                                              // thunder — purple
    }
}
