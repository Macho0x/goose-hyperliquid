import os;
import decimal from "../../decimal";
import crypto from "../../crypto";
import crypto.keccak256;
import signature from "../../signature";
import signature.eip712;
import msgpack from "../../msgpack";
import msgpack.encode;
import deflate from "../../deflate";
import deflate.inflate;
import base64;
import json;
import ethereum from "../../ethereum";
import ethereum.abi;
import ethereum.rpc;
import http from "github.com/kaitk/goose-http@main";
import tls from "github.com/kaitk/goose-tls@v0.0.6";
import hash from "github.com/kaitk/goose-hash@v0.0.4";
import hyperliquid from "..";
import hyperliquid.wire;
import hyperliquid.sign;
import hyperliquid.user;
import hyperliquid.order;
import hyperliquid.l1;
import hyperliquid.deploy;
import hyperliquid.info;
import hyperliquid.ws;
import hyperliquid.evm;
import hyperliquid.morpho;

fn fail(why: u8[:]) {
    write_stdout(why);
    write_stdout("\n");
    exit(1);
}

fn self_check() -> bool {
    let ten, tok = wire::normalize("10.0");
    if !tok || ten != "10" { return false; }
    let usd, uok = user::usd_send(hyperliquid::Chain.Mainnet, "0x2222222222222222222222222222222222222222", "10", 1, 42161);
    if !uok { return false; }
    let body, bok = order::batch("50000", "0.1", "Gtc", order::Priority.Absent);
    if !bok { return false; }
    let dig, dok = order::prehash(body, 1700000000000);
    if !dok { return false; }
    let req = info::request(info::Query.Meta, "");
    if req != "{\"type\":\"meta\"}" { return false; }
    let trades = ws::trades("BTC");
    if trades.len == 0 { return false; }
    let wei, wok = evm::to_wei("69", 6);
    if !wok || wei != "69000000" { return false; }
    if morpho::market_selector() != abi::selector("market(bytes32)") { return false; }
    if l1::noop().len == 0 { return false; }
    if deploy::disable_dex("abcd").len == 0 { return false; }
    if info::spot_meta() != "{\"type\":\"spotMeta\"}" { return false; }
    if !user::has_schema("sendToEvmWithData") { return false; }
    return true;
}

fn ::main() {
    if self_check() { print("hyperliquid ok"); } else { fail("hyperliquid"); }
}
