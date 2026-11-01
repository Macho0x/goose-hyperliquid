// HyperCore and HyperEVM for Goose. This file is the package entry.
// Chain picks the Agent source byte. Mainnet is "a" and testnet is "b".

namespace hyperliquid;

enum Chain { Mainnet, Testnet }

fn chain_name(chain: Chain) -> u8[:] {
    if chain == Chain.Mainnet { return "Mainnet"; }
    return "Testnet";
}

fn ::main() {
    print("goose tests/sign.goose");
}
