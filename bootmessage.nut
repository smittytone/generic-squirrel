// Boot device information functions
// Copyright Tony Smith, 2017-18
// Licence: MIT
#version = "2.0.0";
bootinfo <- {
    "message" : function() {
        // Present OS version and network connection information
        // Take the software version string and extract the version number
        local a = split(imp.getsoftwareversion(), "-");

        // Check for 'seriallog' in the root table - if it's there, use it
        // 'seriallog' is added as a global by including seriallog.nut in your code AHEAD of bootmessage.nut
        // NOTE 'seriallog' will always call server.log() too
        local lg = null;
        if ("seriallog" in getroottable()) { lg = seriallog; } else { lg = server; }
        lg.log("impOS version " + a[2]);
        lg.log(format("Running \'%s\' (%s)", __EI.PRODUCT_NAME, __EI.PRODUCT_ID));
        lg.log(format("SHA %s", __EI.DEPLOYMENT_SHA));

        // Get current networking information
        local i = imp.net.info();

        // Get the active network interface (or the first network on
        // the list if there is no network marked as active)
        local w = i.interface["active" in i ? i.active : 0];

        if (w != null) {
            // Get the SSID of the network the device is connected to (or fallback to the last known network)
            local s = w.type == "wifi" ? ("connectedssid" in w ? w.connectedssid : ("ssid" in w ? w.ssid : "Unknown")) : "Unknown";

            // Get the type of network we are using (WiFi or Ethernet)
            local t = "Connected by " + (w.type == "wifi" ? "WiFi on SSID \"" + s + "\"" : "Ethernet");
            lg.log(t + " with IP address " + i.ipv4.address);
        }

        // Present the reason for the start-up
        lg.log(bootinfo.wakereason());
    },

    "wakereason" : function() {
        // Return the result of hardware.wakereason() as a full message string
        local causes = [ "Cold boot", "Woken after sleep", "Software reset", "Wakeup pin triggered",
                         "Application code updated", "Squirrel error during the last run"
                         "This device has a new impOS", "Woken by a snooze-and-retry event",
                         "imp003 Reset pin triggered", "This device has just been re-configured",
                         "Restarted by server.restart()" ];
        try {
            return("Device restarted: " + causes[hardware.wakereason()]);
        } catch (err) {
            return("Device restarted: Reason unknown");
        }
    }
}

// Present device information now
bootinfo.message();
