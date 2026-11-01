// L1 order actions. The exchange hashes a named MessagePack map, not EIP-712
// fields. A zero cloid is left out. Prices are already normalized strings.

import msgpack from "../msgpack";
import msgpack.encode;
import sign;
import wire;

namespace order;

fn limit(out: u8[>..]&, tif: u8[:]) {
    encode::map(out, 1);
    encode::str(out, "limit");
    encode::map(out, 1);
    encode::str(out, "tif");
    encode::str(out, tif);
}

fn order_wire(out: u8[>..]&, asset: u64, buy: bool, price: u8[:], size: u8[:], reduce_only: bool, tif: u8[:]) {
    encode::map(out, 6);
    encode::str(out, "a");
    encode::uint(out, asset);
    encode::str(out, "b");
    encode::boolean(out, buy);
    encode::str(out, "p");
    encode::str(out, price);
    encode::str(out, "s");
    encode::str(out, size);
    encode::str(out, "r");
    encode::boolean(out, reduce_only);
    encode::str(out, "t");
    limit(out, tif);
}

fn batch(price: u8[:], size: u8[:], tif: u8[:], priority: u64, has_priority: bool) -> u8[>..], bool {
    let px, pok = wire::normalize(price);
    let sz, sok = wire::normalize(size);
    if !pok || !sok { return [], false; }
    var out: u8[>..] = [];
    encode::map(out, 3);
    encode::str(out, "type");
    encode::str(out, "order");
    encode::str(out, "orders");
    encode::array(out, 1);
    order_wire(out, 0, true, px, sz, false, tif);
    encode::str(out, "grouping");
    if has_priority {
        encode::map(out, 1);
        encode::str(out, "p");
        encode::uint(out, priority);
    } else {
        encode::str(out, "na");
    }
    return out, true;
}

fn cancel(asset: u64, oid: u64) -> u8[>..] {
    var out: u8[>..] = [];
    encode::map(out, 2);
    encode::str(out, "type");
    encode::str(out, "cancel");
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
    encode::str(out, "modify");
    encode::str(out, "oid");
    encode::uint(out, oid);
    encode::str(out, "order");
    order_wire(out, 0, true, px, sz, false, "Gtc");
    return out, true;
}

fn prehash(body: u8[:], nonce: u64) -> u8[32], bool {
    var none: u8[20] = [0; 20];
    return sign::l1_prehash(body, nonce, false, none, false, 0, true);
}
