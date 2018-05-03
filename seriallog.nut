// Serial logger
// Licence: MIT
// Code version 1.0.0

class SerialLogger {

    _uart = null;
    _enabled = false;

    constructor(uart = null, baud = 9600, enable = true) {
        // Pass the UART object, eg. hardware.uart6E, Baud rate, Offline Enable True/False,
        // and whether you are logging to a Raspberry Pi (which seems to require \n\r for newline
        // NOTE UART is enabled by default; Pi setting disable by default
        if (uart == null) throw "SerialLogger requires a valid imp UART object";
        _uart = uart;
        _uart.configure(baud, 8, PARITY_NONE, 1, NO_RX | NO_CTSRTS);

        if (typeof enable == "bool") _enabled = enable;
  }

    function enable() { _enabled = true; }
    function disable() { _enabled = false; }

    function log(message) {
        if (_enabled) _uart.write("[IMP LOG] " + setTimeString() + " " + message + "\r\n");
        server.log(message);
    }

    function error(message) {
        if (_enabled) _uart.write("[IMP ERR] " + setTimeString() + " " + message + "\r\n");
        server.error(message);
    }

    function setTimeString(time = null) {
        local now = time != null ? time : date();
        return format("%04d-%02d-%02d %02d:%02d:%02d", now.year, now.month + 1, now.day, now.hour, now.min, now.sec);
    }
}

// Set up the debugger as 'serialLog'
local uart = null;
switch(imp.info().type) {
  case "imp001":
  case "imp002":
    uart = hardware.uart12;
    break;
  case "imp003":
    uart = hardware.uartDM;
    break;
  case "imp004m":
    uart = hardware.uartHJ;
    break;
  case "imp005":
    uart = hardware.uart0;
}

serialLog <- SerialLogger(uart, 19200);
serialLog.log("Log initialised and ready...");
