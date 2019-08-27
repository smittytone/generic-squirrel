// Code version for Squinter
#version "2.2.2"

/**
 * Boot-time device information functions
 *
 * Code which logs impOS and network information. It is intended to be included early in the runtime (hence the name).
 * Includes functions and code to trigger those functions
 *
 * @author    Tony Smith (@smittytone)
 * @copyright Tony Smith, 2017-18
 * @licence   MIT
 * @version   2.2.2
 *
 * @table
 *
 */
bootinfo <- {

    /**
     * Present OS version and network connection information
     *
     */
    "message" : function() {
        // Check for 'seriallog' in the root table - if it's there, use it
        // 'seriallog' is added as a global by including seriallog.nut in your code AHEAD of bootmessage.nut
        // NOTE 'seriallog' will always call server.log() too
        local lg = "seriallog" in getroottable() ? seriallog : server;
        lg.log("impOS version " + bootinfo.version());
        lg.log(format("Product \'%s\' (%s)", __EI.PRODUCT_NAME, __EI.PRODUCT_ID));
        lg.log(format("Device Group \'%s\' (%s)", __EI.DEVICEGROUP_NAME, __EI.DEVICEGROUP_ID));
        lg.log(format("SHA %s", __EI.DEPLOYMENT_SHA));

        // Get current networking information
        local i = imp.net.info();

        // Get the active network interface (or the first network on
        // the list if there is no network marked as active)
        local w = i.interface["active" in i ? i.active : 0];

        if (w != null) {
            // Get the SSID of the network the device is connected to (or fallback to the last known network)
            if (w.type != "cell") {
                local s = w.type == "wifi" ? ("connectedssid" in w ? w.connectedssid : ("ssid" in w ? w.ssid : "Unknown")) : "Unknown";

                // Get the type of network we are using (WiFi or Ethernet)
                local t = "Connected by " + (w.type == "wifi" ? "WiFi on SSID \"" + s + "\"" : w.type);
                lg.log(t + " with IP address " + i.ipv4.address);
            } else {
                lg.log("Connected by cellular (IMEI " + w.imei + ")");
            }
        }

        // Present the reason for the start-up
        lg.log(bootinfo._wakereason());
    },

    /**
     * Provides impOS version information in a human-readable string
     *
     * @returns {string} The impOS version number as a string
     */
    "version" : function() {
        // Take the software version string and extract the version number
        local a = split(imp.getsoftwareversion(), "-");
        return a[2];
    },

    // ********** Private Methods DO NOT CALL DIRECTLY **********

    /**
     * Return the result of hardware.wakereason() as a full message string
     *
     * @private
     *
     * @returns {string} The message string
     */
    "_wakereason" : function() {
        local causes = [ "Cold boot", "Woken after sleep", "Software reset", "Wakeup pin triggered",
                         "Application code updated", "Squirrel error during the last run"
                         "This device has a new impOS", "Woken by a snooze-and-retry event",
                         "Reset pin triggered", "This device has just been re-configured",
                         "Restarted by server.restart()", "VBAT powered during a cold start" ];
        try {
            return("Device restarted: " + causes[hardware.wakereason()]);
        } catch (err) {
            return("Device restarted: Reason unknown");
        }
    }
}

// Present device information now
bootinfo.message();
