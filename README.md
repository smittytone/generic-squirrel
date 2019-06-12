# Generic Squirrel #

Squirrel code used in multiple projects. The `.nut` files kept here can be cut and pasted into project source code or integrated via [Squinter](https://smittytone.github.io/squinter/version2/index.html).

**Note** Updates are made regularly to the `develop` branch, which is merged into `master` on a (roughly) monthly basis.

## File List ##

- [bootmessage.nut](#bootmessagenut)
- [disconnect.nut](#disconnectnut)
- [seriallog.nut](#seriallognut)
- [utilities.nut](#utilitiesnut)
- [simpleslack.nut](#simpleslacknut)
- [crashreporter.nut](#crashreporternut)

## bootmessage.nut ##

#### Version 2.2.2 ####

Incorporates code which logs impOS and network information. It is intended to be included early in the runtime (hence the name). Includes functions and code to trigger those functions. Compatible with **seriallog.nut**.

#### Public Methods ####

- *message()* &mdash; Display the boot info to the log
- *version()* &mdash; Return the current impOS&trade; version, eg. `"38.5"`

#### Release Notes #####

- 2.2.2
    - Add device group information
- 2.2.1
    - Remove imp type (imp003) from reset button wake reason
- 2.2.0
    - Add cellular imp support
- 2.1.0
    - Add *version()* function to return impOS version number as string
    - Remove *wakereason()* as a public method
- 2.0.0
    - Change table name to *bootinfo* (lowercase)
    - Change function names to *message()* and *wakereason()*
    - Add version number
- 1.1.1
    - Bug fixes
- 1.1.0
    - Support `seriallog.nut`

<p align="right"><a href="#generic-squirrel"><i>Back to Top</i></a></p>

## disconnect.nut ##

#### Version 2.1.1 ####

Provides *disconnectionManager*, a gloabl object which operates as a handler for imp connection states. Call *disconnectionManager.start()* to begin monitoring and to allow the imp automatically to attempt to reconnect when it disconnects unexpectedly. *disconnectionManager.connect()* and *disconnectionManager.disconnect()* can then be used to, respectively, connect to and disconnect from the server, and should be used in place of the imp API methods *server.connect()* and *server.disconnect()*.

The properties *disconnectionManager.reconnectTimeout* and *disconnectionManager.reconnectDelay* can be used to set, respectively, the period after which a disconnected imp will attempt to reconnect, and the timeout period it allows for the reconnection attempt. These values default to, respectively, 60 and 30 seconds.

The property *disconnectionManager.eventCallback* can be set to a function with a single parameter, *event*. This function will then be called whenever a connection is made, the imp disconnects, or the imp attempts to connect. The value of *event* is a table:

| Key | Description |
| --- | --- |
| *type* | The imp’s state, one of:<br />`"connected"`,<br />`"disconnected"`,<br /> `"connecting"` |
| *message* | A human-readable status message |

#### Public Properties ####

- *reconnectTimeout* &mdash; Connection attempt timeout. Integer. Default: 30
- *reconnectDelay* &mdash; Delay between connection attempts. Integer. Default: 60
- *isConnected* &mdash; Whether the device is currently connected or not. Boolean
- *eventCallback* &mdash; A function to be called when the device's state changes. Should take the form 'function(event)', where 'event' is a table with the key 'message', whose value is a human-readable string, and 'type' is a machine readable string, eg. 'connected'. Default: `null`

#### Public Methods ####

- *start()* &mdash; Begin monitoring device connection. Parameters:
    - *timeout* &mdash; See imp API's **server.setsendtimeoutpolicy()**. Integer. Default: 10
    - *sendPolicy* &mdash; See imp API's **server.setsendtimeoutpolicy()**. Integer. Default: *WAIT_TIL_SENT*
- *stop()* &mdash; Stop monitoring device connection
- *connect()* &mdash; Manually attempt to connect to the server
- *disconnect()* &mdash; Manually disconnect from the server
- *setCallback()* &mdash; Set the event callback (see above). Parameters:
    - *callback* &mdash; A function to be called when the device's state changes. Should take the form 'function(event)', where 'event' is a table with the key 'message', whose value is a human-readable string, and 'type' is a machine readable string, eg. 'connected'. Default: `null`

#### Release Notes ####

- 2.1.1
    - Check the argument of *start()*'s *sendPolicy* parameter is a valid value
    - Make sure we call server.disconnect() when the imp is idle
- 2.1.0
    - Add a timestamp (Squirrel *time()*) to all messages
    - Change mis-connection reason codes
- 2.0.1
    - Add reason code to back-online messaging
- 2.0.0
    - Add *sendPolicy* parameter to *start()* (default: *WAIT_TIL_SENT*)
    - Set state when *start()* called
    - Deal with impOS <= 38 issue with ounexpecteddisconnect() being called twice when IP address lost (ie. WiFi up but router link lost)
    - Add support for *utilities* *(see above)* to set time string correctly
- 1.0.2
    - Add 'timeout' parameter to *start()* (default: 10s)
    - Add version number to file
- 1.0.1
    - Change order of re-connect message: off-time then on-time
- 1.0.0
    - Initial release

<p align="right"><a href="#generic-squirrel"><i>Back to Top</i></a></p>

## seriallog.nut ##

#### Version 2.1.0 ####

Incorporates code which sends log and error messages to UART as well as to *server.log()* and *server.error()*. To use this code as-is, replace all your *server.log()* and *server.error()* calls with *seriallog.log()* and *seriallog.error()*. The code creates the object *seriallog* as a global variable. you can therefore check for the presence of the object using `if ("seriallog" in getroottable()) { ... }`.

The code does not now call *configure()* immediately, to allow you to so do first. If you do not, *configure()* will be called the first time you attempt to send a log message.

The default UART depends on the the type of imp on which the code is running:

| imp | Default UART |
| --- | --- |
| imp001 | hardware.uart12 |
| imp002 | hardware.uart12 |
| imp003 | hardware.uartDM |
| imp004m | hardware.uartHJ |
| imp005 | hardware.uart0 |
| impC001 | hardware.uartNU |

Logging to UART can be controlled by calling *seriallog.enable()* or *seriallog.disable()*, or setting the *seriallog.enabled* property directly. This does not affect logging via the server, which will always be used, provided there is a connection to the server.

#### Public Properties ####

- *enabled* &mdash; Whether the serial output is enabled. Boolean

#### Public Methods ####

- *configure()* &mdash; Set up the serial link. Should always be called by host app. Parameters:
    - *uart* &mdash; See imp API's **server.setsendtimeoutpolicy()**. Integer. Default: depends on device imp type
    - *baudrate* &mdash; The UART speed. Integer. Default: 115200
    - *txsize* &mdash; The size of the UART TX buffer. Integer. Default: 160 characters
    - *enable* &mdash; Whether to enable serial logging. Boolean. Default: `true`
- *enable()* &mdash; Enable serial logging
- *disable()* &mdash; Disable serial logging
- *log()* &mdash; Log a non-error message to serial (if enabled) and the server
- *error()* &mdash; Log an error message to serial (if enabled) and the server

#### Release Notes ####

- 2.1.0
    - Add impC001 support
    - Log width fix; increase default frame size
    - Log actual bus speed
- 2.0.3
    - Rename a private function for cross-library consistency
- 2.0.2
    - Fix line-splitting bug
    - Reformat output: bracket timestamp
- 2.0.1
    - Add support for *utilities* *(see below)* to set time string correctly
    - Add TX buffer size setting to *configure()*
    - Output large log messages as multiple lines
- 2.0.0
    - Convert from class to table as per other files
    - Table is named to *seriallog* (lowercase)
    - Add *configure()* function &mdash; if not called, serial logging is disabled
    - Auto-select UART *configure()*, if necessary

<p align="right"><a href="#generic-squirrel"><i>Back to Top</i></a></p>

## utilities.nut ##

#### Version 3.1.0 ####

A table of utility routines, accessed through the global object *utilities*. Please see the source code for further information, including a list of available methods.

#### Public Methods ####

- Conversion Functions
    - *hexStringToInteger()*
    - *hexStringToBlob()*
    - *integerToHexString()*
    - *blobToHexString()*
    - *binaryToInteger()*
    - *jsonencode()*
    - *printblob()*
- Random Number and Numerical Functions
    - *frnd()*
    - *rnd()*
    - *sign()*
    - *numberFormatter()*
- Calendar Functions
    - *dayOfWeek()*
    - *isLeapYear()*
    - *isBST()*
    - *isDST()*
    - *uuid()*
- I2C Functions
    - *debugI2C()*
- BASIC-style String Functions
    - *mid()*
    - *left()*
    - *right()*
    - *chr()*
    - *asc()*

#### Release Notes ####

- 3.1.0
    - Add *printblob()* function
- 3.0.0
    - *numberFormatter()* now throws on invalid input **breaking change**
    - *debugI2C()* now throws on error **breaking change**
    - Improve *jsonencode()*:
        - Valid JSON output for non-serializable entities: function, instance, class, blobs
        - Add *unsafe* option (Boolean value, default `true`) to catch [unsafe strings](https://developer.electricimp.com/resources/serialisablesquirrel)
    - Fix *dayOfWeek()*
- 2.3.0
    - Add *binaryToInteger()* function
    - Add extra input checks to some functions
- 2.2.0
    - Add *jsonencode()* function for devices
- 2.1.2
    - String handler bug fixes and code tweaks
- 2.1.1
    - Correct RFC 4412 4.4 behaviour for *uuid()*
- 2.1.0
    - Add *mid*, *left*, *right*, *asc*, *chr* functions for BASIC-style string manipulation
- 2.0.2
    - Add *isDST()* and *isBST()* convenience methods
    - All *bstCheck()* and *dstCheck()* to take optional date values for checks (Default: current time and date)
- 2.0.1
    - Fix table naming bug
    - Reformat table to match JSON format
    - Add version number
- 2.0.0
    - Change table name to *utilities* (lowercase)

<p align="right"><a href="#generic-squirrel"><i>Back to Top</i></a></p>

## simpleslack.nut ##

#### Version 1.0.0 ####

A very basic class for posting messages to Slack via the Incoming Webhook mechanism. Requires a Slack account able to create Incoming Webhooks. The constructor takes the new Incoming Webhook **path**, as provided by Slack, as a string.

#### Example ####

```squirrel
local slack = SimpleSlack("T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX");
```

#### Public Methods ####

- *post()* &mdash; Takes the message string to be posted

#### Release Notes ####

- 1.0.0
    - Initial release

<p align="right"><a href="#generic-squirrel"><i>Back to Top</i></p>

## crashreporter.nut ##

#### Version 1.0.1 ####

A generic error reporter, implemented as a Squirrel table called *crashReporter*. Call the *init()* function and pass in a reference to a messenger function such as the SimpleSlack class’ *post()* method, described above. You can provide any messenger function you like, but it **must** take a single message string.

#### Example ####

```squirrel
local slack = SimpleSlack("T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX");
crashReporter.init(slack.post.bindenv(slack));
```

#### Public Methods ####

- *init()* &mdash; Takes the messenger object
- *report()* &mdash; Used internally to relay the error report via the messenger
- *timestamp()* &mdash; Returns the current date as a formatted string

#### Release Notes ####

- 1.0.1
    - Minor code changes
- 1.0.0
    - Initial release

<p align="right"><a href="#generic-squirrel"><i>Back to Top</i></a></p>