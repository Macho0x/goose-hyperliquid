// HyperCore and HyperEVM for Goose. This file is the package entry.
// Chain picks the Agent source byte. Mainnet is "a" and testnet is "b".

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

fn ::main() {
    print("goose tests/sign.goose");
}
