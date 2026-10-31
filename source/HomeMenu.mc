// HomeMenu.mc — the MENU button's menu in the full-screen widget: Refresh, and
// Set Home here (saves the current GPS position as Home, after a confirmation).
// Runs in the foreground (widget) process only.
//
// Setting Home on the watch needs no typing, and works where the Garmin Connect
// settings are not available (a widget copied to the watch over USB).

import Toybox.Lang;
import Toybox.WatchUi;

//! Builds and shows the menu.
module HomeMenu {

    //! Shows the menu. The "Set Home here" item shows the position it would save,
    //! or that there is no position yet.
    //! @param view The widget view the menu acts on.
    function show(view as WeatherView) as Void {
        var menu = new WatchUi.Menu2({ :title => Rez.Strings.AppName });
        menu.addItem(new WatchUi.MenuItem(Rez.Strings.MenuRefresh, null, :refresh, null));
        var pos = view.position();
        var detail = (pos != null) ? WeatherFormat.positionText(pos)
                                   : WatchUi.loadResource(Rez.Strings.NoPositionYet) as String;
        menu.addItem(new WatchUi.MenuItem(Rez.Strings.MenuSetHome, detail, :setHome, null));
        WatchUi.pushView(menu, new HomeMenuDelegate(view), WatchUi.SLIDE_UP);
    }
}

//! Saving the current position as Home, kept out of the menu so it can be unit
//! tested (see source/test/WeatherDataTest.mc).
module HomeHere {

    //! Saves the best known GPS position as the Home settings, then fetches Home
    //! as after a settings change (WeatherData.settingsChanged()).
    //! Side effects: writes the Home settings; web requests.
    //! @param watch Watch services used to save the settings.
    //! @param data The widget's weather data.
    //! @return false if there is no position yet (nothing changed).
    function apply(watch as WatchServices, data as WeatherData) as Boolean {
        var pos = data.position();
        if (pos == null) { return false; }
        watch.setHomeSettings(WeatherFormat.settingText(pos[0]), WeatherFormat.settingText(pos[1]));
        data.settingsChanged();
        return true;
    }
}

//! Handles a choice in the menu.
class HomeMenuDelegate extends WatchUi.Menu2InputDelegate {

    //! The widget view the menu acts on.
    private var view as WeatherView;

    //! @param view The widget view the menu acts on.
    function initialize(view as WeatherView) {
        Menu2InputDelegate.initialize();
        self.view = view;
    }

    //! Refresh closes the menu and refreshes. Set Home here asks for confirmation
    //! first, because it replaces the Home setting; with no position it just closes.
    //! @param item The chosen item.
    function onSelect(item as WatchUi.MenuItem) as Void {
        if (item.getId() == :setHome && view.position() != null) {
            var question = WatchUi.loadResource(Rez.Strings.ConfirmSetHome) as String;
            WatchUi.switchToView(new WatchUi.Confirmation(question), new SetHomeDelegate(view), WatchUi.SLIDE_IMMEDIATE);
            return;
        }
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        if (item.getId() == :refresh) { view.refresh(); }
    }
}

//! Handles the answer to "Set Home to this location?".
class SetHomeDelegate extends WatchUi.ConfirmationDelegate {

    //! The widget view to update.
    private var view as WeatherView;

    //! @param view The widget view to update.
    function initialize(view as WeatherView) {
        ConfirmationDelegate.initialize();
        self.view = view;
    }

    //! @param response The answer: yes (CONFIRM_YES) or no (CONFIRM_NO).
    //! @return true, because the answer is always handled.
    function onResponse(response as WatchUi.Confirm) as Boolean {
        if (response == WatchUi.CONFIRM_YES) { view.setHomeHere(); }
        return true;
    }
}
