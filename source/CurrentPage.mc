// CurrentPage.mc — draws page 0 of the full-screen widget: current conditions.
// Runs in the foreground (widget) process only. Drawing only; the data comes
// from WeatherData through WeatherView.

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;

//! Current-conditions page: three sectors divided by clock-hand lines. Values
//! are stored in metric and shown in the watch's units (Units.mc).
//!   Top (9:30→12→2:30)         : location name, H, current temp, L, feels-like
//!   Centre                     : condition icon in a dark circle
//!   Bottom-right quadrant (3→6): wind speed, gust + compass direction
//!   Bottom-left  quadrant (6→9): rain amount + probability
module CurrentPage {

    //! Gap in pixels between the screen centre and the start of each dividing
    //! line. Matches the icon circle radius for a 44 px icon (44/2 + 8).
    const CENTRE_GAP = 30;
    //! Text alignment used for every centred label.
    const CENTER = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;

    //! Draws the page. Rain probability and today's high/low come from the forecast.
    //! @param dc The drawing context.
    //! @param w A validated current-conditions array (WeatherSlots.CUR_*).
    //! @param forecast The matching validated forecast, or null.
    //! @param res Bitmap and text cache.
    function draw(dc as Dc, w as Array, forecast as Array?, res as ResourceCache) as Void {
        var f = Units.fahrenheit();
        var temp = Math.round((w[WeatherSlots.CUR_TEMP] as Numeric).toFloat()).toNumber();
        var hiLo = highLow(forecast, temp);
        drawDividers(dc);
        drawTemperature(dc, w[WeatherSlots.CUR_NAME] as String,
            [Units.temperature(w[WeatherSlots.CUR_TEMP] as Numeric, f),
             Units.temperature(hiLo[0], f), Units.temperature(hiLo[1], f)] as Array<Number>,
            res.text(f ? Rez.Strings.UnitFahrenheit : Rez.Strings.UnitCelsius), res);
        drawIcon(dc, w, res, f);
        drawRain(dc, w[WeatherSlots.CUR_RAIN] as Numeric, rainProbability(forecast), res);
        drawWind(dc, w[WeatherSlots.CUR_WIND] as Numeric, w[WeatherSlots.CUR_GUST] as Numeric,
            (w[WeatherSlots.CUR_WIND_DIR] as Numeric).toFloat(), res);
    }

    //! @param forecast A validated forecast array, or null.
    //! @param temp The current temperature, used when there is no forecast.
    //! @return [high, low] for today.
    function highLow(forecast as Array?, temp as Number) as Array<Number> {
        if (forecast == null) { return [temp, temp] as Array<Number>; }
        var maxT = forecast[WeatherSlots.FC_DAY_MAX] as Array;
        var minT = forecast[WeatherSlots.FC_DAY_MIN] as Array;
        return [maxT[0] as Number, minT[0] as Number] as Array<Number>;
    }

    //! @param forecast A validated forecast array, or null.
    //! @return This hour's rain probability in %, or 0 if unknown (old cached data has none).
    function rainProbability(forecast as Array?) as Number {
        if (forecast == null) { return 0; }
        var probs = forecast[WeatherSlots.FC_HOUR_RAIN_PROB] as Array?;
        return (probs != null) ? probs[0] as Number : 0;
    }

    //! Draws the three dividing lines at the 2:30, 6:00 and 9:30 clock positions.
    //! sin(75°)=0.966 and cos(75°)=0.259 give the 2:30 and 9:30 directions; the
    //! lines reach 92% of the half-width. They are decorative (the text alone
    //! carries the meaning), so they stay dark grey.
    //! @param dc The drawing context.
    function drawDividers(dc as Dc) as Void {
        var W = dc.getWidth();
        var cx = W / 2;
        var cy = dc.getHeight() / 2;
        var R    = (W * 0.46f).toNumber();
        var dx   = (R * 0.966f).toNumber();
        var dy   = (R * 0.259f).toNumber();
        var gapX = (CENTRE_GAP * 0.966f).toNumber();
        var gapY = (CENTRE_GAP * 0.259f).toNumber();
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(cx + gapX, cy - gapY, cx + dx, cy - dy);   // 2:30
        dc.drawLine(cx, cy + CENTRE_GAP, cx, cy + R);          // 6:00
        dc.drawLine(cx - gapX, cy - gapY, cx - dx, cy - dy);   // 9:30
    }

    //! Draws the top sector: place name, then the temperature in large digits
    //! with a superscript unit, flanked by today's high and low.
    //! @param dc The drawing context.
    //! @param name Location name.
    //! @param temps [current, high, low] in the display unit.
    //! @param unit "°C" or "°F".
    //! @param res Text cache.
    function drawTemperature(dc as Dc, name as String, temps as Array<Number>, unit as String,
                             res as ResourceCache) as Void {
        var W = dc.getWidth();
        var H = dc.getHeight();
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(W / 2, (H * 0.10).toNumber(), Graphics.FONT_TINY, name, CENTER);

        var tempStr = temps[0].format("%d");
        var numW = dc.getTextWidthInPixels(tempStr, Graphics.FONT_NUMBER_MEDIUM);
        var unitW = dc.getTextWidthInPixels(unit, Graphics.FONT_SMALL);
        var numX = (W - numW - unitW) / 2;
        var numY = (H * 0.25).toNumber();
        dc.drawText(numX - 6, numY, Graphics.FONT_TINY, res.text(Rez.Strings.High) + temps[1].format("%d") + "°",
            Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(numX + numW + unitW + 6, numY, Graphics.FONT_TINY, res.text(Rez.Strings.Low) + temps[2].format("%d") + "°",
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(numX, numY, Graphics.FONT_NUMBER_MEDIUM, tempStr,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(numX + numW + 2, numY - (H * 0.05).toNumber(), Graphics.FONT_SMALL, unit,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    //! Draws the condition icon in a dark circle with an arc around its lower
    //! half, then the feels-like temperature just above it.
    //! @param dc The drawing context.
    //! @param w The current-conditions array.
    //! @param res Bitmap and text cache.
    //! @param f true to show the feels-like temperature in °F.
    function drawIcon(dc as Dc, w as Array, res as ResourceCache, f as Boolean) as Void {
        var cx = dc.getWidth() / 2;
        var cy = dc.getHeight() / 2;
        var isDay = (w[WeatherSlots.CUR_IS_DAY] as Number) != 0;
        var icon = res.bitmap(WeatherIcons.largeId(w[WeatherSlots.CUR_CODE] as Number, isDay));
        var iW = icon.getWidth();
        var iH = icon.getHeight();
        var circR = (iW > iH ? iW : iH) / 2 + 8;
        dc.setColor(0x1E1E1E, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, circR);
        // Garmin arc angles: 0° = 3 o'clock, counter-clockwise positive. 2:30 is
        // 15° and 9:30 is 165°; clockwise from 15° to 165° passes through 6 o'clock.
        dc.setColor(0x484848, Graphics.COLOR_TRANSPARENT);
        dc.drawArc(cx, cy, circR, Graphics.ARC_CLOCKWISE, 15, 165);
        dc.drawBitmap(cx - iW / 2, cy - iH / 2, icon);

        var feels = Units.temperature(w[WeatherSlots.CUR_FEELS] as Numeric, f);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, (dc.getHeight() * 0.37).toNumber(), Graphics.FONT_XTINY,
            res.text(Rez.Strings.Feels) + " " + feels.format("%d")
                + res.text(f ? Rez.Strings.UnitFahrenheit : Rez.Strings.UnitCelsius), CENTER);
    }

    //! Draws the bottom-left quadrant: rain this hour and its probability.
    //! @param dc The drawing context.
    //! @param rain Rain in mm (converted to inches when the watch uses miles).
    //! @param prob Probability in %.
    //! @param res Text cache.
    function drawRain(dc as Dc, rain as Numeric, prob as Number, res as ResourceCache) as Void {
        var W = dc.getWidth();
        var s = Units.statute();
        drawQuadrant(dc, (W * 0.06).toNumber(), Graphics.TEXT_JUSTIFY_LEFT, (W * 0.25).toNumber(),
            res.text(Rez.Strings.Rain),
            Units.rainText(rain, s) + " " + res.text(s ? Rez.Strings.UnitInch : Rez.Strings.UnitMm),
            res.text(Rez.Strings.Chance) + " " + prob.format("%d") + "%");
    }

    //! Draws the bottom-right quadrant: wind speed, gust and compass direction.
    //! @param dc The drawing context.
    //! @param speed Wind speed km/h (converted to mph when the watch uses miles).
    //! @param gust Gust km/h, converted the same way.
    //! @param dir Direction in degrees the wind blows from.
    //! @param res Text cache.
    function drawWind(dc as Dc, speed as Numeric, gust as Numeric, dir as Float, res as ResourceCache) as Void {
        var W = dc.getWidth();
        var s = Units.statute();
        drawQuadrant(dc, (W * 0.94).toNumber(), Graphics.TEXT_JUSTIFY_RIGHT, (W * 0.75).toNumber(),
            res.text(Rez.Strings.Wind),
            Units.speedText(speed, s) + " " + res.text(s ? Rez.Strings.UnitMph : Rez.Strings.UnitKmh),
            res.text(Rez.Strings.Gust) + " " + Units.speedText(gust, s) + "  " + WeatherFormat.windDirName(dir));
    }

    //! Draws one lower quadrant: a heading near the edge, a value and a detail line.
    //! @param dc The drawing context.
    //! @param titleX Heading x position.
    //! @param titleAlign Heading justification (left or right).
    //! @param x Centre x of the value and detail lines.
    //! @param title Heading text.
    //! @param value Main value text.
    //! @param detail Detail text.
    function drawQuadrant(dc as Dc, titleX as Number, titleAlign as Number, x as Number,
                          title as String, value as String, detail as String) as Void {
        var H = dc.getHeight();
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(titleX, (H * 0.58).toNumber() - 5, Graphics.FONT_TINY, title,
            titleAlign | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(x, (H * 0.77).toNumber(), Graphics.FONT_XTINY, detail, CENTER);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, (H * 0.68).toNumber(), Graphics.FONT_SMALL, value, CENTER);
    }
}
