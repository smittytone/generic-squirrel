function bootMessage() {
    local a = split(imp.getsoftwareversion(), "-");
    server.log("impOS version " + a[2]);
    local i = imp.net.info();
    local w = i.interface[i.active];
    local s = ("connectedssid" in w) ? w.connectedssid : w.ssid;
    local t = "Connected by " + ((w.type == "wifi") ? "WiFi on SSID \"" + s + "\"" : "Ethernet");
    server.log(t + " with IP address " + i.ipv4.address);

    s = logWokenReason();
    if (s.len() > 0) server.log(s);
}

function logWokenReason() {
    // Log the reason the imp restarted
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

// Boot 'screen'
bootMessage();
