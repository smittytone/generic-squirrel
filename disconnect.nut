DisconnectionHandler <- {

    // Provide disconnection functionality as a table of functions
    
    // Mock CONSTS
    "reconnectTimeout": 30,
    "reconnectDelay": 60,

    // Disconnection state data
    "message": "",
    "flag": false,
    "debug": false,

    // The reconnection callback
    "eventCallback": null,

    "eventHandler": function(reason) {
        // Called if the server connection is broken or re-established
        // Sets 'flag' to true if there is NO connection
        if (reason != SERVER_CONNECTED) {
            // We weren't previously disconnected, so mark us as disconnected now
            if (!flag) {
                flag = true;
                local now = date();
                message = "Went offline at " + now.hour + ":" + now.min + ":" + now.sec + ". Reason: " + reason;
                if (eventCallback != null) callback({"event": "disconnected"});
            }

            // Schedule an attempt to re-connect in RECONNECT_DELAY seconds
            imp.wakeup(reconnectDelayr, function() {
                // Tell the host app that we're connecting
                if (eventCallback != null) callback({"event": "connecting"});
                
                // If we're not connected, attempt to do so. If we are connected,
                // re-call 'eventHandler()' to make sure the 'connnected' flow is actioned
                if (!server.isconnected()) {
                    server.connect(DisconnectionHandler.eventHandler.bindenv(this), reconnectTimeout);
                } else {
                    DisconnectionHandler.eventHandler(SERVER_CONNECTE);
                }
            }.bindenv(this));
        } else {
            // Back online so request a weather forecast from the agent
            if (flag) {
                if (debug) {
                    server.log(message);
                    local now = date();
                    server.log("Back online at " + now.hour + ":" + now.min + ":" + now.sec);
                }

                if (eventCallback != null) callback({"event": "connected"});
            }

            flag = false;
        }
    }
    
    "startMonitoring": function() {
        // Register handlers etc.
        server.onunexpecteddisconnect(DisconnectionHandler.eventHandler)
    }
}
