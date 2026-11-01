// Decimal amounts and wei. Scale stops at 28, which is goose-decimal's limit.
// A wider scale returns false.

import decimal from "../decimal";

namespace evm;

fn to_wei(amount: u8[:], decimals: i64) -> u8[>..], bool {
    if decimals < 0 || decimals > 28 { return [], false; }
    let d, ok = decimal::parse(amount);
    if !ok { return [], false; }
    let text = decimal::text(d);
    var whole: u8[>..] = [];
    var frac: u8[>..] = [];
    var dot = false;
    for i in 0..text.len {
        if text[i] == '.' { dot = true; }
        else if text[i] == '-' { return [], false; }
        else if dot { frac.push(text[i]); }
        else { whole.push(text[i]); }
    }
    if frac.len > decimals { return [], false; }
    var out: u8[>..] = [];
    if whole.len == 0 { out.push('0'); } else { out.append(whole); }
    out.append(frac);
    for i in frac.len..decimals { out.push('0'); }
    var i: i64 = 0;
    while i + 1 < out.len && out[i] == '0' { i += 1; }
    var trimmed: u8[>..] = [];
    for k in i..out.len { trimmed.push(out[k]); }
    return trimmed, true;
}

fn from_wei(wei: u8[:], decimals: i64) -> u8[>..], bool {
    if decimals < 0 || decimals > 28 || wei.len == 0 { return [], false; }
    for i in 0..wei.len {
        if wei[i] < '0' || wei[i] > '9' { return [], false; }
    }
    var plain: u8[>..] = [];
    if wei.len <= decimals {
        plain.push('0');
        plain.push('.');
        for i in wei.len..decimals { plain.push('0'); }
        plain.append(wei);
    } else {
        let cut = wei.len - decimals;
        for i in 0..cut { plain.push(wei[i]); }
        if decimals > 0 {
            plain.push('.');
            for i in cut..wei.len { plain.push(wei[i]); }
        }
    }
    let d, ok = decimal::parse(plain);
    if !ok { return [], false; }
    return decimal::text(d), true;
}
