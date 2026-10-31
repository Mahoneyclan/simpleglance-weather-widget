// GpsPosition.mc — finds the watch's position for the GPS location, from the
// best available system source. Runs in the foreground (widget) process only;
// the background refresh uses the position saved here ("gps_coords").

import Toybox.Activity;
import Toybox.Application;
import Toybox.Lang;
import Toybox.Position;
import Toybox.Weather;

//! Position lookup with fallbacks.
module GpsPosition {

    //! Finds the best position, trying in order: Position (live fix), the active
    //! activity, the Garmin Weather observation, then the last saved position.
    //! Every source is checked with Coordinates.validOrNull().
    //! Side effect: a live hit is saved to Storage "gps_coords", rounded to about
    //! 1 km (Coordinates.rounded()).
    //! @return [latitude, longitude] in degrees, or null if no source has one.
    function find() as Array<Double>? {
        var pos = null;
        var info = Position.getInfo();
        if (info.position != null) {
            pos = Coordinates.validOrNull((info.position as Position.Location).toDegrees());
        }
        var act = Activity.getActivityInfo();
        if (pos == null && act != null && act.currentLocation != null) {
            pos = Coordinates.validOrNull((act.currentLocation as Position.Location).toDegrees());
        }
        if (pos == null && Toybox has :Weather) {
            var cond = Weather.getCurrentConditions();
            if (cond != null && cond.observationLocationPosition != null) {
                pos = Coordinates.validOrNull((cond.observationLocationPosition as Position.Location).toDegrees());
            }
        }
        if (pos != null) {
            Storage.setValue("gps_coords", Coordinates.rounded(pos));
            return pos;
        }
        // Security: the saved value is untrusted; validOrNull() range-checks it.
        return Coordinates.validOrNull(Storage.getValue("gps_coords"));
    }
}
