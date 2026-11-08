<p align="center">
  <img src="logo.png" alt="A goose holding a drop" width="220">
</p>

<h1 align="center">goose-hyperliquid</h1>

<p align="center">
  HyperCore signing, info, and HyperEVM reads for <a href="https://github.com/aardappel/goose">Goose</a><br>
  <strong>0.2.0</strong> · <a href="LICENSE">Apache-2.0</a>
</p>

Signs the same HyperCore hashes as [hypersdk](https://github.com/infinitefield/hypersdk) 0.3.0 and the Hyperliquid Python SDK. An L1 order is a named MessagePack map, a nonce, and an Agent signature. A transfer is EIP-712 under `HyperliquidSignTransaction`. Prices go through goose-decimal, so `10.0` is hashed as `10`.

The nonce is a `u64` you pass in. HTTPS and the websocket are [goose-http](https://github.com/kaitk/goose-http) over [goose-tls](https://github.com/kaitk/goose-tls). `info_url`, `exchange_url`, and `ws_url` are the mainnet and testnet addresses. `info::post` and `exchange::post` send the JSON those modules build. `exchange::body` appends the signature as the JSON object with `r`, `s`, and `v`. `ws::connect` takes a session and a `ws` or `wss` URL. `send` writes a subscription text, `read` returns the next message, and `subscribe` does both on the chain's socket. A dropped connection is `connect` again and the same text. The client offers no permessage-deflate. goose-http compresses with [goose-compress](https://github.com/kaitk/goose-compress), and this package does not inflate websocket frames. Fast asset contexts still inflate with the deflate package beside this one.

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

A program that imports `hyperliquid.ws` declares goose-http, goose-tls, and goose-hash in its root file. Set `session.deadline` before `connect`. `conn.limit` is 64 KiB until the caller raises it.

```goose
import http from "github.com/kaitk/goose-http@main";
import tls from "github.com/kaitk/goose-tls@v0.0.6";
import hash from "github.com/kaitk/goose-hash@v0.0.4";
import hyperliquid from "../hyperliquid";
import hyperliquid.ws;

fn main() {
    var session = http::session();
    session.deadline = http::deadline(10000);
    var conn, err = ws::connect(session, "wss://api.hyperliquid.xyz/ws");
    if err.code == 0 {
        let sub = ws::trades("BTC");
        ws::send(conn, sub);
        let msg, rerr = ws::read(conn);
        print(rerr.code);
        print(msg.data);
        ws::close(conn);
    }
    http::free(session);
}
```

## Check

```sh
goose tests/self_check.goose
```

A good run prints `hyperliquid ok`. `tests/actions.goose` checks every action map against hypersdk 0.3.0. The signing, user, order, http, websocket, and evm files can be run on their own.

`goose tests/live.goose` posts `/info` and `/exchange` and subscribes to BTC trades on mainnet. A good run prints `live ok`. It needs the network. The other tests do not.

The stack timing is three clang binaries. TinyCC is not a timing result.

```sh
goose build -o /tmp/stack-bench tests/stack_bench.goose --cc clang && /tmp/stack-bench
goose build -o /tmp/stack-local tests/stack_local.goose --cc clang && /tmp/stack-local
goose build -o /tmp/stack-live tests/stack_live.goose --cc clang && /tmp/stack-live
```

`stack-bench` is the parser and the body builders. `stack-local` is a loopback socket: a book pushed as fast as it will go, the same book over `wss`, plain HTTP posts, and a peer that stalls. `stack-live` posts meta twenty times, then reads BTC `bbo`, trades, and the fast book for eight seconds, then one `allMids`.

## Modules

| Module | What it does |
| --- | --- |
| `wire` | Normalized decimals and `0x` addresses |
| `sign` | L1 connection id and user-signed EIP-712 digest |
| `user` | Transfers, agent approval, delegation, and the other user-signed actions |
| `l1` | Leverage, margin, vault, borrow, dust, and sub-account MessagePack |
| `order` | Order, cancel, modify, trigger, and client-order-id MessagePack |
| `deploy` | HIP-1, HIP-3, and HIP-4 deploy MessagePack |
| `exchange` | The JSON body for `/exchange`, and `post` |
| `info` | Info requests, `post`, a market name, and raw-deflate asset contexts |
| `ws` | Subscription texts, connect, send, read, close, and `subscribe`. No permessage-deflate |
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
