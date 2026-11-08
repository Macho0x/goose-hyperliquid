// Subscription texts for the HyperCore websocket, and a blocking socket
// on http.wsclient. send writes one text frame. After a drop, connect
// again and send the same text. The client offers no permessage-deflate.
// goose-http compresses with goose-compress, and this file imports neither
// that package nor the deflate package.
// A program that imports this module declares goose-http, goose-tls, and
// goose-hash in its root file. Set session.deadline before connect.
// conn.limit is 64 KiB until the caller raises it.

import json;
import http from "github.com/kaitk/goose-http@main";
import tls from "github.com/kaitk/goose-tls@v0.0.6";
import hash from "github.com/kaitk/goose-hash@v0.0.4";
import http.wsclient;

namespace ws;

enum Channel {
    Trades,
    L2Book,
    Candle,
    UserEvents,
    Bbo,
    OrderUpdates,
    UserFills,
    ActiveAssetCtx,
    SpotAssetCtxs,
    FastAssetCtxs,
    Notification,
    WebData3,
    UserTwapSliceFills,
    UserTwapHistory,
    UserHistoricalOrders,
    AllDexsClearinghouseState,
    UserFundings,
    UserNonFundingLedgerUpdates,
    AllDexsAssetCtxs,
    OutcomeMetaUpdates,
    AllMids,
    AssetCtxs,
    OpenOrders,
    TwapStates,
    ActiveAssetData,
    ClearinghouseState,
    SpotState,
}

fn channel_text(k: Channel) -> u8[:] {
    if k == Channel.Trades { return "trades"; }
    if k == Channel.L2Book { return "l2Book"; }
    if k == Channel.Candle { return "candle"; }
    if k == Channel.UserEvents { return "userEvents"; }
    if k == Channel.Bbo { return "bbo"; }
    if k == Channel.OrderUpdates { return "orderUpdates"; }
    if k == Channel.UserFills { return "userFills"; }
    if k == Channel.ActiveAssetCtx { return "activeAssetCtx"; }
    if k == Channel.SpotAssetCtxs { return "spotAssetCtxs"; }
    if k == Channel.FastAssetCtxs { return "fastAssetCtxs"; }
    if k == Channel.Notification { return "notification"; }
    if k == Channel.WebData3 { return "webData3"; }
    if k == Channel.UserTwapSliceFills { return "userTwapSliceFills"; }
    if k == Channel.UserTwapHistory { return "userTwapHistory"; }
    if k == Channel.UserHistoricalOrders { return "userHistoricalOrders"; }
    if k == Channel.AllDexsClearinghouseState { return "allDexsClearinghouseState"; }
    if k == Channel.UserFundings { return "userFundings"; }
    if k == Channel.UserNonFundingLedgerUpdates { return "userNonFundingLedgerUpdates"; }
    if k == Channel.AllDexsAssetCtxs { return "allDexsAssetCtxs"; }
    if k == Channel.OutcomeMetaUpdates { return "outcomeMetaUpdates"; }
    if k == Channel.AllMids { return "allMids"; }
    if k == Channel.AssetCtxs { return "assetCtxs"; }
    if k == Channel.OpenOrders { return "openOrders"; }
    if k == Channel.TwapStates { return "twapStates"; }
    if k == Channel.ActiveAssetData { return "activeAssetData"; }
    if k == Channel.ClearinghouseState { return "clearinghouseState"; }
    return "spotState";
}

enum Flag { Absent, No, Yes }
enum Stamp { Absent, At { n: i64 } }

fn flag_set(f: Flag.Absent) -> bool { return false; }
fn flag_set(f: Flag.No) -> bool { return true; }
fn flag_set(f: Flag.Yes) -> bool { return true; }

fn stamp_set(s: Stamp.Absent) -> bool { return false; }
fn stamp_set(s: Stamp.At) -> bool { return true; }
fn stamp_n(s: Stamp.Absent) -> i64 { return 0; }
fn stamp_n(s: Stamp.At) -> i64 { return s.n; }


fn sub(out: u8[>..]&, kind: Channel, coin: u8[:], extra_key: u8[:], extra: u8[:]) {
    out.push('{');
    json::format_key(out, "method");
    json::format_string(out, "subscribe");
    out.push(',');
    json::format_key(out, "subscription");
    out.push('{');
    json::format_key(out, "type");
    json::format_string(out, channel_text(kind));
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
    sub(o, Channel.Trades, coin, "", "");
    return o;
}

fn l2_book(coin: u8[:]) -> u8[>..] {
    var o: u8[>..] = [];
    sub(o, Channel.L2Book, coin, "", "");
    return o;
}

fn candle(coin: u8[:], interval: u8[:]) -> u8[>..] {
    var o: u8[>..] = [];
    sub(o, Channel.Candle, coin, "interval", interval);
    return o;
}

fn user_events(user: u8[:]) -> u8[>..] {
    var o: u8[>..] = [];
    sub(o, Channel.UserEvents, "", "user", user);
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
    json::format_string(out, channel_text(Channel.ActiveAssetData));
    out.push(',');
    json::format_key(out, "user");
    json::format_string(out, user);
    out.push(',');
    json::format_key(out, "coin");
    json::format_string(out, coin);
    out.push('}');
    out.push('}');
}

fn bbo(coin: u8[:]) -> u8[>..] {
    var o: u8[>..] = [];
    sub(o, Channel.Bbo, coin, "", "");
    return o;
}

fn all_mids(dex: u8[:]) -> u8[>..] { return all_mids_kind(Channel.AllMids, dex); }

fn order_updates(user: u8[:]) -> u8[>..] {
    var o: u8[>..] = [];
    sub(o, Channel.OrderUpdates, "", "user", user);
    return o;
}

fn user_fills(user: u8[:]) -> u8[>..] {
    var o: u8[>..] = [];
    sub(o, Channel.UserFills, "", "user", user);
    return o;
}

fn active_asset_ctx(coin: u8[:]) -> u8[>..] {
    var o: u8[>..] = [];
    sub(o, Channel.ActiveAssetCtx, coin, "", "");
    return o;
}

fn spot_asset_ctxs() -> u8[>..] {
    var o: u8[>..] = [];
    sub(o, Channel.SpotAssetCtxs, "", "", "");
    return o;
}

fn fast_asset_ctxs() -> u8[>..] {
    var o: u8[>..] = [];
    sub(o, Channel.FastAssetCtxs, "", "", "");
    return o;
}

fn notification(user: u8[:]) -> u8[>..] {
    var o: u8[>..] = [];
    sub(o, Channel.Notification, "", "user", user);
    return o;
}

fn web_data3(user: u8[:]) -> u8[>..] {
    var o: u8[>..] = [];
    sub(o, Channel.WebData3, "", "user", user);
    return o;
}

fn clearinghouse_state(user: u8[:], dex: u8[:]) -> u8[>..] {
    var o: u8[>..] = [];
    o.push('{');
    json::format_key(o, "method");
    json::format_string(o, "subscribe");
    o.push(',');
    json::format_key(o, "subscription");
    o.push('{');
    json::format_key(o, "type");
    json::format_string(o, channel_text(Channel.ClearinghouseState));
    o.push(',');
    json::format_key(o, "user");
    json::format_string(o, user);
    if dex.len != 0 {
        o.push(',');
        json::format_key(o, "dex");
        json::format_string(o, dex);
    }
    o.push('}');
    o.push('}');
    return o;
}

fn user_twap_slice_fills(user: u8[:]) -> u8[>..] {
    var o: u8[>..] = [];
    sub(o, Channel.UserTwapSliceFills, "", "user", user);
    return o;
}

fn user_twap_history(user: u8[:]) -> u8[>..] {
    var o: u8[>..] = [];
    sub(o, Channel.UserTwapHistory, "", "user", user);
    return o;
}

fn asset_ctxs(dex: u8[:]) -> u8[>..] { return all_mids_kind(Channel.AssetCtxs, dex); }

fn user_historical_orders(user: u8[:]) -> u8[>..] {
    var o: u8[>..] = [];
    sub(o, Channel.UserHistoricalOrders, "", "user", user);
    return o;
}

fn all_dexs_clearinghouse(user: u8[:]) -> u8[>..] {
    var o: u8[>..] = [];
    sub(o, Channel.AllDexsClearinghouseState, "", "user", user);
    return o;
}

fn open_orders(user: u8[:], dex: u8[:]) -> u8[>..] { return user_dex(Channel.OpenOrders, user, dex); }

fn spot_state(user: u8[:], margin: Flag) -> u8[>..] {
    var o: u8[>..] = [];
    o.push('{');
    json::format_key(o, "method");
    json::format_string(o, "subscribe");
    o.push(',');
    json::format_key(o, "subscription");
    o.push('{');
    json::format_key(o, "type");
    json::format_string(o, channel_text(Channel.SpotState));
    o.push(',');
    json::format_key(o, "user");
    json::format_string(o, user);
    if flag_set(margin) {
        o.push(',');
        json::format_key(o, "isPortfolioMargin");
        json::format_bool(o, margin == Flag.Yes);
    }
    o.push('}');
    o.push('}');
    return o;
}

fn twap_states(user: u8[:], dex: u8[:]) -> u8[>..] { return user_dex(Channel.TwapStates, user, dex); }

fn user_fundings(user: u8[:]) -> u8[>..] {
    var o: u8[>..] = [];
    sub(o, Channel.UserFundings, "", "user", user);
    return o;
}

fn user_ledger(user: u8[:]) -> u8[>..] {
    var o: u8[>..] = [];
    sub(o, Channel.UserNonFundingLedgerUpdates, "", "user", user);
    return o;
}

fn all_dexs_asset_ctxs() -> u8[>..] {
    var o: u8[>..] = [];
    sub(o, Channel.AllDexsAssetCtxs, "", "", "");
    return o;
}

fn outcome_meta_updates() -> u8[>..] {
    var o: u8[>..] = [];
    sub(o, Channel.OutcomeMetaUpdates, "", "", "");
    return o;
}

fn all_mids_kind(kind: Channel, dex: u8[:]) -> u8[>..] {
    var o: u8[>..] = [];
    if dex.len == 0 {
        sub(o, kind, "", "", "");
        return o;
    }
    o.push('{');
    json::format_key(o, "method");
    json::format_string(o, "subscribe");
    o.push(',');
    json::format_key(o, "subscription");
    o.push('{');
    json::format_key(o, "type");
    json::format_string(o, channel_text(kind));
    o.push(',');
    json::format_key(o, "dex");
    json::format_string(o, dex);
    o.push('}');
    o.push('}');
    return o;
}

fn user_dex(kind: Channel, user: u8[:], dex: u8[:]) -> u8[>..] {
    var o: u8[>..] = [];
    o.push('{');
    json::format_key(o, "method");
    json::format_string(o, "subscribe");
    o.push(',');
    json::format_key(o, "subscription");
    o.push('{');
    json::format_key(o, "type");
    json::format_string(o, channel_text(kind));
    o.push(',');
    json::format_key(o, "user");
    json::format_string(o, user);
    if dex.len != 0 {
        o.push(',');
        json::format_key(o, "dex");
        json::format_string(o, dex);
    }
    o.push('}');
    o.push('}');
    return o;
}

fn l2_book_opts(coin: u8[:], figs: Stamp, mantissa: Stamp, fast: bool) -> u8[>..] {
    var o: u8[>..] = [];
    o.push('{');
    json::format_key(o, "method");
    json::format_string(o, "subscribe");
    o.push(',');
    json::format_key(o, "subscription");
    o.push('{');
    json::format_key(o, "type");
    json::format_string(o, channel_text(Channel.L2Book));
    o.push(',');
    json::format_key(o, "coin");
    json::format_string(o, coin);
    if stamp_set(figs) {
        o.push(',');
        json::format_key(o, "nSigFigs");
        json::format_int(o, stamp_n(figs));
    }
    if stamp_set(mantissa) {
        o.push(',');
        json::format_key(o, "mantissa");
        json::format_int(o, stamp_n(mantissa));
    }
    if fast {
        o.push(',');
        json::format_key(o, "fast");
        json::format_bool(o, true);
    }
    o.push('}');
    o.push('}');
    return o;
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

fn connect(session: http::Session&, url: u8[:]) -> http::WsClient, http::Error {
    return http::ws_client_connect(session, url);
}

fn send(conn: http::WsClient&, text: u8[:]) -> http::Error {
    return http::ws_client_text(conn, text);
}

fn read(conn: http::WsClient&) -> http::WsMessage, http::Error {
    return http::ws_client_recv(conn);
}

fn close(conn: http::WsClient&) -> http::Error {
    return http::ws_client_close(conn);
}

// Connects to the chain's wss URL, sends text, and returns the next message.
// The caller closes conn. Set session.deadline before this call.
fn subscribe(session: http::Session&, chain: hyperliquid::Chain, text: u8[:]) -> http::WsClient, http::WsMessage, http::Error {
    var conn, err = connect(session, hyperliquid::ws_url(chain));
    guard err.code == 0 else { return conn, http::WsMessage { .. }, err; }
    let sent = send(conn, text);
    guard sent.code == 0 else { return conn, http::WsMessage { .. }, sent; }
    let msg, rerr = read(conn);
    return conn, msg, rerr;
}
