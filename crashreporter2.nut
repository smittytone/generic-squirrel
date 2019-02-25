// Code version for Squinter
#version "0.0.2"

/**
 * Generic development-oriented crash report service
 * 
 * @author    Tony Smith (@smittytone)
 * @copyright Tony Smith, 2019
 * @licence   MIT
 * @version   0.0.2
 *
 */
crashReporter <- {

    /**
     * Relay an error received from the device (or the agent itself)
     *
     * @param {string} error - The error message to relay 
     *
     */
    "report" : function(error) {
        local report = "    DG: \"" + __EI.DEVICEGROUP_NAME + "\" (" + __EI.DEVICEGROUP_ID + ")\n";
        report = report + "DEVICE: " + imp.configparams.deviceid + "\n";
        report = report + " ERROR: " + error;
        local data = { "comment" : report, "useragent" : http.agenturl() };
        local head = { "X-GDERH-ID" : "6FB3E89C-8ED6-4718-A1B0-56DC6B7555E6" };
        local request = http.post("https://agent.electricimp.com/sQlpFbCUmhLF/crashreport", head, http.jsonencode(data));
        
        // Send report synchronously to ensure the VM doesn't close down before it's sent
        request.sendsync();
    },

    /**
     * Initilize the service
     *
     */
    "init" : function() {
        // Register the agent's device message handler on the agent
        local isAgent = (imp.environment() == 2);
        if (isAgent) device.on("crash.reporter.relay.debug.error", crashReporter.report);
        
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
    }
};

crashReporter.init();