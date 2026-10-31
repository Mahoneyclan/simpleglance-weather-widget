// ForecastPages.mc — draws pages 1 (hourly) and 2 (daily) of the full-screen
// widget. Runs in the foreground (widget) process only. Drawing only; the data
// comes from WeatherData through WeatherView.

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
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
    //! The rule is decorative, so it stays dark grey.
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
    //! icon, temperature, rain, wind speed and compass direction, in the watch's
    //! units. Icons are always the day variant (see README Known issues).
    //! 24-hour headings ("14:00") are wider, so they use the smaller font.
    //! @param dc The drawing context.
    //! @param fc A validated forecast array (WeatherSlots.FC_*).
    //! @param res Bitmap and text cache.
    //! @param fetchTime Unix time the data was fetched, or null if unknown.
    function drawHourly(dc as Dc, fc as Array, res as ResourceCache, fetchTime as Number?) as Void {
        drawHeader(dc, fc[WeatherSlots.FC_NAME] as String);
        var W = dc.getWidth();
        var H = dc.getHeight();
        var is24 = System.getDeviceSettings().is24Hour;
        var labels = hourLabels(fc, res, fetchTime, is24);
        var temps  = fc[WeatherSlots.FC_HOUR_TEMPS] as Array;
        var codes  = fc[WeatherSlots.FC_HOUR_CODE] as Array;
        var rain   = fc[WeatherSlots.FC_HOUR_RAIN] as Array;
        var wind   = fc[WeatherSlots.FC_HOUR_WIND] as Array;
        var dirs   = fc[WeatherSlots.FC_HOUR_WIND_DIR] as Array;
        var f = Units.fahrenheit();
        var s = Units.statute();
        var rainUnit = res.text(s ? Rez.Strings.UnitInch : Rez.Strings.UnitMm);
        var windUnit = res.text(s ? Rez.Strings.UnitMph : Rez.Strings.UnitKmh);
        for (var i = 0; i < WeatherParser.HOURS; i++) {
            var x = (W * (HOUR_COLUMNS[i] as Float)).toNumber();
            dc.setColor((i == 0) ? Graphics.COLOR_WHITE : Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(x, row(H, 0.16f), is24 ? Graphics.FONT_XTINY : Graphics.FONT_TINY, labels[i], CENTER);
            drawIconAt(dc, res.bitmap(WeatherIcons.smallId(codes[i] as Number, true)), x, row(H, 0.27f));
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(x, row(H, 0.40f), Graphics.FONT_TINY,
                Units.temperature(temps[i] as Number, f).format("%d") + "°", CENTER);
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(x, row(H, 0.52f), Graphics.FONT_XTINY, Units.rainText(rain[i] as Numeric, s) + rainUnit, CENTER);
            dc.drawText(x, row(H, 0.63f), Graphics.FONT_XTINY, Units.speedText(wind[i] as Numeric, s) + windUnit, CENTER);
            dc.drawText(x, row(H, 0.74f), Graphics.FONT_XTINY,
                WeatherFormat.windDirName((dirs[i] as Numeric).toFloat()), CENTER);
        }
    }

    //! Draws the daily page: for each of WeatherParser.DAYS rows, the day name,
    //! icon, high/low and rain total, in the watch's units.
    //! @param dc The drawing context.
    //! @param fc A validated forecast array (WeatherSlots.FC_*).
    //! @param res Bitmap and text cache.
    //! @param fetchTime Unix time the data was fetched, or null if unknown.
    function drawDaily(dc as Dc, fc as Array, res as ResourceCache, fetchTime as Number?) as Void {
        drawHeader(dc, fc[WeatherSlots.FC_NAME] as String);
        var W = dc.getWidth();
        var H = dc.getHeight();
        var labels = dayLabels(fc, res, fetchTime);
        var maxT   = fc[WeatherSlots.FC_DAY_MAX] as Array;
        var minT   = fc[WeatherSlots.FC_DAY_MIN] as Array;
        var rain   = fc[WeatherSlots.FC_DAY_RAIN] as Array;
        var codes  = fc[WeatherSlots.FC_DAY_CODE] as Array;
        var f = Units.fahrenheit();
        var s = Units.statute();
        var rainUnit = res.text(s ? Rez.Strings.UnitInch : Rez.Strings.UnitMm);
        for (var i = 0; i < WeatherParser.DAYS; i++) {
            var y = row(H, DAY_ROWS[i] as Float);
            dc.setColor((i == 0) ? Graphics.COLOR_WHITE : Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText((W * 0.10).toNumber(), y, Graphics.FONT_XTINY, labels[i],
                Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
            drawIconAt(dc, res.bitmap(WeatherIcons.smallId(codes[i] as Number, true)), (W * 0.36).toNumber(), y);
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText((W * 0.62).toNumber() - 5, y, Graphics.FONT_XTINY,
                Units.temperature(maxT[i] as Number, f).format("%d") + "/"
                    + Units.temperature(minT[i] as Number, f).format("%d") + "°", CENTER);
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText((W * 0.88).toNumber(), y, Graphics.FONT_XTINY,
                Units.rainText(rain[i] as Numeric, s) + rainUnit,
                Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    //! Hour headings from the fetch time (WeatherFormat.hourHeadings()), or the
    //! labels stored with the data when the fetch time is unknown (older versions).
    //! @param fc A validated forecast array.
    //! @param res Text cache.
    //! @param fetchTime Unix time the data was fetched, or null.
    //! @param is24 true when the watch is set to 24-hour time.
    //! @return One heading per hourly column.
    function hourLabels(fc as Array, res as ResourceCache, fetchTime as Number?, is24 as Boolean) as Array<String> {
        if (fetchTime == null) { return fc[WeatherSlots.FC_HOUR_LABELS] as Array<String>; }
        var fetched = Gregorian.info(new Time.Moment(fetchTime), Time.FORMAT_SHORT);
        var now = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var stillThatHour = fetched.day == now.day && fetched.hour == now.hour;
        return WeatherFormat.hourHeadings(fetched.hour as Number, stillThatHour, is24,
            res.text(Rez.Strings.Now), WeatherParser.HOURS);
    }

    //! Day headings from the fetch date, in the watch's language. "Today" goes on
    //! the row that is today, so older data is never labelled as today's. Falls back
    //! to the stored labels when the fetch time is unknown (older versions).
    //! Each day is taken at noon, so a daylight-saving change cannot skip a day.
    //! @param fc A validated forecast array.
    //! @param res Text cache.
    //! @param fetchTime Unix time the data was fetched, or null.
    //! @return One heading per daily row.
    function dayLabels(fc as Array, res as ResourceCache, fetchTime as Number?) as Array<String> {
        if (fetchTime == null) { return fc[WeatherSlots.FC_DAY_LABELS] as Array<String>; }
        var fetched = Gregorian.info(new Time.Moment(fetchTime), Time.FORMAT_SHORT);
        var noon = fetchTime - (fetched.hour as Number) * 3600 - (fetched.min as Number) * 60
            - (fetched.sec as Number) + 12 * 3600;
        var today = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var out = new [WeatherParser.DAYS] as Array<String>;
        for (var i = 0; i < WeatherParser.DAYS; i++) {
            var day = Gregorian.info(new Time.Moment(noon + i * 86400), Time.FORMAT_MEDIUM);
            // Day of month alone is enough: the rows span only DAYS days.
            out[i] = (day.day == today.day) ? res.text(Rez.Strings.Today) : day.day_of_week as String;
        }
        return out;
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
