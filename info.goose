// Info requests, a few response reads, and POST /info.
// Fast asset contexts are base64 wrapped around a raw DEFLATE stream.

import base64;
import deflate from "../deflate";
import deflate.inflate;
import json;
import http from "github.com/kaitk/goose-http@main";
import tls from "github.com/kaitk/goose-tls@v0.0.6";
import http.client;

namespace info;

enum Query {
    SpotMeta,
    PerpDexs,
    OutcomeMeta,
    OutcomeTemplates,
    PredictedFundings,
    PerpDeployAuctionStatus,
    SpotPairDeployAuctionStatus,
    AllPerpMetas,
    PerpCategories,
    PerpConciseAnnotations,
    SpotMetaAndAssetCtxs,
    AllBorrowLendReserveStates,
    ExchangeStatus,
    GossipRootIps,
    GossipPriorityAuctionStatus,
    Liquidatable,
    MaxMarketOrderNtls,
    ValidatorL1Votes,
    ValidatorSummaries,
    VaultSummaries,
    UsdcRouting,
    HistoricalOrders,
    SpotClearinghouseState,
    ClearinghouseState,
    ExtraAgents,
    UserFees,
    UserVaultEquities,
    UserRole,
    SubAccounts,
    SubAccounts2,
    UserAbstraction,
    UserDexAbstraction,
    UserRateLimit,
    Portfolio,
    Referral,
    Delegations,
    DelegatorSummary,
    OpenOrders,
    TwapHistory,
    LegalCheck,
    IsVip,
    UserToMultiSigSigners,
    ApprovedBuilders,
    DelegatorHistory,
    DelegatorRewards,
    BorrowLendUserState,
    UserTwapSliceFills,
    SpotDeployState,
    UserStarState,
    LeadingVaults,
    Meta,
    MetaAndAssetCtxs,
    AllMids,
    PerpsAtOpenInterestCap,
    PerpDexLimits,
    PerpDexStatus,
    UserFunding,
    UserNonFundingLedgerUpdates,
    UserBorrowLendInterest,
    UserFillsByTime,
    UserTwapSliceFillsByTime,
    FrontendOpenOrders,
    UserFills,
    PerpAnnotation,
    RecentTrades,
    SettledOutcome,
    WebData2,
    L2Book,
    CandleSnapshot,
    MaxBuilderFee,
    ActiveAssetData,
    FundingHistory,
    VaultDetails,
    OrderStatus,
    BorrowLendReserveState,
    MarginTable,
    PreTransferCheck,
    TokenDetails,
}

fn query_text(k: Query) -> u8[:] {
    if k == Query.SpotMeta { return "spotMeta"; }
    if k == Query.PerpDexs { return "perpDexs"; }
    if k == Query.OutcomeMeta { return "outcomeMeta"; }
    if k == Query.OutcomeTemplates { return "outcomeTemplates"; }
    if k == Query.PredictedFundings { return "predictedFundings"; }
    if k == Query.PerpDeployAuctionStatus { return "perpDeployAuctionStatus"; }
    if k == Query.SpotPairDeployAuctionStatus { return "spotPairDeployAuctionStatus"; }
    if k == Query.AllPerpMetas { return "allPerpMetas"; }
    if k == Query.PerpCategories { return "perpCategories"; }
    if k == Query.PerpConciseAnnotations { return "perpConciseAnnotations"; }
    if k == Query.SpotMetaAndAssetCtxs { return "spotMetaAndAssetCtxs"; }
    if k == Query.AllBorrowLendReserveStates { return "allBorrowLendReserveStates"; }
    if k == Query.ExchangeStatus { return "exchangeStatus"; }
    if k == Query.GossipRootIps { return "gossipRootIps"; }
    if k == Query.GossipPriorityAuctionStatus { return "gossipPriorityAuctionStatus"; }
    if k == Query.Liquidatable { return "liquidatable"; }
    if k == Query.MaxMarketOrderNtls { return "maxMarketOrderNtls"; }
    if k == Query.ValidatorL1Votes { return "validatorL1Votes"; }
    if k == Query.ValidatorSummaries { return "validatorSummaries"; }
    if k == Query.VaultSummaries { return "vaultSummaries"; }
    if k == Query.UsdcRouting { return "usdcRouting"; }
    if k == Query.HistoricalOrders { return "historicalOrders"; }
    if k == Query.SpotClearinghouseState { return "spotClearinghouseState"; }
    if k == Query.ClearinghouseState { return "clearinghouseState"; }
    if k == Query.ExtraAgents { return "extraAgents"; }
    if k == Query.UserFees { return "userFees"; }
    if k == Query.UserVaultEquities { return "userVaultEquities"; }
    if k == Query.UserRole { return "userRole"; }
    if k == Query.SubAccounts { return "subAccounts"; }
    if k == Query.SubAccounts2 { return "subAccounts2"; }
    if k == Query.UserAbstraction { return "userAbstraction"; }
    if k == Query.UserDexAbstraction { return "userDexAbstraction"; }
    if k == Query.UserRateLimit { return "userRateLimit"; }
    if k == Query.Portfolio { return "portfolio"; }
    if k == Query.Referral { return "referral"; }
    if k == Query.Delegations { return "delegations"; }
    if k == Query.DelegatorSummary { return "delegatorSummary"; }
    if k == Query.OpenOrders { return "openOrders"; }
    if k == Query.TwapHistory { return "twapHistory"; }
    if k == Query.LegalCheck { return "legalCheck"; }
    if k == Query.IsVip { return "isVip"; }
    if k == Query.UserToMultiSigSigners { return "userToMultiSigSigners"; }
    if k == Query.ApprovedBuilders { return "approvedBuilders"; }
    if k == Query.DelegatorHistory { return "delegatorHistory"; }
    if k == Query.DelegatorRewards { return "delegatorRewards"; }
    if k == Query.BorrowLendUserState { return "borrowLendUserState"; }
    if k == Query.UserTwapSliceFills { return "userTwapSliceFills"; }
    if k == Query.SpotDeployState { return "spotDeployState"; }
    if k == Query.UserStarState { return "userStarState"; }
    if k == Query.LeadingVaults { return "leadingVaults"; }
    if k == Query.Meta { return "meta"; }
    if k == Query.MetaAndAssetCtxs { return "metaAndAssetCtxs"; }
    if k == Query.AllMids { return "allMids"; }
    if k == Query.PerpsAtOpenInterestCap { return "perpsAtOpenInterestCap"; }
    if k == Query.PerpDexLimits { return "perpDexLimits"; }
    if k == Query.PerpDexStatus { return "perpDexStatus"; }
    if k == Query.UserFunding { return "userFunding"; }
    if k == Query.UserNonFundingLedgerUpdates { return "userNonFundingLedgerUpdates"; }
    if k == Query.UserBorrowLendInterest { return "userBorrowLendInterest"; }
    if k == Query.UserFillsByTime { return "userFillsByTime"; }
    if k == Query.UserTwapSliceFillsByTime { return "userTwapSliceFillsByTime"; }
    if k == Query.FrontendOpenOrders { return "frontendOpenOrders"; }
    if k == Query.UserFills { return "userFills"; }
    if k == Query.PerpAnnotation { return "perpAnnotation"; }
    if k == Query.RecentTrades { return "recentTrades"; }
    if k == Query.SettledOutcome { return "settledOutcome"; }
    if k == Query.WebData2 { return "webData2"; }
    if k == Query.L2Book { return "l2Book"; }
    if k == Query.CandleSnapshot { return "candleSnapshot"; }
    if k == Query.MaxBuilderFee { return "maxBuilderFee"; }
    if k == Query.ActiveAssetData { return "activeAssetData"; }
    if k == Query.FundingHistory { return "fundingHistory"; }
    if k == Query.VaultDetails { return "vaultDetails"; }
    if k == Query.OrderStatus { return "orderStatus"; }
    if k == Query.BorrowLendReserveState { return "borrowLendReserveState"; }
    if k == Query.MarginTable { return "marginTable"; }
    if k == Query.PreTransferCheck { return "preTransferCheck"; }
    return "tokenDetails";
}

enum Stamp { Absent, At { n: i64 } }
enum Flag { Absent, No, Yes }
enum Text { Absent, Present { text: const u8[:] } }

fn stamp_set(s: Stamp.Absent) -> bool { return false; }
fn stamp_set(s: Stamp.At) -> bool { return true; }
fn stamp_n(s: Stamp.Absent) -> i64 { return 0; }
fn stamp_n(s: Stamp.At) -> i64 { return s.n; }

fn flag_set(f: Flag.Absent) -> bool { return false; }
fn flag_set(f: Flag.No) -> bool { return true; }
fn flag_set(f: Flag.Yes) -> bool { return true; }

fn text_set(t: Text.Absent) -> bool { return false; }
fn text_set(t: Text.Present) -> bool { return true; }
fn text_of(t: Text.Absent) -> u8[:] { return ""; }
fn text_of(t: Text.Present) -> u8[:] { return t.text; }


fn field_str(out: u8[>..]&, key: u8[:], value: u8[:]) {
    out.push(',');
    json::format_key(out, key);
    json::format_string(out, value);
}

fn field_int(out: u8[>..]&, key: u8[:], value: i64) {
    out.push(',');
    json::format_key(out, key);
    json::format_int(out, value);
}

fn field_bool(out: u8[>..]&, key: u8[:], value: bool) {
    out.push(',');
    json::format_key(out, key);
    json::format_bool(out, value);
}

fn spot_meta() -> u8[>..] { return typed(Query.SpotMeta); }
fn perp_dexs() -> u8[>..] { return typed(Query.PerpDexs); }
fn outcome_meta() -> u8[>..] { return typed(Query.OutcomeMeta); }
fn outcome_templates() -> u8[>..] { return typed(Query.OutcomeTemplates); }
fn predicted_fundings() -> u8[>..] { return typed(Query.PredictedFundings); }
fn perp_deploy_auction() -> u8[>..] { return typed(Query.PerpDeployAuctionStatus); }
fn spot_pair_deploy_auction() -> u8[>..] { return typed(Query.SpotPairDeployAuctionStatus); }
fn all_perp_metas() -> u8[>..] { return typed(Query.AllPerpMetas); }
fn perp_categories() -> u8[>..] { return typed(Query.PerpCategories); }
fn perp_concise_annotations() -> u8[>..] { return typed(Query.PerpConciseAnnotations); }
fn spot_meta_and_asset_ctxs() -> u8[>..] { return typed(Query.SpotMetaAndAssetCtxs); }
fn all_borrow_lend_reserves() -> u8[>..] { return typed(Query.AllBorrowLendReserveStates); }
fn exchange_status() -> u8[>..] { return typed(Query.ExchangeStatus); }
fn gossip_root_ips() -> u8[>..] { return typed(Query.GossipRootIps); }
fn gossip_priority_auction() -> u8[>..] { return typed(Query.GossipPriorityAuctionStatus); }
fn liquidatable() -> u8[>..] { return typed(Query.Liquidatable); }
fn max_market_order_ntls() -> u8[>..] { return typed(Query.MaxMarketOrderNtls); }
fn validator_l1_votes() -> u8[>..] { return typed(Query.ValidatorL1Votes); }
fn validator_summaries() -> u8[>..] { return typed(Query.ValidatorSummaries); }
fn vault_summaries() -> u8[>..] { return typed(Query.VaultSummaries); }
fn usdc_routing() -> u8[>..] { return typed(Query.UsdcRouting); }

fn historical_orders(user: u8[:]) -> u8[>..] { return request(Query.HistoricalOrders, user); }
fn spot_clearinghouse(user: u8[:]) -> u8[>..] { return request(Query.SpotClearinghouseState, user); }
fn clearinghouse(user: u8[:]) -> u8[>..] { return request(Query.ClearinghouseState, user); }
fn extra_agents(user: u8[:]) -> u8[>..] { return request(Query.ExtraAgents, user); }
fn user_fees(user: u8[:]) -> u8[>..] { return request(Query.UserFees, user); }
fn user_vault_equities(user: u8[:]) -> u8[>..] { return request(Query.UserVaultEquities, user); }
fn user_role(user: u8[:]) -> u8[>..] { return request(Query.UserRole, user); }
fn subaccounts(user: u8[:]) -> u8[>..] { return request(Query.SubAccounts, user); }
fn subaccounts2(user: u8[:]) -> u8[>..] { return request(Query.SubAccounts2, user); }
fn user_abstraction(user: u8[:]) -> u8[>..] { return request(Query.UserAbstraction, user); }
fn user_dex_abstraction(user: u8[:]) -> u8[>..] { return request(Query.UserDexAbstraction, user); }
fn user_rate_limit(user: u8[:]) -> u8[>..] { return request(Query.UserRateLimit, user); }
fn portfolio(user: u8[:]) -> u8[>..] { return request(Query.Portfolio, user); }
fn referral(user: u8[:]) -> u8[>..] { return request(Query.Referral, user); }
fn delegations(user: u8[:]) -> u8[>..] { return request(Query.Delegations, user); }
fn delegator_summary(user: u8[:]) -> u8[>..] { return request(Query.DelegatorSummary, user); }
fn open_orders(user: u8[:]) -> u8[>..] { return request(Query.OpenOrders, user); }
fn twap_history(user: u8[:]) -> u8[>..] { return request(Query.TwapHistory, user); }
fn legal_check(user: u8[:]) -> u8[>..] { return request(Query.LegalCheck, user); }
fn is_vip(user: u8[:]) -> u8[>..] { return request(Query.IsVip, user); }
fn user_to_multisig_signers(user: u8[:]) -> u8[>..] { return request(Query.UserToMultiSigSigners, user); }
fn approved_builders(user: u8[:]) -> u8[>..] { return request(Query.ApprovedBuilders, user); }
fn delegator_history(user: u8[:]) -> u8[>..] { return request(Query.DelegatorHistory, user); }
fn delegator_rewards(user: u8[:]) -> u8[>..] { return request(Query.DelegatorRewards, user); }
fn borrow_lend_user(user: u8[:]) -> u8[>..] { return request(Query.BorrowLendUserState, user); }
fn user_twap_slice_fills(user: u8[:]) -> u8[>..] { return request(Query.UserTwapSliceFills, user); }
fn spot_deploy_state(user: u8[:]) -> u8[>..] { return request(Query.SpotDeployState, user); }
fn user_star_state(user: u8[:]) -> u8[>..] { return request(Query.UserStarState, user); }
fn leading_vaults(user: u8[:]) -> u8[>..] { return request(Query.LeadingVaults, user); }

fn meta(dex: u8[:]) -> u8[>..] { return dex_query(Query.Meta, dex); }
fn meta_and_asset_ctxs(dex: u8[:]) -> u8[>..] { return dex_query(Query.MetaAndAssetCtxs, dex); }
fn all_mids(dex: u8[:]) -> u8[>..] { return dex_query(Query.AllMids, dex); }
fn perps_at_cap(dex: u8[:]) -> u8[>..] { return dex_query(Query.PerpsAtOpenInterestCap, dex); }
fn perp_dex_limits(dex: u8[:]) -> u8[>..] { return dex_query(Query.PerpDexLimits, dex); }
fn perp_dex_status(dex: u8[:]) -> u8[>..] { return dex_query(Query.PerpDexStatus, dex); }

fn frontend_open_orders(user: u8[:], dex: u8[:]) -> u8[>..] {
    var out: u8[>..] = [];
    out.push('{');
    json::format_key(out, "type");
    json::format_string(out, query_text(Query.FrontendOpenOrders));
    field_str(out, "user", user);
    if dex.len != 0 { field_str(out, "dex", dex); }
    out.push('}');
    return out;
}

fn user_fills(user: u8[:], aggregate: Flag) -> u8[>..] {
    var out: u8[>..] = [];
    out.push('{');
    json::format_key(out, "type");
    json::format_string(out, query_text(Query.UserFills));
    field_str(out, "user", user);
    if flag_set(aggregate) { field_bool(out, "aggregateByTime", aggregate == Flag.Yes); }
    out.push('}');
    return out;
}

fn user_funding(user: u8[:], start_time: i64, end: Stamp) -> u8[>..] {
    return user_span(Query.UserFunding, user, start_time, end);
}

fn user_ledger(user: u8[:], start_time: i64, end: Stamp) -> u8[>..] {
    return user_span(Query.UserNonFundingLedgerUpdates, user, start_time, end);
}

fn user_borrow_interest(user: u8[:], start_time: i64, end: Stamp) -> u8[>..] {
    return user_span(Query.UserBorrowLendInterest, user, start_time, end);
}

fn span_agg(kind: Query, user: u8[:], start_time: i64, end: Stamp, aggregate: Flag) -> u8[>..] {
    var out: u8[>..] = [];
    out.push('{');
    json::format_key(out, "type");
    json::format_string(out, query_text(kind));
    field_str(out, "user", user);
    field_int(out, "startTime", start_time);
    if stamp_set(end) { field_int(out, "endTime", stamp_n(end)); }
    if flag_set(aggregate) { field_bool(out, "aggregateByTime", aggregate == Flag.Yes); }
    out.push('}');
    return out;
}

fn user_fills_by_time(user: u8[:], start_time: i64, end: Stamp, aggregate: Flag) -> u8[>..] {
    return span_agg(Query.UserFillsByTime, user, start_time, end, aggregate);
}

fn user_twap_by_time(user: u8[:], start_time: i64, end: Stamp, aggregate: Flag) -> u8[>..] {
    return span_agg(Query.UserTwapSliceFillsByTime, user, start_time, end, aggregate);
}

fn clearinghouse_on(user: u8[:], dex: u8[:]) -> u8[>..] {
    var out: u8[>..] = [];
    out.push('{');
    json::format_key(out, "type");
    json::format_string(out, query_text(Query.ClearinghouseState));
    field_str(out, "user", user);
    if dex.len != 0 { field_str(out, "dex", dex); }
    out.push('}');
    return out;
}

fn perp_annotation(coin: u8[:]) -> u8[>..] {
    var out: u8[>..] = [];
    out.push('{');
    json::format_key(out, "type");
    json::format_string(out, query_text(Query.PerpAnnotation));
    field_str(out, "coin", coin);
    out.push('}');
    return out;
}

fn recent_trades(coin: u8[:]) -> u8[>..] {
    var out: u8[>..] = [];
    out.push('{');
    json::format_key(out, "type");
    json::format_string(out, query_text(Query.RecentTrades));
    field_str(out, "coin", coin);
    out.push('}');
    return out;
}

fn settled_outcome(outcome: i64) -> u8[>..] {
    var out: u8[>..] = [];
    out.push('{');
    json::format_key(out, "type");
    json::format_string(out, query_text(Query.SettledOutcome));
    field_int(out, "outcome", outcome);
    out.push('}');
    return out;
}

fn web_data2(user: u8[:], dex: u8[:]) -> u8[>..] {
    var out: u8[>..] = [];
    out.push('{');
    json::format_key(out, "type");
    json::format_string(out, query_text(Query.WebData2));
    field_str(out, "user", user);
    if dex.len != 0 { field_str(out, "dex", dex); }
    out.push('}');
    return out;
}

fn typed(kind: Query) -> u8[>..] {
    var out: u8[>..] = [];
    out.push('{');
    json::format_key(out, "type");
    json::format_string(out, query_text(kind));
    out.push('}');
    return out;
}

fn user_query(kind: Query, user: u8[:]) -> u8[>..] { return request(kind, user); }

fn dex_query(kind: Query, dex: u8[:]) -> u8[>..] {
    var out: u8[>..] = [];
    out.push('{');
    json::format_key(out, "type");
    json::format_string(out, query_text(kind));
    if dex.len != 0 { field_str(out, "dex", dex); }
    out.push('}');
    return out;
}

fn user_span(kind: Query, user: u8[:], start_time: i64, end: Stamp) -> u8[>..] {
    var out: u8[>..] = [];
    out.push('{');
    json::format_key(out, "type");
    json::format_string(out, query_text(kind));
    field_str(out, "user", user);
    field_int(out, "startTime", start_time);
    if stamp_set(end) { field_int(out, "endTime", stamp_n(end)); }
    out.push('}');
    return out;
}

fn l2_book(coin: u8[:], figs: Stamp, mantissa: Stamp) -> u8[>..] {
    var out: u8[>..] = [];
    out.push('{');
    json::format_key(out, "type");
    json::format_string(out, query_text(Query.L2Book));
    field_str(out, "coin", coin);
    if stamp_set(figs) { field_int(out, "nSigFigs", stamp_n(figs)); }
    if stamp_set(mantissa) { field_int(out, "mantissa", stamp_n(mantissa)); }
    out.push('}');
    return out;
}

fn candle_snapshot(coin: u8[:], interval: u8[:], start_time: i64, end_time: i64) -> u8[>..] {
    var out: u8[>..] = [];
    out.push('{');
    json::format_key(out, "type");
    json::format_string(out, query_text(Query.CandleSnapshot));
    out.push(',');
    json::format_key(out, "req");
    out.push('{');
    json::format_key(out, "coin");
    json::format_string(out, coin);
    field_str(out, "interval", interval);
    field_int(out, "startTime", start_time);
    field_int(out, "endTime", end_time);
    out.push('}');
    out.push('}');
    return out;
}

fn max_builder_fee(user: u8[:], builder: u8[:]) -> u8[>..] {
    var out: u8[>..] = [];
    out.push('{');
    json::format_key(out, "type");
    json::format_string(out, query_text(Query.MaxBuilderFee));
    field_str(out, "user", user);
    field_str(out, "builder", builder);
    out.push('}');
    return out;
}

fn active_asset_data(user: u8[:], coin: u8[:]) -> u8[>..] {
    var out: u8[>..] = [];
    out.push('{');
    json::format_key(out, "type");
    json::format_string(out, query_text(Query.ActiveAssetData));
    field_str(out, "user", user);
    field_str(out, "coin", coin);
    out.push('}');
    return out;
}

fn funding_history(coin: u8[:], start_time: i64, end: Stamp) -> u8[>..] {
    var out: u8[>..] = [];
    out.push('{');
    json::format_key(out, "type");
    json::format_string(out, query_text(Query.FundingHistory));
    field_str(out, "coin", coin);
    field_int(out, "startTime", start_time);
    if stamp_set(end) { field_int(out, "endTime", stamp_n(end)); }
    out.push('}');
    return out;
}

fn vault_details(vault: u8[:], user: Text) -> u8[>..] {
    var out: u8[>..] = [];
    out.push('{');
    json::format_key(out, "type");
    json::format_string(out, query_text(Query.VaultDetails));
    field_str(out, "vaultAddress", vault);
    if text_set(user) { field_str(out, "user", text_of(user)); }
    out.push('}');
    return out;
}

fn order_status_oid(user: u8[:], oid: i64) -> u8[>..] {
    var out: u8[>..] = [];
    out.push('{');
    json::format_key(out, "type");
    json::format_string(out, query_text(Query.OrderStatus));
    field_str(out, "user", user);
    field_int(out, "oid", oid);
    out.push('}');
    return out;
}

fn order_status_cloid(user: u8[:], cloid: u8[:]) -> u8[>..] {
    var out: u8[>..] = [];
    out.push('{');
    json::format_key(out, "type");
    json::format_string(out, query_text(Query.OrderStatus));
    field_str(out, "user", user);
    field_str(out, "oid", cloid);
    out.push('}');
    return out;
}

fn borrow_lend_reserve(token: i64) -> u8[>..] {
    var out: u8[>..] = [];
    out.push('{');
    json::format_key(out, "type");
    json::format_string(out, query_text(Query.BorrowLendReserveState));
    field_int(out, "token", token);
    out.push('}');
    return out;
}

fn margin_table(id: i64) -> u8[>..] {
    var out: u8[>..] = [];
    out.push('{');
    json::format_key(out, "type");
    json::format_string(out, query_text(Query.MarginTable));
    field_int(out, "id", id);
    out.push('}');
    return out;
}

fn pre_transfer_check(user: u8[:], source: u8[:]) -> u8[>..] {
    var out: u8[>..] = [];
    out.push('{');
    json::format_key(out, "type");
    json::format_string(out, query_text(Query.PreTransferCheck));
    field_str(out, "user", user);
    field_str(out, "source", source);
    out.push('}');
    return out;
}

fn token_details(token_id: u8[:]) -> u8[>..] {
    var out: u8[>..] = [];
    out.push('{');
    json::format_key(out, "type");
    json::format_string(out, query_text(Query.TokenDetails));
    field_str(out, "tokenId", token_id);
    out.push('}');
    return out;
}

fn request(kind: Query, user: u8[:]) -> u8[>..] {
    var out: u8[>..] = [];
    out.push('{');
    json::format_key(out, "type");
    json::format_string(out, query_text(kind));
    if user.len != 0 {
        out.push(',');
        json::format_key(out, "user");
        json::format_string(out, user);
    }
    out.push('}');
    return out;
}

fn has(text: u8[:], needle: u8[:]) -> bool {
    if needle.len == 0 || needle.len > text.len { return false; }
    for i in 0..(text.len - needle.len + 1) {
        var same = true;
        for j in 0..needle.len {
            if text[i + j] != needle[j] { same = false; }
        }
        if same { return true; }
    }
    return false;
}

fn exchange_ok(text: u8[:]) -> bool {
    if has(text, "\"status\":\"err\"") { return false; }
    return has(text, "\"status\":\"ok\"");
}

fn first_market(text: u8[:]) -> u8[>..], bool {
    var doc: json::Node[>..] = [];
    var decoded: u8[>..] = [];
    let root, err = json::parse(text, doc, decoded);
    if root == null { return [], false; }
    let uni = json::member(root, "universe");
    if uni == null { return [], false; }
    let row = uni.first;
    if row == null { return [], false; }
    let name = json::member(row, "name");
    let s, ok = json::as_string(name);
    if !ok { return [], false; }
    var out: u8[>..] = [];
    out.append(s);
    return out, true;
}

fn asset_ctx(encoded: u8[:]) -> u8[>..], bool {
    var raw: u8[>..] = [];
    if !base64::decode(raw, encoded) { return [], false; }
    return inflate::decode(raw);
}

fn fast_message(text: u8[:]) -> u8[>..], bool {
    var doc: json::Node[>..] = [];
    var decoded: u8[>..] = [];
    let root, err = json::parse(text, doc, decoded);
    if root == null { return [], false; }
    let node = json::member(root, "data");
    let s, ok = json::as_string(node);
    if !ok { return [], false; }
    return asset_ctx(s);
}

// Posts payload, the JSON from request and the other builders.
// A program that calls post declares goose-http and goose-tls in its root file.
fn post(session: http::Session&, chain: hyperliquid::Chain, payload: u8[:]) -> http::ClientResponse, http::Error {
    return http::post(session, hyperliquid::info_url(chain)) { req =>
        http::body(req, "application/json", payload);
    };
}
