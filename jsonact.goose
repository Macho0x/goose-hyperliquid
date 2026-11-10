// The JSON object an L1 action posts. The MessagePack map is the action.
// This walk copies that tree, so a null stays null and an omitted key stays
// omitted. Key order is the order the builder wrote.

import json;
import msgpack from "../msgpack";
import msgpack.value;

namespace jsonact;

fn write_u64(out: u8[>..]&, v: u64) {
    if v <= 9223372036854775807 { json::format_int(out, v as! i64); return; }
    var digs: u8[20] = [0; 20];
    var n = v;
    var nd: i64 = 0;
    while n > 0 {
        let d = (n % 10) as! u8;
        digs[nd] = '0' + d;
        nd += 1;
        n = n / 10;
    }
    for i in 0..nd { out.push(digs[nd - 1 - i]); }
}

recursive fn write_node(n: value::Node&, out: u8[>..]&) -> bool {
    match n.val {
        Nil => { out.append("null"); },
        Bool b => { json::format_bool(out, b.v); },
        Int x => { json::format_int(out, x.n); },
        Uint x => { write_u64(out, x.n); },
        Str &s => { json::format_string(out, s.s); },
        Arr &a => {
            out.push('[');
            var c = a.first;
            for i in a.count {
                if !c { return false; }
                if i > 0 { out.push(','); }
                if !write_node(c, out) { return false; }
                c .= c.next;
            }
            out.push(']');
        },
        Map &m => {
            out.push('{');
            var c = m.first;
            for i in m.count {
                if !c { return false; }
                if i > 0 { out.push(','); }
                match c.val {
                    Str &s => { json::format_key(out, s.s); },
                    _ => { return false; },
                }
                let v = c.next;
                if !v { return false; }
                if !write_node(v, out) { return false; }
                c .= v.next;
            }
            out.push('}');
        },
        _ => { return false; },
    }
    return true;
}

fn of(src: u8[:]) -> u8[>..], bool {
    var pool: value::Node[>..] = [];
    if !value::decode(src, pool) { return [], false; }
    let r = value::root(pool);
    if !r { return [], false; }
    var out: u8[>..] = [];
    if !write_node(r, out) { return [], false; }
    return out, true;
}
