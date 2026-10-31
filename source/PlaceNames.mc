// PlaceNames.mc — the place names of both locations in the full-screen widget:
// reuses a saved name while the position has not moved, otherwise asks Nominatim
// and saves the answer. Runs in the foreground (widget) process only; WeatherData
// owns it and writes new names into its weather arrays.
//
// Storage keys written here: gps_place, home_place.

import Toybox.Application;
import Toybox.Lang;

//! Place names by slot, and the lookups that change them.
class PlaceNames {

    //! Names used when parsing new weather replies, by slot.
    private var names as Array<String> = [WeatherParser.GPS_PLACEHOLDER, WeatherParser.HOME_PLACEHOLDER] as Array<String>;
    //! Coordinates of the lookup in flight, by slot; saved with the name as
    //! "gps_place" / "home_place" only if it succeeds.
    private var pending as Array<Array<Numeric>> = [[0, 0], [0, 0]] as Array<Array<Numeric>>;
    //! Called with (slot, name) whenever a slot's name changes.
    private var onChange as Method(slot as Number, name as String) as Void;

    //! @param changed Called with (slot, name) when a slot gets a new name, so the
    //!   owner can write it into its cached arrays.
    function initialize(changed as Method(slot as Number, name as String) as Void) {
        onChange = changed;
    }

    //! @param slot WeatherState.GPS or WeatherState.HOME.
    //! @return The slot's current name.
    function name(slot as Number) as String { return names[slot]; }

    //! Sets a name read from the cache, without saving or notifying.
    //! @param slot WeatherState.GPS or WeatherState.HOME.
    //! @param value The cached name.
    function setCached(slot as Number, value as String) as Void { names[slot] = value; }

    //! Uses the slot's saved name while the position is within
    //! FetchRules.PLACE_TOLERANCE of its last successful lookup; otherwise asks
    //! Nominatim (usage policy; less data sent). Until a new Home name arrives,
    //! Home is labelled WeatherParser.HOME_PLACEHOLDER, never the previous Home's
    //! or the GPS name (the Home cache may hold a copy of the GPS data).
    //! Side effect: possibly one web request.
    //! @param slot WeatherState.GPS or WeatherState.HOME.
    //! @param lat Latitude of the slot's position.
    //! @param lon Longitude of the slot's position.
    function lookUp(slot as Number, lat as Numeric, lon as Numeric) as Void {
        var saved = FetchRules.savedPlaceName(lat, lon,
            Storage.getValue(WeatherState.PLACE_KEYS[slot] as String));
        if (saved != null) {
            if (!saved.equals(names[slot])) { change(slot, saved); }
            return;
        }
        if (slot == WeatherState.HOME) { names[slot] = WeatherParser.HOME_PLACEHOLDER; }
        pending[slot] = [lat, lon] as Array<Numeric>;
        WeatherRequests.placeName(lat.toFloat(), lon.toFloat(),
            (slot == WeatherState.HOME) ? method(:onHomePlace) : method(:onGpsPlace));
    }

    //! GPS place-name callback; see arrived().
    //! @param responseCode HTTP status, or a negative Connect IQ error code.
    //! @param data Parsed JSON body, or null.
    function onGpsPlace(responseCode as Number, data as Dictionary?) as Void {
        arrived(WeatherState.GPS, responseCode, data);
    }

    //! Home place-name callback; see arrived().
    //! @param responseCode HTTP status, or a negative Connect IQ error code.
    //! @param data Parsed JSON body, or null.
    function onHomePlace(responseCode as Number, data as Dictionary?) as Void {
        arrived(WeatherState.HOME, responseCode, data);
    }

    //! On success saves the name with the coordinates it was asked for, and
    //! passes it on. Failures are ignored: the old name stays, and the lookup is
    //! tried again on the next fetch because nothing was saved.
    //! Side effect: Storage write.
    //! @param slot WeatherState.GPS or WeatherState.HOME.
    //! @param responseCode HTTP status, or a negative Connect IQ error code.
    //! @param data Parsed JSON body, or null.
    private function arrived(slot as Number, responseCode as Number, data as Dictionary?) as Void {
        var value = (responseCode == 200) ? WeatherParser.parsePlaceName(data) : null;
        if (value == null) { return; }
        var at = pending[slot];
        Storage.setValue(WeatherState.PLACE_KEYS[slot] as String, FetchRules.placeRecord(at[0], at[1], value));
        change(slot, value);
    }

    //! @param slot WeatherState.GPS or WeatherState.HOME.
    //! @param value The new name.
    private function change(slot as Number, value as String) as Void {
        names[slot] = value;
        onChange.invoke(slot, value);
    }
}
