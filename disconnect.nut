// Provide disconnection functionality as a table of functions and properties
// Copyright Tony Smith, 2018
// Licence: MIT
#version "1.0.2"
disconnectionManager <- {

    // Timeout periods
    "reconnectTimeout" : 30,
    "reconnectDelay" : 60,

    // Disconnection state data and information stores
    "monitoring" : false,
    "flag" : false,
    "message" : "",
    "reason" : SERVER_CONNECTED,
    "retries" : 0,
    "offtime" : null,
    "timer" : null,

    // The event report callback
    // Should take the form 'function(event)', where 'event' is a table with the key 'message', whose
    // value is a human-readable string, and 'type' is a machine readable string, eg. 'connected'
    // NOTE 'type' may be absent for purely informational, event-less messages
    "eventCallback" : null,

    "eventHandler" : function(reason) {
        // Called if the server connection is broken or re-established, initially by impOS' unexpected disconnect
        // code and then repeatedly by server.connect(), below, as it periodically attempts to reconnect
        // Sets 'flag' to true if there is NO connection

        // If we are not checking for unexpected disconnections, bail
        if (!disconnectionManager.monitoring) return;

        if (reason != SERVER_CONNECTED) {
            // The device wasn't previously disconnected, so set the state to 'disconnected', ie. 'flag' is true
            if (!disconnectionManager.flag) {
                // Reset the disconnection state data
                disconnectionManager.flag = true;
                disconnectionManager.retries = 0;
                disconnectionManager.reason = reason;

                // Record the disconnection time for future reference
                // NOTE connection fails 60s before 'eventHandler' is called
                disconnectionManager.offtime = date();

                // Send a 'disconnected' event to the host app
                if (disconnectionManager.eventCallback != null) disconnectionManager.eventCallback({"message": "Device unexpectedly disconnected", "type" : "disconnected"});
            } else {
                // Send a 'still disconnected' event to the host app
                if (disconnectionManager.eventCallback != null) disconnectionManager.eventCallback({"type" : "disconnected"});
            }

            // Schedule an attempt to re-connect in 'reconnectDelay' seconds
            if (disconnectionManager.timer == null) {
                disconnectionManager.timer = imp.wakeup(disconnectionManager.reconnectDelay, function() {
                    disconnectionManager.timer = null;
                    if (!server.isconnected()) {
                        // If we're not connected, send a 'connecting' event to the host app and try to connect
                        disconnectionManager.retries += 1;
                        if (disconnectionManager.eventCallback != null) disconnectionManager.eventCallback({"message": "Device connecting", "type" : "connecting"});
                        server.connect(disconnectionManager.eventHandler.bindenv(this), disconnectionManager.reconnectTimeout);
                    } else {
                        // If we are connected, re-call 'eventHandler()' to make sure the 'connnected' flow is executed
                        if (disconnectionManager.eventCallback != null) disconnectionManager.eventCallback({"message": "Wakeup code called, but already connected"});
                        disconnectionManager.eventHandler(SERVER_CONNECTED);
                    }
                }.bindenv(this));
            }
        } else {
            // The imp is back online
            if (disconnectionManager.flag) {

                if (disconnectionManager.timer != null) {
                    // For some reason (TBD) we have a timer in play, so cancel it now we're back online
                    imp.cancelwakeup(disconnectionManager.timer);
                    disconnectionManager.timer = null;
                }

                if (disconnectionManager.eventCallback != null) {
                    // Send a 'connected' event to the host app
                    // Report the time that the device went offline
                    local now = disconnectionManager.offtime;
                    disconnectionManager.eventCallback({"message": format("Went offline at %02i:%02i:%02i. Reason %i", now.hour, now.min, now.sec, disconnectionManager.reason)});

                    // Report the time that the device is back online
                    now = date();
                    disconnectionManager.eventCallback({"message": format("Back online at %02i:%02i:%02i. Connection attempts: %i", now.hour, now.min, now.sec, disconnectionManager.retries), "type" : "connected"});
                }
            }

            disconnectionManager.flag = false;
            disconnectionManager.offtime = null;
        }
    }

    "start" : function(timeout = 10) {
        // Check parameter type, and fix if it's wrong
        if (typeof timeout != "integer") timeout = 10;

        // Register handlers etc.
        server.setsendtimeoutpolicy(RETURN_ON_ERROR, WAIT_TIL_SENT, timeout);
        server.onunexpecteddisconnect(disconnectionManager.eventHandler);
        disconnectionManager.monitoring = true;
        if (disconnectionManager.eventCallback != null) disconnectionManager.eventCallback({"message": "Enabling disconnection monitoring"});
    }

    "stop" : function() {
        // De-Register handlers etc.
        disconnectionManager.monitoring = false;
        if (disconnectionManager.eventCallback != null) disconnectionManager.eventCallback({"message": "Disabling disconnection monitoring"});
    }

    "connect" : function() {
        // Attempt to connect to the server if we're not connected already
        if (!server.isconnected()) {
            server.connect(disconnectionManager.eventHandler.bindenv(this), disconnectionManager.reconnectTimeout);
            if (disconnectionManager.eventCallback != null) disconnectionManager.eventCallback({"message": "Manually connecting to server", "type": "connecting"});
        } else {
            if (disconnectionManager.eventCallback != null) disconnectionManager.eventCallback({"type": "connected"});
        }
    }

    "disconnect" : function() {
        // Disconnect from the server if we're not disconnected already
        if (server.isconnected()) {
            server.flush(10);
            server.disconnect();
            if (disconnectionManager.eventCallback != null) disconnectionManager.eventCallback({"message": "Manually disconnected from server", "type": "disconnected"});
        } else {
            if (disconnectionManager.eventCallback != null) disconnectionManager.eventCallback({"type": "disconnected"});
        }
    }

    "setCallback" : function(cb = null) {
        // Convenience function for setting the framework's event report callback
        if (cb != null && typeof cb == "function") disconnectionManager.eventCallback = cb;
    }
}
