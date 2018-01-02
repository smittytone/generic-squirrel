// Utility functions accessed via the table 'utilities'
// Licence: MIT
// Code version 1.1.1

utilities <- {};

// ********** Hex Conversion Functions **********
// **********         Public           **********
utilities.hexStringToInteger <- function(hs) {
    if (hs.slice(0, 2) == "0x") hs = hs.slice(2);
    local i = 0;
    foreach (c in hs) {
        local n = c - '0';
        if (n > 9) n = ((n & 0x1F) - 7);
        i = (i << 4) + n;
    }
    return i;
}

utilities.hexStringToBlob <- function(hs) {
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
}

utilities.integerToHexString <- function (i) {
    return format("0x%02x", i);
}

utilities.blobToHexString <- function (b) {
    local s = "0x";
    for (local i = 0 ; i < b.len() ; i++) s += format("%02x", b[i]);
    return s;
}

// ********** Random Number Functions  **********
// **********         Public           **********
utilities.frnd <- function(m) {
    // Return a pseudorandom float between 0 and max, inclusive
    return (1.0 * math.rand() / RAND_MAX) * (m + 1);
}

utilities.rnd <- function(m) {
    // Return a pseudorandom integer between 0 and max, inclusive
    return frnd(m).tointeger();
}

// ********** Number Format Functions  **********
// **********         Public           **********
utilities.numberFormatter <- function(n, d = null, s = ",") {
    if (d == null) {
        if (typeof n == "string") d = 0;
        else if (typeof n == "integer") d = 0;
        else if (typeof n == "float") d = 2;
        else return n;
    }

    if (typeof n == "string") {
        if (d == 0) {
            n = n.tointeger();
        } else {
            n = n.tofloat();
        }
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
}

// **********    Calendar Functions    **********
// **********         Public           **********
utilities.dayOfWeek <- function(d, m, y) {
    local dim = [
        [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31],
        [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    ];

    local ad = ((y - 1) * 365) + _totalLeapDays(y) + d - 5;
    for (local i = 0 ; i < m ; ++i) {
        local a = dim[utilities._isLeapYear(y)];
        ad = ad + a[i];
    }
    return (ad % 7) - 1;
}

utilities.isLeapYear <- function(y) {
    if (utilities._isLeapYear(y) == 1) return true;
    return false;
}

utilities.bstCheck <- function() {
    // Checks the current date for British Summer Time,
    // returning true or false accordingly
    local n = date();
    if (n.month > 2 && n.month < 9) return true;

    if (n.month == 2) {
        // BST starts on the last Sunday of March
        for (local i = 31 ; i > 24 ; --i) {
            if (utilities.dayOfWeek(i, 2, n.year) == 0 && n.day >= i) return true;
        }
    }

    if (n.month == 9) {
        // BST ends on the last Sunday of October
        for (local i = 31 ; i > 24 ; --i) {
            if (utilities.dayOfWeek(i, 9, n.year) == 0 && n.day < i) return true;
        }
    }
    return false;
}

utilities.dstCheck <- function() {
    // Checks the current date for US Daylight Savings Time,
    // returning true or false accordingly
    local n = date();
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
}

// **********         Private         **********
utilities._totalLeapDays <- function(y) {
    local t = y / 4;
    if (utilities._isLeapYear(y) == 1) t = t - 1;
    t = t - ((y / 100) - (1752 / 100)) + ((y / 400) - (1752 / 400));
    return t;
}

utilities._isLeapYear <- function(y) {
    if ((y % 400) || ((y % 100) && !(y % 4))) return 1;
    return 0;
}

// **********  UUID Accessor Function  **********
// **********         Public           **********
utilities.getNewUUID <- function(cb = null) {
    if (cb == null) {
        server.error("getNewUUID() requires a callback function with err, data parameters");
        return;
    }

    ::_uuidcb <- cb;
    http.get("https://www.uuidgenerator.net/").sendasync(utilities._extractUUID);
}

// **********         Private          **********
utilities._extractUUID <- function(rs) {
    local u = "";
    if (rs.statuscode == 200) {
        if (rs.body.len() > 0) {
            for (local i = 0 ; i < (rs.body.len() - 15) ; ++i) {
                local s = rs.body.slice(i, i + 15);
                if (s == "h2 class=\"uuid\"") {
                    u = rs.body.slice(i + 16, i + 52);
                    break;
                }
            }

            ::_uuidcb(null, u);
        }
    } else {
        ::_uuidcb("Error connecting to or receiving data from UUID generator", null);
    }
}

// **********       I2C Function       **********
// **********         Public           **********
utilities.debugI2C <- function(i2c) {
    if (imp.environment() == ENVIRONMENT_AGENT) {
        server.error("utilities.debugI2C() can only be run on a device");
        return;
    }

    for (local i = 2 ; i < 256 ; i+=2) {
        if (i2c.read(i, "", 1) != null) {
            server.log(format("Device at 8-bit address: 0x%02X (7-bit address: 0x%02X)", i, (i >> 1)));
        }
    }
}

// **********    Start up Function     **********
// **********         Public           **********
utilities.getStartUpReason <- function(reasonCode = null) {
    // Return the recorded reason for the device’s start-up
    local reason = "";
    local causes = [ "Cold boot", "Woken after sleep", "Software reset", "Wakeup pin triggered",
                     "Application code updated", "Squirrel error during the last run"
                     "This device has a new impOS", "Woken by a snooze-and-retry event",
                     "imp003 Reset pin triggered", "This device has just been re-configured",
                     "Restarted by server.restart()" ];
    try {
        reason = reasonCode != null ? "Device restarted: " + causes[reasonCode] : "Device restarted: " + causes[hardware.wakereason()];
    } catch (err) {
        reason = "Device restarted: Reason unknown";
    }

    return reason;
}

