// WeatherApp.mc — application entry point.
// Loaded in all three Connect IQ processes (widget, glance and background), so
// the class carries both the :glance and :background annotations. It creates the
// views, owns the background refresh schedule, and copies background results into
// Application.Storage, which is the only channel between the processes.

import Toybox.Application;
import Toybox.Application.Storage;
import Toybox.Background;
import Toybox.Lang;
import Toybox.Time;
import Toybox.WatchUi;

//! Application object for the SimpleGlance widget.
(:glance, :background)
class WeatherApp extends Application.AppBase {

    //! The full-screen view, kept so settings changes and background results reach it.
    //! Null in the glance and background processes, where it is never created.
    private var mainView as WeatherView?;

    //! Creates the application object (once per process).
    function initialize() {
        AppBase.initialize();
    }

    //! Lifecycle hook; the app keeps no state that needs setting up here.
    //! @param state Launch state from the system (unused).
    function onStart(state as Dictionary?) as Void {
    }

    //! Lifecycle hook; nothing needs saving because data is written to Storage as it arrives.
    //! @param state Stop state from the system (unused).
    function onStop(state as Dictionary?) as Void {
    }

    //! Creates the full-screen view and its input delegate, and (re)registers the
    //! background refresh so it follows the current refresh-interval setting.
    //! @return The main view and its delegate.
    function getInitialView() as [ WatchUi.Views ] or [ WatchUi.Views, WatchUi.InputDelegates ] {
        var view = new WeatherView();
        mainView = view;
        scheduleBackground();
        return [ view, new WeatherDelegate(view) ];
    }

    //! @return The glance view shown in the watch's glance list.
    function getGlanceView() as [ WatchUi.GlanceView ] or [ WatchUi.GlanceView, WatchUi.GlanceViewDelegate ] or Null {
        return [ new WeatherGlanceView() ];
    }

    //! @return The delegate that runs each scheduled background refresh.
    function getServiceDelegate() as [ Toybox.System.ServiceDelegate ] {
        return [ new BackgroundService() ];
    }

    //! Receives the result of a background refresh and saves it to Storage, so the
    //! widget and glance show it next time they draw. Which keys are written is
    //! decided by BackgroundResult.writes(): slots that are null (a failed or
    //! skipped fetch) are not written, which keeps the last good data on screen.
    //! Side effects: Storage writes (weather, forecasts, their fetch times and
    //! "home_place"); tells an open widget to reload.
    //! @param data The BackgroundResult array from BackgroundService.
    function onBackgroundData(data as Application.PersistableType) as Void {
        var writes = BackgroundResult.writes(data, Time.now().value());
        var keys = writes.keys();
        for (var i = 0; i < keys.size(); i++) {
            Storage.setValue(keys[i], writes[keys[i]]);
        }
        if (mainView != null) {
            mainView.backgroundDataSaved();
        } else {
            WatchUi.requestUpdate();
        }
    }

    //! Called when the user changes settings in Garmin Connect (refresh interval or
    //! Home coordinates). Re-registers the background schedule and tells the view,
    //! which fetches Home straight away (WeatherData.settingsChanged()).
    function onSettingsChanged() as Void {
        scheduleBackground();
        if (mainView != null) {
            mainView.settingsChanged();
        }
    }

    //! Registers a recurring background refresh at the user's interval
    //! (refresh_rate, in minutes, checked by FetchRules.refreshMinutes()).
    //! deleteTemporalEvent() is called first because registering a second event
    //! without deleting the previous one is a runtime error on the device.
    private function scheduleBackground() as Void {
        Background.deleteTemporalEvent();
        var minutes = FetchRules.refreshMinutes(Properties.getValue("refresh_rate"));
        Background.registerForTemporalEvent(new Time.Duration(minutes * 60));
    }
}
