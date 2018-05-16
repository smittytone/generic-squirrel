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

- 2.0.0
    - Change table name to *bootinfo* (lowercase)
    - Change function names to *message()* and *wakereason()*
- 1.1.1
    - Bug fixes
- 1.1.0
    - Support `seriallog.nut`

### utilities.nut 2.0.0 ###

A table of utility routines.  Please see the source code for further information.

#### Release Notes #####

- 2.0.0
    - Change table name to *utilities* (lowercase)
