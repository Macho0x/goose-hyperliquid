// HIP-1, HIP-3, and HIP-4 deploy actions. Each value is the MessagePack
// map the exchange hashes. Lists are MessagePack arrays the caller built,
// already sorted the way the exchange requires.

import msgpack from "../msgpack";
import msgpack.encode;

namespace deploy;

enum Family { SpotDeploy, ActivateOutcomeDeployer, OutcomeDeploy, PerpDeploy }
enum Text { Absent, Present { text: const u8[:] } }
enum Flag { Absent, No, Yes }
enum Count { Absent, At { n: u64 } }
enum Bytes { Absent, Present { raw: const u8[:] } }

fn family_text(f: Family) -> u8[:] {
    if f == Family.SpotDeploy { return "spotDeploy"; }
    if f == Family.ActivateOutcomeDeployer { return "activateOutcomeDeployer"; }
    if f == Family.OutcomeDeploy { return "outcomeDeploy"; }
    return "perpDeploy";
}

fn text_set(t: Text.Absent) -> bool { return false; }
fn text_set(t: Text.Present) -> bool { return true; }
fn text_of(t: Text.Absent) -> u8[:] { return ""; }
fn text_of(t: Text.Present) -> u8[:] { return t.text; }

fn flag_set(f: Flag.Absent) -> bool { return false; }
fn flag_set(f: Flag.No) -> bool { return true; }
fn flag_set(f: Flag.Yes) -> bool { return true; }

fn count_set(c: Count.Absent) -> bool { return false; }
fn count_set(c: Count.At) -> bool { return true; }
fn count_n(c: Count.Absent) -> u64 { return 0; }
fn count_n(c: Count.At) -> u64 { return c.n; }

fn bytes_set(b: Bytes.Absent) -> bool { return false; }
fn bytes_set(b: Bytes.Present) -> bool { return true; }

fn put_text(out: u8[>..]&, t: Text.Absent) { encode::nil(out); }
fn put_text(out: u8[>..]&, t: Text.Present) { encode::str(out, t.text); }

fn put_count(out: u8[>..]&, c: Count.Absent) { encode::nil(out); }
fn put_count(out: u8[>..]&, c: Count.At) { encode::uint(out, c.n); }

fn put_bytes(out: u8[>..]&, b: Bytes.Absent) { encode::nil(out); }
fn put_bytes(out: u8[>..]&, b: Bytes.Present) { out.append(b.raw); }

fn append_bytes(out: u8[>..]&, b: Bytes.Absent) { return; }
fn append_bytes(out: u8[>..]&, b: Bytes.Present) { out.append(b.raw); }


fn wrap(family: Family, variant: u8[:], body: u8[:]) -> u8[>..] {
    var out: u8[>..] = [];
    encode::map(out, 2);
    encode::str(out, "type");
    encode::str(out, family_text(family));
    encode::str(out, variant);
    out.append(body);
    return out;
}

fn wrap_str(family: Family, variant: u8[:], text: u8[:]) -> u8[>..] {
    var body: u8[>..] = [];
    encode::str(body, text);
    return wrap(family, variant, body);
}

fn wrap_nil(family: Family, variant: u8[:]) -> u8[>..] {
    var body: u8[>..] = [];
    encode::nil(body);
    return wrap(family, variant, body);
}

fn str_pair(out: u8[>..]&, a: u8[:], b: u8[:]) {
    encode::array(out, 2);
    encode::str(out, a);
    encode::str(out, b);
}

fn register_token(name: u8[:], sz: u64, wei: u64, max_gas: u64, full: Text) -> u8[>..] {
    var body: u8[>..] = [];
    if text_set(full) { encode::map(body, 3); } else { encode::map(body, 2); }
    encode::str(body, "spec");
    encode::map(body, 3);
    encode::str(body, "name");
    encode::str(body, name);
    encode::str(body, "szDecimals");
    encode::uint(body, sz);
    encode::str(body, "weiDecimals");
    encode::uint(body, wei);
    encode::str(body, "maxGas");
    encode::uint(body, max_gas);
    if text_set(full) {
        encode::str(body, "fullName");
        encode::str(body, text_of(full));
    }
    return wrap(Family.SpotDeploy, "registerToken2", body);
}

fn user_genesis(token: u64, users: u8[:], existing: u8[:], black: Bytes) -> u8[>..] {
    var body: u8[>..] = [];
    if bytes_set(black) { encode::map(body, 4); } else { encode::map(body, 3); }
    encode::str(body, "token");
    encode::uint(body, token);
    encode::str(body, "userAndWei");
    body.append(users);
    encode::str(body, "existingTokenAndWei");
    body.append(existing);
    if bytes_set(black) {
        encode::str(body, "blacklistUsers");
        append_bytes(body, black);
    }
    return wrap(Family.SpotDeploy, "userGenesis", body);
}

fn genesis(token: u64, max_supply: u8[:], liq: Flag) -> u8[>..] {
    var body: u8[>..] = [];
    if flag_set(liq) { encode::map(body, 3); } else { encode::map(body, 2); }
    encode::str(body, "token");
    encode::uint(body, token);
    encode::str(body, "maxSupply");
    encode::str(body, max_supply);
    if flag_set(liq) {
        encode::str(body, "noHyperliquidity");
        encode::boolean(body, liq == Flag.Yes);
    }
    return wrap(Family.SpotDeploy, "genesis", body);
}

fn register_spot(base: u64, quote: u64) -> u8[>..] {
    var body: u8[>..] = [];
    encode::map(body, 1);
    encode::str(body, "tokens");
    encode::array(body, 2);
    encode::uint(body, base);
    encode::uint(body, quote);
    return wrap(Family.SpotDeploy, "registerSpot", body);
}

fn hyperliquidity(spot: u64, start_px: u8[:], order_sz: u8[:], n_orders: u64, seeded: Count) -> u8[>..] {
    var body: u8[>..] = [];
    if count_set(seeded) { encode::map(body, 5); } else { encode::map(body, 4); }
    encode::str(body, "spot");
    encode::uint(body, spot);
    encode::str(body, "startPx");
    encode::str(body, start_px);
    encode::str(body, "orderSz");
    encode::str(body, order_sz);
    encode::str(body, "nOrders");
    encode::uint(body, n_orders);
    if count_set(seeded) {
        encode::str(body, "nSeededLevels");
        encode::uint(body, count_n(seeded));
    }
    return wrap(Family.SpotDeploy, "registerHyperliquidity", body);
}

fn fee_share(token: u64, share: u8[:]) -> u8[>..] {
    var body: u8[>..] = [];
    encode::map(body, 2);
    encode::str(body, "token");
    encode::uint(body, token);
    encode::str(body, "share");
    encode::str(body, share);
    return wrap(Family.SpotDeploy, "setDeployerTradingFeeShare", body);
}

fn quote_token(enable: bool, token: u64) -> u8[>..] {
    var body: u8[>..] = [];
    encode::map(body, 1);
    encode::str(body, "token");
    encode::uint(body, token);
    if enable { return wrap(Family.SpotDeploy, "enableQuoteToken", body); }
    return wrap(Family.SpotDeploy, "disableQuoteToken", body);
}

fn token_annotation(token: u64, category: u8[:], description: u8[:], display: Text, keywords: u8[:]) -> u8[>..] {
    var body: u8[>..] = [];
    encode::map(body, 2);
    encode::str(body, "token");
    encode::uint(body, token);
    encode::str(body, "annotation");
    encode::map(body, 4);
    encode::str(body, "category");
    encode::str(body, category);
    encode::str(body, "description");
    encode::str(body, description);
    encode::str(body, "displayName");
    put_text(body, display);
    encode::str(body, "keywords");
    body.append(keywords);
    return wrap(Family.SpotDeploy, "setTokenAnnotation", body);
}

fn deployer_label(label: u8[:]) -> u8[>..] {
    var body: u8[>..] = [];
    encode::map(body, 1);
    encode::str(body, "label");
    encode::str(body, label);
    return wrap(Family.SpotDeploy, "setDeployerLabel", body);
}

fn activate_venue(name: u8[:]) -> u8[>..] {
    var body: u8[>..] = [];
    encode::map(body, 1);
    encode::str(body, "venueName");
    encode::str(body, name);
    return wrap(Family.ActivateOutcomeDeployer, "activate", body);
}

fn deactivate_venue() -> u8[>..] { return wrap_nil(Family.ActivateOutcomeDeployer, "deactivate"); }

fn outcome(venue: u8[:], variant: u8[:], body: u8[:]) -> u8[>..] {
    var op: u8[>..] = [];
    encode::map(op, 1);
    encode::str(op, variant);
    op.append(body);
    var out: u8[>..] = [];
    encode::map(out, 3);
    encode::str(out, "type");
    encode::str(out, family_text(Family.OutcomeDeploy));
    encode::str(out, "venue");
    encode::str(out, venue);
    encode::str(out, "operation");
    out.append(op);
    return out;
}

fn template(id: u8[:], keywords: u8[:], fee: u8[:]) -> u8[>..] {
    var body: u8[>..] = [];
    encode::map(body, 3);
    encode::str(body, "id");
    encode::str(body, id);
    encode::str(body, "keywordToValue");
    body.append(keywords);
    encode::str(body, "deployerFeeScale");
    encode::str(body, fee);
    return body;
}

fn named_outcome(id: u8[:], keywords: u8[:]) -> u8[>..] {
    var body: u8[>..] = [];
    encode::map(body, 2);
    encode::str(body, "id");
    encode::str(body, id);
    encode::str(body, "keywordToValue");
    body.append(keywords);
    return body;
}

fn question(question_template: u8[:], named: u8[:]) -> u8[>..] {
    var body: u8[>..] = [];
    encode::map(body, 2);
    encode::str(body, "questionTemplateInstance");
    body.append(question_template);
    encode::str(body, "namedOutcomeTemplateInstances");
    body.append(named);
    return body;
}

fn associate(question_id: u64, named: u8[:]) -> u8[>..] {
    var body: u8[>..] = [];
    encode::map(body, 2);
    encode::str(body, "question");
    encode::uint(body, question_id);
    encode::str(body, "namedOutcomeTemplateInstance");
    body.append(named);
    return body;
}

fn settlement(outcome_id: u64, fraction: u8[:], details: u8[:], name: u8[:], description: u8[:], yes: u8[:], no: u8[:]) -> u8[>..] {
    var body: u8[>..] = [];
    encode::map(body, 5);
    encode::str(body, "outcome");
    encode::uint(body, outcome_id);
    encode::str(body, "settleFraction");
    encode::str(body, fraction);
    encode::str(body, "details");
    encode::str(body, details);
    encode::str(body, "nameAndDescription");
    encode::array(body, 2);
    encode::str(body, name);
    encode::str(body, description);
    encode::str(body, "sideNames");
    encode::array(body, 2);
    encode::str(body, yes);
    encode::str(body, no);
    return body;
}

fn settle_question(question_id: u64, settlements: u8[:], name: u8[:], description: u8[:]) -> u8[>..] {
    var body: u8[>..] = [];
    encode::map(body, 3);
    encode::str(body, "question");
    encode::uint(body, question_id);
    encode::str(body, "outcomeSettlements");
    body.append(settlements);
    encode::str(body, "nameAndDescription");
    encode::array(body, 2);
    encode::str(body, name);
    encode::str(body, description);
    return body;
}

fn halt(coin: u8[:], is_halted: bool) -> u8[>..] {
    var body: u8[>..] = [];
    encode::map(body, 2);
    encode::str(body, "coin");
    encode::str(body, coin);
    encode::str(body, "isHalted");
    encode::boolean(body, is_halted);
    return wrap(Family.PerpDeploy, "haltTrading", body);
}

fn asset_request2(coin: u8[:], sz: u64, oracle: u8[:], margin_id: u64, mode: u8[:]) -> u8[>..] {
    var body: u8[>..] = [];
    encode::map(body, 5);
    encode::str(body, "coin");
    encode::str(body, coin);
    encode::str(body, "szDecimals");
    encode::uint(body, sz);
    encode::str(body, "oraclePx");
    encode::str(body, oracle);
    encode::str(body, "marginTableId");
    encode::uint(body, margin_id);
    encode::str(body, "marginMode");
    encode::str(body, mode);
    return body;
}

fn asset_request(coin: u8[:], sz: u64, oracle: u8[:], margin_id: u64, only_isolated: bool) -> u8[>..] {
    var body: u8[>..] = [];
    encode::map(body, 5);
    encode::str(body, "coin");
    encode::str(body, coin);
    encode::str(body, "szDecimals");
    encode::uint(body, sz);
    encode::str(body, "oraclePx");
    encode::str(body, oracle);
    encode::str(body, "marginTableId");
    encode::uint(body, margin_id);
    encode::str(body, "onlyIsolated");
    encode::boolean(body, only_isolated);
    return body;
}

fn perp_schema(full: u8[:], collateral: u64, updater: Text, star: bool) -> u8[>..] {
    var body: u8[>..] = [];
    if star { encode::map(body, 4); } else { encode::map(body, 3); }
    encode::str(body, "fullName");
    encode::str(body, full);
    encode::str(body, "collateralToken");
    encode::uint(body, collateral);
    encode::str(body, "oracleUpdater");
    put_text(body, updater);
    if star {
        encode::str(body, "isStar");
        encode::boolean(body, true);
    }
    return body;
}

fn register_asset2(gas: Count, request: u8[:], dex: u8[:], schema: Bytes) -> u8[>..] {
    var body: u8[>..] = [];
    encode::map(body, 4);
    encode::str(body, "maxGas");
    put_count(body, gas);
    encode::str(body, "assetRequest");
    body.append(request);
    encode::str(body, "dex");
    encode::str(body, dex);
    encode::str(body, "schema");
    put_bytes(body, schema);
    return wrap(Family.PerpDeploy, "registerAsset2", body);
}

fn register_asset(gas: Count, request: u8[:], dex: u8[:], schema: Bytes) -> u8[>..] {
    var body: u8[>..] = [];
    encode::map(body, 4);
    encode::str(body, "maxGas");
    put_count(body, gas);
    encode::str(body, "assetRequest");
    body.append(request);
    encode::str(body, "dex");
    encode::str(body, dex);
    encode::str(body, "schema");
    put_bytes(body, schema);
    return wrap(Family.PerpDeploy, "registerAsset", body);
}

fn set_oracle(dex: u8[:], oracle_pxs: u8[:], mark_pxs: u8[:], external_pxs: u8[:]) -> u8[>..] {
    var body: u8[>..] = [];
    encode::map(body, 4);
    encode::str(body, "dex");
    encode::str(body, dex);
    encode::str(body, "oraclePxs");
    body.append(oracle_pxs);
    encode::str(body, "markPxs");
    body.append(mark_pxs);
    encode::str(body, "externalPerpPxs");
    body.append(external_pxs);
    return wrap(Family.PerpDeploy, "setOracle", body);
}

fn fee_recipient(dex: u8[:], recipient: u8[:]) -> u8[>..] {
    var body: u8[>..] = [];
    encode::map(body, 2);
    encode::str(body, "dex");
    encode::str(body, dex);
    encode::str(body, "feeRecipient");
    encode::str(body, recipient);
    return wrap(Family.PerpDeploy, "setFeeRecipient", body);
}

fn sub_deployers(dex: u8[:], rows: u8[:]) -> u8[>..] {
    var body: u8[>..] = [];
    encode::map(body, 2);
    encode::str(body, "dex");
    encode::str(body, dex);
    encode::str(body, "subDeployers");
    body.append(rows);
    return wrap(Family.PerpDeploy, "setSubDeployers", body);
}

fn sub_row(out: u8[>..]&, variant: u8[:], user: u8[:], allowed: bool) {
    encode::map(out, 3);
    encode::str(out, "variant");
    encode::str(out, variant);
    encode::str(out, "user");
    encode::str(out, user);
    encode::str(out, "allowed");
    encode::boolean(out, allowed);
}

fn sub_row_hip3(out: u8[>..]&, action: u8[:], user: u8[:], allowed: bool) {
    encode::map(out, 3);
    encode::str(out, "variant");
    encode::map(out, 1);
    encode::str(out, "hip3Star");
    encode::str(out, action);
    encode::str(out, "user");
    encode::str(out, user);
    encode::str(out, "allowed");
    encode::boolean(out, allowed);
}

fn fee_row(out: u8[>..]&, coin: u8[:], scale: u8[:], growth: bool) {
    encode::array(out, 2);
    encode::str(out, coin);
    encode::map(out, 2);
    encode::str(out, "scale");
    encode::str(out, scale);
    encode::str(out, "growthMode");
    encode::boolean(out, growth);
}

fn perp_annotation(coin: u8[:], category: u8[:], description: u8[:], display: Text, keywords: u8[:]) -> u8[>..] {
    var body: u8[>..] = [];
    encode::map(body, 5);
    encode::str(body, "coin");
    encode::str(body, coin);
    encode::str(body, "category");
    encode::str(body, category);
    encode::str(body, "description");
    encode::str(body, description);
    encode::str(body, "displayName");
    put_text(body, display);
    encode::str(body, "keywords");
    body.append(keywords);
    return wrap(Family.PerpDeploy, "setPerpAnnotation", body);
}

fn margin_tier(out: u8[>..]&, lower: u64, max_leverage: u64) {
    encode::map(out, 2);
    encode::str(out, "lowerBound");
    encode::uint(out, lower);
    encode::str(out, "maxLeverage");
    encode::uint(out, max_leverage);
}

fn insert_margin_table(dex: u8[:], description: u8[:], tiers: u8[:]) -> u8[>..] {
    var body: u8[>..] = [];
    encode::map(body, 2);
    encode::str(body, "dex");
    encode::str(body, dex);
    encode::str(body, "marginTable");
    encode::map(body, 2);
    encode::str(body, "description");
    encode::str(body, description);
    encode::str(body, "marginTiers");
    body.append(tiers);
    return wrap(Family.PerpDeploy, "insertMarginTable", body);
}

fn disable_dex(name: u8[:]) -> u8[>..] { return wrap_str(Family.PerpDeploy, "disableDex", name); }

fn star_oracle(dex: u8[:], oracle_pxs: u8[:]) -> u8[>..] {
    var inner: u8[>..] = [];
    encode::map(inner, 1);
    encode::str(inner, "oraclePxs");
    inner.append(oracle_pxs);
    var op: u8[>..] = [];
    encode::map(op, 1);
    encode::str(op, "setOracle");
    op.append(inner);
    var body: u8[>..] = [];
    encode::map(body, 2);
    encode::str(body, "dex");
    encode::str(body, dex);
    encode::str(body, "operation");
    body.append(op);
    return wrap(Family.PerpDeploy, "star", body);
}

fn star_proxy(dex: u8[:], user: u8[:], inner: u8[:]) -> u8[>..] {
    var proxy: u8[>..] = [];
    encode::array(proxy, 2);
    encode::str(proxy, user);
    proxy.append(inner);
    var op: u8[>..] = [];
    encode::map(op, 1);
    encode::str(op, "proxy");
    op.append(proxy);
    var body: u8[>..] = [];
    encode::map(body, 2);
    encode::str(body, "dex");
    encode::str(body, dex);
    encode::str(body, "operation");
    body.append(op);
    return wrap(Family.PerpDeploy, "star", body);
}

fn star_flag(dex: u8[:], user: u8[:], name: u8[:], value: bool) -> u8[>..] {
    var inner: u8[>..] = [];
    encode::map(inner, 1);
    encode::str(inner, name);
    encode::boolean(inner, value);
    return star_proxy(dex, user, inner);
}

fn star_send(dex: u8[:], user: u8[:], destination: u8[:], amount: u8[:]) -> u8[>..] {
    var send: u8[>..] = [];
    encode::map(send, 2);
    encode::str(send, "destination");
    encode::str(send, destination);
    encode::str(send, "amount");
    encode::str(send, amount);
    var inner: u8[>..] = [];
    encode::map(inner, 1);
    encode::str(inner, "sendAsset");
    inner.append(send);
    return star_proxy(dex, user, inner);
}

fn star_cancel_all(dex: u8[:], user: u8[:], assets: Bytes) -> u8[>..] {
    var cancel: u8[>..] = [];
    encode::map(cancel, 1);
    encode::str(cancel, "assets");
    put_bytes(cancel, assets);
    var kind: u8[>..] = [];
    encode::map(kind, 1);
    encode::str(kind, "cancelAll");
    kind.append(cancel);
    var proxy: u8[>..] = [];
    encode::array(proxy, 2);
    encode::str(proxy, user);
    proxy.append(kind);
    var op: u8[>..] = [];
    encode::map(op, 1);
    encode::str(op, "proxy");
    op.append(proxy);
    var body: u8[>..] = [];
    encode::map(body, 2);
    encode::str(body, "dex");
    encode::str(body, dex);
    encode::str(body, "operation");
    body.append(op);
    return wrap(Family.PerpDeploy, "star", body);
}
