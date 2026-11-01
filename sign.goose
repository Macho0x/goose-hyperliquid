// The two HyperCore signing hashes.
// An L1 action is named MessagePack, the nonce, a vault flag, and an
// optional expiry. Keccak of that is the Agent connection id.
// A user-signed action is EIP-712 under HyperliquidSignTransaction.
// The domain chain id is 1337 for the Agent and the signature chain for
// a user-signed action. A bad vault length returns false.

import crypto from "../crypto";
import crypto.keccak256;
import signature from "../signature";
import signature.eip712;

namespace sign;

const DOMAIN_TYPE: u8[:] = "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)";
const AGENT_TYPE: u8[:] = "Agent(string source,bytes32 connectionId)";

fn word_u64(v: u64) -> u8[32] {
    var o: u8[32] = [0; 32];
    for i in 0..8 {
        let sh = (7 - i) * 8;
        o[24 + i] = ((v >> sh) & 0xff) as! u8;
    }
    return o;
}

fn put_u64(out: u8[>..]&, v: u64) {
    for i in 0..8 {
        let sh = (7 - i) * 8;
        out.push(((v >> sh) & 0xff) as! u8);
    }
}

fn domain(name: u8[:], version: u8[:], chain_id: u64) -> u8[32] {
    var enc: u8[>..] = [];
    enc.append(keccak256::hash(DOMAIN_TYPE));
    enc.append(keccak256::hash(name));
    enc.append(keccak256::hash(version));
    enc.append(word_u64(chain_id));
    var zero: u8[32] = [0; 32];
    enc.append(zero);
    return keccak256::hash(enc);
}


enum Vault { Absent, Present { addr: const u8[:] } }
enum Expiry { Absent, At { time: u64 } }

fn vault_ok(v: Vault.Absent) -> bool { return true; }
fn vault_ok(v: Vault.Present) -> bool { return v.addr.len == 20; }

fn put_vault(buf: u8[>..]&, v: Vault.Absent) { buf.push(0); }
fn put_vault(buf: u8[>..]&, v: Vault.Present) {
    buf.push(1);
    buf.append(v.addr);
}

fn put_expiry(buf: u8[>..]&, e: Expiry.Absent) { return; }
fn put_expiry(buf: u8[>..]&, e: Expiry.At) {
    buf.push(0);
    put_u64(buf, e.time);
}

fn agent_digest(chain: hyperliquid::Chain, connection: u8[:]) -> u8[32], bool {
    if connection.len != 32 { return [0; 32], false; }
    var source: u8[>..] = [];
    if chain == hyperliquid::Chain.Mainnet { source.push('a'); } else { source.push('b'); }
    var enc: u8[>..] = [];
    enc.append(keccak256::hash(AGENT_TYPE));
    enc.append(keccak256::hash(source));
    enc.append(connection);
    let struct_hash = keccak256::hash(enc);
    let dom = domain("Exchange", "1", 1337);
    return eip712::digest(dom, struct_hash);
}

fn l1_prehash(body: u8[:], nonce: u64, vault: Vault, expiry: Expiry, chain: hyperliquid::Chain) -> u8[32], bool {
    if !vault_ok(vault) { return [0; 32], false; }
    var buf: u8[>..] = [];
    buf.append(body);
    put_u64(buf, nonce);
    put_vault(buf, vault);
    put_expiry(buf, expiry);
    let connection = keccak256::hash(buf);
    return agent_digest(chain, connection);
}

fn user_prehash(type_str: u8[:], fields: u8[:], chain_id: u64) -> u8[32], bool {
    if fields.len % 32 != 0 { return [0; 32], false; }
    var enc: u8[>..] = [];
    enc.append(keccak256::hash(type_str));
    enc.append(fields);
    let struct_hash = keccak256::hash(enc);
    let dom = domain("HyperliquidSignTransaction", "1", chain_id);
    return eip712::digest(dom, struct_hash);
}

fn sign_user(secret: u8[:], type_str: u8[:], fields: u8[:], chain_id: u64) -> u8[65], bool {
    if fields.len % 32 != 0 { return [0; 65], false; }
    var enc: u8[>..] = [];
    enc.append(keccak256::hash(type_str));
    enc.append(fields);
    let struct_hash = keccak256::hash(enc);
    let dom = domain("HyperliquidSignTransaction", "1", chain_id);
    return eip712::sign(secret, dom, struct_hash);
}
