import os;
import decimal from "../../decimal";
import msgpack from "../../msgpack";
import msgpack.encode;
import crypto from "../../crypto";
import crypto.keccak256;
import crypto.secp256k1;
import signature from "../../signature";
import signature.eip712;
import hyperliquid from "..";
import hyperliquid.wire;
import hyperliquid.sign;
import hyperliquid.order;

fn fail(why: u8[:]) {
    write_stdout(why);
    write_stdout("\n");
    exit(1);
}

fn hex_digit(v: u8) -> u8 {
    if v < 10 { return '0' + v; }
    return 'a' + (v - 10);
}

fn hex(b: u8[:]) -> u8[>..] {
    var s: u8[>..] = [];
    s.push('0');
    s.push('x');
    for i in 0..b.len {
        s.push(hex_digit(b[i] >> 4));
        s.push(hex_digit(b[i] & 0x0f));
    }
    return s;
}

fn need(got: u8[:], want: u8[:], why: u8[:]) {
    if got != want { fail(why); }
}

fn parse_hex(s: u8[:]) -> u8[>..] {
    var o: u8[>..] = [];
    var i: i64 = 0;
    while i < s.len {
        fn nib(c: u8) -> u8 {
            if c >= '0' && c <= '9' { return c - '0'; }
            if c >= 'a' && c <= 'f' { return c - 'a' + 10; }
            return c - 'A' + 10;
        }
        o.push((nib(s[i]) << 4) | nib(s[i + 1]));
        i += 2;
    }
    return o;
}

fn self_check() -> bool {
    let body, ok = order::batch("50000", "0.1", "Gtc", order::Priority.Absent);
    if !ok { return false; }
    let dig, dok = order::prehash(body, 1700000000000);
    if !dok { return false; }
    need(hex(dig), "0x8503ee5eeab7e05b5acccd402384ae6e39f8e53b38c718b60fa7e6e129cfb93f", "order");
    var saw_c = false;
    for i in 0..body.len - 1 {
        if body[i] == 0xa1 && body[i + 1] == 'c' { saw_c = true; }
    }
    if saw_c { return false; }
    var saw_false = false;
    for i in 0..body.len {
        if body[i] == 0xc2 { saw_false = true; }
    }
    if !saw_false { return false; }

    let prio, pok = order::batch("50000.0", "0.10", "Ioc", order::Priority.At { n: 80000 });
    if !pok { return false; }
    let pdig, pdok = order::prehash(prio, 1700000000000);
    if !pdok { return false; }
    need(hex(pdig), "0x171cc7d6d79c47534abf8c00486ea8ea5c832d9061a76a27c014203138042539", "priority");

    let can = order::cancel(0, 123);
    let cdig, cok = order::prehash(can, 1700000000000);
    if !cok { return false; }
    need(hex(cdig), "0xf90176e0e223f98d123c7d06bfbbd3ead7a3f3e6b5c429af4136e71daba3cb3e", "cancel");

    let mod, mok = order::modify(123, "50000", "0.1");
    if !mok { return false; }
    let mdig, mdok = order::prehash(mod, 1700000000000);
    if !mdok { return false; }
    need(hex(mdig), "0x5b04c36ec7c2d5596258b690ba2fab10dff71f73853cc040cce4fd3920c2141e", "modify");

    let key = parse_hex("e908f86dbb4d55ac876378565aafeabc187f6690f046459397b17d9b9a19688e");
    let rs, sok, v = secp256k1::sign(key, dig);
    if !sok { return false; }
    var sig: u8[65] = [0; 65];
    for i in 0..64 { sig[i] = rs[i]; }
    sig[64] = v;
    let pub, rok = secp256k1::recover(dig, sig);
    if !rok || pub[0] != 4 { return false; }
    let h = keccak256::hash(pub[1..]);
    let want = parse_hex("cd49bbac6e85fdeb167eb7ca41a945d2b8758f6f");
    for i in 0..20 {
        if h[12 + i] != want[i] { return false; }
    }

    let bad, bok = order::batch("nope", "1", "Gtc", order::Priority.Absent);
    if bok { return false; }
    return true;
}

fn ::main() {
    if self_check() { print("order ok"); } else { fail("order"); }
}
