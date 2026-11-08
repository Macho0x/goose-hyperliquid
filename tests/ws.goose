import os;
import json;
import http from "github.com/kaitk/goose-http@main";
import tls from "github.com/kaitk/goose-tls@v0.0.6";
import hash from "github.com/kaitk/goose-hash@v0.0.4";
import http.client;
import hyperliquid from "..";
import hyperliquid.ws;

fn fail(why: u8[:]) {
    write_stdout(why);
    write_stdout("\n");
    exit(1);
}

fn has(text: u8[:], needle: u8[:]) -> bool {
    if needle.len == 0 || needle.len > text.len { return false; }
    for i in 0..(text.len - needle.len + 1) {
        var same = true;
        for j in 0..needle.len {
            if text[i + j] != needle[j] { same = false; }
        }
        if same { return true; }
    }
    return false;
}

fn self_check() -> bool {
    let user = "0x2222222222222222222222222222222222222222";
    let trades = ws::trades("BTC");
    if !has(trades, "\"method\":\"subscribe\"") || !has(trades, "\"coin\":\"BTC\"") { return false; }
    let book = ws::l2_book("ETH");
    if !has(book, "\"type\":\"l2Book\"") || !has(book, "\"coin\":\"ETH\"") { return false; }
    let candle = ws::candle("BTC", "15m");
    if !has(candle, "\"interval\":\"15m\"") { return false; }
    let events = ws::user_events(user);
    if !has(events, "\"user\":\"0x2222222222222222222222222222222222222222\"") { return false; }
    let asset = ws::active_asset(user, "BTC");
    if !has(asset, "\"type\":\"activeAssetData\"") || !has(asset, "\"coin\":\"BTC\"") { return false; }
    let post = ws::post_info("{\"type\":\"meta\"}");
    if !has(post, "\"method\":\"post\"") { return false; }
    let again = ws::trades("BTC");
    if again != trades { return false; }
    var session = http::session();
    var missing, missing_err = ws::connect(session, "");
    if missing_err.call != "url" { return false; }
    var plain, plain_err = ws::connect(session, "https://api.hyperliquid.xyz/ws");
    if plain_err.call != "url" { return false; }
    if ws::send(missing, trades).call != "send" { return false; }
    let msg, read_err = ws::read(missing);
    if read_err.call != "recv" || msg.data.len != 0 { return false; }
    if ws::close(missing).code != 0 { return false; }
    if ws::close(plain).code != 0 { return false; }
    http::free(session);
    return true;
}

fn ::main() {
    if self_check() { print("ws ok"); } else { fail("ws"); }
}
