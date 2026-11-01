// Subscription texts for the HyperCore websocket.
// http.wsclient is not on kaitk/goose-http main yet, so this file does not
// import it and does not open a socket. A dropped connection resends the
// same texts. The opening does not offer permessage-deflate.

import json;

namespace ws;

fn sub(out: u8[>..]&, kind: u8[:], coin: u8[:], extra_key: u8[:], extra: u8[:]) {
    out.push('{');
    json::format_key(out, "method");
    json::format_string(out, "subscribe");
    out.push(',');
    json::format_key(out, "subscription");
    out.push('{');
    json::format_key(out, "type");
    json::format_string(out, kind);
    if coin.len != 0 {
        out.push(',');
        json::format_key(out, "coin");
        json::format_string(out, coin);
    }
    if extra_key.len != 0 {
        out.push(',');
        json::format_key(out, extra_key);
        json::format_string(out, extra);
    }
    out.push('}');
    out.push('}');
}

fn trades(coin: u8[:]) -> u8[>..] {
    var o: u8[>..] = [];
    sub(o, "trades", coin, "", "");
    return o;
}

fn l2_book(coin: u8[:]) -> u8[>..] {
    var o: u8[>..] = [];
    sub(o, "l2Book", coin, "", "");
    return o;
}

fn candle(coin: u8[:], interval: u8[:]) -> u8[>..] {
    var o: u8[>..] = [];
    sub(o, "candle", coin, "interval", interval);
    return o;
}

fn user_events(user: u8[:]) -> u8[>..] {
    var o: u8[>..] = [];
    sub(o, "userEvents", "", "user", user);
    return o;
}

fn active_asset(user: u8[:], coin: u8[:]) -> u8[>..] {
    var o: u8[>..] = [];
    out_active(o, user, coin);
    return o;
}

fn out_active(out: u8[>..]&, user: u8[:], coin: u8[:]) {
    out.push('{');
    json::format_key(out, "method");
    json::format_string(out, "subscribe");
    out.push(',');
    json::format_key(out, "subscription");
    out.push('{');
    json::format_key(out, "type");
    json::format_string(out, "activeAssetData");
    out.push(',');
    json::format_key(out, "user");
    json::format_string(out, user);
    out.push(',');
    json::format_key(out, "coin");
    json::format_string(out, coin);
    out.push('}');
    out.push('}');
}

fn post_info(payload: u8[:]) -> u8[>..] {
    var o: u8[>..] = [];
    o.push('{');
    json::format_key(o, "method");
    json::format_string(o, "post");
    o.push(',');
    json::format_key(o, "id");
    json::format_int(o, 1);
    o.push(',');
    json::format_key(o, "request");
    o.append(payload);
    o.push('}');
    return o;
}

fn opening() -> u8[:] { return "GET /ws HTTP/1.1"; }

fn connect(url: u8[:]) -> bool {
    if url.len == 0 { return false; }
    return false;
}
