# Porting

The behavior source is hypersdk 0.3.0 and the Hyperliquid Python SDK signing helpers. The checks are the hashes in `tests/signing.json`, the USD-send signature, and the wei pairs from `units.rs`.

## Names

`Action::prehash` for an L1 action is `sign::l1_prehash` over the MessagePack body. A user-signed action is `sign::user_prehash`. `float_to_wire` is `wire::normalize`. `to_wei` and `from_wei` keep those names.

## What matches

An L1 hash is MessagePack, then the nonce as 8 big-endian bytes, then `1` and 20 vault bytes or a single `0`. An expiry adds a `0` and 8 big-endian bytes. Keccak of that is the Agent `connectionId`. The source is `a` on mainnet and `b` on testnet. The domain is Exchange, version 1, chain id 1337, and the zero address.

User-signed types use the `HyperliquidTransaction:` prefix and the Arbitrum chain id from `signatureChainId`. A null agent name is the empty string. An address in a string field is lowercase `0x` hex. A zero cloid is omitted.

`to_wei("72.305406316320073386", 18)` is `72305406316320073386`. `from_wei("98996405", 6)` is `98.996405`.

## What is different

Calls are blocking. The nonce is an argument. There is no tokio, reqwest, yawc, or alloy provider.

`ws::connect` returns false. `github.com/kaitk/goose-http@main` has no `wsclient` module, so this package does not copy one in. The subscription texts are ready for that client. They do not offer permessage-deflate. Reconnect is resending those texts.

A scale above 28 returns false. goose-decimal cannot hold a larger coefficient.

Info and exchange tests use saved bodies. They do not post to the network.

## Check

`goose tests/self_check.goose` from this directory printed `hyperliquid ok`. `goose tests/sign.goose` printed `sign ok`. `goose tests/user.goose` printed `user ok`. `goose tests/order.goose` printed `order ok`. `goose tests/http.goose` printed `http ok`. `goose tests/ws.goose` printed `ws ok`. `goose tests/evm.goose` printed `evm ok`.
