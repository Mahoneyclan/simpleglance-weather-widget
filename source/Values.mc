// Values.mc — type checks for untrusted values from web replies, Storage and
// settings. Used by every process (widget, glance and background), so it is
// marked :glance and :background; it is kept small for the glance's memory limit.
//
// Security: Connect IQ's `as` casts are not checked at run time, so every value
// from outside the code goes through one of these checks before it is cast.

import Toybox.Lang;

//! Checks and conversions for values of unknown type.
(:glance, :background)
module Values {

    //! @param value Any value from a response, Storage or settings.
    //! @return true if the value is a Number, Long, Float or Double.
    function isNumeric(value as Object?) as Boolean {
        if (value instanceof Number || value instanceof Long
                || value instanceof Float || value instanceof Double) {
            return true;
        }
        return false;
    }

    //! @param value Any value from a response or Storage.
    //! @param fallback Returned when the value is not numeric.
    //! @return The value as a Float, or the fallback if it is not numeric.
    function toFloatOr(value as Object?, fallback as Float) as Float {
        return isNumeric(value) ? (value as Numeric).toFloat() : fallback;
    }

    //! @param value Any value from a response or Storage.
    //! @param fallback Returned when the value is not numeric.
    //! @return The value truncated to a Number, or the fallback if it is not numeric.
    function toNumberOr(value as Object?, fallback as Number) as Number {
        return isNumeric(value) ? (value as Numeric).toNumber() : fallback;
    }

    //! @param value Any value from a response or Storage.
    //! @param minSize The fewest items the caller will index.
    //! @return The value if it is an Array with at least minSize items, otherwise null.
    function arrayOrNull(value as Object?, minSize as Number) as Array<Object?>? {
        if (value instanceof Array && value.size() >= minSize) { return value as Array<Object?>; }
        return null;
    }

    //! @param value Any value from a response or Storage.
    //! @return The value if it is a String with at least one character, otherwise null.
    function nonEmptyString(value as Object?) as String? {
        if (value instanceof String && value.length() > 0) { return value as String; }
        return null;
    }
}
