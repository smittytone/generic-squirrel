// Code version for Squinter
#version "2.1.1"

/**
 * Disconection/reconnection Mananger
 *
 * Provides disconnectionManager, a gloabl object which operates as a handler for imp connection states.
 * It monitors connection state and will automatically attempt to reconnect when the imp disconnects unexpectedly
 *
 * @author    Tony Smith (@smittytone)
 * @copyright Tony Smith, 2018-19
 * @licence   MIT
 * @version   2.1.1
 *
 * @table
 *
 */
disconnectionManager <- {

    // ********** Public Properties **********

    "reconnectTimeout" : 30,
    "reconnectDelay" : 60,
    "monitoring" : false,
    "isConnected" : true,
    "message" : "",
    "reason" : SERVER_CONNECTED,
    "retries" : 0,
    "offtime" : null,
    "eventCallback" : null,

    /**
     * Begin monitoring device connection state
     *
     * @param {integer/float} [timeout]    - The max. time (in seconds) allowed for the server to acknowledge receipt of data. Default: 10s
     * @param {integer}       [sendPolicy] - The send policy: either WAIT_TIL_SENT or WAIT_FOR_ACK. Default: WAIT_TIL_SENT
     *
     */
    "start" : function(timeout = 10, sendPolicy = WAIT_TIL_SENT) {
        // Check parameter type, and fix if it's wrong
        if (typeof timeout != "integer" && typeof timeout != "float") timeout = 10;
        if (sendPolicy != WAIT_TIL_SENT && sendPolicy != WAIT_FOR_ACK) sendPolicy = WAIT_TIL_SENT;

        // Register handlers etc.
        // NOTE We assume use of RETURN_ON_ERROR as DisconnectionManager is
        //      largely redundant with the SUSPEND_ON_ERROR policy
        server.setsendtimeoutpolicy(RETURN_ON_ERROR, sendPolicy, timeout);
        server.onunexpecteddisconnect(disconnectionManager._hasDisconnected.bindenv(this));
        disconnectionManager.monitoring = true;
        disconnectionManager._wakeup({"message": "Enabling disconnection monitoring"});

        // Check for initial connection (give it time to connect)
        disconnectionManager.connect();
    },

    /**
     * Stop monitoring connection state
     *
     */
    "stop" : function() {
        // De-Register handlers etc.
        disconnectionManager.monitoring = false;
        disconnectionManager._wakeup({"message": "Disabling disconnection monitoring"});
    },

    /**
     * Attempt to connect to the server. No effect if the imp is already connected
     *
     */
    "connect" : function() {
        // Attempt to connect to the server if we're not connected already
        // We do this to set our initial state
        disconnectionManager.isConnected = server.isconnected();
        if (!disconnectionManager.isConnected) {
            disconnectionManager._wakeup({"message": "Manually connecting to server", "type": "connecting"});
            server.connect(disconnectionManager._eventHandler.bindenv(this), disconnectionManager.reconnectTimeout);
        } else {
            disconnectionManager._wakeup({"type": "connected"});
        }
    },

    /**
     * Manually disconnect from the server
     *
     */
    "disconnect" : function() {
        // Disconnect from the server if we're not disconnected already
        disconnectionManager.isConnected = false;
        if (server.isconnected()) {
            imp.onidle(function() {
                server.flush(10);
                server.disconnect();
                disconnectionManager._wakeup({"message": "Manually disconnected from server", "type": "disconnected"});
            }.bindenv(this));
        } else {
            disconnectionManager._wakeup({"type": "disconnected"});
        }
    },

    /**
     * Connection/disconnection event descriptor
     *
     * @typedef {table} eventDesc
     *
     * @property {string}  type    - Human-readable event type: "connected", "connecting", "disconnected"
     * @property {string}  message - Human-readable notification message
     * @property {integer} ts      - The timestamp when the message was queued. Added automatically
     *
     */

    /**
     * Connection state change notification callback function
     *
     * @callback eventcallback
     *
     * @param {eventDesc} event - An event descriptior
     *
     */

    /**
     * Set the manager's network event callback
     *
     * @param {eventcallback} cb - A function to which connection state change notifications are sent
     *
     */
    "setCallback" : function(cb = null) {
        // Convenience function for setting the framework's event report callback
        if (cb != null && typeof cb == "function") disconnectionManager.eventCallback = cb;
    },

    // ********** Private Properties DO NOT ACCESS DIRECTLY **********

    "_noIP" : false,
    "_codes" : ["No WiFi connection", "No LAN connection", "No IP address (DHCP error)", "impCloud IP not resolved (DNS error)",
                "impCloud unreachable", "Connected to impCloud", "No proxy server", "Proxy credentials rejected"],

    // ********** Private Methods DO NOT CALL DIRECTLY **********

    /**
     * Function called whenever the server connection is broken or re-established, initially by impOS' unexpected disconnect
     * code and then repeatedly by server.connect(), below, as it periodically attempts to reconnect
     *
     * @private
     *
     * @param {integer} reason - The imp API (see server.connect()) connection/disconnection event code
     *
     */
    "_eventHandler" : function(reason) {
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

    /**
     * This is an intercept function for 'server.onunexpecteddisconnect()' to handle the double-calling of this method's registered handler
     * when the imp loses its link to DHCP but still has WiFi
     *
     * @private
     *
     * @param {integer} reason - The imp API (see server.connect()) connection/disconnection event code
     *
     */
    "_hasDisconnected" : function(reason) {
        if (!disconnectionManager._noIP) {
            disconnectionManager._noIP = true;
            disconnectionManager._eventHandler(reason);
        }
    },

    /**
     * Return the connection error/disconnection reason as a human-readable string
     *
     * @private
     *
     * @param {integer} code - The imp API (see server.connect()) connection/disconnection event code
     *
     * @returns {string} The human-readable string
     *
     */
    "_getReason" : function(code) {
        return _codes[code];
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
     * @returns {string} The timestamp string, eg. "12:45:0 +1:00"
     *
     */
    "_formatTimeString" : function(time = null) {
        local bst = false;
        if ("utilities" in getroottable()) bst = utilities.isBST();
        if (time == null) time = date();
        time.hour += (bst ? 1 : 0);
        if (time.hour > 23) time.hour -= 24;
        local z = bst ? "+01:00" : "UTC";
        return format("%02i:%02i:%02i %s", time.hour, time.min, time.sec, z);
    },

    //
    /**
     * Queue up a message post with the supplied data on an immediate timer
     *
     * @private
     *
     * @param {eventDesc} evd - An event descriptor
     *
     */
    "_wakeup": function(evd) {
        // Add a message timestamp
        evd.ts <- time();

        if (disconnectionManager.eventCallback != null) {
            imp.wakeup(0, function() {
                disconnectionManager.eventCallback(evd);
            });
        }
    }
}
