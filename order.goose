// L1 order actions. The exchange hashes a named MessagePack map, not EIP-712
// fields. A zero cloid is left out. Prices are already normalized strings.

import msgpack from "../msgpack";
import msgpack.encode;
import sign;
import wire;

namespace order;

enum Action { Order, Cancel, Modify, CancelByCloid, BatchModify }
enum Side { Buy, Sell }
enum Reduce { ReduceOnly, Open }
enum Priority { Absent, At { n: u64 } }

fn action_text(a: Action) -> u8[:] {
    if a == Action.Order { return "order"; }
    if a == Action.Cancel { return "cancel"; }
    if a == Action.Modify { return "modify"; }
    if a == Action.CancelByCloid { return "cancelByCloid"; }
    return "batchModify";
}

fn put_priority(out: u8[>..]&, p: Priority.Absent) { encode::str(out, "na"); }
fn put_priority(out: u8[>..]&, p: Priority.At) {
    encode::map(out, 1);
    encode::str(out, "p");
    encode::uint(out, p.n);
}

fn limit(out: u8[>..]&, tif: u8[:]) {
    encode::map(out, 1);
    encode::str(out, "limit");
    encode::map(out, 1);
    encode::str(out, "tif");
    encode::str(out, tif);
}

fn order_wire(out: u8[>..]&, asset: u64, side: Side, price: u8[:], size: u8[:], reduce: Reduce, tif: u8[:]) {
    encode::map(out, 6);
    encode::str(out, "a");
    encode::uint(out, asset);
    encode::str(out, "b");
    encode::boolean(out, side == Side.Buy);
    encode::str(out, "p");
    encode::str(out, price);
    encode::str(out, "s");
    encode::str(out, size);
    encode::str(out, "r");
    encode::boolean(out, reduce == Reduce.ReduceOnly);
    encode::str(out, "t");
    limit(out, tif);
}

fn batch(price: u8[:], size: u8[:], tif: u8[:], priority: Priority) -> u8[>..], bool {
    let px, pok = wire::normalize(price);
    let sz, sok = wire::normalize(size);
    if !pok || !sok { return [], false; }
    var out: u8[>..] = [];
    encode::map(out, 3);
    encode::str(out, "type");
    encode::str(out, action_text(Action.Order));
    encode::str(out, "orders");
    encode::array(out, 1);
    order_wire(out, 0, Side.Buy, px, sz, Reduce.Open, tif);
    encode::str(out, "grouping");
    put_priority(out, priority);
    return out, true;
}

fn cancel(asset: u64, oid: u64) -> u8[>..] {
    var out: u8[>..] = [];
    encode::map(out, 2);
    encode::str(out, "type");
    encode::str(out, action_text(Action.Cancel));
    encode::str(out, "cancels");
    encode::array(out, 1);
    encode::map(out, 2);
    encode::str(out, "a");
    encode::uint(out, asset);
    encode::str(out, "o");
    encode::uint(out, oid);
    return out;
}

fn modify(oid: u64, price: u8[:], size: u8[:]) -> u8[>..], bool {
    let px, pok = wire::normalize(price);
    let sz, sok = wire::normalize(size);
    if !pok || !sok { return [], false; }
    var out: u8[>..] = [];
    encode::map(out, 3);
    encode::str(out, "type");
    encode::str(out, action_text(Action.Modify));
    encode::str(out, "oid");
    encode::uint(out, oid);
    encode::str(out, "order");
    order_wire(out, 0, Side.Buy, px, sz, Reduce.Open, "Gtc");
    return out, true;
}

fn cancel_fast(asset: u64, oid: u64) -> u8[>..] {
    var out: u8[>..] = [];
    encode::map(out, 3);
    encode::str(out, "type");
    encode::str(out, action_text(Action.Cancel));
    encode::str(out, "cancels");
    encode::array(out, 1);
    encode::map(out, 2);
    encode::str(out, "a");
    encode::uint(out, asset);
    encode::str(out, "o");
    encode::uint(out, oid);
    encode::str(out, "f");
    encode::boolean(out, true);
    return out;
}

fn cancel_cloid(asset: u64, cloid: u8[:]) -> u8[>..] {
    var out: u8[>..] = [];
    encode::map(out, 2);
    encode::str(out, "type");
    encode::str(out, action_text(Action.CancelByCloid));
    encode::str(out, "cancels");
    encode::array(out, 1);
    encode::map(out, 2);
    encode::str(out, "asset");
    encode::uint(out, asset);
    encode::str(out, "cloid");
    encode::str(out, cloid);
    return out;
}

fn batch_modify(oid: u64, price: u8[:], size: u8[:], always_place: bool) -> u8[>..], bool {
    let px, pok = wire::normalize(price);
    let sz, sok = wire::normalize(size);
    if !pok || !sok { return [], false; }
    var out: u8[>..] = [];
    if always_place { encode::map(out, 3); } else { encode::map(out, 2); }
    encode::str(out, "type");
    encode::str(out, action_text(Action.BatchModify));
    encode::str(out, "modifies");
    encode::array(out, 1);
    encode::map(out, 2);
    encode::str(out, "oid");
    encode::uint(out, oid);
    encode::str(out, "order");
    order_wire(out, 0, Side.Buy, px, sz, Reduce.Open, "Gtc");
    if always_place {
        encode::str(out, "a");
        encode::boolean(out, true);
    }
    return out, true;
}

fn trigger(asset: u64, side: Side, price: u8[:], size: u8[:], reduce: Reduce, is_market: bool, trigger_px: u8[:], tpsl: u8[:]) -> u8[>..], bool {
    let px, pok = wire::normalize(price);
    let sz, sok = wire::normalize(size);
    let trig, tok = wire::normalize(trigger_px);
    if !pok || !sok || !tok { return [], false; }
    var out: u8[>..] = [];
    encode::map(out, 3);
    encode::str(out, "type");
    encode::str(out, action_text(Action.Order));
    encode::str(out, "orders");
    encode::array(out, 1);
    encode::map(out, 6);
    encode::str(out, "a");
    encode::uint(out, asset);
    encode::str(out, "b");
    encode::boolean(out, side == Side.Buy);
    encode::str(out, "p");
    encode::str(out, px);
    encode::str(out, "s");
    encode::str(out, sz);
    encode::str(out, "r");
    encode::boolean(out, reduce == Reduce.ReduceOnly);
    encode::str(out, "t");
    encode::map(out, 1);
    encode::str(out, "trigger");
    encode::map(out, 3);
    encode::str(out, "isMarket");
    encode::boolean(out, is_market);
    encode::str(out, "triggerPx");
    encode::str(out, trig);
    encode::str(out, "tpsl");
    encode::str(out, tpsl);
    encode::str(out, "grouping");
    encode::str(out, "na");
    return out, true;
}

fn with_builder(price: u8[:], size: u8[:], builder: u8[:], fee: u64) -> u8[>..], bool {
    let px, pok = wire::normalize(price);
    let sz, sok = wire::normalize(size);
    if !pok || !sok { return [], false; }
    var out: u8[>..] = [];
    encode::map(out, 4);
    encode::str(out, "type");
    encode::str(out, action_text(Action.Order));
    encode::str(out, "orders");
    encode::array(out, 1);
    order_wire(out, 0, Side.Buy, px, sz, Reduce.Open, "Gtc");
    encode::str(out, "grouping");
    encode::str(out, "na");
    encode::str(out, "builder");
    encode::map(out, 2);
    encode::str(out, "b");
    encode::str(out, builder);
    encode::str(out, "f");
    encode::uint(out, fee);
    return out, true;
}

fn with_cloid(price: u8[:], size: u8[:], cloid: u8[:]) -> u8[>..], bool {
    let px, pok = wire::normalize(price);
    let sz, sok = wire::normalize(size);
    if !pok || !sok { return [], false; }
    var out: u8[>..] = [];
    encode::map(out, 3);
    encode::str(out, "type");
    encode::str(out, action_text(Action.Order));
    encode::str(out, "orders");
    encode::array(out, 1);
    encode::map(out, 7);
    encode::str(out, "a");
    encode::uint(out, 0);
    encode::str(out, "b");
    encode::boolean(out, true);
    encode::str(out, "p");
    encode::str(out, px);
    encode::str(out, "s");
    encode::str(out, sz);
    encode::str(out, "r");
    encode::boolean(out, false);
    encode::str(out, "t");
    limit(out, "Gtc");
    encode::str(out, "c");
    encode::str(out, cloid);
    encode::str(out, "grouping");
    encode::str(out, "na");
    return out, true;
}

fn place(asset: u64, side: Side, price: u8[:], size: u8[:], reduce: Reduce, tif: u8[:], priority: Priority) -> u8[>..], bool {
    let px, pok = wire::normalize(price);
    let sz, sok = wire::normalize(size);
    if !pok || !sok { return [], false; }
    var out: u8[>..] = [];
    encode::map(out, 3);
    encode::str(out, "type");
    encode::str(out, action_text(Action.Order));
    encode::str(out, "orders");
    encode::array(out, 1);
    order_wire(out, asset, side, px, sz, reduce, tif);
    encode::str(out, "grouping");
    put_priority(out, priority);
    return out, true;
}

fn market(asset: u64, side: Side, price: u8[:], size: u8[:]) -> u8[>..], bool {
    return place(asset, side, price, size, Reduce.Open, "FrontendMarket", Priority.Absent);
}

fn prehash(body: u8[:], nonce: u64) -> u8[32], bool {
    return sign::l1_prehash(body, nonce, sign::Vault.Absent, sign::Expiry.Absent, hyperliquid::Chain.Mainnet);
}
