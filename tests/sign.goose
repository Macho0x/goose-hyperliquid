import os;
import decimal from "../../decimal";
import hyperliquid from "..";
import hyperliquid.wire;
import hyperliquid.sign;
import msgpack from "../../msgpack";
import msgpack.encode;
import crypto from "../../crypto";
import crypto.keccak256;
import signature from "../../signature";
import signature.eip712;

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
    s.push('0');
    s.push('x');
    for i in 0..b.len {
        s.push(hex_digit(b[i] >> 4));
        s.push(hex_digit(b[i] & 0x0f));
    }
    return s;
}

fn need(got: u8[:], want: u8[:], why: u8[:]) {
    if got != want { fail(why); }
}

fn push_str(out: u8[>..]&, s: u8[:]) { out.append(keccak256::hash(s)); }

fn push_addr(out: u8[>..]&, text: u8[:]) {
    let raw, ok = wire::parse_address(text);
    if !ok { fail("address"); }
    let word, wok = eip712::word_address(raw);
    if !wok { fail("word"); }
    out.append(word);
}

fn push_u64(out: u8[>..]&, v: u64) { out.append(sign::word_u64(v)); }

fn push_bool(out: u8[>..]&, v: bool) {
    if v { push_u64(out, 1); } else { push_u64(out, 0); }
}

fn borrow(out: u8[>..]&) {
    encode::map(out, 4);
    encode::str(out, "type");
    encode::str(out, "borrowLend");
    encode::str(out, "operation");
    encode::str(out, "supply");
    encode::str(out, "token");
    encode::uint(out, 0);
    encode::str(out, "amount");
    encode::str(out, "10");
}

fn l1_body() -> u8[>..] {
    var out: u8[>..] = [];
    encode::array(out, 3);
    encode::str(out, "0x1111111111111111111111111111111111111111");
    encode::str(out, "0x7e5f4552091a69125d5dfcb7b8c2659029395bdf");
    borrow(out);
    return out;
}

fn check_l1(mainnet: bool, has_vault: bool, has_expiry: bool, want: u8[:], why: u8[:]) {
    let body = l1_body();
    var raw: u8[20] = [0x22; 20];
    if mainnet {
        run_l1(hyperliquid::Chain.Mainnet, body, raw, has_vault, has_expiry, want, why);
        return;
    }
    run_l1(hyperliquid::Chain.Testnet, body, raw, has_vault, has_expiry, want, why);
}

fn run_l1(chain: hyperliquid::Chain, body: u8[:], raw: u8[:], has_vault: bool, has_expiry: bool, want: u8[:], why: u8[:]) {
    if has_vault {
        if has_expiry {
            let dig, ok = sign::l1_prehash(body, 1700000000000, sign::Vault.Present { addr: raw }, sign::Expiry.At { time: 1700000010000 }, chain);
            if !ok { fail(why); }
            need(hex(dig), want, why);
            return;
        }
        let dig, ok = sign::l1_prehash(body, 1700000000000, sign::Vault.Present { addr: raw }, sign::Expiry.Absent, chain);
        if !ok { fail(why); }
        need(hex(dig), want, why);
        return;
    }
    if has_expiry {
        let dig, ok = sign::l1_prehash(body, 1700000000000, sign::Vault.Absent, sign::Expiry.At { time: 1700000010000 }, chain);
        if !ok { fail(why); }
        need(hex(dig), want, why);
        return;
    }
    let dig, ok = sign::l1_prehash(body, 1700000000000, sign::Vault.Absent, sign::Expiry.Absent, chain);
    if !ok { fail(why); }
    need(hex(dig), want, why);
}

const APPROVE: u8[:] = "HyperliquidTransaction:ApproveAgent(string hyperliquidChain,address agentAddress,string agentName,uint64 nonce)";
const APPROVE_MS: u8[:] = "HyperliquidTransaction:ApproveAgent(string hyperliquidChain,address payloadMultiSigUser,address outerSigner,address agentAddress,string agentName,uint64 nonce)";
const DELEGATE: u8[:] = "HyperliquidTransaction:TokenDelegate(string hyperliquidChain,address validator,uint64 wei,bool isUndelegate,uint64 nonce)";
const DELEGATE_MS: u8[:] = "HyperliquidTransaction:TokenDelegate(string hyperliquidChain,address payloadMultiSigUser,address outerSigner,address validator,uint64 wei,bool isUndelegate,uint64 nonce)";
const USD: u8[:] = "HyperliquidTransaction:UsdSend(string hyperliquidChain,string destination,string amount,uint64 time)";

fn approve_fields(chain: u8[:], name: u8[:], multi: bool) -> u8[>..] {
    var f: u8[>..] = [];
    push_str(f, chain);
    if multi {
        push_addr(f, "0x1111111111111111111111111111111111111111");
        push_addr(f, "0x7e5f4552091a69125d5dfcb7b8c2659029395bdf");
    }
    push_addr(f, "0x2222222222222222222222222222222222222222");
    push_str(f, name);
    push_u64(f, 1700000000000);
    return f;
}

fn delegate_fields(chain: u8[:], undel: bool, multi: bool) -> u8[>..] {
    var f: u8[>..] = [];
    push_str(f, chain);
    if multi {
        push_addr(f, "0x1111111111111111111111111111111111111111");
        push_addr(f, "0x7e5f4552091a69125d5dfcb7b8c2659029395bdf");
    }
    push_addr(f, "0x2222222222222222222222222222222222222222");
    push_u64(f, 100000000);
    push_bool(f, undel);
    push_u64(f, 1700000000000);
    return f;
}

fn check_user(type_str: u8[:], fields: u8[:], chain_id: u64, want: u8[:], why: u8[:]) {
    let dig, ok = sign::user_prehash(type_str, fields, chain_id);
    if !ok { fail(why); }
    need(hex(dig), want, why);
}

fn hex_byte(s: u8[:], at: i64) -> u8, bool {
    if at + 1 >= s.len { return 0, false; }
    let hi = s[at];
    let lo = s[at + 1];
    fn nib(c: u8) -> u8, bool {
        if c >= '0' && c <= '9' { return c - '0', true; }
        if c >= 'a' && c <= 'f' { return c - 'a' + 10, true; }
        if c >= 'A' && c <= 'F' { return c - 'A' + 10, true; }
        return 0, false;
    }
    let h, hok = nib(hi);
    let l, lok = nib(lo);
    if !hok || !lok { return 0, false; }
    return (h << 4) | l, true;
}

fn parse_hex(s: u8[:]) -> u8[>..], bool {
    var o: u8[>..] = [];
    var i: i64 = 0;
    if s.len >= 2 && s[0] == '0' && s[1] == 'x' { i = 2; }
    if (s.len - i) % 2 != 0 { return o, false; }
    while i < s.len {
        let b, ok = hex_byte(s, i);
        if !ok { return o, false; }
        o.push(b);
        i += 2;
    }
    return o, true;
}

fn self_check() -> bool {
    var raw: u8[>..] = [];
    if !read_file("tests/signing.json", raw) { return false; }
    if raw.len < 1000 { return false; }

    let ten, tok = wire::normalize("10.0");
    if !tok || ten != "10" { return false; }
    let bad, bok = wire::normalize("nope");
    if bok { return false; }

    let body = l1_body();
    check_l1(true, false, false, "0x6719c910a8a11cb08d08706bbb154b1161746de99e6e91d75a193c5e9ea75522", "l1 main");
    check_l1(true, false, true, "0x0d9bbcfb2384c121b704f42eeee718b8c3d4d865736dcd891ed8781f7af24a39", "l1 exp");
    check_l1(true, true, false, "0x0dfccae36d1dd112dfd3dc7489d2469e1932280fb324a7bdc69698254d47d059", "l1 vault");
    check_l1(true, true, true, "0x555c4f5ebc368d55e33bdd0a30d3cf1ab497f4de0869b647c1b547778f65791b", "l1 both");
    check_l1(false, false, false, "0x23cf72fc8a2be4bb15abe17d0d8b5d75e9ccf5e33ed9c8e655acd2968bc50c9f", "l1 t");
    check_l1(false, false, true, "0xf73444b220b3b1b4883548f5cc2216af143b46fb6bb55c8d3228b62750756211", "l1 t exp");
    check_l1(false, true, false, "0x3a741b191d81e941947a8af748b69284e4098ba15cc755aa611df9e14c9c30ce", "l1 t vault");
    check_l1(false, true, true, "0xb2f34c6283c7a4ca5fb69d796a9345a9b5bf4437cf2c72ba939b23a8704faad0", "l1 t both");

    let a0 = approve_fields("Mainnet", "", false);
    check_user(APPROVE, a0, 42161, "0x176dd3681d458eba5ff77b764519c64fa805f7482b02d1b9bd8827efca89f6f1", "approve empty");
    let a1 = approve_fields("Mainnet", "bot", false);
    check_user(APPROVE, a1, 42161, "0xea39a22e632c9783cb895bde19886275fe72501f6b036b954304baa396498396", "approve bot");
    let a2 = approve_fields("Mainnet", "", true);
    check_user(APPROVE_MS, a2, 42161, "0x948bdc31d8263a4e02c743fda4c3e2ade22d89e851478163eec2d6a366a09587", "approve ms");
    let a3 = approve_fields("Mainnet", "bot", true);
    check_user(APPROVE_MS, a3, 42161, "0x06471c13d62aa942bafa0e856ed7d1899e24bad7c018b7083a64adde3f60ccfa", "approve bot ms");
    let a4 = approve_fields("Testnet", "", false);
    check_user(APPROVE, a4, 421614, "0x4a3a14711073d93105a9643d60837a2118ef7984fa7c8a53fc8dd660fb776f33", "approve t");
    let a5 = approve_fields("Testnet", "bot", false);
    check_user(APPROVE, a5, 421614, "0x3e2d91f3170aae67a8984753e79a83eeed7d011a39e1d585e45efea40e29c179", "approve t bot");
    let a6 = approve_fields("Testnet", "", true);
    check_user(APPROVE_MS, a6, 421614, "0xc8ae2e609f895382688c523fe5f7d03fc22a34a6401c66a156c62590e14b83bb", "approve t ms");
    let a7 = approve_fields("Testnet", "bot", true);
    check_user(APPROVE_MS, a7, 421614, "0xb7396bdabe55fd1c7cf439432255cc6a401e18474385c3c7cf22f1469549fbf5", "approve t bot ms");

    let d0 = delegate_fields("Mainnet", false, false);
    check_user(DELEGATE, d0, 42161, "0x62ce21959e335ce054541f50ba346d465355e448400df388c5fb542f91dcca41", "del");
    let d1 = delegate_fields("Mainnet", true, false);
    check_user(DELEGATE, d1, 42161, "0x7012cbad22ee270b269ba39b3b5fc01ed536d0ce82f53149328cc4fe5b18df47", "undel");
    let d2 = delegate_fields("Mainnet", false, true);
    check_user(DELEGATE_MS, d2, 42161, "0x5e3486e6e610cb64b9ccdbcf5359127cb63d75b33b7ac0a3ceffcee8305e3685", "del ms");
    let d3 = delegate_fields("Mainnet", true, true);
    check_user(DELEGATE_MS, d3, 42161, "0x06871adfb91a992e96e5db604332b92ae7279f1c155e1f0ef73d5a48e93872e9", "undel ms");
    let d4 = delegate_fields("Testnet", false, false);
    check_user(DELEGATE, d4, 421614, "0xb4c3f6517add1baad0e7be1101cab377ca318d971ac7ef9450a145ce14dab6c9", "del t");
    let d5 = delegate_fields("Testnet", true, false);
    check_user(DELEGATE, d5, 421614, "0x434be21844df075c4acd848af4d5319d1224726a5b365ed6103e7162ddaef530", "undel t");
    let d6 = delegate_fields("Testnet", false, true);
    check_user(DELEGATE_MS, d6, 421614, "0x030ab7b29963dcd525ff5038ba9a5b5e5f03275cb8321054b98334db6409f113", "del t ms");
    let d7 = delegate_fields("Testnet", true, true);
    check_user(DELEGATE_MS, d7, 421614, "0x34c1090faad92119e120dbbb9ee49923008012995646e9f4c6410392cdbc7576", "undel t ms");

    var usd: u8[>..] = [];
    push_str(usd, "Mainnet");
    push_str(usd, "0x0d1d9635d0640821d15e323ac8adadfa9c111414");
    push_str(usd, "1");
    push_u64(usd, 1690393044548);
    let key, kok = parse_hex("e908f86dbb4d55ac876378565aafeabc187f6690f046459397b17d9b9a19688e");
    if !kok || key.len != 32 { return false; }
    let sig, sok = sign::sign_user(key, USD, usd, 42161);
    if !sok { return false; }
    need(hex(sig), "0xeca6267bcaadc4c0ae1aed73f5a2c45fcdbb7271f2e9356992404e5d4bad75a3572e08fe93f17755abadb7f84be7d1e9c4ce48bb5633e339bc430c672d5a20ed1b", "usd sig");

    if hyperliquid::Chain.Mainnet == hyperliquid::Chain.Testnet { return false; }
    return true;
}

fn ::main() {
    if self_check() { print("sign ok"); } else { fail("sign"); }
}
