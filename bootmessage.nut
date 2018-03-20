// Boot device information functions
// Copyright Tony Smith, 2017-18
// Licence: MIT
// Code version 1.0.2
function bootMessage() {
    // Present OS version and network connection information
    // Take the software version string and extract the version number
    local a = split(imp.getsoftwareversion(), "-");
    server.log("impOS version " + a[2]);

    // Get current networking information
    local i = imp.net.info();

    // Get the active network interface (or the first network on
    // the list if there is no network marked as active)
    local w = i.interface[i.active != null ? i.active : null];

    if (w != null) {
        // Get the SSID of the network the device is connected to
        // (or fallback to the last known network)
        local s = w.type == "wifi" ? ("connectedssid" in w ? w.connectedssid : w.ssid) : "";

        // Get the type of network we are using (WiFi or Ethernet)
        local t = "Connected by " + (w.type == "wifi" ? "WiFi on SSID \"" + s + "\"" : "Ethernet");
        server.log(t + " with IP address " + i.ipv4.address);
    }

    // Present the reason for the start-up
    a = logWokenReason();
    if (a.len() > 0) server.log(a);
}

function logWokenReason() {
    // Return the recorded reason for the device’s start-up
    local reason = "";
    local causes = [ "Cold boot", "Woken after sleep", "Software reset", "Wakeup pin triggered",
                     "Application code updated", "Squirrel error during the last run"
                     "This device has a new impOS", "Woken by a snooze-and-retry event",
                     "imp003 Reset pin triggered", "This device has just been re-configured",
                     "Restarted by server.restart()" ];
    try {
        reason = "Device restarted: " + causes[hardware.wakereason()];
    } catch (err) {
        reason = "Device restarted: Reason unknown";
    }

    return reason;
}

// Present device information now
bootMessage();
