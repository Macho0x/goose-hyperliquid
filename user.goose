// User-signed HyperCore actions. Each one is EIP-712, not MessagePack.
// The primary type is prefixed with HyperliquidTransaction:.
// A null agent name is the empty string. Multisig inserts two addresses
// immediately after hyperliquidChain.

import crypto from "../crypto";
import crypto.keccak256;
import signature from "../signature";
import signature.eip712;
import sign;

namespace user;

fn push_str(out: u8[>..]&, s: u8[:]) { out.append(keccak256::hash(s)); }

fn push_u64(out: u8[>..]&, v: u64) { out.append(sign::word_u64(v)); }

fn push_bool(out: u8[>..]&, v: bool) {
    if v { push_u64(out, 1); } else { push_u64(out, 0); }
}

fn hash_of(type_str: u8[:], fields: u8[:], chain_id: u64) -> u8[32], bool {
    return sign::user_prehash(type_str, fields, chain_id);
}

fn usd_send(chain: u8[:], destination: u8[:], amount: u8[:], time: u64, chain_id: u64) -> u8[32], bool {
    var f: u8[>..] = [];
    push_str(f, chain);
    push_str(f, destination);
    push_str(f, amount);
    push_u64(f, time);
    return hash_of("HyperliquidTransaction:UsdSend(string hyperliquidChain,string destination,string amount,uint64 time)", f, chain_id);
}

fn withdraw(chain: u8[:], destination: u8[:], amount: u8[:], time: u64, chain_id: u64) -> u8[32], bool {
    var f: u8[>..] = [];
    push_str(f, chain);
    push_str(f, destination);
    push_str(f, amount);
    push_u64(f, time);
    return hash_of("HyperliquidTransaction:Withdraw(string hyperliquidChain,string destination,string amount,uint64 time)", f, chain_id);
}

fn spot_send(chain: u8[:], destination: u8[:], token: u8[:], amount: u8[:], time: u64, chain_id: u64) -> u8[32], bool {
    var f: u8[>..] = [];
    push_str(f, chain);
    push_str(f, destination);
    push_str(f, token);
    push_str(f, amount);
    push_u64(f, time);
    return hash_of("HyperliquidTransaction:SpotSend(string hyperliquidChain,string destination,string token,string amount,uint64 time)", f, chain_id);
}

fn approve_builder_fee(chain: u8[:], max_fee: u8[:], builder: u8[20], nonce: u64, chain_id: u64) -> u8[32], bool {
    var f: u8[>..] = [];
    push_str(f, chain);
    push_str(f, max_fee);
    let word, ok = word_addr(builder);
    if !ok { return [0; 32], false; }
    f.append(word);
    push_u64(f, nonce);
    return hash_of("HyperliquidTransaction:ApproveBuilderFee(string hyperliquidChain,string maxFeeRate,address builder,uint64 nonce)", f, chain_id);
}

fn usd_class_transfer(chain: u8[:], amount: u8[:], to_perp: bool, nonce: u64, chain_id: u64) -> u8[32], bool {
    var f: u8[>..] = [];
    push_str(f, chain);
    push_str(f, amount);
    push_bool(f, to_perp);
    push_u64(f, nonce);
    return hash_of("HyperliquidTransaction:UsdClassTransfer(string hyperliquidChain,string amount,bool toPerp,uint64 nonce)", f, chain_id);
}

fn send_asset(chain: u8[:], destination: u8[:], source_dex: u8[:], dest_dex: u8[:], token: u8[:], amount: u8[:], from_sub: u8[:], nonce: u64, chain_id: u64) -> u8[32], bool {
    var f: u8[>..] = [];
    push_str(f, chain);
    push_str(f, destination);
    push_str(f, source_dex);
    push_str(f, dest_dex);
    push_str(f, token);
    push_str(f, amount);
    push_str(f, from_sub);
    push_u64(f, nonce);
    return hash_of("HyperliquidTransaction:SendAsset(string hyperliquidChain,string destination,string sourceDex,string destinationDex,string token,string amount,string fromSubAccount,uint64 nonce)", f, chain_id);
}

fn approve_agent(chain: u8[:], agent: u8[20], name: u8[:], nonce: u64, chain_id: u64, multi: bool, payload_user: u8[20], outer: u8[20]) -> u8[32], bool {
    var f: u8[>..] = [];
    push_str(f, chain);
    if multi {
        let u, uok = word_addr(payload_user);
        let o, ook = word_addr(outer);
        if !uok || !ook { return [0; 32], false; }
        f.append(u);
        f.append(o);
    }
    let a, aok = word_addr(agent);
    if !aok { return [0; 32], false; }
    f.append(a);
    push_str(f, name);
    push_u64(f, nonce);
    if multi {
        return hash_of("HyperliquidTransaction:ApproveAgent(string hyperliquidChain,address payloadMultiSigUser,address outerSigner,address agentAddress,string agentName,uint64 nonce)", f, chain_id);
    }
    return hash_of("HyperliquidTransaction:ApproveAgent(string hyperliquidChain,address agentAddress,string agentName,uint64 nonce)", f, chain_id);
}

fn word_addr(a: u8[20]) -> u8[32], bool {
    return eip712::word_address(a);
}

fn has_schema(kind: u8[:]) -> bool {
    if kind == "noop" { return false; }
    if kind == "usdSend" { return true; }
    if kind == "withdraw3" { return true; }
    if kind == "spotSend" { return true; }
    if kind == "approveBuilderFee" { return true; }
    if kind == "usdClassTransfer" { return true; }
    if kind == "sendAsset" { return true; }
    if kind == "approveAgent" { return true; }
    if kind == "tokenDelegate" { return true; }
    return false;
}

fn multisig_first_three() -> bool {
    let a = "hyperliquidChain";
    let b = "payloadMultiSigUser";
    let c = "outerSigner";
    return a == "hyperliquidChain" && b == "payloadMultiSigUser" && c == "outerSigner";
}
