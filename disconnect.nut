// Provide disconnection functionality as a table of functions and properties
// Copyright Tony Smith, 2018
// Licence: MIT

// Code version for Squinter
#version "1.1.0"

disconnectionManager <- {

  // Timeout periods
  "reconnectTimeout" : 30,
  "reconnectDelay" : 60,

  // Disconnection state data and information stores
  "monitoring" : false,
  "isConnected" : true,
  "noIP" : false,
  "message" : "",
  "reason" : SERVER_CONNECTED,
  "retries" : 0,
  "offtime" : null,
  "codes" : ["Not connected", "No network", "No IP address", "impCloud IP Nor Resolved", "impCloud unreachable",
             "Connected to impCloud", "No proxy server", "Proxy credentials rejected"],

  // The event report callback
  // Should take the form 'function(event)', where 'event' is a table with the key 'message', whose
  // value is a human-readable string, and 'type' is a machine readable string, eg. 'connected'
  // NOTE 'type' may be absent for purely informational, event-less messages
  "eventCallback" : null,

  "eventHandler" : function(reason) {
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
        disconnectionManager.wakeup({"message": "Device unexpectedly disconnected", "type" : "disconnected"});
      } else {
        // Send a 'still disconnected' event to the host app
        local m = disconnectionManager.formatTimeString();
        disconnectionManager.wakeup({"message": "Device still disconnected at" + m,
                                     "type" : "disconnected"});
      }

      // Schedule an attempt to re-connect in 'reconnectDelay' seconds
      imp.wakeup(disconnectionManager.reconnectDelay, function() {
        if (!server.isconnected()) {
          // If we're not connected, send a 'connecting' event to the host app and try to connect
          disconnectionManager.retries += 1;
          disconnectionManager.wakeup({"message": "Device connecting", "type" : "connecting"});
          server.connect(disconnectionManager.eventHandler.bindenv(this), disconnectionManager.reconnectTimeout);
        } else {
          // If we are connected, re-call 'eventHandler()' to make sure the 'connnected' flow is executed
          disconnectionManager.wakeup({"message": "Wakeup code called, but already connected"});
          disconnectionManager.eventHandler(SERVER_CONNECTED);
        }
      }.bindenv(this));
    } else {
      // The imp is back online
      if (!disconnectionManager.isConnected) {
        // Send a 'connected' event to the host app
        // Report the time that the device went offline
        local m = disconnectionManager.formatTimeString(disconnectionManager.offtime);
        m = format("Went offline at %s. Reason: %s", m, disconnectionManager.getReason(disconnectionManager.reason));
        disconnectionManager.wakeup({"message": m});

        // Report the time that the device is back online
        m = disconnectionManager.formatTimeString();
        m = format("Back online at %s. Connection attempts: %i", m, disconnectionManager.retries);
        disconnectionManager.wakeup({"message": m, "type" : "connected"});
      }

      // Re-set state data
      disconnectionManager.isConnected = true;
      disconnectionManager.noIP = false;
      disconnectionManager.offtime = null;
    }
  },

  "hasDisconnected" : function(reason) {
    // This is an intercept function for 'server.onunexpecteddisconnect()'
    // to handle the double-calling of this method's registered handler
    // when the imp loses its link to DHCP but still has WiFi
    if (reason == NO_IP_ADDRESS) {
      if (disconnectionManager.noIP) return;
      disconnectionManager.noIP = true;
    }
    disconnectionManager.eventHandler(reason);
  },

  "start" : function(timeout = 10, sendPolicy = WAIT_TIL_SENT) {
    // Check parameter type, and fix if it's wrong
    if (typeof timeout != "integer" && typeof timeout != "float") timeout = 10;

    // Register handlers etc.
    // NOTE We assume use of RETURN_ON_ERROR as DisconnectionManager is
    //      largely redundant with the SUSPEND_ON_ERROR policy
    server.setsendtimeoutpolicy(RETURN_ON_ERROR, sendPolicy, timeout);
    server.onunexpecteddisconnect(disconnectionManager.hasDisconnected);
    disconnectionManager.monitoring = true;
    disconnectionManager.wakeup({"message": "Enabling disconnection monitoring"});

    // Check for initial connection (give it time to connect)
    disconnectionManager.connect();
  },

  "stop" : function() {
    // De-Register handlers etc.
    disconnectionManager.monitoring = false;
    disconnectionManager.wakeup({"message": "Disabling disconnection monitoring"});
  },

  "connect" : function() {
    // Attempt to connect to the server if we're not connected already
    // We do this to set our initial state
    disconnectionManager.isConnected = server.isconnected();
    if (!disconnectionManager.isConnected) {
      server.connect(disconnectionManager.eventHandler.bindenv(this), disconnectionManager.reconnectTimeout);
      disconnectionManager.wakeup({"message": "Manually connecting to server", "type": "connecting"});
    } else {
      disconnectionManager.wakeup({"type": "connected"});
    }
  },

  "disconnect" : function() {
    // Disconnect from the server if we're not disconnected already
    if (server.isconnected()) {
      server.flush(10);
      server.disconnect();
      disconnectionManager.isConnected = false;
      disconnectionManager.wakeup({"message": "Manually disconnected from server", "type": "disconnected"});
    } else {
      disconnectionManager.wakeup({"type": "disconnected"});
    }
  },

  "setCallback" : function(cb = null) {
    // Convenience function for setting the framework's event report callback
    if (cb != null && typeof cb == "function") disconnectionManager.eventCallback = cb;
  },

  "getReason" : function(code) {
    return codes[code];
  },

  "formatTimeString" : function(n = null) {
    local bst = false;
    if ("utilities" in getroottable()) bst = utilities.isBST();
    if (n == null) n = date();
    n.hour += (bst ? 1 : 0);
    if (n.hour > 23) n.hour -= 24;
    local z = bst ? "+01:00" : "UTC";
    return format("%02i:%02i:%02i %s", n.hour, n.min, n.sec, z);
  },

  "wakeup": function(data) {
    // Queue up a message post with the supplied data
    if (disconnectionManager.eventCallback != null) {
      imp.wakeup(0, function() {
        disconnectionManager.eventCallback(data);
      });
    }
  }
}
