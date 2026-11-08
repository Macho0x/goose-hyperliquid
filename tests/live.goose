// Talks to Hyperliquid mainnet. The other tests do not.
//   goose tests/live.goose
import std;
import os;
import deflate from "../../deflate";
import http from "github.com/kaitk/goose-http@main";
import tls from "github.com/kaitk/goose-tls@v0.0.6";
import hash from "github.com/kaitk/goose-hash@v0.0.4";
import http.client;
import hyperliquid from "..";
import hyperliquid.info;
import hyperliquid.exchange;
import hyperliquid.ws;

fn fail(why: u8[:]) {
    write_stdout(why);
    write_stdout("\n");
    exit(1);
}

fn ::main() {
    var session = http::session();
    session.deadline = http::deadline(15000);
    let meta = info::request(info::Query.Meta, "");
    let info_res, info_err = info::post(session, hyperliquid::Chain.Mainnet, meta);
    if info_err.code != 0 { fail(info_err.call); }
    if info_res.status != 200 { fail("info status"); }
    let name, nok = info::first_market(info_res.body);
    if !nok || name.len == 0 { fail("meta"); }
    print("info ", name);

    session.deadline = http::deadline(15000);
    let action = "{\"type\":\"noop\"}";
    let sig = "{\"r\":\"0x0000000000000000000000000000000000000000000000000000000000000001\",\"s\":\"0x0000000000000000000000000000000000000000000000000000000000000001\",\"v\":27}";
    let posted = exchange::body(action, 1, sig, exchange::Text.Absent, exchange::When.Never);
    let ex_res, ex_err = exchange::post(session, hyperliquid::Chain.Mainnet, posted);
    if ex_err.code != 0 { fail(ex_err.call); }
    if ex_res.status != 200 { fail("exchange status"); }
    if find(ex_res.body, "\"status\"") < 0 { fail("exchange body"); }
    print("exchange ", ex_res.body);

    session.deadline = http::deadline(15000);
    let sub = ws::trades("BTC");
    var conn, msg, ws_err = ws::subscribe(session, hyperliquid::Chain.Mainnet, sub);
    if ws_err.code != 0 {
        ws::close(conn);
        fail(ws_err.call);
    }
    if find(msg.data, "subscriptionResponse") < 0 {
        ws::close(conn);
        fail("subscribe");
    }
    print("ws ", msg.data);
    ws::close(conn);
    http::free(session);
    print("live ok");
}
