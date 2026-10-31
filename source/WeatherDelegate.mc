// WeatherDelegate.mc — button and swipe handling for the full-screen widget.
// Runs in the foreground (widget) process only. Changes WeatherView's page and
// location and opens the MENU menu (HomeMenu.mc); it does no drawing or networking.

import Toybox.Lang;
import Toybox.WatchUi;

//! Handles input for WeatherView.
//!
//! - DOWN / UP cycle through the three pages: current conditions → hourly → daily.
//! - SELECT toggles between the GPS location and the Home location (all pages).
//! - MENU opens a menu: Refresh, or Set Home here (HomeMenu.mc).
class WeatherDelegate extends WatchUi.BehaviorDelegate {

    //! The view this delegate controls.
    private var view as WeatherView;

    //! @param view The main weather view this delegate controls.
    function initialize(view as WeatherView) {
        BehaviorDelegate.initialize();
        self.view = view;
    }

    //! Next page: 0 → 1 → 2 → 0.
    //! Garmin maps this to the DOWN button, or a swipe up on touch screens.
    //! @return true, because the event is always handled.
    function onNextPage() as Boolean {
        view.turnPage(1);
        return true;
    }

    //! Previous page: 0 → 2 → 1 → 0.
    //! Garmin maps this to the UP button, or a swipe down on touch screens.
    //! @return true, because the event is always handled.
    function onPreviousPage() as Boolean {
        view.turnPage(-1);
        return true;
    }

    //! SELECT: toggle between the GPS location and the Home location.
    //! The choice applies to every page.
    //! @return true, because the event is always handled.
    function onSelect() as Boolean {
        view.toggleLocation();
        return true;
    }

    //! MENU: open the menu (Refresh, Set Home here). Refresh fetches only data
    //! that is missing, stale or for another place, so it is not a forced refresh.
    //! @return true, because the event is always handled.
    function onMenu() as Boolean {
        HomeMenu.show(view);
        return true;
    }
}
