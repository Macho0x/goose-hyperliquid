# Remaining

Signing, action maps, info requests, and subscription texts match hypersdk 0.3.0. `jsonact::of` is the JSON for an L1 map. User-signed helpers also return the exchange JSON. `ws::post` sends info and exchange bodies on the socket. `wire::round_price` rounds to a tick.

Still open against the Rust client:

- Reply structs. Bodies stay JSON. `exchange_ok`, `first_market`, `asset_ctx`, and `fast_message` are the readers.
- Morpho and Uniswap beyond the selectors and a pool address read from a saved log.
- A reconnect loop. The caller sends `ping`, answers `needs_pong` with `pong`, and calls `connect` again after a drop.
