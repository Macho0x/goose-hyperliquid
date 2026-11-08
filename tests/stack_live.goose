// Live mainnet, clang, nanosecond stamps.
//   goose build -o /tmp/stack-live tests/stack_live.goose --cc clang
//   /tmp/stack-live
// Twenty posts of meta on one session. Then one socket on BTC bbo, trades,
// and the fast book for eight seconds. Then one allMids read at the
// default 64 KiB limit.

import std;
import os;
import json;
import deflate from "../../deflate";
import decimal from "../../decimal";
import http from "github.com/kaitk/goose-http@main";
import tls from "github.com/kaitk/goose-tls@v0.0.6";
import hash from "github.com/kaitk/goose-hash@v0.0.4";
import http.client;
import hyperliquid from "..";
import hyperliquid.info;
import hyperliquid.ws;
import .book;

fn fail(why: u8[:]) {
    write_stdout(why);
    write_stdout("\n");
    exit(1);
}

fn http_posts() {
    var session = http::session();
    session.deadline = http::deadline(15000);
    let payload = info::request(info::Query.Meta, "");
    let url = hyperliquid::info_url(hyperliquid::Chain.Mainnet);
    var times: i64[20] = [0; 20];
    var status: i64 = 0;
    for i in 20 {
        session.deadline = http::deadline(15000);
        let t0 = clock_ns();
        let res, err = info::post(session, hyperliquid::Chain.Mainnet, payload);
        times[i] = clock_ns() - t0;
        if err.code != 0 { fail(err.call); }
        status = res.status;
        if res.body.len == 0 { fail("empty info"); }
    }
    http::free(session);
    var rest: i64[>..] = [];
    for i in 1..20 { rest.push(times[i]); }
    stack::sort(rest);
    print("http_first_ns ", times[0], " http_median_ns ", rest[rest.len / 2], " status ", status, " url ", url.len);
}

fn ack(conn: http::WsClient&) -> bool {
    loop {
        let msg, e = ws::read(conn);
        if e.code != 0 { return false; }
        if find(msg.data, "subscriptionResponse") >= 0 { return true; }
    }
}

fn note(gap: i64[>..]&, parse: i64[>..]&, last: i64&, arrived: i64, took: i64) {
    if last != 0 { gap.push(arrived - last); }
    last = arrived;
    parse.push(took);
}

fn show(name: u8[:], gap: i64[>..]&, parse: i64[>..]&) {
    print(name, " n ", parse.len, " gap_p50_ns ", stack::percentile(gap, 50), " gap_p99_ns ", stack::percentile(gap, 99), " parse_p99_ns ", stack::percentile(parse, 99));
}

fn feed() {
    var session = http::session();
    session.deadline = http::deadline(10000);
    var conn, err = ws::connect(session, hyperliquid::ws_url(hyperliquid::Chain.Mainnet));
    if err.code != 0 { fail(err.call); }
    let bbo = ws::bbo("BTC");
    let trades = ws::trades("BTC");
    let book = ws::l2_book_opts("BTC", ws::Stamp.Absent, ws::Stamp.Absent, true);
    if ws::send(conn, bbo).code != 0 || !ack(conn) { fail("bbo"); }
    if ws::send(conn, trades).code != 0 || !ack(conn) { fail("trades"); }
    if ws::send(conn, book).code != 0 || !ack(conn) { fail("l2"); }

    conn.session.deadline = http::deadline(8000);
    var bbo_gap: i64[>..] = [];
    var bbo_parse: i64[>..] = [];
    var bbo_last: i64 = 0;
    var tr_gap: i64[>..] = [];
    var tr_parse: i64[>..] = [];
    var tr_last: i64 = 0;
    var l2_gap: i64[>..] = [];
    var l2_parse: i64[>..] = [];
    var l2_last: i64 = 0;
    var other: i64 = 0;
    loop {
        let msg, e = ws::read(conn);
        if e.code != 0 {
            if e.code != http::ETIMEDOUT { print("read ", e.call, " ", e.code); }
            break;
        }
        let arrived = clock_ns();
        var kind = 0;
        if find(msg.data, "\"channel\":\"l2Book\"") >= 0 { kind = 1; }
        else if find(msg.data, "\"channel\":\"bbo\"") >= 0 { kind = 2; }
        else if find(msg.data, "\"channel\":\"trades\"") >= 0 { kind = 3; }
        else { other += 1; continue; }
        if kind == 1 {
            let bid, ask, bn, an, ok = stack::sum(msg.data);
            let took = clock_ns() - arrived;
            if ok && bn == 5 && an == 5 {
                note(l2_gap, l2_parse, l2_last, arrived, took);
                let sink = bid.w[0] + ask.w[0];
                if sink == 0 && msg.data.len == 0 { other += 0; }
            }
        } else {
            var doc: json::Node[>..] = [];
            var decoded: u8[>..] = [];
            let root, perr = json::parse(msg.data, doc, decoded);
            let took = clock_ns() - arrived;
            if root == null || perr.len != 0 { continue; }
            if kind == 2 { note(bbo_gap, bbo_parse, bbo_last, arrived, took); }
            else { note(tr_gap, tr_parse, tr_last, arrived, took); }
        }
    }
    ws::close(conn);
    http::free(session);
    show("bbo", bbo_gap, bbo_parse);
    show("trades", tr_gap, tr_parse);
    show("l2", l2_gap, l2_parse);
    print("other ", other);
}

fn all_mids() {
    var session = http::session();
    session.deadline = http::deadline(10000);
    var conn, err = ws::connect(session, hyperliquid::ws_url(hyperliquid::Chain.Mainnet));
    if err.code != 0 { fail(err.call); }
    let sub = ws::all_mids("");
    if ws::send(conn, sub).code != 0 { fail("allmids send"); }
    var bytes: i64 = 0;
    var call: u8[>..] = [];
    var code: i64 = 0;
    loop {
        let msg, e = ws::read(conn);
        if e.code != 0 {
            call.append(e.call);
            code = e.code;
            break;
        }
        if find(msg.data, "subscriptionResponse") >= 0 { continue; }
        bytes = msg.data.len;
        call.append("ok");
        break;
    }
    ws::close(conn);
    http::free(session);
    print("allmids ", call, " code ", code, " bytes ", bytes);
}

fn ::main() {
    http_posts();
    feed();
    all_mids();
    print("live ok");
}
