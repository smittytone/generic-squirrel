// Code version for Squinter
#version "3.1.2"

/**
 * General utility functions accessed via the table 'utilities'.
 *
 * @author    Tony Smith (@smittytone)
 * @copyright Tony Smith, 2017-19
 * @licence   MIT
 * @version   3.1.2
 *
 * @table
 *
 */
utilities <- {

    // ********** Conversion Functions **********

    /**
     * Convert a hex string (with or without '0x' prefix) to an integer.
     *
     * @param {string} hs - The hex string
     *
     * @returns {integer} The value of the hex string
     *
     */
    "hexStringToInteger" : function(hs) {
        // Check input string type
        if (typeof hs != "string") throw "utilities.hexStringToInteger() requires a string";
        hs = hs.tolower();
        if (hs.slice(0, 2) == "0x") hs = hs.slice(2);
        local i = 0;
        foreach (c in hs) {
            local n = c - '0';
            if (n > 9) n = ((n & 0x1F) - 7);
            i = (i << 4) + n;
        }
        return i;
    },

    /**
     * Convert a hex string (with or without '0x' prefix) to a blob.
     *
     * @param {string} hs - The hex string
     *
     * @returns {blob} A blob in which each octet of the hex is saved as a byte value
     *
     */
    "hexStringToBlob" : function(hs) {
        // Check input string type
        if (typeof hs != "string") throw "utilities.hexStringToBlob() requires a string";
        hs = hs.tolower();
        if (hs.slice(0, 2) == "0x") hs = hs.slice(2);
        if (hs.len() % 2 != 0) hs = "0" + hs;
        local l = hs.len() / 2;
        local r = blob(l);
        for (local i = 0 ; i < l ; i++) {
            local hi = hs[i * 2] - '0';
            if (hi > 9) hi = ((hi & 0x1F) - 7);
            local lo = hs[i * 2 + 1] - '0';
            if (lo > 9) lo = ((lo & 0x1F) - 7);
            r[i] = hi << 4 | lo;
        }
        return r;
    },

    /**
     * Convert a decimal integer into a hex string.
     *
     * @param {integer} i   - The integer
     * @param {integer} [l] - The number of characters in the hex string. Default: 2
     *
     * @returns {string} The hex string representation
     *
     */
    "integerToHexString" : function (i, l = 2) {
        if (typeof i != "integer") throw "utilities.integerToHexString() requires an integer";
        if (l % 2 != 0) l++;
        local fs = "0x%0" + l.tostring() + "x";
        return format(fs, i);
    },

    /**
     * Convert a blob (array of bytes) to a hex string.
     *
     * @param {integer} b   - The blob
     * @param {integer} [l] - The number of characters assigned to each byte in the hex string. Default: 2
     *
     * @returns {string} The hex string representation
     *
     */
    "blobToHexString" : function (b, l = 2) {
        // Check input type
        if (typeof b != "blob") throw "utilities.blobToHexString() requires a blob";
        if (b.len() == 0) throw "utilities.blobToHexString() requires a non-zero blob";
        local s = "0x";
        if (l % 2 != 0) l++;
        if (l < 2) l = 2;
        local fs = "%0" + l.tostring() + "x";
        for (local i = 0 ; i < b.len() ; i++) s += format(fs, b[i]);
        return s;
    },

    /**
     * Convert a string representation of a binary number to an integer.
     *
     * @param {string} b - The binary string, eg. "001001001", up to 32 bits in length
     *
     * @returns {integer} The decimal integer value of the binary representation
     *
     */
    "binaryToInteger" : function(b) {
        // Check input string ranges, type
        if (typeof b != "string") throw "utilities.binaryToInteger() requires the binary value as a string";
        if (b.len() > 32) throw "utilities.binaryToInteger() can only convert up to 32 bits";
        if (b.len() == 0) return 0;

        // Pad with initial zeros to the next full byte
        if (b.len() % 8 != 0) {
            local a = b.len();
            while (a % 8 != 0) {
                b = "0" + b;
                a++;
            }
        }

        local v = 0;
        local a = b.len() - 1;
        for (local i = 0 ; i < b.len() ; i++) {
            if (b[a - i] == 49) v += (1 << i)
        }

        return v;
    },

    "toString" : function (o) {
        jsonencode(o, {"compact":true});
    },

    /**
     * Convert anything into a JSON representation.
     *
     * @param {*}       o   - The integer/float/string/blob/bool
     * @param {table}   [s] - Table of encoding settings: { "compact" : <true/false>, "unsafe" : <true/false> }
     * @param {integer} [i] - Inset value used by the function itself when recurring in non-compact mode
     *
     * @returns {string} The JSON
     *
     */
    "jsonencode" : function(o, s = null, i = 0) {
        local c = "compact" in s ? s.compact : false;
        local u = "unsafe" in s ? s.unsafe : true;
        local e = c ? "" : " ";
        local p = "";
        if (!c && i > 0) {
            for (local j = 0 ; j < i ; j++) p += " ";
        }
        // Branch on type of object being processed
        switch (typeof o) {
            // The following are a containers, so iterate through them
            case "table":
                local t = "";
                foreach (k, v in o) {
                    if (t != "") t += "," + (!c ? "\n " + p : "");
                    t += e + jsonencode(k, s, i + k.len() + 7) + e + ":" + e + jsonencode(v, s, i + k.len() + 7);
                }
                return "{" + t + e + "}";
            case "array":
                local a = "";
                foreach (v in o) {
                    if (a != "") a += "," + e;
                    a += jsonencode(v, s, i + a.len() + 2);
                }
                return "[" + e + a + e + "]";
            // The following are not containers, so just return their value
            case "string":
                if (u && o.find("\0") != null) return "'unsafe string'";
                return "'" + o + "'";
            case "integer":
            case "float":
                return o.tostring();
            case "bool":
                return o ? "true" : "false";
            // Unsupported entities (functions, blobs, classes, instances) are
            default:
                return "'" + typeof(o) + "'";
        }
    },

    /**
     * Create a print-suitable string from a blob.
     *
     * @param {integer} ab - The blob
     *
     * @returns {string} The string representation
     *
     */
    "printblob" : function(ab) {
        local op = "";
        foreach (by in ab) {
            if (by < 32 || by > 127) {
                op += ("[" + format("%02X", by) + "]");
            } else {
                op += by.tochar();
            }
        }
        return op;
    },

    // ********** Random Number and Numerical Functions **********

    /**
     * Return a random floating point number between 0.0 and m, inclusive.
     *
     * @param {integer} m The maximum value
     *
     * @returns {integer} The random float
     *
     */
    "frnd" : function(m) {
        return (1.0 * (m + 1.0) * math.rand() / RAND_MAX) ;
    },

    /**
     * Return a random integer between 0 and m, inclusive.
     *
     * @param {integer} m The maximum value
     *
     * @returns {integer} The random integer
     *
     */
    "rnd" : function(m) {
        return utilities.frnd(m).tointeger();
    },

    /**
     * Indicates the sign of a signed integer or float.
     *
     * @param {integer|float} v - The number
     *
     * @returns {integer} -1 if the number is negative, 1 if the number is positive, or 0
     *
     */
    "sign": function(v) {
        if (typeof v != "integer" && typeof v != "float") throw "?TYPE MISMATCH ERROR";
        if (v < 0) return -1;
        if (v > 0) return 1;
        return 0;
    },

    /**
     * Return a string representation of a number with the specified decimal places (irrespective of type)
     * and the desired hundreds separator (or none if you pass an empty string).
     *
     * @param {integer|float|string} n   - The number to represent
     * @param {integer}              [d] - The number of decimal places for floats. Default: 2 for float; 0 for other types
     * @param {string}               [s] - A hundreds separator character. Default: ","
     *
     * @returns {string} The formatted representation
     *
     */
    "numberFormatter" : function(n, d = null, s = ",") {
        if (d == null) {
            if (typeof n == "string") d = 0;
            else if (typeof n == "integer") d = 0;
            else if (typeof n == "float") d = 2;
            else throw "utilities.numberFormatter() invalid input"
        }

        if (typeof n == "string") {
            n = d == 0 ? n.tointeger() : n.tofloat();
        } else if (typeof n != "integer" && typeof n != "float") {
            throw "utilities.numberFormatter() invalid input"
        }

        local ns = 0;
        if (d == 0) {
            n = format("%0.0f", n.tofloat());
            ns = n.len();
        } else {
            ns = format("%0.0f", n.tofloat()).len();
            n = format("%0.0" + d + "f", n.tofloat());
        }

        local nn = "";
        for (local i = 0 ; i < n.len() ; i++) {
            local ch = n[i];
            nn += ch.tochar();
            if (i >= ns - 2) {
                nn += n.slice(i + 1);
                break;
            }

            if ((ns - i) % 3 == 1) nn += s;
        }
        return nn;
    },

    // ********** Calendar Functions **********

    /**
     * Returns the day of the the week for a specific date.
     *
     * @param {integer} d - The day value (1-31)
     * @param {integer} m - The month value (1-12)
     * @param {integer} y - The four-digit year (eg. 2019)
     *
     * @returns {integer} The day of the week (0-6; Sun-Sat)
     *
     */
    "dayOfWeek" : function(d, m, y) {
        // Use Zeller's Rule (see http://mathforum.org/dr.math/faq/faq.calendar.html)
        m -= 2;
        if (m < 1) m += 12;
        local e = y.tostring().slice(2).tointeger();
        local s = y.tostring().slice(0,2).tointeger();
        local t = m > 10 ? e - 1 : e;
        local f = d + ((13 * m - 1) / 5) + t + (t / 4) + (s / 4) - (2 * s);
        f = f % 7;
        if (f < 0) f += 7;
        return f;
    },

/**
     * Indicates whether a specified year was a leap year.
     *
     * @param {integer} y - The four-digit year (eg. 2019)
     *
     * @returns {bool} Whether the year was a leap year (true) or not (false)
     *
     */
    "isLeapYear" : function(y) {
        if ((y % 4 == 0) && ((y % 100 > 0) || (y % 400 == 0))) return true;
        return false;
    },

    /**
     * Checks a date for British Summer Time.
     *
     * @param {table} [n] - A Squirrel date table (see date()). Default: the current date and time
     *
     * @returns {bool} Whether the date is within the British Summer Time (BST) period (true), or not (false)
     *
     */
    "isBST": function(n = null) {
        return bstCheck(n);
    },

    "bstCheck" : function(n = null) {
        //
        if (n == null) n = date();
        if (n.month > 2 && n.month < 9) return true;

        if (n.month == 2) {
            // BST starts on the last Sunday of March
            for (local i = 31 ; i > 24 ; i--) {
                // NOTE 'utilities.dayOfWeek()' takes months in the range 1-12, but n.month, as per date() will be 0-11
                if (utilities.dayOfWeek(i, 3, n.year) == 0 && n.day >= i) return true;
            }
        }

        if (n.month == 9) {
            // BST ends on the last Sunday of October
            for (local i = 31 ; i > 24 ; i--) {
                // See NOTE above
                if (utilities.dayOfWeek(i, 10, n.year) == 0 && n.day < i) return true;
            }
        }
        return false;
    },

    /**
     * Checks a date for US Daylight Savings Time.
     *
     * @param {table} [n] - A Squirrel date table (see date()). Default: the current date and time
     *
     * @returns {bool} Whether the date is within the US Daylight Savings Time (DST) period (true), or not (false)
     *
     */
    "isDST": function(n = null) {
        return dstCheck(n);
    },

    "dstCheck" : function(n = null) {
        // Checks the current date for US Daylight Savings Time, returning true or false accordingly
        if (n == null) n = date();
        if (n.month > 2 && n.month < 10) return true;

        if (n.month == 2) {
            // DST starts second Sunday in March
            for (local i = 8 ; i < 15 ; i++) {
                // NOTE 'utilities.dayOfWeek()' takes months in the range 1-12, but n.month, as per date() will be 0-11
                if (utilities.dayOfWeek(i, 3, n.year) == 0 && n.day >= i) return true;
            }
        }

        if (n.month == 10) {
            // DST ends first Sunday in November
            for (local i = 1 ; i < 8 ; i++) {
                // See NOTE above
                if (utilities.dayOfWeek(i, 11, n.year) == 0 && n.day <= i)return true;
            }
        }

        return false;
    },

    // ********** UUID ACCESSOR FUNCTIONS **********

    /**
     * Returns a valid UUID.
     *
     * @returns {string} The UUID
     *
     */
    "uuid" : function() {
        // Randomize 16 bytes (128 bits)
        local rnds = blob(16);
        for (local i = 0 ; i < 16 ; i++) rnds.writen((256.0 * math.rand() / RAND_MAX).tointeger(), 'b');

        // Adjust certain bits according to RFC 4122 section 4.4
        rnds[6] = 0x40 | (rnds[6] & 0x0F);
        rnds[8] = 0x80 | (rnds[8] & 0x3F);

        // Create an return the UUID string
        local s = "";
        for (local i = 0 ; i < 16 ; i++) {
            s = s + format("%02X", rnds[i]);
            if (i == 3 || i == 5 || i == 7 || i == 9) s = s + "-";
        }
        return s;
    },

    // ********** I2C Functions **********

    /**
     * Scans an imp I2C bus for devices.
     *
     * @param {imp::i2c} i2c - The imp I2C bus to scan
     *
     */
    "debugI2C" : function(i2c = null) {
        if (imp.environment() == ENVIRONMENT_AGENT) throw "utilities.debugI2C() can only be run on a device";
        if (i2c == null) throw "utilities.debugI2C() requires a non-null I2C object";
        for (local i = 2 ; i < 256 ; i += 2) {
            if (i2c.read(i, "", 1) != null) server.log(format("Device at 8-bit address: 0x%02X (7-bit address: 0x%02X)", i, (i >> 1)));
        }
    },

    // ********** BASIC-style String Functions **********

    /**
     * Returns a sub-string using the MID$() methodology.
     *
     * @param {string}  s   - The source string
     * @param {integer} l   - The index of the first character in the sub-string
     * @param {integer} [c] - The index of the last character in the sub-string. Default: the last character in the source
     *
     * @returns {string} The sub-string
     *
     */
    "mid": function(s, l, c = 0) {
        if (typeof s != "string") throw "?TYPE MISMATCH ERROR";
        if (typeof l != "integer") throw "?TYPE MISMATCH ERROR";
        if (typeof c != "integer") throw "?TYPE MISMATCH ERROR";
        if (l > s.len()) l = s.len();
        if (l > 0) l--;
        if (l < 0) l == 0;
        if (c == 0) c = s.len() - l;
        if (l + c >= s.len()) c = s.len() - l;
        return s.slice(l, l + c);
    },

    /**
     * Returns a sub-string using the LEFT$() methodology: source characters first to r.
     *
     * @param {string}  s   - The source string
     * @param {integer} [r] - The index of the right-most character in the sub-string. Default: the last character in the source
     *
     * @returns {string} The sub-string
     *
     */
    "left": function(s, r = 0) {
        if (typeof s != "string") throw "?TYPE MISMATCH ERROR";
        if (typeof r != "integer") throw "?TYPE MISMATCH ERROR";
        if (r <= 0) r = 1;
        if (r > s.len()) r = s.len();
        return s.slice(0, r);
    },

    /**
     * Returns a sub-string using the RIGHT$() methodology: source characters l to last.
     *
     * @param {string}  s   - The source string
     * @param {integer} [l] - The index of the left-most character in the sub-string. Default: the first character in the source
     *
     * @returns {string} The sub-string
     *
     */
    "right": function(s, l = 0) {
        if (typeof s != "string") throw "?TYPE MISMATCH ERROR";
        if (typeof l != "integer") throw "?TYPE MISMATCH ERROR";
        if (l <= 0) l = 1
        if (l > s.len()) l = s.len();
        return s.slice(s.len() - l);
    },

    /**
     * Return a character string of the specified Ascii value.
     *
     * @param {integer} v - The Ascii value, eg. 65
     *
     * @returns {string} The character string, eg. "A"
     *
     */
    "chr": function(v) {
        if (typeof v == "float") v = v.tointeger();
        if (typeof v != "integer") throw "?TYPE MISMATCH ERROR";
        if (v < 0 || v > 255 ) throw "?ILLEGAL QUANTITY ERROR";
        return format("%c",v);
    },

    /**
     * Return the Ascii value of a given character string.
     *
     * @param {string} s - The character string, eg. "A"
     *
     * @returns {integer} The Ascii value, eg. 65
     *
     */
    "asc": function(s) {
        if (typeof s != "string") throw "?TYPE MISMATCH ERROR";
        if (s.len() < 1) throw "?ILLEGAL QUANTITY ERROR";
        return s[0];
    }
}
