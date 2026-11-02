// Times this package. One untimed batch, then batches until the window
// elapses. The sink keeps the call alive.
// Build with clang on the revision before a change, then again after:
//   goose build -o hyperliquid-bench bench.goose --cc clang
//   ./hyperliquid-bench
// Row names stay fixed. TinyCC (goose bench.goose) is not a timing result.
// ponytail: a fixed window, not a sampled harness. Rows under a microsecond
// move from run to run; lengthen the window before trusting them.

import os;
import crypto from "../crypto";
import signature from "../signature";
import msgpack from "../msgpack";
import decimal from "../decimal";
import hyperliquid;
import order;
import wire;
import evm;
import sign;
import user;

var secret: u8[32] = [0x11; 32];
var fields: u8[32] = [0; 32];
var body: u8[>..] = [];

fn mark(b: u8, ok: bool) -> u64 {
    if !ok { return 0; }
    let v: u64 = b;
    return v + 1;
}

fn time_batch<F>(batch: i64, ms: i64) -> i64, u64 {
    var sink: u64 = 0;
    var k = 0;
    while k < batch {
        sink += F();
        k += 1;
    }
    var n: i64 = 0;
    var dt: i64 = 0;
    let end = clock_ns() + ms * 1000000;
    while true {
        let t0 = clock_ns();
        k = 0;
        while k < batch {
            sink += F();
            k += 1;
        }
        dt += clock_ns() - t0;
        n += batch;
        if clock_ns() >= end { break; }
    }
    return dt / n, sink;
}

fn row<F>(name: u8[:], batch: i64, ms: i64) -> u64 {
    let ns, part = time_batch(batch, ms, F);
    var line: u8[>..] = [];
    format(line, name);
    while line.len < 28 { line.push(' '); }
    format_int(line, ns, 10, 12, ' ');
    format(line, "\n");
    write_stdout(line);
    return part;
}

fn norm_row() -> u64 {
    let t, ok = wire::normalize("10.00");
    if !ok || t.len == 0 { return 0; }
    return mark(t[0], true);
}

fn wei_row() -> u64 {
    let t, ok = evm::to_wei("72.5", 6);
    if !ok || t.len == 0 { return 0; }
    return mark(t[0], true);
}

fn batch_row() -> u64 {
    let raw, ok = order::batch("10.0", "1.5", "Gtc", order::Priority.Absent);
    if !ok || raw.len == 0 { return 0; }
    return mark(raw[0], true);
}

fn pre_row() -> u64 {
    let d, ok = order::prehash(body, 1700000000000);
    return mark(d[0], ok);
}

fn user_row() -> u64 {
    let d, ok = user::usd_send(hyperliquid::Chain.Mainnet, "0x1111111111111111111111111111111111111111", "1.5", 1, 1337);
    return mark(d[0], ok);
}

fn sign_row() -> u64 {
    fields[0] += 1;
    let sig, ok = sign::sign_user(secret, "HyperliquidTransaction:UsdSend", fields, 1337);
    if !ok { return 0; }
    return mark(sig[0], true);
}

fn ready() -> bool {
    let n, nok = wire::normalize("10.0");
    if !nok || n != "10" { return false; }
    let w, wok = evm::to_wei("69", 6);
    if !wok || w != "69000000" { return false; }
    let raw, rok = order::batch("10.0", "1", "Gtc", order::Priority.Absent);
    if !rok { return false; }
    body = copy(raw);
    let dig, dok = order::prehash(body, 1);
    if !dok || dig.len != 32 { return false; }
    let u, uok = user::usd_send(hyperliquid::Chain.Mainnet, "0x1111111111111111111111111111111111111111", "1", 1, 1337);
    if !uok || u.len != 32 { return false; }
    let sig, sok = sign::sign_user(secret, "HyperliquidTransaction:UsdSend", fields, 1337);
    return sok && sig.len == 65;
}

fn ::main() {
    if !ready() { print("bench FAIL"); exit(1); }
    write_stdout("operation                       ns/call\n");
    var sink: u64 = 0;
    sink += row("wire normalize", 32, 200, norm_row);
    sink += row("evm to_wei", 32, 200, wei_row);
    sink += row("order batch", 16, 200, batch_row);
    sink += row("order prehash", 16, 200, pre_row);
    sink += row("user usd_send", 16, 200, user_row);
    sink += row("sign_user", 1, 800, sign_row);
    var tail: u8[>..] = [];
    format(tail, "sink ");
    format(tail, sink);
    format(tail, "\n");
    write_stdout(tail);
}
