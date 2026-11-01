import os;
import decimal from "../../decimal";
import crypto from "../../crypto";
import crypto.keccak256;
import signature from "../../signature";
import signature.eip712;
import hyperliquid from "..";
import hyperliquid.wire;
import hyperliquid.sign;
import hyperliquid.user;

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

fn addr(s: u8[:]) -> u8[20] {
    let a, ok = wire::parse_address(s);
    if !ok { fail("addr"); }
    return a;
}

fn self_check() -> bool {
    let a = addr("0x2222222222222222222222222222222222222222");
    let ms = addr("0x1111111111111111111111111111111111111111");
    let lead = addr("0x7e5f4552091a69125d5dfcb7b8c2659029395bdf");
    let usd, uok = user::usd_send(hyperliquid::Chain.Mainnet, "0x2222222222222222222222222222222222222222", "10", 1, 42161);
    if !uok { return false; }
    need(hex(usd), "0x8a47eda2c73e2cf7dda1a5e3bc6c8a84b3422fa6571b7f1f2bd3721f00e50f07", "usd");
    let wd, wok = user::withdraw(hyperliquid::Chain.Mainnet, "0x2222222222222222222222222222222222222222", "10", 1, 42161);
    if !wok { return false; }
    need(hex(wd), "0x6dc199d98bbd9278585428ea8f35233350f7d56e7054921f14737cc070401b73", "withdraw");
    let sp, sok = user::spot_send(hyperliquid::Chain.Mainnet, "0x2222222222222222222222222222222222222222", "USDC:0x1", "10", 1, 42161);
    if !sok { return false; }
    need(hex(sp), "0xe359af78c51f651b607ec95bfacc2b3a4086146131ac1ccb2ddf442890a61d59", "spot");
    let bf, bok = user::approve_builder_fee(hyperliquid::Chain.Mainnet, "0.001%", a, 1700000000000, 42161);
    if !bok { return false; }
    need(hex(bf), "0xd9fc264416c8bba833a01f345ad8e6e2942b70058e7f6ac85efc64a48c81b22d", "builder");
    let cl, cok = user::usd_class_transfer(hyperliquid::Chain.Mainnet, "10", true, 1700000000000, 42161);
    if !cok { return false; }
    need(hex(cl), "0x36de6bd840a720d21970219e4b511ea61cb3d5ce404b812de1e07f9e1dd4c5f3", "class");
    let asset, aok = user::send_asset(hyperliquid::Chain.Mainnet, "0x2222222222222222222222222222222222222222", "spot", "", "USDC:0x1", "10", "", 1700000000000, 42161);
    if !aok { return false; }
    need(hex(asset), "0xbffcdcc74e5b9ac6f23935385d5595e96332bc0832551f003819223e7039a7ab", "asset");
    let empty, eok = user::approve_agent(hyperliquid::Chain.Mainnet, a, "", 1700000000000, 42161, false, ms, lead);
    if !eok { return false; }
    need(hex(empty), "0x176dd3681d458eba5ff77b764519c64fa805f7482b02d1b9bd8827efca89f6f1", "empty name");
    let multi, mok = user::approve_agent(hyperliquid::Chain.Mainnet, a, "", 1, 42161, true, ms, lead);
    if !mok { return false; }
    need(hex(multi), "0x60d9d318e32743304a732f808d06acaca3b0a085689fb9ee41b8fdd8d8924486", "multisig fields");
    if user::has_schema("noop") { return false; }
    if !user::has_schema("usdSend") { return false; }
    if !user::multisig_first_three() { return false; }
    return true;
}

fn ::main() {
    if self_check() { print("user ok"); } else { fail("user"); }
}
