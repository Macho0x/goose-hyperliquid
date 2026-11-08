import os;
import deflate from "../../deflate";
import deflate.inflate;
import base64;
import json;
import msgpack from "../../msgpack";
import msgpack.encode;
import crypto from "../../crypto";
import crypto.keccak256;
import signature from "../../signature";
import signature.eip712;
import decimal from "../../decimal";
import http from "github.com/kaitk/goose-http@main";
import tls from "github.com/kaitk/goose-tls@v0.0.6";
import hash from "github.com/kaitk/goose-hash@v0.0.4";
import hyperliquid from "..";
import hyperliquid.wire;
import hyperliquid.sign;
import hyperliquid.user;
import hyperliquid.l1;
import hyperliquid.info;
import hyperliquid.ws;

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
    for i in 0..b.len {
        s.push(hex_digit(b[i] >> 4));
        s.push(hex_digit(b[i] & 0x0f));
    }
    return s;
}

fn need(got: u8[:], want: u8[:], why: u8[:]) {
    if got != want { fail(why); }
}

fn addr() -> u8[20] {
    let a, ok = wire::parse_address("0x2222222222222222222222222222222222222222");
    if !ok { fail("addr"); }
    return a;
}

fn self_check() -> bool {
    need(hex(l1::update_leverage(1, l1::Margin.Cross, 5)), "84a474797065ae7570646174654c65766572616765a5617373657401a7697343726f7373c3a86c6576657261676505", "lev");
    need(hex(l1::update_isolated_margin(1, l1::Side.Buy, 1000000)), "84a474797065b475706461746549736f6c617465644d617267696ea5617373657401a56973427579c3a46e746c69ce000f4240", "margin");
    let vault_body = l1::vault_transfer("0x2222222222222222222222222222222222222222", l1::Flow.Deposit, 1000000);
    need(hex(vault_body), "84a474797065ad7661756c745472616e73666572ac7661756c7441646472657373d92a307832323232323232323232323232323232323232323232323232323232323232323232323232323232a969734465706f736974c3a3757364ce000f4240", "vault");
    need(hex(l1::schedule_cancel(l1::When.Never)), "82a474797065ae7363686564756c6543616e63656ca474696d65c0", "sched");
    need(hex(l1::schedule_cancel(l1::When.At { time: 1700000000000 })), "82a474797065ae7363686564756c6543616e63656ca474696d65cf0000018bcfe56800", "sched time");
    need(hex(l1::noop()), "81a474797065a46e6f6f70", "noop");
    need(hex(l1::borrow_lend("supply", 0, "10")), "84a474797065aa626f72726f774c656e64a96f7065726174696f6ea6737570706c79a5746f6b656e00a6616d6f756e74a23130", "borrow");
    need(hex(l1::spot_dust(true)), "82a474797065a873706f7455736572b1746f67676c6553706f7444757374696e6781a66f70744f7574c3", "dust");
    need(hex(l1::sub_account_transfer("0x2222222222222222222222222222222222222222", l1::Flow.Deposit, 5)), "84a474797065b27375624163636f756e745472616e73666572ae7375624163636f756e7455736572d92a307832323232323232323232323232323232323232323232323232323232323232323232323232323232a969734465706f736974c3a375736405", "sub");

    let a = addr();
    let dex, dok = user::user_dex_abstraction(hyperliquid::Chain.Mainnet, a, true, 1, 42161);
    if !dok { return false; }
    need(hex(dex), "a8b9f6957365fb334360934008bbc075f1369a6b021f68083d800e6cb0c5510a", "dex");
    let set, sok = user::user_set_abstraction(hyperliquid::Chain.Mainnet, a, "unifiedAccount", 1, 42161);
    if !sok { return false; }
    need(hex(set), "cb267405c50bc2873f17ca9891e7e9ca4ef8cd8839c9f3f9f2efb25ee1f5b11a", "set");
    let pm, pok = user::user_portfolio_margin(hyperliquid::Chain.Mainnet, a, true, 1, 42161);
    if !pok { return false; }
    need(hex(pm), "d40ac2dfe5f15061c4f6acaa2bd4cd49c88f46efca20a368e7c8368e022713c6", "pm");
    let link, lok = user::link_staking_user(hyperliquid::Chain.Mainnet, a, false, 1, 42161);
    if !lok { return false; }
    need(hex(link), "7019d22aae4c6616289a1c7a67a0f25d807657d97a6d11d2087f55902339f267", "link");
    let dis, disok = user::disable_staking_link(hyperliquid::Chain.Mainnet, a, 1, 42161);
    if !disok { return false; }
    need(hex(dis), "d3702c1e6a5514826afa4ce563dcea2a5e5aa242e7564e2abc0f320951ff72e1", "disable");
    let del, delok = user::token_delegate(hyperliquid::Chain.Mainnet, a, 1000, false, 1, 42161);
    if !delok { return false; }
    need(hex(del), "b63edfaad08b1d08acd28d14a5a5326f4d52b8c199ffab4e7b322930bc4a82da", "delegate");
    var data: u8[2] = [0x12, 0x34];
    let evm, eok = user::send_to_evm(hyperliquid::Chain.Mainnet, "USDC:0x1", "10", "spot", "0x2222222222222222222222222222222222222222", "hex", 1, 100000, data, 1, 42161);
    if !eok { return false; }
    need(hex(evm), "eef72024f2f4841974e081c87c344460c52bf50e994c686f9cd20bb32a8c0928", "evm");
    let conv, cok = user::convert_to_multisig(hyperliquid::Chain.Mainnet, "null", 1, 42161);
    if !cok { return false; }
    need(hex(conv), "294517fdccf3e674b131aba7a8f3059cb720f6239c76672557d14561e2e9d1bc", "convert");

    let user = "0x2222222222222222222222222222222222222222";
    if info::typed(info::Query.SpotMeta) != "{\"type\":\"spotMeta\"}" { return false; }
    if info::typed(info::Query.ExchangeStatus) != "{\"type\":\"exchangeStatus\"}" { return false; }
    if info::user_query(info::Query.ClearinghouseState, user) != "{\"type\":\"clearinghouseState\",\"user\":\"0x2222222222222222222222222222222222222222\"}" { return false; }
    if info::l2_book("BTC", info::Stamp.At { n: 5 }, info::Stamp.Absent) != "{\"type\":\"l2Book\",\"coin\":\"BTC\",\"nSigFigs\":5}" { return false; }
    if info::candle_snapshot("BTC", "15m", 1, 2) != "{\"type\":\"candleSnapshot\",\"req\":{\"coin\":\"BTC\",\"interval\":\"15m\",\"startTime\":1,\"endTime\":2}}" { return false; }
    if info::max_builder_fee(user, user) != "{\"type\":\"maxBuilderFee\",\"user\":\"0x2222222222222222222222222222222222222222\",\"builder\":\"0x2222222222222222222222222222222222222222\"}" { return false; }
    if ws::bbo("BTC").len == 0 { return false; }
    if ws::fast_asset_ctxs().len == 0 { return false; }
    if ws::web_data3(user).len == 0 { return false; }
    if ws::outcome_meta_updates().len == 0 { return false; }
    if info::recent_trades("BTC") != "{\"type\":\"recentTrades\",\"coin\":\"BTC\"}" { return false; }
    if info::user_fills(user, info::Flag.No) != "{\"type\":\"userFills\",\"user\":\"0x2222222222222222222222222222222222222222\",\"aggregateByTime\":false}" { return false; }
    if info::clearinghouse_on(user, "abcd") != "{\"type\":\"clearinghouseState\",\"user\":\"0x2222222222222222222222222222222222222222\",\"dex\":\"abcd\"}" { return false; }
    return true;
}

fn ::main() {
    if self_check() { print("coverage ok"); } else { fail("coverage"); }
}
