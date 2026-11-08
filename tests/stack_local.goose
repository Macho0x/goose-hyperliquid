// Local socket ceiling. Clang. No exchange.
//   goose build -o /tmp/stack-local tests/stack_local.goose --cc clang
//   /tmp/stack-local
// ws: the peer pushes book frames as fast as the socket takes them.
// wss: the client sends the same book and reads the echo, through TLS.
// http: one plain session posts a fat body; the first call is apart from
// the median of the rest. A peer that writes one byte then waits must
// come back ETIMEDOUT.

import std;
import os;
import http from "github.com/kaitk/goose-http@main";
import tls from "github.com/kaitk/goose-tls@v0.0.6";
import hash from "github.com/kaitk/goose-hash@v0.0.4";
import http.client;
import http.wsclient;
import http.websocket;
import http.tls;
import decimal from "../../decimal";
import .book;

let WS_N: i64 = 2000;
let WSS_N: i64 = 200;
let HTTP_N: i64 = 20;

fn fail(why: u8[:]) {
    write_stdout(why);
    write_stdout("\n");
    exit(1);
}

fn listen() -> i32, i32 {
    let a, ok = http::address("127.0.0.1");
    if !ok { fail("address"); }
    let fd = http::net_listen(a.ip, 0, 16, 0);
    if fd < 0 { fail("listen"); }
    return fd, http::net_port(fd);
}

fn send_fd(fd: i32, bytes: u8[:]) {
    var at: i64 = 0;
    while at < bytes.len {
        let n = http::net_send(fd, bytes[at..]);
        if n <= 0 { return; }
        at += n;
    }
}

fn read_headers(fd: i32, out: u8[>..]&) -> bool {
    var buf: u8[1024] = [0; 1024];
    while find(out, "\r\n\r\n") < 0 {
        let n = http::net_recv(fd, buf);
        if n <= 0 { return false; }
        out.append(buf[..n]);
        if out.len > 8192 { return false; }
    }
    return true;
}

fn key_of(req: u8[:]) -> u8[>..] {
    let at = find(req, "Sec-WebSocket-Key: ");
    var key: u8[>..] = [];
    if at >= 0 && at + 19 + 24 <= req.len { key.append(req[at + 19..at + 19 + 24]); }
    return key;
}

fn accept_ws(lfd: i32) -> i32, bool {
    let fd = http::net_accept(lfd, 0);
    if fd < 0 { return fd, false; }
    var req: u8[>..] = [];
    if !read_headers(fd, req) { return fd, false; }
    var answer: u8[>..] = [];
    answer.append("HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Accept: ");
    answer.append(http::ws_accept(key_of(req)));
    answer.append("\r\n\r\n");
    send_fd(fd, answer);
    return fd, true;
}

fn text_frame(payload: u8[:]) -> u8[>..] {
    var out: u8[>..] = [];
    out.push(0x81);
    let n = payload.len;
    if n < 126 {
        out.push(n as! u8);
    } else {
        out.push(126);
        out.push((n >> 8) as! u8);
        out.push(n as! u8);
    }
    out.append(payload);
    return out;
}

thread_fn push(lfd: i32, count: i64) {
    let fd, ok = accept_ws(lfd);
    if ok {
        let frame = text_frame(stack::book(5));
        for i in count { send_fd(fd, frame); }
        var sink: u8[64] = [0; 64];
        while http::net_recv(fd, sink) > 0 {}
    }
    http::net_close(fd);
    http::net_close(lfd);
}

fn per_s(n: i64, span_ns: i64) -> i64 {
    if span_ns <= 0 { return 0; }
    return n * 1000000000 / span_ns;
}

fn ws_flood() {
    let lfd, port = listen();
    let t = thread_spawn(push, lfd, WS_N);
    var url: u8[>..] = [];
    format(url, "ws://127.0.0.1:", port, "/ws");
    var session = http::session();
    session.deadline = http::deadline(10000);
    var conn, err = http::ws_client_connect(session, url);
    if err.code != 0 { fail(err.call); }
    var parses: i64[>..] = [];
    var bytes: i64 = 0;
    let t0 = clock_ns();
    for i in WS_N {
        let msg, e = http::ws_client_recv(conn);
        let got = clock_ns();
        if e.code != 0 { fail(e.call); }
        let bid, ask, bn, an, ok = stack::sum(msg.data);
        let done = clock_ns();
        if !ok || bn != 5 || an != 5 { fail("ws book"); }
        bytes += msg.data.len;
        parses.push(done - got);
        let sink = bid.w[0] + ask.w[0];
        if sink == 0 && bid.w[0] != 0 { fail("sink"); }
    }
    let span = clock_ns() - t0;
    http::ws_client_close(conn);
    http::free(session);
    thread_wait(t);
    print("ws_frames ", WS_N, " bytes ", bytes, " per_s ", per_s(WS_N, span), " parse_p99_ns ", stack::percentile(parses, 99));
}

fn header_len(head: u8[:]) -> i64 {
    let at = find(head, "Content-Length:");
    if at < 0 { return 0; }
    var i = at + 15;
    while i < head.len && (head[i] == ' ' || head[i] == '\t') { i += 1; }
    var n: i64 = 0;
    while i < head.len && head[i] >= '0' && head[i] <= '9' {
        n = n * 10 + (head[i] - '0');
        i += 1;
    }
    return n;
}

fn read_exchange(fd: i32) -> bool {
    var raw: u8[>..] = [];
    var tmp: u8[4096] = [0; 4096];
    var end = -1;
    while end < 0 {
        let n = http::net_recv(fd, tmp);
        if n <= 0 { return false; }
        raw.append(tmp[..n]);
        end = find(raw, "\r\n\r\n");
        if raw.len > 2000000 { return false; }
    }
    let need = header_len(raw[..end]);
    var have = raw.len - (end + 4);
    while have < need {
        let n = http::net_recv(fd, tmp);
        if n <= 0 { return false; }
        have += n;
    }
    return true;
}

fn reply(fd: i32) {
    var body: u8[>..] = [];
    body.append("{\"status\":\"ok\"}");
    var head: u8[>..] = [];
    head.append("HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nConnection: keep-alive\r\nContent-Length: ");
    format(head, body.len);
    head.append("\r\n\r\n");
    send_fd(fd, head);
    send_fd(fd, body);
}

thread_fn http_serve(lfd: i32, n: i64) {
    let fd = http::net_accept(lfd, 0);
    if fd >= 0 {
        for i in n {
            if !read_exchange(fd) { break; }
            reply(fd);
        }
        http::net_close(fd);
    }
    http::net_close(lfd);
}

fn fat() -> u8[>..] {
    var o: u8[>..] = [];
    o.append("{\"type\":\"meta\",\"pad\":\"");
    for i in 32768 { o.push('a'); }
    o.append("\"}");
    return o;
}

fn http_posts() {
    let lfd, port = listen();
    let t = thread_spawn(http_serve, lfd, HTTP_N);
    var url: u8[>..] = [];
    format(url, "http://127.0.0.1:", port, "/info");
    let payload = fat();
    var session = http::session();
    session.deadline = http::deadline(5000);
    var times: i64[20] = [0; 20];
    var status: i64 = 0;
    for i in HTTP_N {
        let t0 = clock_ns();
        let res, err = http::post(session, url) { req =>
            http::body(req, "application/json", payload);
        };
        times[i] = clock_ns() - t0;
        if err.code != 0 { fail(err.call); }
        status = res.status;
    }
    http::free(session);
    thread_wait(t);
    var rest: i64[>..] = [];
    for i in 1..HTTP_N { rest.push(times[i]); }
    stack::sort(rest);
    print("http_first_ns ", times[0], " http_median_ns ", rest[rest.len / 2], " status ", status);
}

thread_fn stall(lfd: i32) {
    let fd = http::net_accept(lfd, 0);
    if fd >= 0 {
        var b: u8[1] = ['H'];
        http::net_send(fd, b);
        sleep_ms(400);
        http::net_close(fd);
    }
    http::net_close(lfd);
}

fn dribble() {
    let lfd, port = listen();
    let t = thread_spawn(stall, lfd);
    var url: u8[>..] = [];
    format(url, "http://127.0.0.1:", port, "/");
    var session = http::session();
    session.deadline = http::deadline(200);
    let res, err = http::get(session, url);
    let call = err.call;
    let code = err.code;
    http::free(session);
    thread_wait(t);
    if code != http::ETIMEDOUT { fail(call); }
    print("dribble ", call, " ", code, " status ", res.status);
}

struct Echo { ws: http::WebSocket = http::WebSocket { .. } }

fn echo(ev: http::Event, st: Echo&, out: http::Reply) {
    if ev.kind == http::REQUEST {
        http::ws_upgrade(ev.req, st.ws, out);
    } else {
        http::ws_read(ev, st.ws, out) { op, data, o => http::ws_send(o, op, data); };
    }
}

thread_fn tls_worker(cfg: http::Config, ctx: tls::Context) {
    var server = http::tls_server(ctx);
    let e = http::serve_epoll(cfg, Echo { .. }, server) { ev, st, out => echo(ev, st, out); };
    http::release(server);
    if e.code != 0 { http::report(e); }
}

fn unix_address(name: u8[:]) -> u8[>..] {
    var dir: u8[>..] = [];
    var a: u8[>..] = [];
    if env("TMPDIR", dir) && dir.len > 0 { format(a, "unix:", dir, "/", name); }
    else { format(a, "unix:", name); }
    return a;
}

fn listening(address: u8[:]) -> bool {
    for i in 500 {
        var s, e = http::connect(address, 0, 200);
        if e.code == 0 {
            http::hangup(s);
            return true;
        }
        sleep_ms(10);
    }
    return false;
}

fn wss_echo() {
    var chain: u8[>..] = [];
    var key: u8[>..] = [];
    let failed = tls::run() {
        let k = tls::key_generate(tls::P256);
        chain = tls::self_signed(k, ["localhost"], 1);
        key = tls::key_pem(k);
        tls::free(k);
    };
    if failed.len != 0 { fail("tls"); }
    let ctx, ok = tls::server(chain, key, ["http/1.1"]);
    if !ok { fail("cert"); }
    let address = unix_address("stack-wss.sock");
    let w = thread_spawn(tls_worker, http::Config { address: address, workers: 1, tls: true, .. }, ctx);
    if !listening(address) { fail("wss listen"); }
    var session, trusted = http::session_trusting(chain, 5000);
    if !trusted { fail("trust"); }
    session.via.append(address);
    var conn, err = http::ws_client_connect(session, "wss://localhost/ws");
    if err.code != 0 { fail(err.call); }
    let payload = stack::book(5);
    var parses: i64[>..] = [];
    let t0 = clock_ns();
    for i in WSS_N {
        let sent = http::ws_client_text(conn, payload);
        if sent.code != 0 { fail(sent.call); }
        let msg, e = http::ws_client_recv(conn);
        let got = clock_ns();
        if e.code != 0 { fail(e.call); }
        let bid, ask, bn, an, book_ok = stack::sum(msg.data);
        let done = clock_ns();
        if !book_ok || bn != 5 || an != 5 { fail("wss book"); }
        parses.push(done - got);
        let sink = bid.w[0] + ask.w[0];
        if sink == 0 && bid.w[0] != 0 { fail("sink"); }
    }
    let span = clock_ns() - t0;
    http::ws_client_close(conn);
    http::free(session);
    http::stop();
    thread_wait(w);
    tls::free(ctx);
    print("wss_trips ", WSS_N, " per_s ", per_s(WSS_N, span), " parse_p99_ns ", stack::percentile(parses, 99));
}

fn ::main() {
    ws_flood();
    http_posts();
    dribble();
    wss_echo();
    print("local ok");
}
