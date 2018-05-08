Generic Squirrel code used in multiple projects. The `.nut` files kept here can be cut and pasted into project source code or integrated via [Squinter](https://smittytone.github.io/squinter/version2/index.html).

## Files ##

### seriallog.nut 1.0.0 ###

Incorporates code which sends log and error messages to UART as well as to *server.log()* and *server.error()*. To use this code as-is, replace all your *server.log()* and *server.error()* calls with *serialLog.log()* and *serialLog.error()*. Includes a logger class and code to instantiate it.

### bootmessage.nut 1.1.0 ###

Incorporates code which logs impOS and network information. It is intended to be included early in the runtime (hence the name). Includes functions and code to trigger those functions. Works with **seriallog.nut**.

### utilities.nut 1.2.0 ###

A table of utility routines.  Please see the source code for further information.
