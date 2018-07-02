# Generic Squirrel #

Squirrel code used in multiple projects. The `.nut` files kept here can be cut and pasted into project source code or integrated via [Squinter](https://smittytone.github.io/squinter/version2/index.html).

## Files ##

### seriallog.nut 2.0.0 ###

Incorporates code which sends log and error messages to UART as well as to *server.log()* and *server.error()*. To use this code as-is, replace all your *server.log()* and *server.error()* calls with *serialLog.log()* and *serialLog.error()*. Includes a logger class and code to instantiate it.

#### Release Notes #####

- 2.0.0
    - Convert from class to table as per other files
    - Table is named to *seriallog* (lowercase)
    - Add *configure()* function &mdash; if not called, serial logging is disabled
    - Auto-select UART *configure()*, if necessary

### bootmessage.nut 2.0.0 ###

Incorporates code which logs impOS and network information. It is intended to be included early in the runtime (hence the name). Includes functions and code to trigger those functions. Compatible with **seriallog.nut**.

#### Release Notes #####

- 2.0.1
    - Add *version()* function to return impOS version number as string
- 2.0.0
    - Change table name to *bootinfo* (lowercase)
    - Change function names to *message()* and *wakereason()*
    - Add version number
- 1.1.1
    - Bug fixes
- 1.1.0
    - Support `seriallog.nut`

### utilities.nut 2.0.1 ###

A table of utility routines.  Please see the source code for further information.

#### Release Notes #####

- 2.0.1
    - Fix table naming bug
    - Reformat table to match JSON format
    - Add version number
- 2.0.0
    - Change table name to *utilities* (lowercase)

### disconnect.nut 1.0.2 ###

Provides DisconnectionManager, a handler for imp connection state. Call *disconnectionManager.start()* to begin monitoring and to allow the imp automatically to attempt to reconnect when it disconnects unexpectedly. *disconnectionManager.connect()* and *disconnectionManager.disconnect()* can then be used to, respectively, connect to and disconnect from the server, and should be used in place of the imp API methods *server.connect()* and *server.disconnect()*.

The properties *disconnectionManager.reconnectTimeout* and *disconnectionManager.reconnectDelay* can be used to set, respectively, the period after which a disconnected imp will attempt to reconnect, and the timeout period it allows for the reconnection attempt. These values default to, respectively, 60 and 30 seconds.

The property *disconnectionManager.eventCallback* can be set to a function with a single parameter, *event*. This function will then be called whenever a connection is made, the imp disconnects, or the imp attempts to connect. The value of *event* is a table. Its possible keys include:

- *type* &mdash; `"connected"`, `"disconnected"` or `"connecting"`, ie. the imp’s state
- *message* &mdash; a human-readable status message

#### Release Notes ####

- 1.1.0
    - Add 'sendPolicy' parameter to start() (default: *WAIT_TIL_SENT*)
    - Set state when start() called
    - Deal with impOS <= 38 issue with ounexpecteddisconnect() being called twice when IP address lost (ie. WiFi up but router link lost)

- 1.0.2
    - Add 'timeout' parameter to start() (default: 10s)
    - Add version number to file
- 1.0.1
    - Change order of re-connect message: off-time then on-time
- 1.0.0
    - Initial release
