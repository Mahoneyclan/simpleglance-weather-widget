// WeatherView.mc — the full-screen widget view: which page and location are
// shown, status messages and the location dots. Runs in the foreground (widget)
// process only. Data comes from WeatherData; the pages are drawn by
// CurrentPage and ForecastPages.

import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

//! Full-screen weather view with three pages, each shown for the active location
//! (GPS or Home, toggled by SELECT in WeatherDelegate):
//!   0 = current conditions
//!   1 = hourly forecast (Now + 3 hours)
//!   2 = daily forecast (Today + 4 days)
class WeatherView extends WatchUi.View {

    //! Number of pages.
    private const PAGE_COUNT = 3;

    //! Storage, settings, requests and timers, shared with data.
    private var services as WatchServices = new WatchServices();
    //! Weather for both locations.
    private var data as WeatherData = new WeatherData(services);
    //! Icon bitmaps and page text, kept while the widget is on screen.
    private var res as ResourceCache = new ResourceCache();
    //! Active page, 0…PAGE_COUNT-1.
    private var pageIndex as Number = 0;
    //! Active location: WeatherState.GPS or WeatherState.HOME. Applies to every page.
    private var locationIndex as Number = WeatherState.GPS;

    //! Creates the view; cached data is loaded in onLayout().
    function initialize() {
        View.initialize();
    }

    // MARK: - Lifecycle and input

    //! Loads cached data so the first frame shows the last known weather, then
    //! starts a refresh.
    //! @param dc The drawing context (unused).
    function onLayout(dc as Dc) as Void {
        data.loadCache();
        data.refresh();
    }

    //! Stops the retry timer and frees icons and text while the widget is off screen.
    function onHide() as Void {
        data.stop();
        res.clear();
    }

    //! Moves to another page, wrapping around. Called by WeatherDelegate.
    //! @param step +1 for the next page, -1 for the previous one.
    function turnPage(step as Number) as Void {
        pageIndex = (pageIndex + step + PAGE_COUNT) % PAGE_COUNT;
        WatchUi.requestUpdate();
    }

    //! Switches between the GPS and Home locations. Called by WeatherDelegate.
    function toggleLocation() as Void {
        locationIndex = (locationIndex == WeatherState.GPS) ? WeatherState.HOME : WeatherState.GPS;
        WatchUi.requestUpdate();
    }

    //! Fetches whatever is missing or older than the refresh interval (MENU).
    function refresh() as Void {
        data.refresh();
    }

    //! Settings changed in Garmin Connect; see WeatherData.settingsChanged().
    function settingsChanged() as Void {
        data.settingsChanged();
        WatchUi.requestUpdate();
    }

    //! @return The best known GPS position, or null (for the MENU menu).
    function position() as Array<Double>? {
        return data.position();
    }

    //! MENU → Set Home here, confirmed: saves the position as Home and fetches it.
    //! Shows the Home page so the change is visible.
    function setHomeHere() as Void {
        if (HomeHere.apply(services, data)) { locationIndex = WeatherState.HOME; }
        WatchUi.requestUpdate();
    }

    //! A background refresh saved new data to Storage: reload it and redraw.
    function backgroundDataSaved() as Void {
        data.loadCache();
        WatchUi.requestUpdate();
    }

    // MARK: - Drawing

    //! Draws the active page for the active location, a status line when the data
    //! could not be refreshed, and the location dots.
    //! @param dc The drawing context.
    function onUpdate(dc as Dc) as Void {
        View.onUpdate(dc);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        var current = data.currentFor(locationIndex);
        var forecast = data.forecastFor(locationIndex);
        var hasPageData = (pageIndex == 0) ? current != null : forecast != null;
        if (locationIndex == WeatherState.HOME && data.homeInvalid()) {
            // Security: invalid settings are never fetched (see HomeSettings). Say so,
            // rather than silently showing GPS weather under the Home dot.
            drawMessage(dc, Rez.Strings.CheckHome);
        } else if (!hasPageData) {
            drawMessage(dc, emptyMessage());
        } else {
            if (pageIndex == 0) {
                CurrentPage.draw(dc, current as Array, forecast, res);
            } else if (pageIndex == 1) {
                ForecastPages.drawHourly(dc, forecast as Array, res, data.fetchTime(locationIndex));
            } else {
                ForecastPages.drawDaily(dc, forecast as Array, res, data.fetchTime(locationIndex));
            }
            if (data.lastAttemptFailed(locationIndex)) { drawOfflineLine(dc); }
        }
        drawIndicator(dc);
    }

    //! @return The message explaining why the active location has nothing to show.
    private function emptyMessage() as ResourceId {
        var reason = data.emptyReason(locationIndex);
        if (reason == WeatherState.EMPTY_NO_CONNECTION) { return Rez.Strings.NoConnection; }
        if (reason == WeatherState.EMPTY_WAITING_GPS) { return Rez.Strings.WaitingGps; }
        return Rez.Strings.LoadingWeather;
    }

    //! Draws a status message in the centre of the screen.
    //! @param dc The drawing context.
    //! @param id A string resource; may contain line breaks.
    private function drawMessage(dc as Dc, id as ResourceId) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, dc.getHeight() / 2, Graphics.FONT_SMALL,
            res.text(id),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    //! Draws "No connection · 14:05" above the dots: the data shown is the last
    //! that arrived, at that time. The time is left out when it is unknown (data
    //! saved by an older version).
    //! @param dc The drawing context.
    private function drawOfflineLine(dc as Dc) as Void {
        var text = res.text(Rez.Strings.Offline);
        var time = data.fetchTime(locationIndex);
        if (time != null) {
            var info = Gregorian.info(new Time.Moment(time), Time.FORMAT_SHORT);
            text += " · " + WeatherFormat.clockTime(info.hour as Number, info.min as Number,
                System.getDeviceSettings().is24Hour);
        }
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2, (dc.getHeight() * 0.86).toNumber(), Graphics.FONT_XTINY, text,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    //! Draws two dots at the bottom of every page: left = GPS, right = Home.
    //! The active location's dot is filled white; the other is outlined light grey
    //! (dark grey would be below the 3:1 contrast needed for a control's state).
    //! @param dc The drawing context.
    private function drawIndicator(dc as Dc) as Void {
        var W = dc.getWidth();
        var r = (W * 0.027).toNumber();
        var cy = (dc.getHeight() * 0.93).toNumber();
        var gap = r * 3;
        for (var slot = 0; slot < 2; slot++) {
            var cx = W / 2 + (slot == 0 ? -gap : gap) / 2;
            if (slot == locationIndex) {
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(cx, cy, r);
            } else {
                dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.drawCircle(cx, cy, r);
            }
        }
    }
}
