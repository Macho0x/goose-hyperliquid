// HyperCore and HyperEVM for Goose. This file is the package entry.
// Chain picks the Agent source byte. Mainnet is "a" and testnet is "b".

import os;

namespace hyperliquid;

enum Chain { Mainnet, Testnet }

fn chain_name(chain: Chain) -> u8[:] {
    if chain == Chain.Mainnet { return "Mainnet"; }
    return "Testnet";
}

fn info_url(chain: Chain) -> u8[:] {
    if chain == Chain.Mainnet { return "https://api.hyperliquid.xyz/info"; }
    return "https://api.hyperliquid-testnet.xyz/info";
}

fn exchange_url(chain: Chain) -> u8[:] {
    if chain == Chain.Mainnet { return "https://api.hyperliquid.xyz/exchange"; }
    return "https://api.hyperliquid-testnet.xyz/exchange";
}

fn ws_url(chain: Chain) -> u8[:] {
    if chain == Chain.Mainnet { return "wss://api.hyperliquid.xyz/ws"; }
    return "wss://api.hyperliquid-testnet.xyz/ws";
}

fn nonce() -> i64 { return time_ns() / 1000000; }

fn chain_hex(id: u64) -> u8[>..] {
    var digs: u8[16] = [0; 16];
    var n = id;
    var nd: i64 = 0;
    if n == 0 { nd = 1; digs[0] = '0'; }
    while n > 0 {
        let d = (n % 16) as! u8;
        if d < 10 { digs[nd] = '0' + d; } else { digs[nd] = 'a' + (d - 10); }
        nd += 1;
        n = n / 16;
    }
    var o: u8[>..] = [];
    o.push('0');
    o.push('x');
    for i in 0..nd { o.push(digs[nd - 1 - i]); }
    return o;
}

fn ::main() {
    print("goose tests/sign.goose");
}
