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

fn copy(s: u8[:]) -> u8[>..] {
    var o: u8[>..] = [];
    o.append(s);
    return o;
}

fn api_mode(s: u8[:]) -> u8[>..], bool {
    if s == "disabled" || s == "i" || s == "standard" || s == "Standard" { return copy("disabled"), true; }
    if s == "unifiedAccount" || s == "u" || s == "unified" || s == "default" { return copy("unifiedAccount"), true; }
    if s == "portfolioMargin" || s == "p" || s == "portfolio" { return copy("portfolioMargin"), true; }
    return [], false;
}

fn agent_code(s: u8[:]) -> u8[>..], bool {
    if s == "disabled" || s == "i" || s == "standard" || s == "Standard" { return copy("i"), true; }
    if s == "unifiedAccount" || s == "u" || s == "unified" || s == "default" { return copy("u"), true; }
    if s == "portfolioMargin" || s == "p" || s == "portfolio" { return copy("p"), true; }
    return [], false;
}

fn perp_max(sz_decimals: i64) -> i64 { return 6 - sz_decimals; }

fn spot_max(sz_decimals: i64) -> i64 { return 8 - sz_decimals; }

fn floor_log10(text: u8[:]) -> i64, bool {
    if text.len == 0 || text[0] == '-' { return 0, false; }
    var dot: i64 = -1;
    for i in 0..text.len {
        if text[i] == '.' { dot = i; }
    }
    if dot < 0 {
        if text == "0" { return 0, false; }
        return text.len - 1, true;
    }
    if dot > 1 || text[0] != '0' { return dot - 1, true; }
    var zeros: i64 = 0;
    var saw = false;
    for i in dot + 1..text.len {
        if text[i] != '0' { saw = true; break; }
        zeros += 1;
    }
    if !saw { return 0, false; }
    return -(zeros + 1), true;
}

fn prefix_one(digs: u8[>..]&) {
    var grown: u8[>..] = [];
    grown.push('1');
    grown.append(digs);
    digs.clear();
    digs.append(grown);
}

fn bump_digits(digs: u8[>..]&, n: i64) -> bool {
    var i = n - 1;
    while i >= 0 {
        if digs[i] < '9' { digs[i] = digs[i] + 1; return false; }
        digs[i] = '0';
        i -= 1;
    }
    return true;
}

fn round_away(frac: u8[:], at: i64) -> bool {
    if at >= frac.len { return false; }
    if frac[at] > '5' { return true; }
    if frac[at] < '5' { return false; }
    for i in at + 1..frac.len {
        if frac[i] != '0' { return true; }
    }
    return false;
}

fn round_text(text: u8[:], places: i64) -> u8[>..], bool {
    var whole: u8[>..] = [];
    var frac: u8[>..] = [];
    var dot = false;
    for i in 0..text.len {
        if text[i] == '.' { dot = true; }
        else if dot { frac.push(text[i]); }
        else { whole.push(text[i]); }
    }
    if whole.len == 0 { whole.push('0'); }
    var up = false;
    if places <= 0 {
        up = round_away(frac, 0);
        frac.clear();
    } else {
        while frac.len < places { frac.push('0'); }
        if frac.len > places {
            up = round_away(frac, places);
            while frac.len > places { frac.pop(); }
        }
    }
    if up {
        if places > 0 {
            let carry = bump_digits(frac, places);
            if carry {
                let wcarry = bump_digits(whole, whole.len);
                if wcarry { prefix_one(whole); }
            }
        } else {
            let wcarry = bump_digits(whole, whole.len);
            if wcarry { prefix_one(whole); }
        }
    }
    var out: u8[>..] = [];
    out.append(whole);
    if places > 0 {
        out.push('.');
        out.append(frac);
    }
    return out, true;
}

fn tick(max_decimals: i64, price: u8[:]) -> u8[>..], bool {
    if max_decimals < 0 { return [], false; }
    let plain, pok = normalize(price);
    if !pok { return [], false; }
    let exp, eok = floor_log10(plain);
    if !eok { return [], false; }
    var places = 5 - (exp + 1);
    if places < 0 { places = 0; }
    if places > max_decimals { places = max_decimals; }
    if places > 28 { return [], false; }
    if places == 0 { return copy("1"), true; }
    var out: u8[>..] = [];
    out.append("0.");
    for i in 1..places { out.push('0'); }
    out.push('1');
    return out, true;
}

fn round_price(max_decimals: i64, price: u8[:]) -> u8[>..], bool {
    let step, sok = tick(max_decimals, price);
    if !sok || step.len == 0 { return [], false; }
    let plain, pok = normalize(price);
    if !pok { return [], false; }
    let exp, eok = floor_log10(plain);
    if !eok { return [], false; }
    var places = 5 - (exp + 1);
    if places < 0 { places = 0; }
    if places > max_decimals { places = max_decimals; }
    if places > 28 { return [], false; }
    let rounded, rok = round_text(plain, places);
    if !rok { return [], false; }
    return normalize(rounded);
}
