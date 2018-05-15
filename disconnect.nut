disconnectionmanager <- {

    // Provide disconnection functionality as a table of functions and properties

    // Timeout periods
    "reconnectTimeout" : 30,
    "reconnectDelay" : 60,

    // Disconnection state data
    "message" : "",
    "flag" : false,
    "monitoring" : false,
    "debug" : false,

    // The reconnection callback
    // Should take the form 'function(event)', where 'event' is a table with the key 'message', whose
    // value is a string, and 'type' is also a string, but intended to be machine readable
    "eventCallback" : null,

    "eventHandler" : function(reason) {
        // Called if the server connection is broken or re-established
        // Sets 'flag' to true if there is NO connection
        if (!disconnectionhandler.monitoring) return;
        if (reason != SERVER_CONNECTED) {
            // We weren't previously disconnected, so mark us as disconnected now
            if (!disconnectionhandler.flag) {
                disconnectionhandler.flag = true;
                local now = date();
                disconnectionhandler.message = "Went offline at " + now.hour + ":" + now.min + ":" + now.sec + ". Reason: " + reason;
            }

            if (disconnectionhandler.eventCallback != null) disconnectionhandler.eventCallback({"message": "unexpectedly disconnected", "type" : "disconnect"});

            // Schedule an attempt to re-connect in RECONNECT_DELAY seconds
            imp.wakeup(disconnectionhandler.reconnectDelay, function() {
                // Tell the host app that we're connecting
                if (disconnectionhandler.eventCallback != null) disconnectionhandler.eventCallback({"message": "connecting", "type" : "connecting"});

                // If we're not connected, attempt to do so. If we are connected,
                // re-call 'eventHandler()' to make sure the 'connnected' flow is actioned
                if (!server.isconnected()) {
                    server.connect(disconnectionhandler.eventHandler.bindenv(this), disconnectionhandler.reconnectTimeout);
                } else {
                    disconnectionhandler.eventHandler(SERVER_CONNECTED);
                }
            }.bindenv(this));
        } else {
            // Back online so request a weather forecast from the agent
            if (disconnectionhandler.flag) {
                if (disconnectionhandler.debug) {
                    server.log(disconnectionhandler.message);
                    local now = date();
                    server.log("Back online at " + now.hour + ":" + now.min + ":" + now.sec);
                }
            }

            disconnectionhandler.flag = false;
            if (disconnectionhandler.eventCallback != null) disconnectionhandler.eventCallback({"message": "connected", "type" : "connect"});
        }
    }

    "start" : function() {
        // Register handlers etc.
        server.setsendtimeoutpolicy(RETURN_ON_ERROR, WAIT_TIL_SENT, 10);
        server.onunexpecteddisconnect(disconnectionhandler.eventHandler);
        disconnectionhandler.monitoring = true;
        if (disconnectionhandler.debug) server.log("Enabling disconnection monitoring");
        if (disconnectionhandler.eventCallback != null) disconnectionhandler.eventCallback({"message": "monitoring on", "type" : "status"});
    }

    "stop" : function() {
        // De-Register handlers etc.
        disconnectionhandler.monitoring = false;
        if (disconnectionhandler.debug) server.log("Disabling disconnection monitoring");
        if (disconnectionhandler.eventCallback != null) disconnectionhandler.eventCallback({"message": "monitoring off", "type" : "status"});
    }

    "connect" : function() {
        if (!server.isconnected()) server.connect(disconnectionhandler.eventHandler.bindenv(this), disconnectionhandler.reconnectTimeout);
    }

    "disconnect" : function() {
        if (server.isconnected()) {
            server.flush(10);
            server.disconnect();
            if (disconnectionhandler.eventCallback != null) disconnectionhandler.eventCallback({"message": "manually disconnected", "type" : "disconnect"});
        }
    }

    "setCallback" : function(cb = null) {
        if (cb != null && typeof cb == "function") disconnectionhandler.eventCallback = cb;
    }

    "setDebug" : function(state = false) {
        if (state != null && typeof state == "boolean") disconnectionhandler.debug = state;
    }
}
