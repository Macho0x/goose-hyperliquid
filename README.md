<p align="center">
  <img src="logo.png" alt="A goose holding a drop" width="220">
</p>

<h1 align="center">goose-hyperliquid</h1>

<p align="center">
  HyperCore signing, info, and HyperEVM reads for <a href="https://github.com/aardappel/goose">Goose</a><br>
  <strong>0.1.1</strong> · <a href="LICENSE">Apache-2.0</a>
</p>

Signs the same HyperCore hashes as [hypersdk](https://github.com/infinitefield/hypersdk) 0.3.0 and the Hyperliquid Python SDK. An L1 order is a named MessagePack map, a nonce, and an Agent signature. A transfer is EIP-712 under `HyperliquidSignTransaction`. Prices go through goose-decimal, so `10.0` is hashed as `10`.

The nonce is a `u64` you pass in. HTTPS is [goose-http](https://github.com/kaitk/goose-http) over [goose-tls](https://github.com/kaitk/goose-tls). Subscription texts are here. `http.wsclient` is not on goose-http `main` yet, so `ws::connect` stays closed until that module lands.

## Example

```goose
import hyperliquid from "../hyperliquid";
import hyperliquid.order;

fn main() {
    let body, ok = order::batch("50000", "0.1", "Gtc", order::Priority.Absent);
    if ok {
        let dig, dok = order::prehash(body, 1700000000000);
        print(dok);
        print(dig);
    }
}
```

`prehash` is the 32-byte Agent digest. `eip712::sign` turns a user-signed field list into the 65-byte signature.

## Check

```sh
goose tests/self_check.goose
```

A good run prints `hyperliquid ok`. `tests/actions.goose` checks every action map against hypersdk 0.3.0. The signing, user, order, http, websocket, and evm files can be run on their own.

## Modules

| Module | What it does |
| --- | --- |
| `wire` | Normalized decimals and `0x` addresses |
| `sign` | L1 connection id and user-signed EIP-712 digest |
| `user` | Transfers, agent approval, delegation, and the other user-signed actions |
| `l1` | Leverage, margin, vault, borrow, dust, and sub-account MessagePack |
| `order` | Order, cancel, modify, trigger, and client-order-id MessagePack |
| `deploy` | HIP-1, HIP-3, and HIP-4 deploy MessagePack |
| `exchange` | The JSON body for `/exchange` |
| `info` | Info requests, a market name, and raw-deflate asset contexts |
| `ws` | Subscription texts. No permessage-deflate |
| `evm` | `to_wei` and `from_wei` up to 28 decimal places |
| `morpho` | `market(bytes32)` and `idToMarketParams(bytes32)` |
| `uniswap` | `slot0`, `token0`, and a pool address from a saved log |

`PORTING.md` lists the Rust paths and the differences. `TODO.md` lists what is still open.

## Benchmarks

`bench.goose` times this package. The row names stay fixed, so a clang run before a change and a clang run after it compare.

```sh
goose build -o hyperliquid-bench bench.goose --cc clang
./hyperliquid-bench
```

`goose bench.goose` runs in TinyCC. That is not a timing result. Numbers depend on the machine, so this page does not publish them.

## License

Apache-2.0. Free and open to everyone. The terms are in [LICENSE](LICENSE).
