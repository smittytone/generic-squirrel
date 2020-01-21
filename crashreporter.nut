// Set up the crash reporter
// Code version for Squinter
#version "1.1.1"

/**
 * Generic development-oriented crash report service
 *
 * @author    Tony Smith (@smittytone)
 * @copyright Tony Smith, 2019-20
 * @licence   MIT
 * @version   1.1.1
 *
 */
crashReporter <- {

    /**
     * Reference to a function responsible for sending notifications
     *
     * @property
     *
     */
    "messenger" : null,

    /**
     * The host agent's unique ID
     *
     * @property
     *
     */
    "agentid": "",

    /**
     * Initilize the service
     *
     * @param {function} messengerFunction - The function to send error messages (agent only)
     * @param {bool}     doReportStatus    - Should the agent report device status? Default: false (agent only)
     *
     */
    "init" : function(messengerFunction = null, doReportStatus = false) {
        // Register the agent's device message handler on the agent
        local isAgent = (imp.environment() == 2);

        // Set up the agent and check the messenger object
        if (isAgent) {
            if (messengerFunction == null || typeof messengerFunction != "function") throw("crashReporter.init() requires a messenger function");
            crashReporter.messenger = messengerFunction;
            device.on("crash.reporter.relay.debug.error", crashReporter.report);

            // FROM 1.1.0
            // Add device connection status reporting (disabled by default)
            if (doReportStatus) {
                crashReporter._getagentid();
                crashReporter._setWatchers();
            }
        }

        // Register the onunhandled callback
        imp.onunhandledexception(function(error) {
            // Only operate in DEBUG mode, ie. with development device groups
            if (__EI.DEVICEGROUP_TYPE == "development") {
                if (isAgent) {
                    // Running on the agent: just relay the error
                    crashReporter.report(error);
                } else {
                    // Running on the device: send the error to the agent
                    agent.send("crash.reporter.relay.debug.error", error);
                    server.flush(10);
                }
            }

            // Squirrel VM will restart at this point
        }.bindenv(this));
    },

    /**
     * ADDED 1.1.0
     * Activate or de-activate device connection state reporting
     *
     * @param {bool} state - Should reporting take place? Default: true
     *
     */
    "enableStateReports": function(state = true) {
        // Only proceed if we're running on the agent
        if (isAgent) {
            if (state) {
                // Set up the standard connection/disconnection reporters
                crashReporter._setReporters();
            } else {
                // Clear the connection/disconnection reporters
                device.onconnect(null);
                device.ondisconnect(null);
            }
        }
    },

    /**
     * Relay an error received from the device (or the agent itself)
     *
     * @param {string} error - The error message to relay
     *
     */
    "report" : function(error) {
        // Prepare the error report text
        local report = "*ERROR REPORT*\n*ERROR* " + error + "\n";
        report += crashReporter._makereport();

        // Send the report text via the chosen messenger object
        crashReporter.messenger(report);
    },

    /**
     * Returns the current date as a formatted string. Uses the Utilities library
     * to determine daylight savings status; assumes GMT if Utilities is not present
     *
     * @returns {string} The formatted date
     *
     */
    "timestamp": function() {
        local time = date();
        local bst = false;
        if ("utilities" in getroottable()) bst = utilities.isBST();
        time.hour += (bst ? 1 : 0);
        if (time.hour > 23) time.hour -= 24;
        local z = bst ? "+01:00" : "UTC";
        return format("%04d-%02d-%02d %02d:%02d:%02d %s", time.year, time.month + 1, time.day, time.hour, time.min, time.sec, z);
    },

    /**
     * ADDED 1.1.0
     * Determines the host agennt's unique ID
     *
     * @private
     *
     */
    "_getagentid": function() {
        local url = http.agenturl();
        local urlparts = split(url, "/");
        agentid = urlparts[2];
    },

    /**
     * ADDED 1.1.0
     * Assembles crash report boilerplate
     *
     * @returns {string} The report body text
     *
     * @private
     *
     */
    "_makereport": function() {
        local report = "*TIME* " + crashReporter.timestamp() + "\n";
        report += ("*DEVICE* " + imp.configparams.deviceid + "\n");
        report += ("*GROUP* " + __EI.DEVICEGROUP_NAME + "\n");
        report += ("*PRODUCT* " + __EI.PRODUCT_NAME);
        return report;
    },

    /**
     * ADDED 1.1.0
     * Registers device-connection and disconnection callbacks
     *
     * @private
     *
     */
    "_setReporters": function() {
        device.onconnect(function() {
            local report = "*STATUS REPORT*\nAgent " + agentid + " reports device connected\n";
            report += crashReporter._makereport();
            crashReporter.messenger(report);
        }.bindenv(this));

        device.ondisconnect(function() {
            local report = "*STATUS REPORT*\nAgent " + agentid + " reports device registered as disconnected\n";
            report += crashReporter._makereport();
            crashReporter.messenger(report);
        }.bindenv(this));
    }
};
