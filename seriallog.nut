// Code version for Squinter
#version "2.2.0"

/**
 * Serial logger
 *
 * Incorporates code which sends log and error messages to UART as well as to the imp API methods server.log()*
 * and server.error(). To use this code as-is, replace all of your application's server.log() and server.error()
 * calls with seriallog.log() and *seriallog.error()
 *
 * @Author  Tony Smith (@smittytone)
 * @licence MIT
 * @version 2.2.0
 *
 * @table
 *
 */
seriallog <- {
    // Public Properties
    "uart" : null,
    "enabled" : false,
    "configured": false,
    "txsize": 120,

    /**
     * Configures the serial logger
     *
     * @param {imp::uart} [uart]     - The imp UART object. Default: imp-specific UART (see code)
     * @param {integer}   [baudrate] - The speed of the UART in bits per second. Default: 115200
     * @param {integer}   [txsize]   - The size of the UART transmit buffer in bytes. Default: 80
     * @param {bool}      [enable]   - Whether to enable the serial logger immediately. Default: true
     *
     */
    "configure" : function(uart = null, baudrate = 115200, txsize = 120, enable = true) {
        // Pass a UART object, eg. hardware.uart6E; your preferred baud rate; and initial state
        // NOTE UART is enabled by default and UART will be chosen for you if you pass in null
        //      If you don't call configure, serial logging is disabled by default but
        //      server logging will continue (provided the imp is connected)
        if (uart == null) {
            // No passed in UART object, so pick one and log it
            local u = "";
            switch(imp.info().type) {
              case "imp001":
              case "imp002":
                uart = hardware.uart12;
                u = "12";
                break;
              case "imp003":
                uart = hardware.uartDM;
                u = "DM";
                break;
              case "imp004m":
                uart = hardware.uartHJ;
                u = "HJ";
                break;
              case "imp005":
                uart = hardware.uart0;
                u = "0";
              case "imp006":
                uart = hardware.uartABCD;
                u = "ABCD";
              case "impC001":
                uart = hardware.uartNU;
                u = "NU";
            }
            server.log("Read the serial log via hardware.uart" + u);
        } else {
            server.log("Read the serial log via the programmed UART");
        }
        seriallog.uart = uart;
        if (typeof txsize != "integer" || txsize < 80) txsize = 80;
        seriallog.txsize = txsize;
        seriallog.uart.settxfifosize(txsize);
        local speed = seriallog.uart.configure(baudrate, 8, PARITY_NONE, 1, NO_RX | NO_CTSRTS);
        server.log("UART speed: " + speed);
        seriallog.configured = true;
        if (typeof enable == "bool") seriallog.enabled = enable;
    },

    /**
     * Enable logging via serial
     *
     */
    "enable" : function() {
        if (!seriallog.configured) seriallog.configure();
        seriallog.enabled = true;
    },

    /**
     * Disable logging via serial
     *
     */
    "disable" : function() {
        seriallog.enabled = false;
    },

    /**
     * Log a message. This also (always) logs to the server
     *
     * @param  {string} message - The message to be logged
     *
     */
    "log": function(message) {
        seriallog._logtouart(message);
        server.log(message);
    },

    /**
     * Log an error message. This also (always) logs to the server
     *
     * @param {string} message - The error message to be logged
     *
     */
    "error": function(message) {
        seriallog._logtouart(message);
        server.error(message);
    },

    // ********** Private Methods DO NOT CALL DIRECTLY **********

    /**
     * Writes the supplied text string ('message') to UART
     *
     * @private
     *
     * @param {string} message - The error message to be logged
     *
     */
    "_logtouart": function(message) {
        if (seriallog.enabled) {
            if (!seriallog.configured) seriallog.configure();
            local s = "[IMP LOG] (" + seriallog._formatTimeString() + ") " + message;

            // Break the message into lines of 'txsize' characters (last may be less)
            local done = false;
            do {
                local t = "";
                if (s.len() > seriallog.txsize) {
                    t = s.slice(0, seriallog.txsize);
                    s = s.slice(seriallog.txsize, s.len());
                } else {
                    t = s;
                    done = true;
                }
                seriallog.uart.write(t + "\r\n");
            } while (!done);
        }
    },

    /**
     * Format a timestamp string, either the current time (default; pass null as the argument),
     * or a specific time (pass a timestamp as the argument). Includes the timezone
     * NOTE It is able to make use of the 'utilities' BST checker, if also included in your application
     *
     * @private
     *
     * @param {table} [n] - A Squirrel date/time description table (see date()). Default: current date
     *
     * @returns {string} The timestamp string, eg. "2019-01-31 12:45:0 +1:00"
     *
     */
    "_formatTimeString": function(time = null) {
        local bst = false;
        if ("utilities" in getroottable()) bst = utilities.isBST();
        if (time == null) time = date();
        time.hour += (bst ? 1 : 0);
        if (time.hour > 23) time.hour -= 24;
        local z = bst ? "+01:00" : "UTC";
        return format("%04d-%02d-%02d %02d:%02d:%02d %s", time.year, time.month + 1, time.day, time.hour, time.min, time.sec, z);
    }
}

log <- function(msg) {
    seriallog.log(msg);
}

err <- function(msg) {
    seriallog.error(msg);
}