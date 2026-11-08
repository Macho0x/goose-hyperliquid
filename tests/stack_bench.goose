// Parser and body builders, no socket. Clang, nanoseconds per call.
//   goose build -o /tmp/stack-bench tests/stack_bench.goose --cc clang
//   /tmp/stack-bench
// TinyCC is not a timing result.

import os;
import decimal from "../../decimal";
import deflate from "../../deflate";
import http from "github.com/kaitk/goose-http@main";
import tls from "github.com/kaitk/goose-tls@v0.0.6";
import hyperliquid from "..";
import hyperliquid.info;
import hyperliquid.exchange;
import .book;

var fast_book: u8[>..] = [];
var deep_book: u8[>..] = [];
var step: i64 = 1;

fn mix(body: u8[:]) -> u64 {
    var s: u64 = 0;
    for b in body { s += b; }
    return s;
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
    print(name, " ", ns);
    return part;
}

fn use_book(text: u8[:]) -> u64 {
    let bid, ask, bn, an, ok = stack::sum(text);
    if !ok || bn != 5 || an != 5 { return 0; }
    let t = decimal::text(bid);
    let u = decimal::text(ask);
    if t.len == 0 || u.len == 0 { return 0; }
    return t[0] + u[0];
}

fn row_fast() -> u64 { return use_book(fast_book); }
fn row_deep() -> u64 { return use_book(deep_book); }

fn row_info() -> u64 {
    step += 1;
    var user: u8[>..] = [];
    format(user, step);
    let body = info::request(info::Query.ClearinghouseState, user);
    if body.len == 0 { return 0; }
    return mix(body);
}

fn row_exchange() -> u64 {
    step += 1;
    let sig = "{\"r\":\"0x1\",\"s\":\"0x2\",\"v\":27}";
    let body = exchange::body("{\"type\":\"noop\"}", step, sig, exchange::Text.Absent, exchange::When.Never);
    if body.len == 0 { return 0; }
    return mix(body);
}

fn ::main() {
    fast_book = stack::book(5);
    deep_book = stack::book(20);
    let check = use_book(fast_book) + use_book(deep_book);
    if check == 0 { print("book"); exit(1); }
    var sink: u64 = 0;
    sink += row("book5_ns", 20, 300, row_fast);
    sink += row("book20_ns", 20, 300, row_deep);
    sink += row("info_ns", 50, 200, row_info);
    sink += row("exchange_ns", 50, 200, row_exchange);
    print("sink ", sink);
}
