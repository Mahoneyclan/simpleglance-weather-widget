// ForecastPages.mc — draws pages 1 (hourly) and 2 (daily) of the full-screen
// widget. Runs in the foreground (widget) process only. Drawing only; the data
// comes from WeatherData through WeatherView.

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

//! Hourly and daily forecast pages.
module ForecastPages {

    //! Vertical offset in pixels applied to both pages, to clear the round bezel at the top.
    const Y_OFFSET = 4;
    //! Text alignment used for every centred label.
    const CENTER = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
    //! Column centres of the hourly page as a fraction of the width, pulled inward
    //! to clear the round bezel at the bottom rows.
    const HOUR_COLUMNS = [0.18f, 0.38f, 0.62f, 0.82f];
    //! Row centres of the daily page as a fraction of the height.
    const DAY_ROWS = [0.20f, 0.34f, 0.48f, 0.62f, 0.76f];

    //! Draws the place name and a short rule under it, shared by both pages.
    //! @param dc The drawing context.
    //! @param name Location name.
    function drawHeader(dc as Dc, name as String) as Void {
        var W = dc.getWidth();
        var H = dc.getHeight();
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(W / 2, (H * 0.07).toNumber() + Y_OFFSET, Graphics.FONT_TINY, name, CENTER);
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        var y = (H * 0.13).toNumber() + Y_OFFSET;
        dc.drawLine((W * 0.22).toNumber(), y, (W * 0.78).toNumber(), y);
    }

    //! Draws the hourly page: for each of WeatherParser.HOURS columns, the hour,
    //! icon, temperature, rain mm, wind speed and compass direction. Icons are
    //! always the day variant (see README Known issues).
    //! @param dc The drawing context.
    //! @param fc A validated forecast array (WeatherSlots.FC_*).
    //! @param icons Bitmap cache.
    function drawHourly(dc as Dc, fc as Array, icons as IconCache) as Void {
        drawHeader(dc, fc[WeatherSlots.FC_NAME] as String);
        var W = dc.getWidth();
        var H = dc.getHeight();
        var labels = fc[WeatherSlots.FC_HOUR_LABELS] as Array;
        var temps  = fc[WeatherSlots.FC_HOUR_TEMPS] as Array;
        var codes  = fc[WeatherSlots.FC_HOUR_CODE] as Array;
        var rain   = fc[WeatherSlots.FC_HOUR_RAIN] as Array;
        var wind   = fc[WeatherSlots.FC_HOUR_WIND] as Array;
        var dirs   = fc[WeatherSlots.FC_HOUR_WIND_DIR] as Array;
        for (var i = 0; i < WeatherParser.HOURS; i++) {
            var x = (W * (HOUR_COLUMNS[i] as Float)).toNumber();
            dc.setColor((i == 0) ? Graphics.COLOR_WHITE : Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(x, row(H, 0.16f), Graphics.FONT_TINY, labels[i] as String, CENTER);
            drawIconAt(dc, icons.get(WeatherIcons.smallId(codes[i] as Number, true)), x, row(H, 0.27f));
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(x, row(H, 0.40f), Graphics.FONT_TINY, (temps[i] as Number).format("%d") + "°", CENTER);
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(x, row(H, 0.52f), Graphics.FONT_XTINY, (rain[i] as Numeric).toFloat().format("%.1f") + "mm", CENTER);
            dc.drawText(x, row(H, 0.63f), Graphics.FONT_XTINY, (wind[i] as Numeric).toFloat().format("%.0f") + "km", CENTER);
            dc.drawText(x, row(H, 0.74f), Graphics.FONT_XTINY,
                WeatherFormat.windDirName((dirs[i] as Numeric).toFloat()), CENTER);
        }
    }

    //! Draws the daily page: for each of WeatherParser.DAYS rows, the day name,
    //! icon, high/low and rain total.
    //! @param dc The drawing context.
    //! @param fc A validated forecast array (WeatherSlots.FC_*).
    //! @param icons Bitmap cache.
    function drawDaily(dc as Dc, fc as Array, icons as IconCache) as Void {
        drawHeader(dc, fc[WeatherSlots.FC_NAME] as String);
        var W = dc.getWidth();
        var H = dc.getHeight();
        var labels = fc[WeatherSlots.FC_DAY_LABELS] as Array;
        var maxT   = fc[WeatherSlots.FC_DAY_MAX] as Array;
        var minT   = fc[WeatherSlots.FC_DAY_MIN] as Array;
        var rain   = fc[WeatherSlots.FC_DAY_RAIN] as Array;
        var codes  = fc[WeatherSlots.FC_DAY_CODE] as Array;
        for (var i = 0; i < WeatherParser.DAYS; i++) {
            var y = row(H, DAY_ROWS[i] as Float);
            dc.setColor((i == 0) ? Graphics.COLOR_WHITE : Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText((W * 0.10).toNumber(), y, Graphics.FONT_XTINY, labels[i] as String,
                Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
            drawIconAt(dc, icons.get(WeatherIcons.smallId(codes[i] as Number, true)), (W * 0.36).toNumber(), y);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText((W * 0.62).toNumber() - 5, y, Graphics.FONT_XTINY,
                (maxT[i] as Number).format("%d") + "/" + (minT[i] as Number).format("%d") + "°", CENTER);
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText((W * 0.88).toNumber(), y, Graphics.FONT_XTINY,
                (rain[i] as Numeric).toFloat().format("%.1f") + "mm",
                Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    //! @param H Screen height in pixels.
    //! @param fraction Row centre as a fraction of the height.
    //! @return The row's y position, including Y_OFFSET.
    function row(H as Number, fraction as Float) as Number {
        return (H * fraction).toNumber() + Y_OFFSET;
    }

    //! Draws a bitmap centred on (x, y).
    //! @param dc The drawing context.
    //! @param bitmap The icon.
    //! @param x Centre x.
    //! @param y Centre y.
    function drawIconAt(dc as Dc, bitmap as WatchUi.BitmapResource, x as Number, y as Number) as Void {
        dc.drawBitmap(x - bitmap.getWidth() / 2, y - bitmap.getHeight() / 2, bitmap);
    }
}
