// Boot device information functions
function bootMessage() {
    // Present OS version and network connection information
    local a = split(imp.getsoftwareversion(), "-");
    server.log("impOS version " + a[2]);
    local i = imp.net.info();
    local w = i.interface[i.active != null ? i.active : 0];
    local s = w.type == "wifi" ? ("connectedssid" in w ? w.connectedssid : w.ssid) : "";
    local t = "Connected by " + (w.type == "wifi" ? "WiFi on SSID \"" + s + "\"" : "Ethernet");
    server.log(t + " with IP address " + i.ipv4.address);

    // Present the reason for the start-up
    s = logWokenReason();
    if (s.len() > 0) server.log(s);
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

// Present device information on boot
bootMessage();
