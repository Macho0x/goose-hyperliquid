// Info requests and a few response reads. Fast asset contexts are
// base64 wrapped around a raw DEFLATE stream.

import base64;
import deflate from "../deflate";
import deflate.inflate;
import json;

namespace info;

fn request(kind: u8[:], user: u8[:]) -> u8[>..] {
    var out: u8[>..] = [];
    out.push('{');
    json::format_key(out, "type");
    json::format_string(out, kind);
    if user.len != 0 {
        out.push(',');
        json::format_key(out, "user");
        json::format_string(out, user);
    }
    out.push('}');
    return out;
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

fn exchange_ok(text: u8[:]) -> bool {
    if has(text, "\"status\":\"err\"") { return false; }
    return has(text, "\"status\":\"ok\"");
}

fn first_market(text: u8[:]) -> u8[>..], bool {
    var doc: json::Node[>..] = [];
    var decoded: u8[>..] = [];
    let root, err = json::parse(text, doc, decoded);
    if root == null { return [], false; }
    let uni = json::member(root, "universe");
    if uni == null { return [], false; }
    let row = uni.first;
    if row == null { return [], false; }
    let name = json::member(row, "name");
    let s, ok = json::as_string(name);
    if !ok { return [], false; }
    var out: u8[>..] = [];
    out.append(s);
    return out, true;
}

fn asset_ctx(encoded: u8[:]) -> u8[>..], bool {
    var raw: u8[>..] = [];
    if !base64::decode(raw, encoded) { return [], false; }
    return inflate::decode(raw);
}
