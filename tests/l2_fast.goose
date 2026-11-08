// Five seconds of the BTC book with fast set, built with clang.
//   goose build -o /tmp/l2-fast tests/l2_fast.goose --cc clang
//   /tmp/l2-fast
// TinyCC (goose tests/l2_fast.goose) is not a timing result.
// Each line is one snapshot: milliseconds since the first book, the gap
// since the previous one, the parse, and the resting size of the best
// five bids and five asks. sz is coins resting at those prices.

import std;
import os;
import json;
import http from "github.com/kaitk/goose-http@main";
import tls from "github.com/kaitk/goose-tls@v0.0.6";
import hash from "github.com/kaitk/goose-hash@v0.0.4";
import decimal from "../../decimal";
import hyperliquid from "..";
import hyperliquid.ws;

fn fail(why: u8[:]) {
    write_stdout(why);
    write_stdout("\n");
    exit(1);
}

fn add_sz(total: decimal::Dec, level: json::Node?) -> decimal::Dec, bool {
    let sz = json::member(level, "sz");
    let text, ok = json::as_string(sz);
    if !ok { return total, false; }
    let d, dok = decimal::parse(text);
    if !dok { return total, false; }
    return decimal::add(total, d);
}

fn sum_top(side: json::Node?, n: i64) -> decimal::Dec, i64 {
    var total = decimal::zero();
    var got: i64 = 0;
    guard side else { return total, 0; }
    var c = side.first;
    while c && got < n {
        let next, ok = add_sz(total, c);
        if !ok { return total, got; }
        total = next;
        got += 1;
        c .= c.next;
    }
    return total, got;
}

fn book(text: u8[:]) -> decimal::Dec, decimal::Dec, i64, i64, bool {
    var doc: json::Node[>..] = [];
    var decoded: u8[>..] = [];
    let root, err = json::parse(text, doc, decoded);
    if root == null || err.len != 0 { return decimal::zero(), decimal::zero(), 0, 0, false; }
    let data = json::member(root, "data");
    let levels = json::member(data, "levels");
    guard levels else { return decimal::zero(), decimal::zero(), 0, 0, false; }
    let bids = levels.first;
    let bid, bn = sum_top(bids, 5);
    var ask = decimal::zero();
    var an: i64 = 0;
    if bids {
        let a, n = sum_top(bids.next, 5);
        ask = a;
        an = n;
    }
    return bid, ask, bn, an, true;
}

fn ::main() {
    var session = http::session();
    session.deadline = http::deadline(10000);
    var conn, err = ws::connect(session, hyperliquid::ws_url(hyperliquid::Chain.Mainnet));
    if err.code != 0 { fail(err.call); }
    let sub = ws::l2_book_opts("BTC", ws::Stamp.Absent, ws::Stamp.Absent, true);
    let sent_at = http::net_clock_ms();
    let sent = ws::send(conn, sub);
    if sent.code != 0 { ws::close(conn); http::free(session); fail(sent.call); }

    let ack, aerr = ws::read(conn);
    if aerr.code != 0 { ws::close(conn); http::free(session); fail(aerr.call); }
    if find(ack.data, "subscriptionResponse") < 0 {
        ws::close(conn);
        http::free(session);
        fail("ack");
    }
    print("ack ", http::net_clock_ms() - sent_at, " ", ack.data);

    conn.session.deadline = http::deadline(5000);
    var times: i64[>..] = [];
    var slow: i64 = 0;
    var books: i64 = 0;
    var bad: i64 = 0;
    var last_bid = decimal::zero();
    var last_ask = decimal::zero();
    loop {
        let msg, e = ws::read(conn);
        if e.code != 0 {
            if e.code != http::ETIMEDOUT { print("read ", e.call, " ", e.code); }
            break;
        }
        let arrived = http::net_clock_ms();
        if find(msg.data, "l2Book") < 0 { continue; }
        let bid, ask, bn, an, ok = book(msg.data);
        let parsed = http::net_clock_ms();
        if !ok { bad += 1; continue; }
        let took = parsed - arrived;
        if took > slow { slow = took; }
        let gap = if times.len == 0 { 0 } else { arrived - times[times.len - 1] };
        times.push(arrived);
        books += 1;
        last_bid = bid;
        last_ask = ask;
        print(books, " ", arrived - times[0], " ", gap, " ", took, " ", bn, " ", an, " ", decimal::text(bid), " ", decimal::text(ask));
    }
    ws::close(conn);
    http::free(session);
    if books == 0 { fail("no book"); }
    var gmin: i64 = 0;
    var gmax: i64 = 0;
    var gsum: i64 = 0;
    var gaps: i64 = 0;
    for i in 1..times.len {
        let g = times[i] - times[i - 1];
        if gaps == 0 || g < gmin { gmin = g; }
        if g > gmax { gmax = g; }
        gsum += g;
        gaps += 1;
    }
    let mean = if gaps == 0 { 0 } else { gsum / gaps };
    let span = times[times.len - 1] - times[0];
    print("books ", books, " bad ", bad, " span_ms ", span, " gap_min ", gmin, " gap_max ", gmax, " gap_mean ", mean, " parse_max_ms ", slow);
    print("last_bid ", decimal::text(last_bid), " last_ask ", decimal::text(last_ask));
}
