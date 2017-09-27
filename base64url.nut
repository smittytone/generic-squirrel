// Base64 URL functions accessed via the table 'Base64URL'
// Licence: MIT
// Code version 1.0.0

// EXAMPLES
// server.log(Base64URL.encode("ladies and gentlemen we are floating in space"));
// server.log(Base64URL.fromBase64("qL8R4QIcQ/ZsRqOAbeRfcZhilN/MksRtDaErMA=="));
// server.log(Base64URL.toBase64("qL8R4QIcQ_ZsRqOAbeRfcZhilN_MksRtDaErMA"));
// server.log(Base64URL.decode("cmlkZTogZHJlYW1zIGJ1cm4gZG93bg"));

Base64URL <- {};

Base64URL.padString <- function (input) {
    local strLen = input.len();
    local diff = strLen % 4;

    if (!diff) return input;

    local pos = strLen;
    local padLen = 4 - diff;
    local buffer = blob(strLen + padLen);
    buffer.writestring(input);

    while (padLen--) {
        buffer.writestring("=");
        pos++;
    }

    return buffer.tostring();
}

Base64URL.fromBase64 <- function (base64string) {
    local rs = "";
    local i = 0;
    local a = 0;

    do {
        if (a > base64string.len()) break;
        i = base64string.find("=", a);

        if (i != null) {
            rs = rs + base64string.slice(a, i);
            a = i + 1;
        } else {
            rs = rs + base64string.slice(a);
        }
    } while (i != null);

    base64string = rs;

    rs = "";
    i = 0;
    a = 0;
    do {
        if (a > base64string.len()) break;
        i = base64string.find("+", a);

        if (i != null) {
            rs = rs + base64string.slice(a, i) + "-";
            a = i + 1;
        } else {
            rs = rs + base64string.slice(a);
        }
    } while (i != null);

    base64string = rs;

    rs = "";
    i = 0;
    a = 0;
    do {
        if (a > base64string.len()) break;
        i = base64string.find("/", a);

        if (i != null) {
            rs = rs + base64string.slice(a, i) + "_";
            a = i + 1;
        } else {
            rs = rs + base64string.slice(a);
        }
    } while (i != null);

    return rs;
}

Base64URL.toBase64 <- function (base64url) {
    local rs = "";
    local i = 0;
    local a = 0;

    do {
        if (a > base64url.len()) break;
        i = base64url.find("-", a);

        if (i != null) {
            rs = rs + base64url.slice(a, i) + "+";
            a = i + 1;
        } else {
            rs = rs + base64url.slice(a);
        }
    } while (i != null);

    base64url = rs;

    rs = "";
    i = 0;
    a = 0;
    do {
        if (a > base64url.len()) break;
        i = base64url.find("_", a);

        if (i != null) {
            rs = rs + base64url.slice(a, i) + "/";
            a = i + 1;
        } else {
            rs = rs + base64url.slice(a);
        }
    } while (i != null);

    return padString(rs);
}

Base64URL.encode <- function (input){
    return fromBase64(http.base64encode(input));
}

Base64URL.decode <- function (base64url) {
    return http.base64decode(toBase64(base64url));
}
