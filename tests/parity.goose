import os;
import decimal from "../../decimal";
import msgpack from "../../msgpack";
import msgpack.encode;
import msgpack.value;
import crypto from "../../crypto";
import crypto.keccak256;
import signature from "../../signature";
import signature.eip712;
import deflate from "../../deflate";
import deflate.inflate;
import base64;
import json;
import http from "github.com/kaitk/goose-http@main";
import tls from "github.com/kaitk/goose-tls@v0.0.6";
import hash from "github.com/kaitk/goose-hash@v0.0.4";
import hyperliquid from "..";
import hyperliquid.wire;
import hyperliquid.sign;
import hyperliquid.user;
import hyperliquid.order;
import hyperliquid.l1;
import hyperliquid.jsonact;
import hyperliquid.info;
import hyperliquid.ws;
import hyperliquid.exchange;

fn fail(why: u8[:]) {
    write_stdout(why);
    write_stdout("\n");
    exit(1);
}

fn need(got: u8[:], want: u8[:], why: u8[:]) {
    if got != want { fail(why); }
}

fn self_check() -> bool {
    let noop = l1::noop();
    let js, jok = jsonact::of(noop);
    if !jok { return false; }
    need(js, "{\"type\":\"noop\"}", "noop json");

    let body, bok = order::batch("50000", "0.1", "Gtc", order::Priority.Absent);
    if !bok { return false; }
    let order_js, ojk = jsonact::of(body);
    if !ojk { return false; }
    need(order_js, "{\"type\":\"order\",\"orders\":[{\"a\":0,\"b\":true,\"p\":\"50000\",\"s\":\"0.1\",\"r\":false,\"t\":{\"limit\":{\"tif\":\"Gtc\"}}}],\"grouping\":\"na\"}", "order json");

    let sched = l1::schedule_cancel(l1::When.Never);
    let sched_js, sjk = jsonact::of(sched);
    if !sjk { return false; }
    need(sched_js, "{\"type\":\"scheduleCancel\",\"time\":null}", "null time");

    let trail = l1::trailing_px(1, l1::Side.Buy, "2", l1::Reduce.Open, "10", l1::Text.Absent);
    let trail_js, tjk = jsonact::of(trail);
    if !tjk { return false; }
    if trail_js.len < 20 { return false; }
    var saw_null = false;
    let needle = "\"activationPx\":null";
    if needle.len <= trail_js.len {
        for i in 0..(trail_js.len - needle.len + 1) {
            var same = true;
            for j in 0..needle.len { if trail_js[i + j] != needle[j] { same = false; } }
            if same { saw_null = true; }
        }
    }
    if !saw_null { return false; }

    let armed = l1::trailing_pct(1, l1::Side.Buy, "2", l1::Reduce.Open, "1.5%", l1::Text.Present { text: "100" });
    let armed_js, ajk = jsonact::of(armed);
    if !ajk { return false; }
    var saw_px = false;
    let mark = "\"activationPx\":\"100\"";
    if mark.len <= armed_js.len {
        for i in 0..(armed_js.len - mark.len + 1) {
            var same = true;
            for j in 0..mark.len { if armed_js[i + j] != mark[j] { same = false; } }
            if same { saw_px = true; }
        }
    }
    if !saw_px { return false; }

    let mkt, mok = order::market(1, order::Side.Sell, "3500", "0.01");
    if !mok { return false; }
    let mjs, mjk = jsonact::of(mkt);
    if !mjk { return false; }
    var saw_m = false;
    let tif = "\"tif\":\"FrontendMarket\"";
    if tif.len <= mjs.len {
        for i in 0..(mjs.len - tif.len + 1) {
            var same = true;
            for j in 0..tif.len { if mjs[i + j] != tif[j] { same = false; } }
            if same { saw_m = true; }
        }
    }
    if !saw_m { return false; }

    let who = "0x2222222222222222222222222222222222222222";
    let usd = user::usd_body(hyperliquid::Chain.Mainnet, who, "10", 1, 42161);
    need(usd, "{\"type\":\"usdSend\",\"signatureChainId\":\"0xa4b1\",\"hyperliquidChain\":\"Mainnet\",\"destination\":\"0x2222222222222222222222222222222222222222\",\"amount\":\"10\",\"time\":1}", "usd body");

    var addr: u8[20] = [0x22; 20];
    let set_a, aok = user::user_set_abstraction(hyperliquid::Chain.Mainnet, addr, "unifiedAccount", 1, 42161);
    let set_b, bok2 = user::user_set_abstraction(hyperliquid::Chain.Mainnet, addr, "default", 1, 42161);
    if !aok || !bok2 { return false; }
    if set_a != set_b { return false; }
    let set_js, setok = user::set_abstraction_body(hyperliquid::Chain.Mainnet, addr, "default", 1, 42161);
    if !setok { return false; }
    var saw_mode = false;
    let mode = "\"abstraction\":\"unifiedAccount\"";
    if mode.len <= set_js.len {
        for i in 0..(set_js.len - mode.len + 1) {
            var same = true;
            for j in 0..mode.len { if set_js[i + j] != mode[j] { same = false; } }
            if same { saw_mode = true; }
        }
    }
    if !saw_mode { return false; }

    let agent_u = l1::agent_set_abstraction("u");
    let agent_d = l1::agent_set_abstraction("default");
    if agent_u != agent_d { return false; }

    let tick, tok = wire::tick(wire::perp_max(5), "93231.23");
    if !tok || tick != "1" { return false; }
    let rounded, rok = wire::round_price(wire::perp_max(5), "93231.23");
    if !rok || rounded != "93231" { return false; }
    let tick2, t2 = wire::tick(wire::perp_max(2), "137.23025");
    if !t2 || tick2 != "0.01" { return false; }
    let r2, r2ok = wire::round_price(wire::perp_max(2), "137.23025");
    if !r2ok || r2 != "137.23" { return false; }
    let r3, r3ok = wire::round_price(wire::perp_max(2), "99.98241");
    if !r3ok || r3 != "99.982" { return false; }
    let r4, r4ok = wire::round_price(wire::spot_max(2), "15.9715981");
    if !r4ok || r4 != "15.972" { return false; }
    let r5, r5ok = wire::round_price(wire::perp_max(0), "1000");
    if !r5ok { return false; }
    let t5, t5ok = wire::tick(wire::perp_max(0), "1000");
    if !t5ok || t5 != "0.1" { return false; }
    let bad, bok3 = wire::tick(wire::perp_max(7), "100");
    if bok3 || bad.len != 0 { return false; }
    let zero, zok = wire::round_price(wire::perp_max(0), "0");
    if zok { return false; }
    let half, hok = wire::round_price(wire::perp_max(0), "10000.5");
    if !hok || half != "10000" { return false; }
    let up, uok = wire::round_price(wire::perp_max(0), "10000.6");
    if !uok || up != "10001" { return false; }
    let carry, cok2 = wire::round_price(wire::perp_max(0), "9.99996");
    if !cok2 || carry != "10" { return false; }
    let tiny, tinyok = wire::round_price(wire::spot_max(0), "0.0000003315");
    if !tinyok || tiny != "0.00000033" { return false; }
    let mid, midok = wire::round_price(wire::spot_max(0), "0.9543309");
    if !midok || mid != "0.95433" { return false; }
    let one, oneok = wire::tick(wire::perp_max(0), "1");
    if !oneok || one != "0.0001" { return false; }
    let book, bookok = info::fast_message("{\"channel\":\"fastAssetCtxs\",\"data\":\"q1ZyCnFWsqpWyk0syg6oULJSMlSqrQUA\"}");
    if !bookok || book != "{\"BTC\":{\"markPx\":\"1\"}}" { return false; }

    if hyperliquid::nonce() <= 0 { return false; }
    if hyperliquid::chain_hex(421614) != "0x66eee" { return false; }

    let posted = exchange::body(order_js, 1, "{\"r\":\"0x1\",\"s\":\"0x2\",\"v\":27}", exchange::Text.Absent, exchange::When.Never);
    let frame = ws::post_action(3, posted);
    if frame.len < 20 { return false; }
    return true;
}

fn ::main() {
    if self_check() { print("parity ok"); } else { fail("parity"); }
}
