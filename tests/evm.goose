import os;
import json;
import crypto from "../../crypto";
import crypto.keccak256;
import ethereum from "../../ethereum";
import ethereum.abi;
import ethereum.rpc;
import decimal from "../../decimal";
import hyperliquid from "..";
import hyperliquid.evm;
import hyperliquid.morpho;
import hyperliquid.uniswap;

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

fn self_check() -> bool {
    let wei, wok = evm::to_wei("72.305406316320073386", 18);
    if !wok || wei != "72305406316320073386" { return false; }
    let back, bok = evm::from_wei("98996405", 6);
    if !bok || back != "98.996405" { return false; }
    let usdc, uok = evm::to_wei("69", 6);
    if !uok || usdc != "69000000" { return false; }
    let wide, wideok = evm::to_wei("1", 29);
    if wideok { return false; }
    if hex(morpho::market_selector()) != "5c60e39a" { return false; }
    if hex(uniswap::slot0_selector()) != "3850c7bd" { return false; }
    let pool, pok = uniswap::pool_address("{\"address\":\"0x00000000000000000000000000000000000000aa\"}");
    if !pok || pool != "0x00000000000000000000000000000000000000aa" { return false; }
    let prjx, xok = uniswap::prjx_pool("{\"pool\":\"0x00000000000000000000000000000000000000bb\"}");
    if !xok || prjx != "0x00000000000000000000000000000000000000bb" { return false; }
    var call: u8[>..] = [];
    rpc::call(call, 1, "0x00000000000000000000000000000000000000aa", "0x3850c7bd", "latest");
    var saw = false;
    let needle = "\"method\":\"eth_call\"";
    if call.len >= needle.len {
        for i in 0..(call.len - needle.len + 1) {
            var same = true;
            for j in 0..needle.len {
                if call[i + j] != needle[j] { same = false; }
            }
            if same { saw = true; }
        }
    }
    if !saw { return false; }
    return true;
}

fn ::main() {
    if self_check() { print("evm ok"); } else { fail("evm"); }
}
