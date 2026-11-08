// The JSON body posted to /exchange, and the POST itself.
// signature is the JSON object text, with r, s, and v.
// A program that calls post declares goose-http and goose-tls in its root file.

import json;
import http from "github.com/kaitk/goose-http@main";
import tls from "github.com/kaitk/goose-tls@v0.0.6";
import http.client;

namespace exchange;

enum Text { Absent, Present { text: const u8[:] } }
enum When { Never, At { time: i64 } }

fn put_vault(out: u8[>..]&, t: Text.Absent) { return; }
fn put_vault(out: u8[>..]&, t: Text.Present) {
    out.push(',');
    json::format_key(out, "vaultAddress");
    json::format_string(out, t.text);
}

fn put_expiry(out: u8[>..]&, w: When.Never) { return; }
fn put_expiry(out: u8[>..]&, w: When.At) {
    out.push(',');
    json::format_key(out, "expiresAfter");
    json::format_int(out, w.time);
}

fn body(action: u8[:], nonce: i64, signature: u8[:], vault: Text, expiry: When) -> u8[>..] {
    var out: u8[>..] = [];
    out.push('{');
    json::format_key(out, "action");
    out.append(action);
    out.push(',');
    json::format_key(out, "nonce");
    json::format_int(out, nonce);
    out.push(',');
    json::format_key(out, "signature");
    out.append(signature);
    put_vault(out, vault);
    put_expiry(out, expiry);
    out.push('}');
    return out;
}

fn post(session: http::Session&, chain: hyperliquid::Chain, payload: u8[:]) -> http::ClientResponse, http::Error {
    return http::post(session, hyperliquid::exchange_url(chain)) { req =>
        http::body(req, "application/json", payload);
    };
}
