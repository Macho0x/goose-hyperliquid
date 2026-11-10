# Porting

The behavior source is hypersdk 0.3.0 and the Hyperliquid Python SDK signing helpers. The checks are the hashes in `tests/signing.json`, the USD-send signature, and the wei pairs from `units.rs`.

## Names

`Action::prehash` for an L1 action is `sign::l1_prehash` over the MessagePack body. A user-signed action is `sign::user_prehash`. `float_to_wire` is `wire::normalize`. `to_wei` and `from_wei` keep those names.

## What matches

An L1 hash is MessagePack, then the nonce as 8 big-endian bytes, then `1` and 20 vault bytes or a single `0`. An expiry adds a `0` and 8 big-endian bytes. Keccak of that is the Agent `connectionId`. The source is `a` on mainnet and `b` on testnet. The domain is Exchange, version 1, chain id 1337, and the zero address.

User-signed types use the `HyperliquidTransaction:` prefix and the Arbitrum chain id from `signatureChainId`. A null agent name is the empty string. An address in a string field is lowercase `0x` hex. A zero cloid is omitted.

`to_wei("72.305406316320073386", 18)` is `72305406316320073386`. `from_wei("98996405", 6)` is `98.996405`.

## Covered surface

User-signed EIP-712 actions are `usdSend`, `spotSend`, `withdraw`, `sendAsset`, `sendToEvmWithData`, `approveAgent`, `approveBuilderFee`, `usdClassTransfer`, `tokenDelegate`, `userDexAbstraction`, `userSetAbstraction`, `userPortfolioMargin`, `linkStakingUser`, `stakingLinkDisableTradingUser`, and `convertToMultiSigUser`.

L1 MessagePack actions cover the hypersdk `Action` variants, including orders, cancels, TWAP, trailing stops, vault and sub-account operations, validator actions, and the HIP-1, HIP-3, and HIP-4 deploy families in `deploy.goose`. `tests/actions.hex` is `rmp_serde::to_vec_named` of those actions from hypersdk 0.3.0. A missing optional field is null when the Rust struct writes null, and omitted when the struct skips it.

Info requests are the `InfoRequest` names. `info::typed` and `info::request` build a type, or a type plus a user. The rest have their own functions. `info::post` sends that JSON. Websocket subscriptions are the `Subscription` variants in `ws.goose`. `ws::connect` opens one with `http.wsclient`, and `ws::subscribe` sends one text and returns the next message. Reply bodies stay JSON. `json::member` reads the fields a caller needs.

The exchange body is the JSON object the Python SDK posts. `signature` is the object text with `r`, `s`, and `v`, appended as JSON. `exchange::post` sends that body.

## What is different

Calls are blocking. The nonce is an argument. There is no tokio, reqwest, yawc, or alloy provider.

A closed set is an enum. A missing field is one absent-or-present value, and a wire bool such as buy, reduce-only, cross, or deposit is a two-variant enum. `user` takes `Chain` and hashes it as the text `Mainnet` or `Testnet`. The MessagePack and JSON bytes are unchanged.

`ws::connect` calls `http.wsclient`. `l2_book_opts` can set `fast`, which asks the exchange for five levels on the short timer. The opening offers no permessage-deflate. goose-http's compressor is goose-compress, not the deflate package beside this one, and this socket imports neither. Reconnect is the caller opening again and sending the same texts. `unsubscribe` rewrites a subscribe text. `ping` and `pong` are the application frames, and `needs_pong` matches a server ping. `post` wraps an info body or an exchange body as `{"type","payload"}` with the caller's id. `WsClient.limit` stays 64 KiB until the caller raises it. There is no reconnect task and no timer.

`jsonact::of` writes the JSON object for an L1 MessagePack map. `user` body functions write the JSON for a user-signed action, including `signatureChainId`. `wire::api_mode` reads `"default"` as unified account. `wire::tick` and `wire::round_price` use the five-significant-figure rule. `order::market` is a FrontendMarket order. `nonce` is `time_ns` in milliseconds.

A scale above 28 returns false. goose-decimal cannot hold a larger coefficient.

`tests/http.goose` checks saved bodies and does not open a socket. `tests/live.goose` posts `/info` and `/exchange` and subscribes on `wss` against mainnet.

## Check

`goose tests/self_check.goose` from this directory printed `hyperliquid ok`. `goose tests/sign.goose` printed `sign ok`. `goose tests/user.goose` printed `user ok`. `goose tests/order.goose` printed `order ok`. `goose tests/http.goose` printed `http ok`. `goose tests/ws.goose` printed `ws ok`. `goose tests/evm.goose` printed `evm ok`. `goose tests/actions.goose` printed `actions ok`. `goose tests/coverage.goose` printed `coverage ok`. `goose tests/live.goose` printed `live ok`.
