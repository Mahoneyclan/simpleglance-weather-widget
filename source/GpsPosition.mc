// GpsPosition.mc — finds the watch's position for the GPS location, from the
// best available system source. Runs in the foreground (widget) process only;
// the background refresh uses the position saved here ("gps_coords").
//
// The choice between sources is the pure function choose(), so it can be unit
// tested (see source/test/WeatherDataTest.mc).

import Toybox.Activity;
import Toybox.Application;
import Toybox.Lang;
import Toybox.Position;
import Toybox.Weather;

//! Position lookup with fallbacks.
module GpsPosition {

    //! Index of the "is a current fix" flag in the arrays from find() and choose().
    const CURRENT = 2;

    //! Finds the best position (see choose()) from the live fix, the active
    //! activity, the watch's last known position, the saved position and Garmin
    //! Weather's observation station. Every source is checked with
    //! Coordinates.validOrNull().
    //! Side effect: a position from the watch itself (not the saved one or the
    //! weather station) is saved to Storage "gps_coords", rounded to about 1 km.
    //! @return [latitude, longitude, isCurrent] (Double, Double, Boolean), or null
    //!   if no source has a position.
    function find() as Array? {
        var live = null;
        var quality = Position.QUALITY_NOT_AVAILABLE;
        var info = Position.getInfo();
        if (info.position != null) {
            live = Coordinates.validOrNull((info.position as Position.Location).toDegrees());
            quality = info.accuracy;
        }
        var act = Activity.getActivityInfo();
        var activity = null;
        if (act != null && act.currentLocation != null
                && act.currentLocationAccuracy != null && (act.currentLocationAccuracy as Number) >= Position.QUALITY_POOR) {
            activity = Coordinates.validOrNull((act.currentLocation as Position.Location).toDegrees());
        }
        var station = null;
        if (Toybox has :Weather) {
            var cond = Weather.getCurrentConditions();
            if (cond != null && cond.observationLocationPosition != null) {
                station = Coordinates.validOrNull((cond.observationLocationPosition as Position.Location).toDegrees());
            }
        }
        // Security: the saved value is untrusted; validOrNull() range-checks it.
        var saved = Coordinates.validOrNull(Storage.getValue("gps_coords"));
        var best = choose(live, quality as Number, activity, saved, station);
        if (best != null && (live != null || activity != null)) {
            Storage.setValue("gps_coords", Coordinates.rounded([best[0], best[1]] as Array<Double>));
        }
        return best;
    }

    //! Picks the best position. A current fix (the live position with at least
    //! poor accuracy, or a running activity's) wins. Otherwise the watch's last
    //! known position, then the position the app saved, and Garmin Weather's
    //! observation station only as a last resort, because the station can be
    //! many kilometres away. Anything but a current fix is flagged so the caller
    //! can ask for a fresh fix.
    //! @param live The live/last-known position, already checked, or null.
    //! @param quality Its Position.QUALITY_* accuracy.
    //! @param activity The running activity's position with at least poor accuracy, or null.
    //! @param saved The saved "gps_coords", already checked, or null.
    //! @param station Garmin Weather's observation station position, or null.
    //! @return [latitude, longitude, isCurrent], or null if every source is null.
    function choose(live as Array<Double>?, quality as Number, activity as Array<Double>?,
                    saved as Array<Double>?, station as Array<Double>?) as Array? {
        if (live != null && quality >= Position.QUALITY_POOR) { return [live[0], live[1], true]; }
        if (activity != null) { return [activity[0], activity[1], true]; }
        var fallbacks = [live, saved, station];
        for (var i = 0; i < fallbacks.size(); i++) {
            var p = fallbacks[i] as Array<Double>?;
            if (p != null) { return [p[0], p[1], false]; }
        }
        return null;
    }
}
