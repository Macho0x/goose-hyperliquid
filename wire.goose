// Decimal text and hex addresses for the bytes Hyperliquid hashes.
// A price is normalized before it is written, so 10.0 becomes 10.

import decimal from "../decimal";

namespace wire;

fn nibble(c: u8) -> u8, bool {
    if c >= '0' && c <= '9' { return c - '0', true; }
    if c >= 'a' && c <= 'f' { return c - 'a' + 10, true; }
    if c >= 'A' && c <= 'F' { return c - 'A' + 10, true; }
    return 0, false;
}

fn hex_digit(v: u8) -> u8 {
    if v < 10 { return '0' + v; }
    return 'a' + (v - 10);
}

fn parse_address(s: u8[:]) -> u8[20], bool {
    var o: u8[20] = [0; 20];
    var i: i64 = 0;
    if s.len >= 2 && s[0] == '0' && (s[1] == 'x' || s[1] == 'X') { i = 2; }
    if s.len - i != 40 { return o, false; }
    for k in 0..20 {
        let hi, hok = nibble(s[i]);
        let lo, lok = nibble(s[i + 1]);
        if !hok || !lok { return o, false; }
        o[k] = (hi << 4) | lo;
        i += 2;
    }
    return o, true;
}

fn address_hex(a: u8[:]) -> u8[>..], bool {
    var o: u8[>..] = [];
    if a.len != 20 { return o, false; }
    o.push('0');
    o.push('x');
    for i in 0..20 {
        o.push(hex_digit(a[i] >> 4));
        o.push(hex_digit(a[i] & 0x0f));
    }
    return o, true;
}

fn normalize(s: u8[:]) -> u8[>..], bool {
    let d, ok = decimal::parse(s);
    if !ok { return [], false; }
    return decimal::text(decimal::normalize(d)), true;
}
