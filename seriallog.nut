// Serial logger
// Licence: MIT

// Code version for Squinter
#version "2.0.2"

seriallog <- {
    "uart" : null,
    "enabled" : false,
    "configured": false,
    "configure" : function(uart = null, baud = 115200, txsize = 160, enable = true) {
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
            }
            server.log("Read the serial log via hardware.uart" + u);
        } else {
            server.log("Read the serial log via the programmed UART");
        }
        seriallog.uart = uart;
        seriallog.uart.settxfifosize(txsize);
        seriallog.uart.configure(baud, 8, PARITY_NONE, 1, NO_RX | NO_CTSRTS);
        seriallog.configured = true;
        if (typeof enable == "bool") seriallog.enabled = enable;
    },

    "enable" : function() { 
        if (!seriallog.configured) seriallog.configure();
        seriallog.enabled = true;
    },
    
    "disable" : function() { 
        seriallog.enabled = false;
    },

    "log": function(message) {
        if (seriallog.enabled) {
            if (!seriallog.configured) seriallog.configure();
            seriallog.uart.write("[IMP LOG] " + seriallog.settimestring() + " " + message + "\r\n");
        }
        server.log(message);
    },

    "error": function(message) {
        if (seriallog.enabled) {
            if (!seriallog.configured) seriallog.configure();
            seriallog.uart.write("[IMP ERR] " + seriallog.settimestring() + " " + message + "\r\n");
        }
        server.error(message);
    },

    "settimestring": function(time = null) {
        // If 'time' is supplied, it must be a table formatted as per the output of 'date()'
        local now = time != null ? time : date();
        local bst = false;
        if ("utilities" in getroottable()) bst = utilities.isBST();
        now.hour += (bst ? 1 : 0);
        if (now.hour > 23) now.hour -= 24;
        local z = bst ? "+01:00" : "UTC";
        return format("%04d-%02d-%02d %02d:%02d:%02d %s", now.year, now.month + 1, now.day, now.hour, now.min, now.sec, z);
    }
}
