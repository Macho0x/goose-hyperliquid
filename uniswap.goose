// Uniswap V3 and PRJX reads. slot0 and token0 are the pool words.
// A saved log is JSON with an address field.

import crypto from "../crypto";
import crypto.keccak256;
import ethereum from "../ethereum";
import ethereum.abi;
import json;

namespace uniswap;

fn slot0_selector() -> u8[4] { return abi::selector("slot0()"); }

fn token0_selector() -> u8[4] { return abi::selector("token0()"); }

fn pool_address(text: u8[:]) -> u8[>..], bool {
    var doc: json::Node[>..] = [];
    var decoded: u8[>..] = [];
    let root, err = json::parse(text, doc, decoded);
    if root == null { return [], false; }
    let node = json::member(root, "address");
    let s, ok = json::as_string(node);
    if !ok { return [], false; }
    var out: u8[>..] = [];
    out.append(s);
    return out, true;
}

fn prjx_pool(text: u8[:]) -> u8[>..], bool {
    var doc: json::Node[>..] = [];
    var decoded: u8[>..] = [];
    let root, err = json::parse(text, doc, decoded);
    if root == null { return [], false; }
    let node = json::member(root, "pool");
    let s, ok = json::as_string(node);
    if !ok { return [], false; }
    var out: u8[>..] = [];
    out.append(s);
    return out, true;
}
