// Set up the crash reporter
// Code version for Squinter
#version "1.0.0"

/**
 * Generic development-oriented crash report service
 * 
 * @author    Tony Smith (@smittytone)
 * @copyright Tony Smith, 2019
 * @licence   MIT
 * @version   1.0.0
 *
 */
crashReporter <- {

    /**
     * Reference to the object handling notification messaging
     *
     * @property
     *
     */
    "messenger" : null,
    
    /**
     * Relay an error received from the device (or the agent itself)
     *
     * @param {string} error - The error message to relay 
     *
     */
    "report" : function(error) {
        // Prepare the error report text
        local report = "*ERROR REPORT*\n*TIME* " + crashReporter.timestamp() + "\n";
        report = report + "*ERROR* " + error + "\n";
        report = report + "*DEVICE* " + imp.configparams.deviceid + "\n";
        report = report + "*GROUP* " + __EI.DEVICEGROUP_NAME;
        
        // Send the report text via the chosen messenger object
        crashReporter.messenger.post(report);
    },

    /**
     * Initilize the service
     *
     * @param {instance} messengerInstance - The error messenger instance (agent only)
     *
     */
    "init" : function(messengerInstance = null) {
        // Register the agent's device message handler on the agent
        local isAgent = (imp.environment() == 2);
        
        // Set up the agenrt and check the messenger object
        if (isAgent) {
            if (messengerInstance == null) throw("crashReporter.init() requires an instance of a messenger object");
            crashReporter.messenger = messengerInstance;
            device.on("crash.reporter.relay.debug.error", crashReporter.report);
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
     * Returns the current date as a formatted string
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
    }
};