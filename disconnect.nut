// Provide disconnection functionality as a table of functions and properties
// Copyright Tony Smith, 2018
// Licence: MIT

// Code version for Squinter
#version "2.1.0"

disconnectionManager <- {

    // Public Properties
    "reconnectTimeout" : 30,
    "reconnectDelay" : 60,
    "monitoring" : false,
    "isConnected" : true,
    "message" : "",
    "reason" : SERVER_CONNECTED,
    "retries" : 0,
    "offtime" : null,
    
    // The event report callback
    // Should take the form 'function(event)', where 'event' is a table with the key 'message', whose
    // value is a human-readable string, and 'type' is a machine readable string, eg. 'connected'
    // NOTE 'type' may be absent for purely informational, event-less messages
    "eventCallback" : null,

    // Public Methods
    "start" : function(timeout = 10, sendPolicy = WAIT_TIL_SENT) {
        // Check parameter type, and fix if it's wrong
        if (typeof timeout != "integer" && typeof timeout != "float") timeout = 10;

        // Register handlers etc.
        // NOTE We assume use of RETURN_ON_ERROR as DisconnectionManager is
        //      largely redundant with the SUSPEND_ON_ERROR policy
        server.setsendtimeoutpolicy(RETURN_ON_ERROR, sendPolicy, timeout);
        server.onunexpecteddisconnect(disconnectionManager._hasDisconnected);
        disconnectionManager.monitoring = true;
        disconnectionManager._wakeup({"message": "Enabling disconnection monitoring"});

        // Check for initial connection (give it time to connect)
        disconnectionManager.connect();
    },

    "stop" : function() {
        // De-Register handlers etc.
        disconnectionManager.monitoring = false;
        disconnectionManager._wakeup({"message": "Disabling disconnection monitoring"});
    },

    "connect" : function() {
        // Attempt to connect to the server if we're not connected already
        // We do this to set our initial state
        disconnectionManager.isConnected = server.isconnected();
        if (!disconnectionManager.isConnected) {
            server.connect(disconnectionManager._eventHandler.bindenv(this), disconnectionManager.reconnectTimeout);
            disconnectionManager._wakeup({"message": "Manually connecting to server", "type": "connecting"});
        } else {
            disconnectionManager._wakeup({"type": "connected"});
        }
    },

    "disconnect" : function() {
        // Disconnect from the server if we're not disconnected already
        if (server.isconnected()) {
            server.flush(10);
            server.disconnect();
            disconnectionManager.isConnected = false;
            disconnectionManager._wakeup({"message": "Manually disconnected from server", "type": "disconnected"});
        } else {
            disconnectionManager._wakeup({"type": "disconnected"});
        }
    },

    "setCallback" : function(cb = null) {
        // Convenience function for setting the framework's event report callback
        if (cb != null && typeof cb == "function") disconnectionManager.eventCallback = cb;
    },

    // Private Properties **DO NOT ACCESS DIRECTLY**
    "_noIP" : false,
    "_codes" : ["No WiFi connection", "No LAN connection", "No IP address (DHCP error)", "impCloud IP not resolved (DNS error)", 
                "impCloud unreachable", "Connected to impCloud", "No proxy server", "Proxy credentials rejected"],

    // Private Methods **DO NOT CALL DIRECTLY**
    "_eventHandler" : function(reason) {
        // Called if the server connection is broken or re-established, initially by impOS' unexpected disconnect
        // code and then repeatedly by server.connect(), below, as it periodically attempts to reconnect
        // Sets 'isConnected' to true if there is NO connection

        // If we are not checking for unexpected disconnections, bail
        if (!disconnectionManager.monitoring) return;

        if (reason != SERVER_CONNECTED) {
            // The device wasn't previously disconnected, so set the state to 'disconnected', ie. 'isConnected' is true
            if (disconnectionManager.isConnected) {
                // Set the connection state data and disconnection info data
                // NOTE connection fails 60s before 'eventHandler' is called
                disconnectionManager.isConnected = false;
                disconnectionManager.retries = 0;
                disconnectionManager.reason = reason;
                disconnectionManager.offtime = date();

                // Send a 'disconnected' event to the host app
                disconnectionManager._wakeup({"message": "Device unexpectedly disconnected", "type" : "disconnected"});
            } else {
                // Send a 'still disconnected' event to the host app
                local m = disconnectionManager._formatTimeString();
                disconnectionManager._wakeup({"message": "Device still disconnected at " + m,
                                              "type" : "disconnected"});
            }

            // Schedule an attempt to re-connect in 'reconnectDelay' seconds
            imp.wakeup(disconnectionManager.reconnectDelay, function() {
                if (!server.isconnected()) {
                    // If we're not connected, send a 'connecting' event to the host app and try to connect
                    disconnectionManager.retries += 1;
                    disconnectionManager._wakeup({"message": "Device connecting", "type" : "connecting"});
                    server.connect(disconnectionManager._eventHandler.bindenv(this), disconnectionManager.reconnectTimeout);
                } else {
                    // If we are connected, re-call 'eventHandler()' to make sure the 'connnected' flow is executed
                    // disconnectionManager._wakeup({"message": "Wakeup code called, but device already connected"});
                    disconnectionManager._eventHandler(SERVER_CONNECTED);
                }
            }.bindenv(this));
        } else {
            // The imp is back online
            if (!disconnectionManager.isConnected) {
                // Send a 'connected' event to the host app
                // Report the time that the device went offline
                local m = disconnectionManager._formatTimeString(disconnectionManager.offtime);
                m = format("Went offline at %s. Reason: %s (%i)", m, disconnectionManager._getReason(disconnectionManager.reason), disconnectionManager.reason);
                disconnectionManager._wakeup({"message": m});

                // Report the time that the device is back online
                m = disconnectionManager._formatTimeString();
                m = format("Back online at %s. Connection attempts: %i", m, disconnectionManager.retries);
                disconnectionManager._wakeup({"message": m, "type" : "connected"});
            }

            // Re-set state data
            disconnectionManager.isConnected = true;
            disconnectionManager._noIP = false;
            disconnectionManager.offtime = null;
        }
    },

    "_hasDisconnected" : function(reason) {
        // This is an intercept function for 'server.onunexpecteddisconnect()'
        // to handle the double-calling of this method's registered handler
        // when the imp loses its link to DHCP but still has WiFi
        if (!disconnectionManager._noIP) {
            disconnectionManager._noIP = true;
            disconnectionManager._eventHandler(reason);
        }
    },

    "_getReason" : function(code) {
        return _codes[code];
    },

    "_formatTimeString" : function(n = null) {
        local bst = false;
        if ("utilities" in getroottable()) bst = utilities.isBST();
        if (n == null) n = date();
        n.hour += (bst ? 1 : 0);
        if (n.hour > 23) n.hour -= 24;
        local z = bst ? "+01:00" : "UTC";
        return format("%02i:%02i:%02i %s", n.hour, n.min, n.sec, z);
    },

    "_wakeup": function(data) {
        // Queue up a message post with the supplied data

        // Add a message timestamp
        data.ts <- time();

        if (disconnectionManager.eventCallback != null) {
            imp.wakeup(0, function() {
                disconnectionManager.eventCallback(data);
            });
        }
    }
}
