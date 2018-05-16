disconnectionmanager <- {

    // Provide disconnection functionality as a table of functions and properties

    // Timeout periods
    "reconnectTimeout" : 30,
    "reconnectDelay" : 60,

    // Disconnection state data and information stores
    "message" : "",
    "flag" : false,
    "monitoring" : false,

    // The event report callback
    // Should take the form 'function(event)', where 'event' is a table with the key 'message', whose
    // value is a human-readable string, and 'type' is a machine readable string, eg. 'connected'
    // NOTE 'type' may be absent for purely informational, event-less messages
    "eventCallback" : null,

    "eventHandler" : function(reason) {
        // Called if the server connection is broken or re-established
        // Sets 'flag' to true if there is NO connection
        if (!disconnectionhandler.monitoring) return;
        if (reason != SERVER_CONNECTED) {
            // We weren't previously disconnected, so mark us as disconnected now
            if (!disconnectionhandler.flag) {
                disconnectionhandler.flag = true;

                // Record the disconnection time for future reference
                local now = date();
                disconnectionhandler.message = "Went offline at " + now.hour + ":" + now.min + ":" + now.sec + ". Reason: " + reason;
            }

            // Send a 'disconnected' event to the host app
            if (disconnectionhandler.eventCallback != null) disconnectionhandler.eventCallback({"message": "Device unexpectedly disconnected", "type" : "disconnected"});

            // Schedule an attempt to re-connect in 'reconnectDelay' seconds
            imp.wakeup(disconnectionhandler.reconnectDelay, function() {
                if (!server.isconnected()) {
                    // If we're not connected, send a 'connecting' event to the host app and try to connect
                    if (disconnectionhandler.eventCallback != null) disconnectionhandler.eventCallback({"message": "Device connecting", "type" : "connecting"});
                    server.connect(disconnectionhandler.eventHandler.bindenv(this), disconnectionhandler.reconnectTimeout);
                } else {
                    // If we are connected, re-call 'eventHandler()' to make sure the 'connnected' flow is executed
                    disconnectionhandler.eventHandler(SERVER_CONNECTED);
                }
            }.bindenv(this));
        } else {
            // The imp is back online
            if (disconnectionhandler.flag && disconnectionhandler.eventCallback != null) {
                // Send a 'connected' event to the host app
                local now = date();
                disconnectionhandler.eventCallback({"message": ("Back online at " + now.hour + ":" + now.min + ":" + now.sec), "type" : "connected"});

                // Report the time that the device went offline
                disconnectionhandler.eventCallback({"message": disconnectionhandler.message});
            }

            disconnectionhandler.flag = false;
        }
    }

    "start" : function() {
        // Register handlers etc.
        server.setsendtimeoutpolicy(RETURN_ON_ERROR, WAIT_TIL_SENT, 10);
        server.onunexpecteddisconnect(disconnectionhandler.eventHandler);
        disconnectionhandler.monitoring = true;
        if (disconnectionhandler.eventCallback != null) disconnectionhandler.eventCallback({"message": "Enabling disconnection monitoring"});
    }

    "stop" : function() {
        // De-Register handlers etc.
        disconnectionhandler.monitoring = false;
        if (disconnectionhandler.eventCallback != null) disconnectionhandler.eventCallback({"message": "Disabling disconnection monitoring"});
    }

    "connect" : function() {
        // Attempt to connect to the server if we're not connected already
        if (!server.isconnected()) server.connect(disconnectionhandler.eventHandler.bindenv(this), disconnectionhandler.reconnectTimeout);
        if (disconnectionhandler.eventCallback != null) disconnectionhandler.eventCallback({"message": "Manually connecting to server", "type": "connecting"});
    }

    "disconnect" : function() {
        // Disconnect from the server if we're not disconnected already
        if (server.isconnected()) {
            server.flush(10);
            server.disconnect();
            if (disconnectionhandler.eventCallback != null) disconnectionhandler.eventCallback({"message": "Manually disconnected from server", "type": "disconnected"});
        }
    }

    "setCallback" : function(cb = null) {
        // Convenience function for setting the framework's event report callback
        if (cb != null && typeof cb == "function") disconnectionhandler.eventCallback = cb;
    }
}
