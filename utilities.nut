// General utility functions accessed via the table 'utilities'
// Copyright Tony Smith, 2014-18
// Licence: MIT

// Code version for Squinter
#version "2.2.0"

utilities <- {

    // HEX CONVERSION FUNCTIONS

    "hexStringToInteger" : function(hs) {
        if (hs.slice(0, 2) == "0x") hs = hs.slice(2);
        local i = 0;
        foreach (c in hs) {
            local n = c - '0';
            if (n > 9) n = ((n & 0x1F) - 7);
            i = (i << 4) + n;
        }
        return i;
    },

    "hexStringToBlob" : function(hs) {
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

    "integerToHexString" : function (i, r = 2) {
        if (r % 2 != 0) r++;
        local fs = "0x%0" + r.tostring() + "x";
        return format(fs, i);
    },

    "blobToHexString" : function (b, r = 2) {
        local s = "0x";
        if (r % 2 != 0) r++;
        local fs = "%0" + r.tostring() + "x";
        for (local i = 0 ; i < b.len() ; i++) s += format(fs, b[i]);
        return s;
    },

    "toString" : function (obj) {
        jsonencode(obj, {"compact":true});   
    },

    "jsonencode" : function(obj, opts = null, ins = 0) {
        local cp = "compact" in opts ? opts.compact : false;
        local es = cp ? "" : " "; 
        local sp = "";
        if (!cp && ins > 0) {
            for (local i = 0 ; i < ins ; i++) sp += " ";
        }
        // Branch on type of object being processed
        switch (typeof obj) {
            // The following are a containers, so iterate through them
            case "table":
                local tab = "";
                foreach (key, val in obj) {
                    if (tab != "") tab += "," + (!cp ? "\n " + sp : "");
                    tab += es + jsonencode(key, opts, ins + key.len() + 7) + es + ":" + es + jsonencode(val, opts, ins + key.len() + 7);
                }
                return "{" + tab + es + "}";
            case "array":
                local arr = "";
                foreach (val in obj) {
                    if (arr != "") arr += "," + es;
                    arr += jsonencode(val, opts, ins + arr.len() + 2);
                }
                return "[" + es + arr + es + "]";
            // The following are not containers, so just return their value
            case "string":
                return "'" + obj + "'";
            case "integer":
                return obj.tostring();
            case "bool":
                return obj ? "true" : "false";
            default:
                return typeof(obj);
        }
    },

    // RANDOM NUMBER FUNCTIONS

    "frnd" : function(m) {
        // Return a pseudorandom float between 0 and max, inclusive
        return (1.0 * math.rand() / RAND_MAX) * (m + 1);
    },

    "rnd" : function(m) {
        // Return a pseudorandom integer between 0 and max, inclusive
        return utilities.frnd(m).tointeger();
    },

    // NUMBER FORMAT FUNCTIONS

    "numberFormatter" : function(n, d = null, s = ",") {
        if (d == null) {
            if (typeof n == "string") d = 0;
            else if (typeof n == "integer") d = 0;
            else if (typeof n == "float") d = 2;
            else return n;
        }

        if (typeof n == "string") {
            n = d == 0 ? n.tointeger() : n.tofloat();
        } else if (typeof n != "integer" && typeof n != "float") {
            return n;
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

    // CALENDAR FUNCTIONS (PUBLIC)

    "dayOfWeek" : function(d, m, y) {
        local dim = [
            [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31],
            [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
        ];

        local ad = ((y - 1) * 365) + utilities._totalLeapDays(y) + d - 5;
        for (local i = 0 ; i < m ; i++) {
            local a = dim[utilities._isLeapYear(y)];
            ad = ad + a[i];
        }
        return (ad % 7) - 1;
    },

    "isLeapYear" : function(y) {
        if (utilities._isLeapYear(y) == 1) return true;
        return false;
    },

    "bstCheck" : function(n = null) {
        // Checks the current date for British Summer Time,
        // returning true or false accordingly
        if (n == null) n = date();
        if (n.month > 2 && n.month < 9) return true;

        if (n.month == 2) {
            // BST starts on the last Sunday of March
            for (local i = 31 ; i > 24 ; i--) {
                if (utilities.dayOfWeek(i, 2, n.year) == 0 && n.day >= i) return true;
            }
        }

        if (n.month == 9) {
            // BST ends on the last Sunday of October
            for (local i = 31 ; i > 24 ; i--) {
                if (utilities.dayOfWeek(i, 9, n.year) == 0 && n.day < i) return true;
            }
        }
        return false;
    },

    "isBST": function(n = null) {
        return bstCheck(n);
    },

    "dstCheck" : function(n = null) {
        // Checks the current date for US Daylight Savings Time, returning true or false accordingly
        if (n == null) n = date();
        if (n.month > 2 && n.month < 10) return true;

        if (n.month == 2) {
            // DST starts second Sunday in March
            for (local i = 8 ; i < 15 ; ++i) {
                if (utilities.dayOfWeek(i, 2, n.year) == 0 && n.day >= i) return true;
            }
        }

        if (n.month == 10) {
            // DST ends first Sunday in November
            for (local i = 1 ; i < 8 ; ++i) {
                if (utilities.dayOfWeek(i, 10, n.year) == 0 && n.day <= i) return true;
            }
        }

        return false;
    },

    "isDST": function(n = null) {
        return dstCheck(n);
    },

    // CALENDAR FUNCTIONS (PRIVATE)

    "_totalLeapDays" : function(y) {
        local t = y / 4;
        if (utilities._isLeapYear(y) == 1) t = t - 1;
        t = t - ((y / 100) - (1752 / 100)) + ((y / 400) - (1752 / 400));
        return t;
    },

    "_isLeapYear" : function(y) {
        if ((y % 400) || ((y % 100) && !(y % 4))) return 1;
        return 0;
    },

    // UUID ACCESSOR FUNCTIONS

    // We create this string here for later use, but only populte it if it is actually needed
    "uuid" : function() {
        // Randomize 16 bytes (128 bits)
        local rnds = blob(16);
        for (local i = 0 ; i < 16 ; i++) rnds.writen(((1.0 * math.rand() / RAND_MAX) * 256.0).tointeger(), 'b');

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

    // I2C FUNCTIONS

    "debugI2C" : function(i2c) {
        if (imp.environment() == ENVIRONMENT_AGENT) {
            server.error("utilities.debugI2C() can only be run on a device");
            return;
        }

        for (local i = 2 ; i < 256 ; i += 2) {
            if (i2c.read(i, "", 1) != null) server.log(format("Device at 8-bit address: 0x%02X (7-bit address: 0x%02X)", i, (i >> 1)));
        }
    },

    // BASIC STRING FUNCTIONS

    "mid": function(s, l, c = 0) {
        if (typeof s != "string") throw "?TYPE MISMATCH ERROR";
        if (l > s.len()) l = s.len();
        if (l > 0) l--;
        if (l < 0) l == 0;
        if (c == 0) c = s.len() - l;
        if (l + c >= s.len()) c = s.len() - l;
        return s.slice(l, l + c);
    },

    "left": function(s, r = 0) {
        if (typeof s != "string") throw "?TYPE MISMATCH ERROR";
        if (r <= 0) r = 1;
        if (r > s.len()) r = s.len();
        return s.slice(0, r);
    },

    "right": function(s, l = 0) {
        if (typeof s != "string") throw "?TYPE MISMATCH ERROR";
        if (l <= 0) l = 1
        if (l > s.len()) l = s.len();
        return s.slice(s.len() - l);
    },

    "chr": function(v) {
        if (typeof v == "float") v = v.tointeger();
        if (typeof v != "integer") throw "?TYPE MISMATCH ERROR";
        if (v < 0 || v > 255 ) throw "?ILLEGAL QUANTITY ERROR";
        return format("%c",v);
    },

    "asc": function(s) {
        if (typeof s != "string") throw "?TYPE MISMATCH ERROR";
        if (s.len() < 1) throw "?ILLEGAL QUANTITY ERROR";
        return s[0];
    },

    "sign": function(v) {
        if (v < 0) return -1;
        if (v > 0) return 1;
        return 0;
    }
}
