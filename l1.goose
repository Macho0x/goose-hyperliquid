// L1 actions other than the order family. Each map is the internally tagged
// Action the exchange hashes. Field names are the camelCase serde names.

import msgpack from "../msgpack";
import msgpack.encode;
import sign;

namespace l1;

enum Kind {
    BorrowLend,
    EvmUserModify,
    GossipPriorityBid,
    AgentEnableDexAbstraction,
    AgentSetAbstraction,
    TwapOrder,
    TwapCancel,
    TrailingStop,
    CDeposit,
    CWithdraw,
    ReserveRequestWeight,
    Hip3LiquidatorTransfer,
    UserOutcome,
    TopUpIsolatedOnlyMargin,
    ClaimRewards,
    AuthorizeAqav2Role,
    ValidatorL1Stream,
    CreateSubAccount,
    SubAccountModify,
    SubAccountSpotTransfer,
    CreateVault,
    VaultModify,
    VaultDistribute,
    SetDisplayName,
    SetReferrer,
    RegisterReferrer,
    CSignerAction,
    CValidatorAction,
    FinalizeEvmContract,
    MultiSig,
    UpdateLeverage,
    UpdateIsolatedMargin,
    VaultTransfer,
    ScheduleCancel,
    Noop,
    SpotUser,
    SubAccountTransfer,
    AgentSendAsset,
}

fn kind_text(k: Kind) -> u8[:] {
    if k == Kind.BorrowLend { return "borrowLend"; }
    if k == Kind.EvmUserModify { return "evmUserModify"; }
    if k == Kind.GossipPriorityBid { return "gossipPriorityBid"; }
    if k == Kind.AgentEnableDexAbstraction { return "agentEnableDexAbstraction"; }
    if k == Kind.AgentSetAbstraction { return "agentSetAbstraction"; }
    if k == Kind.TwapOrder { return "twapOrder"; }
    if k == Kind.TwapCancel { return "twapCancel"; }
    if k == Kind.TrailingStop { return "trailingStop"; }
    if k == Kind.CDeposit { return "cDeposit"; }
    if k == Kind.CWithdraw { return "cWithdraw"; }
    if k == Kind.ReserveRequestWeight { return "reserveRequestWeight"; }
    if k == Kind.Hip3LiquidatorTransfer { return "hip3LiquidatorTransfer"; }
    if k == Kind.UserOutcome { return "userOutcome"; }
    if k == Kind.TopUpIsolatedOnlyMargin { return "topUpIsolatedOnlyMargin"; }
    if k == Kind.ClaimRewards { return "claimRewards"; }
    if k == Kind.AuthorizeAqav2Role { return "authorizeAqav2Role"; }
    if k == Kind.ValidatorL1Stream { return "validatorL1Stream"; }
    if k == Kind.CreateSubAccount { return "createSubAccount"; }
    if k == Kind.SubAccountModify { return "subAccountModify"; }
    if k == Kind.SubAccountSpotTransfer { return "subAccountSpotTransfer"; }
    if k == Kind.CreateVault { return "createVault"; }
    if k == Kind.VaultModify { return "vaultModify"; }
    if k == Kind.VaultDistribute { return "vaultDistribute"; }
    if k == Kind.SetDisplayName { return "setDisplayName"; }
    if k == Kind.SetReferrer { return "setReferrer"; }
    if k == Kind.RegisterReferrer { return "registerReferrer"; }
    if k == Kind.CSignerAction { return "CSignerAction"; }
    if k == Kind.CValidatorAction { return "CValidatorAction"; }
    if k == Kind.FinalizeEvmContract { return "finalizeEvmContract"; }
    if k == Kind.MultiSig { return "multiSig"; }
    if k == Kind.UpdateLeverage { return "updateLeverage"; }
    if k == Kind.UpdateIsolatedMargin { return "updateIsolatedMargin"; }
    if k == Kind.VaultTransfer { return "vaultTransfer"; }
    if k == Kind.ScheduleCancel { return "scheduleCancel"; }
    if k == Kind.Noop { return "noop"; }
    if k == Kind.SpotUser { return "spotUser"; }
    if k == Kind.SubAccountTransfer { return "subAccountTransfer"; }
    return "agentSendAsset";
}

enum Side { Buy, Sell }
enum Margin { Cross, Isolated }
enum Flow { Deposit, Withdraw }
enum Reduce { ReduceOnly, Open }
enum When { Never, At { time: u64 } }
enum Text { Absent, Present { text: const u8[:] } }
enum Flag { Absent, No, Yes }
enum Count { Absent, At { n: u64 } }

fn put_text(out: u8[>..]&, t: Text.Absent) { encode::nil(out); }
fn put_text(out: u8[>..]&, t: Text.Present) { encode::str(out, t.text); }

fn dest_present(t: Text.Absent) -> bool { return false; }
fn dest_present(t: Text.Present) -> bool { return true; }

fn put_dest(out: u8[>..]&, t: Text.Absent) { return; }
fn put_dest(out: u8[>..]&, t: Text.Present) {
    encode::str(out, "destination");
    encode::str(out, t.text);
}

fn put_ip(out: u8[>..]&, t: Text.Absent) { encode::nil(out); }
fn put_ip(out: u8[>..]&, t: Text.Present) {
    encode::map(out, 1);
    encode::str(out, "Ip");
    encode::str(out, t.text);
}

fn put_flag(out: u8[>..]&, f: Flag) {
    if f == Flag.Absent { encode::nil(out); return; }
    encode::boolean(out, f == Flag.Yes);
}

fn put_count(out: u8[>..]&, c: Count) {
    if c == Count.Absent { encode::nil(out); return; }
    encode::uint(out, count_n(c));
}

fn count_n(c: Count.Absent) -> u64 { return 0; }
fn count_n(c: Count.At) -> u64 { return c.n; }

fn put_when(out: u8[>..]&, w: When.Never) { encode::nil(out); }
fn put_when(out: u8[>..]&, w: When.At) { encode::uint(out, w.time); }

fn prehash(body: u8[:], nonce: u64, chain: hyperliquid::Chain) -> u8[32], bool {
    return sign::l1_prehash(body, nonce, sign::Vault.Absent, sign::Expiry.Absent, chain);
}

fn update_leverage(asset: u64, margin: Margin, leverage: u64) -> u8[>..] {
    var out: u8[>..] = [];
    encode::map(out, 4);
    encode::str(out, "type");
    encode::str(out, kind_text(Kind.UpdateLeverage));
    encode::str(out, "asset");
    encode::uint(out, asset);
    encode::str(out, "isCross");
    encode::boolean(out, margin == Margin.Cross);
    encode::str(out, "leverage");
    encode::uint(out, leverage);
    return out;
}

fn update_isolated_margin(asset: u64, side: Side, ntli: i64) -> u8[>..] {
    var out: u8[>..] = [];
    encode::map(out, 4);
    encode::str(out, "type");
    encode::str(out, kind_text(Kind.UpdateIsolatedMargin));
    encode::str(out, "asset");
    encode::uint(out, asset);
    encode::str(out, "isBuy");
    encode::boolean(out, side == Side.Buy);
    encode::str(out, "ntli");
    encode::int(out, ntli);
    return out;
}

fn vault_transfer(vault: u8[:], flow: Flow, usd: u64) -> u8[>..] {
    var out: u8[>..] = [];
    encode::map(out, 4);
    encode::str(out, "type");
    encode::str(out, kind_text(Kind.VaultTransfer));
    encode::str(out, "vaultAddress");
    encode::str(out, vault);
    encode::str(out, "isDeposit");
    encode::boolean(out, flow == Flow.Deposit);
    encode::str(out, "usd");
    encode::uint(out, usd);
    return out;
}

fn schedule_cancel(when: When) -> u8[>..] {
    var out: u8[>..] = [];
    encode::map(out, 2);
    encode::str(out, "type");
    encode::str(out, kind_text(Kind.ScheduleCancel));
    encode::str(out, "time");
    put_when(out, when);
    return out;
}

fn noop() -> u8[>..] {
    var out: u8[>..] = [];
    encode::map(out, 1);
    encode::str(out, "type");
    encode::str(out, kind_text(Kind.Noop));
    return out;
}

fn borrow_lend(operation: u8[:], token: u64, amount: u8[:]) -> u8[>..] {
    var out: u8[>..] = [];
    encode::map(out, 4);
    encode::str(out, "type");
    encode::str(out, kind_text(Kind.BorrowLend));
    encode::str(out, "operation");
    encode::str(out, operation);
    encode::str(out, "token");
    encode::uint(out, token);
    encode::str(out, "amount");
    encode::str(out, amount);
    return out;
}

fn spot_dust(opt_out: bool) -> u8[>..] {
    var out: u8[>..] = [];
    encode::map(out, 2);
    encode::str(out, "type");
    encode::str(out, kind_text(Kind.SpotUser));
    encode::str(out, "toggleSpotDusting");
    encode::map(out, 1);
    encode::str(out, "optOut");
    encode::boolean(out, opt_out);
    return out;
}

fn sub_account_transfer(user: u8[:], flow: Flow, usd: u64) -> u8[>..] {
    var out: u8[>..] = [];
    encode::map(out, 4);
    encode::str(out, "type");
    encode::str(out, kind_text(Kind.SubAccountTransfer));
    encode::str(out, "subAccountUser");
    encode::str(out, user);
    encode::str(out, "isDeposit");
    encode::boolean(out, flow == Flow.Deposit);
    encode::str(out, "usd");
    encode::uint(out, usd);
    return out;
}

fn agent_send_asset(destination: u8[:], source_dex: u8[:], dest_dex: u8[:], token: u8[:], amount: u8[:], from_sub: u8[:], nonce: u64) -> u8[>..] {
    var out: u8[>..] = [];
    encode::map(out, 8);
    encode::str(out, "type");
    encode::str(out, kind_text(Kind.AgentSendAsset));
    encode::str(out, "destination");
    encode::str(out, destination);
    encode::str(out, "sourceDex");
    encode::str(out, source_dex);
    encode::str(out, "destinationDex");
    encode::str(out, dest_dex);
    encode::str(out, "token");
    encode::str(out, token);
    encode::str(out, "amount");
    encode::str(out, amount);
    encode::str(out, "fromSubAccount");
    encode::str(out, from_sub);
    encode::str(out, "nonce");
    encode::uint(out, nonce);
    return out;
}

fn begin(out: u8[>..]&, n: i64, kind: Kind) {
    encode::map(out, n);
    encode::str(out, "type");
    encode::str(out, kind_text(kind));
}

fn borrow_lend_max(operation: u8[:], token: u64) -> u8[>..] {
    var out: u8[>..] = [];
    begin(out, 4, Kind.BorrowLend);
    encode::str(out, "operation");
    encode::str(out, operation);
    encode::str(out, "token");
    encode::uint(out, token);
    encode::str(out, "amount");
    encode::nil(out);
    return out;
}

fn evm_user_modify(using_big_blocks: bool) -> u8[>..] {
    var out: u8[>..] = [];
    begin(out, 2, Kind.EvmUserModify);
    encode::str(out, "usingBigBlocks");
    encode::boolean(out, using_big_blocks);
    return out;
}

fn gossip_priority_bid(slot_id: u64, ip: u8[:], max_gas: u64) -> u8[>..] {
    var out: u8[>..] = [];
    begin(out, 4, Kind.GossipPriorityBid);
    encode::str(out, "slotId");
    encode::uint(out, slot_id);
    encode::str(out, "ip");
    encode::str(out, ip);
    encode::str(out, "maxGas");
    encode::uint(out, max_gas);
    return out;
}

fn agent_enable_dex_abstraction() -> u8[>..] {
    var out: u8[>..] = [];
    begin(out, 1, Kind.AgentEnableDexAbstraction);
    return out;
}

fn agent_set_abstraction(code: u8[:]) -> u8[>..] {
    var out: u8[>..] = [];
    begin(out, 2, Kind.AgentSetAbstraction);
    encode::str(out, "abstraction");
    encode::str(out, code);
    return out;
}

fn twap_order(asset: u64, side: Side, size: u8[:], reduce: Reduce, minutes: u64, randomize: bool) -> u8[>..] {
    var out: u8[>..] = [];
    begin(out, 2, Kind.TwapOrder);
    encode::str(out, "twap");
    encode::map(out, 6);
    encode::str(out, "a");
    encode::uint(out, asset);
    encode::str(out, "b");
    encode::boolean(out, side == Side.Buy);
    encode::str(out, "s");
    encode::str(out, size);
    encode::str(out, "r");
    encode::boolean(out, reduce == Reduce.ReduceOnly);
    encode::str(out, "m");
    encode::uint(out, minutes);
    encode::str(out, "t");
    encode::boolean(out, randomize);
    return out;
}

fn twap_cancel(asset: u64, twap_id: u64) -> u8[>..] {
    var out: u8[>..] = [];
    begin(out, 3, Kind.TwapCancel);
    encode::str(out, "a");
    encode::uint(out, asset);
    encode::str(out, "t");
    encode::uint(out, twap_id);
    return out;
}

fn trail_head(out: u8[>..]&, asset: u64, side: Side, size: u8[:], reduce: Reduce) {
    begin(out, 7, Kind.TrailingStop);
    encode::str(out, "asset");
    encode::uint(out, asset);
    encode::str(out, "isBuy");
    encode::boolean(out, side == Side.Buy);
    encode::str(out, "sz");
    encode::str(out, size);
    encode::str(out, "reduceOnly");
    encode::boolean(out, reduce == Reduce.ReduceOnly);
    encode::str(out, "retracement");
}

fn trailing_pct(asset: u64, side: Side, size: u8[:], reduce: Reduce, pct: u8[:]) -> u8[>..] {
    var out: u8[>..] = [];
    trail_head(out, asset, side, size, reduce);
    encode::map(out, 1);
    encode::str(out, "pct");
    encode::str(out, pct);
    encode::str(out, "activationPx");
    encode::nil(out);
    return out;
}

fn trailing_px(asset: u64, side: Side, size: u8[:], reduce: Reduce, px: u8[:], activation: u8[:]) -> u8[>..] {
    var out: u8[>..] = [];
    trail_head(out, asset, side, size, reduce);
    encode::map(out, 1);
    encode::str(out, "px");
    encode::str(out, px);
    encode::str(out, "activationPx");
    encode::str(out, activation);
    return out;
}

fn c_deposit(wei: u64) -> u8[>..] {
    var out: u8[>..] = [];
    begin(out, 2, Kind.CDeposit);
    encode::str(out, "wei");
    encode::uint(out, wei);
    return out;
}

fn c_withdraw(wei: u64) -> u8[>..] {
    var out: u8[>..] = [];
    begin(out, 2, Kind.CWithdraw);
    encode::str(out, "wei");
    encode::uint(out, wei);
    return out;
}

fn reserve_weight(weight: u64, dest: Text) -> u8[>..] {
    var out: u8[>..] = [];
    if dest_present(dest) { begin(out, 3, Kind.ReserveRequestWeight); } else { begin(out, 2, Kind.ReserveRequestWeight); }
    encode::str(out, "weight");
    encode::uint(out, weight);
    put_dest(out, dest);
    return out;
}

fn hip3_transfer(dex: u8[:], ntl: u64, flow: Flow) -> u8[>..] {
    var out: u8[>..] = [];
    begin(out, 4, Kind.Hip3LiquidatorTransfer);
    encode::str(out, "dex");
    encode::str(out, dex);
    encode::str(out, "ntl");
    encode::uint(out, ntl);
    encode::str(out, "isDeposit");
    encode::boolean(out, flow == Flow.Deposit);
    return out;
}

fn outcome_split(outcome: u64, amount: u8[:]) -> u8[>..] {
    var out: u8[>..] = [];
    begin(out, 2, Kind.UserOutcome);
    encode::str(out, "splitOutcome");
    encode::map(out, 2);
    encode::str(out, "outcome");
    encode::uint(out, outcome);
    encode::str(out, "amount");
    encode::str(out, amount);
    return out;
}

fn outcome_merge(outcome: u64, amount: Text) -> u8[>..] {
    var out: u8[>..] = [];
    begin(out, 2, Kind.UserOutcome);
    encode::str(out, "mergeOutcome");
    encode::map(out, 2);
    encode::str(out, "outcome");
    encode::uint(out, outcome);
    encode::str(out, "amount");
    put_text(out, amount);
    return out;
}

fn outcome_merge_question(question: u64, amount: Text) -> u8[>..] {
    var out: u8[>..] = [];
    begin(out, 2, Kind.UserOutcome);
    encode::str(out, "mergeQuestion");
    encode::map(out, 2);
    encode::str(out, "question");
    encode::uint(out, question);
    encode::str(out, "amount");
    put_text(out, amount);
    return out;
}

fn outcome_negate(question: u64, outcome: u64, amount: u8[:]) -> u8[>..] {
    var out: u8[>..] = [];
    begin(out, 2, Kind.UserOutcome);
    encode::str(out, "negateOutcome");
    encode::map(out, 3);
    encode::str(out, "question");
    encode::uint(out, question);
    encode::str(out, "outcome");
    encode::uint(out, outcome);
    encode::str(out, "amount");
    encode::str(out, amount);
    return out;
}

fn top_up_isolated(asset: u64, leverage: u8[:]) -> u8[>..] {
    var out: u8[>..] = [];
    begin(out, 3, Kind.TopUpIsolatedOnlyMargin);
    encode::str(out, "asset");
    encode::uint(out, asset);
    encode::str(out, "leverage");
    encode::str(out, leverage);
    return out;
}

fn claim_rewards() -> u8[>..] {
    var out: u8[>..] = [];
    begin(out, 1, Kind.ClaimRewards);
    return out;
}

fn authorize_aqav2(token: u64, role: u8[:]) -> u8[>..] {
    var out: u8[>..] = [];
    begin(out, 3, Kind.AuthorizeAqav2Role);
    encode::str(out, "token");
    encode::uint(out, token);
    encode::str(out, "role");
    encode::str(out, role);
    return out;
}

fn validator_stream(rate: u8[:]) -> u8[>..] {
    var out: u8[>..] = [];
    begin(out, 2, Kind.ValidatorL1Stream);
    encode::str(out, "riskFreeRate");
    encode::str(out, rate);
    return out;
}

fn create_sub_account(name: u8[:]) -> u8[>..] {
    var out: u8[>..] = [];
    begin(out, 2, Kind.CreateSubAccount);
    encode::str(out, "name");
    encode::str(out, name);
    return out;
}

fn sub_account_modify(user: u8[:], name: u8[:]) -> u8[>..] {
    var out: u8[>..] = [];
    begin(out, 3, Kind.SubAccountModify);
    encode::str(out, "subAccountUser");
    encode::str(out, user);
    encode::str(out, "name");
    encode::str(out, name);
    return out;
}

fn sub_account_spot(user: u8[:], flow: Flow, token: u8[:], amount: u8[:]) -> u8[>..] {
    var out: u8[>..] = [];
    begin(out, 5, Kind.SubAccountSpotTransfer);
    encode::str(out, "subAccountUser");
    encode::str(out, user);
    encode::str(out, "isDeposit");
    encode::boolean(out, flow == Flow.Deposit);
    encode::str(out, "token");
    encode::str(out, token);
    encode::str(out, "amount");
    encode::str(out, amount);
    return out;
}

fn create_vault(name: u8[:], description: u8[:], initial_usd: u64, nonce: u64) -> u8[>..] {
    var out: u8[>..] = [];
    begin(out, 5, Kind.CreateVault);
    encode::str(out, "name");
    encode::str(out, name);
    encode::str(out, "description");
    encode::str(out, description);
    encode::str(out, "initialUsd");
    encode::uint(out, initial_usd);
    encode::str(out, "nonce");
    encode::uint(out, nonce);
    return out;
}

fn vault_modify(vault: u8[:], allow: Flag, close: Flag) -> u8[>..] {
    var out: u8[>..] = [];
    begin(out, 4, Kind.VaultModify);
    encode::str(out, "vaultAddress");
    encode::str(out, vault);
    encode::str(out, "allowDeposits");
    put_flag(out, allow);
    encode::str(out, "alwaysCloseOnWithdraw");
    put_flag(out, close);
    return out;
}

fn vault_distribute(vault: u8[:], usd: u64) -> u8[>..] {
    var out: u8[>..] = [];
    begin(out, 3, Kind.VaultDistribute);
    encode::str(out, "vaultAddress");
    encode::str(out, vault);
    encode::str(out, "usd");
    encode::uint(out, usd);
    return out;
}

fn set_display_name(name: u8[:]) -> u8[>..] {
    var out: u8[>..] = [];
    begin(out, 2, Kind.SetDisplayName);
    encode::str(out, "displayName");
    encode::str(out, name);
    return out;
}

fn set_referrer(code: u8[:]) -> u8[>..] {
    var out: u8[>..] = [];
    begin(out, 2, Kind.SetReferrer);
    encode::str(out, "code");
    encode::str(out, code);
    return out;
}

fn register_referrer(code: u8[:]) -> u8[>..] {
    var out: u8[>..] = [];
    begin(out, 2, Kind.RegisterReferrer);
    encode::str(out, "code");
    encode::str(out, code);
    return out;
}

fn jail_self() -> u8[>..] {
    var out: u8[>..] = [];
    begin(out, 2, Kind.CSignerAction);
    encode::str(out, "jailSelf");
    encode::nil(out);
    return out;
}

fn unjail_self() -> u8[>..] {
    var out: u8[>..] = [];
    begin(out, 2, Kind.CSignerAction);
    encode::str(out, "unjailSelf");
    encode::nil(out);
    return out;
}

fn validator_unregister() -> u8[>..] {
    var out: u8[>..] = [];
    begin(out, 2, Kind.CValidatorAction);
    encode::str(out, "unregister");
    encode::nil(out);
    return out;
}

fn validator_register(ip: u8[:], name: u8[:], description: u8[:], delegations_disabled: bool, commission_bps: u64, signer: u8[:], unjailed: bool, initial_wei: u64) -> u8[>..] {
    var out: u8[>..] = [];
    begin(out, 2, Kind.CValidatorAction);
    encode::str(out, "register");
    encode::map(out, 3);
    encode::str(out, "profile");
    encode::map(out, 6);
    encode::str(out, "node_ip");
    encode::map(out, 1);
    encode::str(out, "Ip");
    encode::str(out, ip);
    encode::str(out, "name");
    encode::str(out, name);
    encode::str(out, "description");
    encode::str(out, description);
    encode::str(out, "delegations_disabled");
    encode::boolean(out, delegations_disabled);
    encode::str(out, "commission_bps");
    encode::uint(out, commission_bps);
    encode::str(out, "signer");
    encode::str(out, signer);
    encode::str(out, "unjailed");
    encode::boolean(out, unjailed);
    encode::str(out, "initial_wei");
    encode::uint(out, initial_wei);
    return out;
}

fn validator_change(ip: Text, name: Text, description: Text, unjailed: bool, disable: Flag, bps: Count, signer: Text) -> u8[>..] {
    var out: u8[>..] = [];
    begin(out, 2, Kind.CValidatorAction);
    encode::str(out, "changeProfile");
    encode::map(out, 7);
    encode::str(out, "node_ip");
    put_ip(out, ip);
    encode::str(out, "name");
    put_text(out, name);
    encode::str(out, "description");
    put_text(out, description);
    encode::str(out, "unjailed");
    encode::boolean(out, unjailed);
    encode::str(out, "disable_delegations");
    put_flag(out, disable);
    encode::str(out, "commission_bps");
    put_count(out, bps);
    encode::str(out, "signer");
    put_text(out, signer);
    return out;
}

fn finalize_create(token: u64, nonce: u64) -> u8[>..] {
    var out: u8[>..] = [];
    begin(out, 3, Kind.FinalizeEvmContract);
    encode::str(out, "token");
    encode::uint(out, token);
    encode::str(out, "input");
    encode::map(out, 1);
    encode::str(out, "create");
    encode::map(out, 1);
    encode::str(out, "nonce");
    encode::uint(out, nonce);
    return out;
}

fn finalize_slot(token: u64, slot: u8[:]) -> u8[>..] {
    var out: u8[>..] = [];
    begin(out, 3, Kind.FinalizeEvmContract);
    encode::str(out, "token");
    encode::uint(out, token);
    encode::str(out, "input");
    encode::str(out, slot);
    return out;
}

fn one_signature(out: u8[>..]&, r: u8[:], s: u8[:], v: u64) {
    encode::map(out, 3);
    encode::str(out, "r");
    encode::str(out, r);
    encode::str(out, "s");
    encode::str(out, s);
    encode::str(out, "v");
    encode::uint(out, v);
}

fn multi_sig(chain_id: u8[:], signatures: u8[:], user: u8[:], outer: u8[:], action: u8[:]) -> u8[>..] {
    var out: u8[>..] = [];
    begin(out, 4, Kind.MultiSig);
    encode::str(out, "signatureChainId");
    encode::str(out, chain_id);
    encode::str(out, "signatures");
    out.append(signatures);
    encode::str(out, "payload");
    encode::map(out, 3);
    encode::str(out, "multiSigUser");
    encode::str(out, user);
    encode::str(out, "outerSigner");
    encode::str(out, outer);
    encode::str(out, "action");
    out.append(action);
    return out;
}
