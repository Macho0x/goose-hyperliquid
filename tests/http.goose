import os;
import json;
import base64;
import decimal from "../../decimal";
import deflate from "../../deflate";
import deflate.inflate;
import hyperliquid from "..";
import hyperliquid.exchange;
import hyperliquid.info;

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
    let action = "{\"type\":\"order\"}";
    var long: u8[>..] = [];
    long.append("0x");
    for i in 0..130 { long.push('a'); }
    let body = exchange::body(action, 1700000000000, long, exchange::Text.Absent, exchange::When.Never);
    if !has(body, "\"action\":") { return false; }
    if !has(body, "\"nonce\":1700000000000") { return false; }
    if has(body, "vaultAddress") { return false; }
    if long.len != 132 { return false; }
    let vaulted = exchange::body(action, 1, long, exchange::Text.Present { text: "0x2222222222222222222222222222222222222222" }, exchange::When.Never);
    if !has(vaulted, "\"vaultAddress\":\"0x2222222222222222222222222222222222222222\"") { return false; }

    var meta: u8[>..] = [];
    if !read_file("tests/fixtures/meta.json", meta) { return false; }
    let name, nok = info::first_market(meta);
    if !nok || name != "BTC" { return false; }
    var user: u8[>..] = [];
    if !read_file("tests/fixtures/user.json", user) { return false; }
    if !info::exchange_ok(user) { return false; }
    if !has(user, "\"total\":\"12.5\"") { return false; }
    if info::exchange_ok("{\"status\":\"err\"}") { return false; }
    let bad, bok = info::first_market("{");
    if bok { return false; }

    let plain, pok = info::asset_ctx("q1ZyCnFWsqpWyk0syg6oULJSMlSqrQUA");
    if !pok || plain != "{\"BTC\":{\"markPx\":\"1\"}}" { return false; }
    let req = info::request(info::Query.Meta, "");
    if req != "{\"type\":\"meta\"}" { return false; }
    return true;
}

fn ::main() {
    if self_check() { print("http ok"); } else { fail("http"); }
}
