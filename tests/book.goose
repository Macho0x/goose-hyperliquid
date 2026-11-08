// A book message in the shape the exchange sends, and the top-of-book sum.
import json;
import decimal from "../../decimal";

namespace stack;

fn push_level(out: u8[>..]&, i: i64, first: bool) {
    if !first { out.push(','); }
    out.append("{\"px\":\"");
    format(out, 60000 + i);
    out.append(".5\",\"sz\":\"1.");
    format(out, 100 + i);
    out.append("\",\"n\":1}");
}

fn book(n: i64) -> u8[>..] {
    var o: u8[>..] = [];
    o.append("{\"channel\":\"l2Book\",\"data\":{\"coin\":\"BTC\",\"time\":1,\"levels\":[");
    o.push('[');
    for i in n { push_level(o, i, i == 0); }
    o.append("],[");
    for i in n { push_level(o, 100 + i, i == 0); }
    o.append("]]}}");
    return o;
}

fn add_sz(total: decimal::Dec, level: json::Node?) -> decimal::Dec, bool {
    let sz = json::member(level, "sz");
    let text, ok = json::as_string(sz);
    if !ok { return total, false; }
    let d, dok = decimal::parse(text);
    if !dok { return total, false; }
    return decimal::add(total, d);
}

fn sum_side(side: json::Node?, n: i64) -> decimal::Dec, i64 {
    var total = decimal::zero();
    var got: i64 = 0;
    guard side else { return total, 0; }
    var c = side.first;
    while c && got < n {
        let next, ok = add_sz(total, c);
        if !ok { return total, got; }
        total = next;
        got += 1;
        c .= c.next;
    }
    return total, got;
}

fn sum(text: u8[:]) -> decimal::Dec, decimal::Dec, i64, i64, bool {
    var doc: json::Node[>..] = [];
    var decoded: u8[>..] = [];
    let root, err = json::parse(text, doc, decoded);
    if root == null || err.len != 0 { return decimal::zero(), decimal::zero(), 0, 0, false; }
    let data = json::member(root, "data");
    let levels = json::member(data, "levels");
    guard levels else { return decimal::zero(), decimal::zero(), 0, 0, false; }
    let bids = levels.first;
    let bid, bn = sum_side(bids, 5);
    var ask = decimal::zero();
    var an: i64 = 0;
    if bids {
        let a, n = sum_side(bids.next, 5);
        ask = a;
        an = n;
    }
    return bid, ask, bn, an, true;
}

fn sort(xs: i64[>..]&) {
    for i in 1..xs.len {
        let v = xs[i];
        var j = i;
        while j > 0 && xs[j - 1] > v {
            xs[j] = xs[j - 1];
            j -= 1;
        }
        xs[j] = v;
    }
}

fn percentile(xs: i64[>..]&, p: i64) -> i64 {
    if xs.len == 0 { return 0; }
    sort(xs);
    let at = (xs.len - 1) * p / 100;
    return xs[at];
}
