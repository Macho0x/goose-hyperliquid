import os;
import msgpack from "../../msgpack";
import msgpack.encode;
import crypto from "../../crypto";
import crypto.keccak256;
import signature from "../../signature";
import signature.eip712;
import decimal from "../../decimal";
import hyperliquid from "..";
import hyperliquid.wire;
import hyperliquid.sign;
import hyperliquid.l1;
import hyperliquid.order;
import hyperliquid.deploy;

fn fail(why: u8[:]) {
    write_stdout(why);
    write_stdout("\n");
    exit(1);
}

fn hex_digit(v: u8) -> u8 {
    if v < 10 { return '0' + v; }
    return 'a' + (v - 10);
}

fn hex(b: u8[:]) -> u8[>..] {
    var s: u8[>..] = [];
    for i in 0..b.len {
        s.push(hex_digit(b[i] >> 4));
        s.push(hex_digit(b[i] & 0x0f));
    }
    return s;
}

fn line(out: u8[>..]&, name: u8[:], body: u8[:]) {
    out.append(name);
    out.push(9);
    out.append(hex(body));
    out.push('\n');
}

fn users() -> u8[>..] {
    var a: u8[>..] = [];
    encode::array(a, 1);
    deploy::str_pair(a, "0x2222222222222222222222222222222222222222", "10");
    return a;
}

fn existing() -> u8[>..] {
    var a: u8[>..] = [];
    encode::array(a, 1);
    encode::array(a, 2);
    encode::uint(a, 0);
    encode::str(a, "5");
    return a;
}

fn one_pair() -> u8[>..] {
    var a: u8[>..] = [];
    encode::array(a, 1);
    deploy::str_pair(a, "BTC", "1");
    return a;
}

fn marks() -> u8[>..] {
    var inner: u8[>..] = [];
    encode::array(inner, 1);
    deploy::str_pair(inner, "BTC", "1");
    var a: u8[>..] = [];
    encode::array(a, 1);
    a.append(inner);
    return a;
}

fn interest() -> u8[>..] {
    var a: u8[>..] = [];
    encode::array(a, 1);
    deploy::str_pair(a, "BTC", "0.0001");
    return a;
}

fn margin_ids() -> u8[>..] {
    var a: u8[>..] = [];
    encode::array(a, 1);
    encode::array(a, 2);
    encode::str(a, "BTC");
    encode::uint(a, 1);
    return a;
}

fn caps() -> u8[>..] {
    var a: u8[>..] = [];
    encode::array(a, 1);
    encode::array(a, 2);
    encode::str(a, "BTC");
    encode::uint(a, 1000000);
    return a;
}

fn modes() -> u8[>..] {
    var a: u8[>..] = [];
    encode::array(a, 1);
    deploy::str_pair(a, "BTC", "noCross");
    return a;
}

fn fees() -> u8[>..] {
    var a: u8[>..] = [];
    encode::array(a, 1);
    deploy::fee_row(a, "BTC", "1", false);
    return a;
}

fn keywords() -> u8[>..] {
    var a: u8[>..] = [];
    encode::array(a, 1);
    deploy::str_pair(a, "year", "2026");
    return a;
}

fn side_keys() -> u8[>..] {
    var a: u8[>..] = [];
    encode::array(a, 1);
    deploy::str_pair(a, "side", "yes");
    return a;
}

fn bird() -> u8[>..] {
    var a: u8[>..] = [];
    encode::array(a, 1);
    encode::str(a, "bird");
    return a;
}

fn empty() -> u8[>..] {
    var a: u8[>..] = [];
    encode::array(a, 0);
    return a;
}

fn named_list() -> u8[>..] {
    var a: u8[>..] = [];
    encode::array(a, 1);
    a.append(deploy::named_outcome("n1", side_keys()));
    return a;
}

fn one_settlement() -> u8[>..] {
    var a: u8[>..] = [];
    encode::array(a, 1);
    a.append(deploy::settlement(7, "1", "", "name", "desc", "yes", "no"));
    return a;
}

fn outcome_subs() -> u8[>..] {
    var a: u8[>..] = [];
    encode::array(a, 1);
    deploy::sub_row(a, "settleOutcome", "0x2222222222222222222222222222222222222222", true);
    return a;
}

fn perp_subs() -> u8[>..] {
    var a: u8[>..] = [];
    encode::array(a, 1);
    deploy::sub_row_hip3(a, "order", "0x2222222222222222222222222222222222222222", true);
    return a;
}

fn tiers() -> u8[>..] {
    var a: u8[>..] = [];
    encode::array(a, 1);
    deploy::margin_tier(a, 0, 10);
    return a;
}

fn sigs() -> u8[>..] {
    var a: u8[>..] = [];
    encode::array(a, 1);
    l1::one_signature(a, "0x1", "0x2", 27);
    return a;
}

fn dump() -> u8[>..] {
    let who = "0x2222222222222222222222222222222222222222";
    var out: u8[>..] = [];
    line(out, "lev", l1::update_leverage(1, l1::Margin.Cross, 5));
    line(out, "iso", l1::update_isolated_margin(1, l1::Side.Buy, 1000000));
    line(out, "vault", l1::vault_transfer(who, l1::Flow.Deposit, 1000000));
    line(out, "sched0", l1::schedule_cancel(l1::When.Never));
    line(out, "sched1", l1::schedule_cancel(l1::When.At { time: 1700000000000 }));
    line(out, "noop", l1::noop());
    line(out, "borrow", l1::borrow_lend("supply", 0, "10"));
    line(out, "borrow_max", l1::borrow_lend_max("borrow", 1));
    line(out, "agent_asset", l1::agent_send_asset(who, "spot", "", "USDC:0x1", "10", "", 1));
    line(out, "evm_user", l1::evm_user_modify(true));
    line(out, "gossip", l1::gossip_priority_bid(1, "1.2.3.4", 1000));
    line(out, "dex_abs", l1::agent_enable_dex_abstraction());
    line(out, "agent_abs", l1::agent_set_abstraction("u"));
    line(out, "twap", l1::twap_order(3, l1::Side.Buy, "1.5", l1::Reduce.Open, 30, true));
    line(out, "twap_cancel", l1::twap_cancel(3, 9));
    line(out, "trail_pct", l1::trailing_pct(1, l1::Side.Buy, "2", l1::Reduce.Open, "1.5%"));
    line(out, "trail_px", l1::trailing_px(1, l1::Side.Sell, "2", l1::Reduce.ReduceOnly, "10", "100"));
    line(out, "cdep", l1::c_deposit(1000));
    line(out, "cwdr", l1::c_withdraw(1000));
    line(out, "reserve0", l1::reserve_weight(4, l1::Text.Absent));
    line(out, "reserve1", l1::reserve_weight(4, l1::Text.Present { text: who }));
    line(out, "hip3", l1::hip3_transfer("abcd", 1000000000, l1::Flow.Deposit));
    line(out, "split", l1::outcome_split(7, "10"));
    line(out, "merge_max", l1::outcome_merge(7, l1::Text.Absent));
    line(out, "merge_q", l1::outcome_merge_question(3, l1::Text.Present { text: "1" }));
    line(out, "negate", l1::outcome_negate(3, 7, "2"));
    line(out, "topup", l1::top_up_isolated(1, "5"));
    line(out, "claim", l1::claim_rewards());
    line(out, "aqa", l1::authorize_aqav2(0, "technical"));
    line(out, "aqa_t", l1::authorize_aqav2(1, "treasury"));
    line(out, "rate", l1::validator_stream("0.04"));
    line(out, "sub_new", l1::create_sub_account("alpha"));
    line(out, "sub_mod", l1::sub_account_modify(who, "beta"));
    line(out, "sub_usd", l1::sub_account_transfer(who, l1::Flow.Deposit, 5));
    line(out, "sub_spot", l1::sub_account_spot(who, l1::Flow.Withdraw, "USDC:0x1", "1.25"));
    line(out, "vault_new", l1::create_vault("goose", "a small vault", 100000000, 1));
    line(out, "vault_mod", l1::vault_modify(who, l1::Flag.Yes, l1::Flag.Absent));
    line(out, "vault_mod_both", l1::vault_modify(who, l1::Flag.No, l1::Flag.Yes));
    line(out, "vault_dist", l1::vault_distribute(who, 10));
    line(out, "display", l1::set_display_name("goose"));
    line(out, "referrer", l1::set_referrer("GOOSE"));
    line(out, "register_ref", l1::register_referrer("GOOSE"));
    line(out, "jail", l1::jail_self());
    line(out, "unjail", l1::unjail_self());
    line(out, "unregister", l1::validator_unregister());
    line(out, "register_val", l1::validator_register("1.2.3.4", "goose", "node", false, 100, who, true, 1000));
    line(out, "change_profile", l1::validator_change(l1::Text.Absent, l1::Text.Present { text: "goose" }, l1::Text.Absent, true, l1::Flag.Absent, l1::Count.Absent, l1::Text.Absent));
    line(out, "finalize_create", l1::finalize_create(1, 4));
    line(out, "finalize_first", l1::finalize_slot(1, "firstStorageSlot"));
    line(out, "finalize_custom", l1::finalize_slot(2, "customStorageSlot"));
    line(out, "cancel_cloid", order::cancel_cloid(1, "0x00000000000000000000000000000001"));
    line(out, "cancel_fast", order::cancel_fast(1, 9));
    let mod0, m0 = order::batch_modify(9, "50000", "0.1", false);
    if !m0 { fail("batch"); }
    line(out, "batch_mod", mod0);
    let mod1, m1 = order::batch_modify(9, "50000", "0.1", true);
    if !m1 { fail("batch a"); }
    line(out, "batch_mod_a", mod1);
    let trig, tok = order::trigger(1, order::Side.Sell, "10", "1", order::Reduce.ReduceOnly, true, "9.5", "sl");
    if !tok { fail("trigger"); }
    line(out, "trigger", trig);
    line(out, "multisig", l1::multi_sig("0x66eee", sigs(), "0x1111111111111111111111111111111111111111", who, l1::noop()));
    line(out, "spot_reg", deploy::register_token("GOOSE", 2, 8, 1000, deploy::Text.Present { text: "Goose" }));
    line(out, "spot_users", deploy::user_genesis(1, users(), existing(), deploy::Bytes.Absent));
    line(out, "spot_gen", deploy::genesis(1, "100", deploy::Flag.Yes));
    line(out, "spot_pair", deploy::register_spot(1, 0));
    line(out, "spot_hl", deploy::hyperliquidity(1, "1", "1", 1, deploy::Count.Absent));
    line(out, "spot_fee", deploy::fee_share(1, "1%"));
    line(out, "spot_quote", deploy::quote_token(true, 1));
    line(out, "spot_unquote", deploy::quote_token(false, 1));
    line(out, "spot_note", deploy::token_annotation(1, "cat", "desc", deploy::Text.Present { text: "G" }, bird()));
    line(out, "spot_label", deploy::deployer_label("gs"));
    line(out, "out_on", deploy::activate_venue("gs"));
    line(out, "out_off", deploy::deactivate_venue());
    line(out, "out_standalone", deploy::outcome("gs", "registerStandaloneOutcomeFromTemplate", deploy::template("t1", keywords(), "1")));
    line(out, "out_question", deploy::outcome("gs", "registerQuestionFromTemplate", deploy::question(deploy::template("t1", keywords(), "1"), named_list())));
    line(out, "out_add", deploy::outcome("gs", "registerAndAssociateNamedOutcomeFromTemplate", deploy::associate(3, deploy::named_outcome("n1", side_keys()))));
    line(out, "out_settle", deploy::outcome("gs", "settleOutcome", deploy::settlement(7, "1", "", "name", "desc", "yes", "no")));
    line(out, "out_settle_q", deploy::outcome("gs", "settleQuestion2", deploy::settle_question(3, one_settlement(), "q", "d")));
    line(out, "out_subs", deploy::outcome("gs", "setSubDeployers", outcome_subs()));
    line(out, "perp_halt", deploy::halt("abcd:BTC", true));
    line(out, "perp_asset2", deploy::register_asset2(deploy::Count.Absent, deploy::asset_request2("BTC", 5, "1", 1, "normal"), "abcd", deploy::Bytes.Absent));
    line(out, "perp_asset", deploy::register_asset(deploy::Count.At { n: 10 }, deploy::asset_request("BTC", 5, "1", 1, false), "abcd", deploy::Bytes.Present { raw: deploy::perp_schema("Goose", 0, deploy::Text.Absent, false) }));
    line(out, "perp_oracle", deploy::set_oracle("abcd", one_pair(), marks(), one_pair()));
    line(out, "perp_fund", deploy::wrap(deploy::Family.PerpDeploy, "setFundingMultipliers", one_pair()));
    line(out, "perp_interest", deploy::wrap(deploy::Family.PerpDeploy, "setFundingInterestRates", interest()));
    line(out, "perp_margin_ids", deploy::wrap(deploy::Family.PerpDeploy, "setMarginTableIds", margin_ids()));
    line(out, "perp_fee_to", deploy::fee_recipient("abcd", who));
    line(out, "perp_caps", deploy::wrap(deploy::Family.PerpDeploy, "setOpenInterestCaps", caps()));
    line(out, "perp_subs", deploy::sub_deployers("abcd", perp_subs()));
    line(out, "perp_modes", deploy::wrap(deploy::Family.PerpDeploy, "setMarginModes", modes()));
    line(out, "perp_fees", deploy::wrap(deploy::Family.PerpDeploy, "setDeployerFees", fees()));
    line(out, "perp_note", deploy::perp_annotation("abcd:BTC", "cat", "desc", deploy::Text.Absent, empty()));
    line(out, "perp_table", deploy::insert_margin_table("abcd", "tiers", tiers()));
    line(out, "perp_off", deploy::disable_dex("abcd"));
    line(out, "star_oracle", deploy::star_oracle("abcd", one_pair()));
    line(out, "star_proxy", deploy::star_cancel_all("abcd", who, deploy::Bytes.Absent));
    let built, bok = order::with_builder("50000", "0.1", who, 10);
    if !bok { fail("builder"); }
    line(out, "builder", built);
    line(out, "star_bool", deploy::star_flag("abcd", who, "modifyApproval", true));
    line(out, "star_send", deploy::star_send("abcd", who, who, "1"));
    let cloid, cok = order::with_cloid("50000", "0.1", "0x00000000000000000000000000000001");
    if !cok { fail("cloid"); }
    line(out, "cloid", cloid);
    return out;
}

fn ::main() {
    var want: u8[>..] = [];
    if !read_file("tests/actions.hex", want) { fail("missing actions.hex"); }
    let got = dump();
    if got != want {
        write_stdout(got);
        fail("actions");
    }
    print("actions ok");
}
