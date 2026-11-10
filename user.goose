// User-signed HyperCore actions. Each one is EIP-712, not MessagePack.
// The primary type is prefixed with HyperliquidTransaction:.
// A null agent name is the empty string. Multisig inserts two addresses
// immediately after hyperliquidChain.

import json;
import crypto from "../crypto";
import crypto.keccak256;
import signature from "../signature";
import signature.eip712;
import sign;
import wire;

namespace user;

fn push_str(out: u8[>..]&, s: u8[:]) { out.append(keccak256::hash(s)); }

fn push_u64(out: u8[>..]&, v: u64) { out.append(sign::word_u64(v)); }

fn push_bool(out: u8[>..]&, v: bool) {
    if v { push_u64(out, 1); } else { push_u64(out, 0); }
}

fn hash_of(type_str: u8[:], fields: u8[:], chain_id: u64) -> u8[32], bool {
    return sign::user_prehash(type_str, fields, chain_id);
}

fn usd_send(chain: hyperliquid::Chain, destination: u8[:], amount: u8[:], time: u64, chain_id: u64) -> u8[32], bool {
    var f: u8[>..] = [];
    push_str(f, hyperliquid::chain_name(chain));
    push_str(f, destination);
    push_str(f, amount);
    push_u64(f, time);
    return hash_of("HyperliquidTransaction:UsdSend(string hyperliquidChain,string destination,string amount,uint64 time)", f, chain_id);
}

fn withdraw(chain: hyperliquid::Chain, destination: u8[:], amount: u8[:], time: u64, chain_id: u64) -> u8[32], bool {
    var f: u8[>..] = [];
    push_str(f, hyperliquid::chain_name(chain));
    push_str(f, destination);
    push_str(f, amount);
    push_u64(f, time);
    return hash_of("HyperliquidTransaction:Withdraw(string hyperliquidChain,string destination,string amount,uint64 time)", f, chain_id);
}

fn spot_send(chain: hyperliquid::Chain, destination: u8[:], token: u8[:], amount: u8[:], time: u64, chain_id: u64) -> u8[32], bool {
    var f: u8[>..] = [];
    push_str(f, hyperliquid::chain_name(chain));
    push_str(f, destination);
    push_str(f, token);
    push_str(f, amount);
    push_u64(f, time);
    return hash_of("HyperliquidTransaction:SpotSend(string hyperliquidChain,string destination,string token,string amount,uint64 time)", f, chain_id);
}

fn approve_builder_fee(chain: hyperliquid::Chain, max_fee: u8[:], builder: u8[20], nonce: u64, chain_id: u64) -> u8[32], bool {
    var f: u8[>..] = [];
    push_str(f, hyperliquid::chain_name(chain));
    push_str(f, max_fee);
    let word, ok = word_addr(builder);
    if !ok { return [0; 32], false; }
    f.append(word);
    push_u64(f, nonce);
    return hash_of("HyperliquidTransaction:ApproveBuilderFee(string hyperliquidChain,string maxFeeRate,address builder,uint64 nonce)", f, chain_id);
}

fn usd_class_transfer(chain: hyperliquid::Chain, amount: u8[:], to_perp: bool, nonce: u64, chain_id: u64) -> u8[32], bool {
    var f: u8[>..] = [];
    push_str(f, hyperliquid::chain_name(chain));
    push_str(f, amount);
    push_bool(f, to_perp);
    push_u64(f, nonce);
    return hash_of("HyperliquidTransaction:UsdClassTransfer(string hyperliquidChain,string amount,bool toPerp,uint64 nonce)", f, chain_id);
}

fn send_asset(chain: hyperliquid::Chain, destination: u8[:], source_dex: u8[:], dest_dex: u8[:], token: u8[:], amount: u8[:], from_sub: u8[:], nonce: u64, chain_id: u64) -> u8[32], bool {
    var f: u8[>..] = [];
    push_str(f, hyperliquid::chain_name(chain));
    push_str(f, destination);
    push_str(f, source_dex);
    push_str(f, dest_dex);
    push_str(f, token);
    push_str(f, amount);
    push_str(f, from_sub);
    push_u64(f, nonce);
    return hash_of("HyperliquidTransaction:SendAsset(string hyperliquidChain,string destination,string sourceDex,string destinationDex,string token,string amount,string fromSubAccount,uint64 nonce)", f, chain_id);
}

fn approve_agent(chain: hyperliquid::Chain, agent: u8[20], name: u8[:], nonce: u64, chain_id: u64, multi: bool, payload_user: u8[20], outer: u8[20]) -> u8[32], bool {
    var f: u8[>..] = [];
    push_str(f, hyperliquid::chain_name(chain));
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

fn token_delegate(chain: hyperliquid::Chain, validator: u8[20], wei: u64, undelegate: bool, nonce: u64, chain_id: u64) -> u8[32], bool {
    var f: u8[>..] = [];
    push_str(f, hyperliquid::chain_name(chain));
    let v, vok = word_addr(validator);
    if !vok { return [0; 32], false; }
    f.append(v);
    push_u64(f, wei);
    push_bool(f, undelegate);
    push_u64(f, nonce);
    return hash_of("HyperliquidTransaction:TokenDelegate(string hyperliquidChain,address validator,uint64 wei,bool isUndelegate,uint64 nonce)", f, chain_id);
}

fn user_dex_abstraction(chain: hyperliquid::Chain, user_addr: u8[20], enabled: bool, nonce: u64, chain_id: u64) -> u8[32], bool {
    var f: u8[>..] = [];
    push_str(f, hyperliquid::chain_name(chain));
    let u, uok = word_addr(user_addr);
    if !uok { return [0; 32], false; }
    f.append(u);
    push_bool(f, enabled);
    push_u64(f, nonce);
    return hash_of("HyperliquidTransaction:UserDexAbstraction(string hyperliquidChain,address user,bool enabled,uint64 nonce)", f, chain_id);
}

fn user_set_abstraction(chain: hyperliquid::Chain, user_addr: u8[20], abstraction: u8[:], nonce: u64, chain_id: u64) -> u8[32], bool {
    let mode, mok = wire::api_mode(abstraction);
    if !mok { return [0; 32], false; }
    var f: u8[>..] = [];
    push_str(f, hyperliquid::chain_name(chain));
    let u, uok = word_addr(user_addr);
    if !uok { return [0; 32], false; }
    f.append(u);
    push_str(f, mode);
    push_u64(f, nonce);
    return hash_of("HyperliquidTransaction:UserSetAbstraction(string hyperliquidChain,address user,string abstraction,uint64 nonce)", f, chain_id);
}

fn user_portfolio_margin(chain: hyperliquid::Chain, user_addr: u8[20], enabled: bool, nonce: u64, chain_id: u64) -> u8[32], bool {
    var f: u8[>..] = [];
    push_str(f, hyperliquid::chain_name(chain));
    let u, uok = word_addr(user_addr);
    if !uok { return [0; 32], false; }
    f.append(u);
    push_bool(f, enabled);
    push_u64(f, nonce);
    return hash_of("HyperliquidTransaction:UserPortfolioMargin(string hyperliquidChain,address user,bool enabled,uint64 nonce)", f, chain_id);
}

fn link_staking_user(chain: hyperliquid::Chain, user_addr: u8[20], is_finalize: bool, nonce: u64, chain_id: u64) -> u8[32], bool {
    var f: u8[>..] = [];
    push_str(f, hyperliquid::chain_name(chain));
    let u, uok = word_addr(user_addr);
    if !uok { return [0; 32], false; }
    f.append(u);
    push_bool(f, is_finalize);
    push_u64(f, nonce);
    return hash_of("HyperliquidTransaction:LinkStakingUser(string hyperliquidChain,address user,bool isFinalize,uint64 nonce)", f, chain_id);
}

fn disable_staking_link(chain: hyperliquid::Chain, trading_user: u8[20], nonce: u64, chain_id: u64) -> u8[32], bool {
    var f: u8[>..] = [];
    push_str(f, hyperliquid::chain_name(chain));
    let u, uok = word_addr(trading_user);
    if !uok { return [0; 32], false; }
    f.append(u);
    push_u64(f, nonce);
    return hash_of("HyperliquidTransaction:StakingLinkDisableTradingUser(string hyperliquidChain,address tradingUser,uint64 nonce)", f, chain_id);
}

fn convert_to_multisig(chain: hyperliquid::Chain, signers: u8[:], nonce: u64, chain_id: u64) -> u8[32], bool {
    var f: u8[>..] = [];
    push_str(f, hyperliquid::chain_name(chain));
    push_str(f, signers);
    push_u64(f, nonce);
    return hash_of("HyperliquidTransaction:ConvertToMultiSigUser(string hyperliquidChain,string signers,uint64 nonce)", f, chain_id);
}

fn send_to_evm(chain: hyperliquid::Chain, token: u8[:], amount: u8[:], source_dex: u8[:], recipient: u8[:], encoding: u8[:], dest_chain: u64, gas_limit: u64, data: u8[:], nonce: u64, chain_id: u64) -> u8[32], bool {
    var f: u8[>..] = [];
    push_str(f, hyperliquid::chain_name(chain));
    push_str(f, token);
    push_str(f, amount);
    push_str(f, source_dex);
    push_str(f, recipient);
    push_str(f, encoding);
    push_u64(f, dest_chain);
    push_u64(f, gas_limit);
    f.append(keccak256::hash(data));
    push_u64(f, nonce);
    return hash_of("HyperliquidTransaction:SendToEvmWithData(string hyperliquidChain,string token,string amount,string sourceDex,string destinationRecipient,string addressEncoding,uint32 destinationChainId,uint64 gasLimit,bytes data,uint64 nonce)", f, chain_id);
}

fn open_user(out: u8[>..]&, typ: u8[:], chain: hyperliquid::Chain, chain_id: u64) {
    out.push('{');
    json::format_key(out, "type");
    json::format_string(out, typ);
    out.push(',');
    json::format_key(out, "signatureChainId");
    json::format_string(out, hyperliquid::chain_hex(chain_id));
    out.push(',');
    json::format_key(out, "hyperliquidChain");
    json::format_string(out, hyperliquid::chain_name(chain));
}

fn str_field(out: u8[>..]&, key: u8[:], value: u8[:]) {
    out.push(',');
    json::format_key(out, key);
    json::format_string(out, value);
}

fn num_field(out: u8[>..]&, key: u8[:], value: u64) {
    out.push(',');
    json::format_key(out, key);
    json::format_int(out, value as! i64);
}

fn bool_field(out: u8[>..]&, key: u8[:], value: bool) {
    out.push(',');
    json::format_key(out, key);
    json::format_bool(out, value);
}

fn addr_field(out: u8[>..]&, key: u8[:], a: u8[20]) -> bool {
    let text, ok = wire::address_hex(a);
    if !ok { return false; }
    str_field(out, key, text);
    return true;
}

fn usd_body(chain: hyperliquid::Chain, destination: u8[:], amount: u8[:], time: u64, chain_id: u64) -> u8[>..] {
    var o: u8[>..] = [];
    open_user(o, "usdSend", chain, chain_id);
    str_field(o, "destination", destination);
    str_field(o, "amount", amount);
    num_field(o, "time", time);
    o.push('}');
    return o;
}

fn withdraw_body(chain: hyperliquid::Chain, destination: u8[:], amount: u8[:], time: u64, chain_id: u64) -> u8[>..] {
    var o: u8[>..] = [];
    open_user(o, "withdraw3", chain, chain_id);
    str_field(o, "destination", destination);
    str_field(o, "amount", amount);
    num_field(o, "time", time);
    o.push('}');
    return o;
}

fn spot_body(chain: hyperliquid::Chain, destination: u8[:], token: u8[:], amount: u8[:], time: u64, chain_id: u64) -> u8[>..] {
    var o: u8[>..] = [];
    open_user(o, "spotSend", chain, chain_id);
    str_field(o, "destination", destination);
    str_field(o, "token", token);
    str_field(o, "amount", amount);
    num_field(o, "time", time);
    o.push('}');
    return o;
}

fn send_asset_body(chain: hyperliquid::Chain, destination: u8[:], source_dex: u8[:], dest_dex: u8[:], token: u8[:], amount: u8[:], from_sub: u8[:], nonce: u64, chain_id: u64) -> u8[>..] {
    var o: u8[>..] = [];
    open_user(o, "sendAsset", chain, chain_id);
    str_field(o, "destination", destination);
    str_field(o, "sourceDex", source_dex);
    str_field(o, "destinationDex", dest_dex);
    str_field(o, "token", token);
    str_field(o, "amount", amount);
    str_field(o, "fromSubAccount", from_sub);
    num_field(o, "nonce", nonce);
    o.push('}');
    return o;
}

fn approve_agent_body(chain: hyperliquid::Chain, agent: u8[20], name: u8[:], nonce: u64, chain_id: u64) -> u8[>..], bool {
    var o: u8[>..] = [];
    open_user(o, "approveAgent", chain, chain_id);
    if !addr_field(o, "agentAddress", agent) { return [], false; }
    str_field(o, "agentName", name);
    num_field(o, "nonce", nonce);
    o.push('}');
    return o, true;
}

fn approve_builder_body(chain: hyperliquid::Chain, max_fee: u8[:], builder: u8[20], nonce: u64, chain_id: u64) -> u8[>..], bool {
    var o: u8[>..] = [];
    open_user(o, "approveBuilderFee", chain, chain_id);
    str_field(o, "maxFeeRate", max_fee);
    if !addr_field(o, "builder", builder) { return [], false; }
    num_field(o, "nonce", nonce);
    o.push('}');
    return o, true;
}

fn class_body(chain: hyperliquid::Chain, amount: u8[:], to_perp: bool, nonce: u64, chain_id: u64) -> u8[>..] {
    var o: u8[>..] = [];
    open_user(o, "usdClassTransfer", chain, chain_id);
    str_field(o, "amount", amount);
    bool_field(o, "toPerp", to_perp);
    num_field(o, "nonce", nonce);
    o.push('}');
    return o;
}

fn set_abstraction_body(chain: hyperliquid::Chain, user_addr: u8[20], abstraction: u8[:], nonce: u64, chain_id: u64) -> u8[>..], bool {
    let mode, mok = wire::api_mode(abstraction);
    if !mok { return [], false; }
    var o: u8[>..] = [];
    open_user(o, "userSetAbstraction", chain, chain_id);
    if !addr_field(o, "user", user_addr) { return [], false; }
    str_field(o, "abstraction", mode);
    num_field(o, "nonce", nonce);
    o.push('}');
    return o, true;
}

fn hex_data(data: u8[:]) -> u8[>..] {
    var o: u8[>..] = [];
    o.push('0');
    o.push('x');
    for i in 0..data.len {
        let v = data[i];
        let hi = v >> 4;
        let lo = v & 0x0f;
        if hi < 10 { o.push('0' + hi); } else { o.push('a' + (hi - 10)); }
        if lo < 10 { o.push('0' + lo); } else { o.push('a' + (lo - 10)); }
    }
    return o;
}

fn send_evm_body(chain: hyperliquid::Chain, token: u8[:], amount: u8[:], source_dex: u8[:], recipient: u8[:], encoding: u8[:], dest_chain: u64, gas_limit: u64, data: u8[:], nonce: u64, chain_id: u64) -> u8[>..] {
    var o: u8[>..] = [];
    open_user(o, "sendToEvmWithData", chain, chain_id);
    str_field(o, "token", token);
    str_field(o, "amount", amount);
    str_field(o, "sourceDex", source_dex);
    str_field(o, "destinationRecipient", recipient);
    str_field(o, "addressEncoding", encoding);
    num_field(o, "destinationChainId", dest_chain);
    num_field(o, "gasLimit", gas_limit);
    str_field(o, "data", hex_data(data));
    num_field(o, "nonce", nonce);
    o.push('}');
    return o;
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
    if kind == "userDexAbstraction" { return true; }
    if kind == "userSetAbstraction" { return true; }
    if kind == "userPortfolioMargin" { return true; }
    if kind == "linkStakingUser" { return true; }
    if kind == "stakingLinkDisableTradingUser" { return true; }
    if kind == "convertToMultiSigUser" { return true; }
    if kind == "sendToEvmWithData" { return true; }
    return false;
}

fn multisig_first_three() -> bool {
    let a = "hyperliquidChain";
    let b = "payloadMultiSigUser";
    let c = "outerSigner";
    return a == "hyperliquidChain" && b == "payloadMultiSigUser" && c == "outerSigner";
}
