# Remaining

Signing, action maps, info requests, and subscription texts match hypersdk 0.3.0. `goose tests/self_check.goose` prints `hyperliquid ok`. What is still open:

- [ ] Point `ws::connect` at `http.wsclient` once that module is on [goose-http](https://github.com/kaitk/goose-http) `main`. Subscribe, read, and resubscribe with the texts already in `ws.goose`. Until then `connect` returns false for every URL, including a real `wss` URL. Do not vendor a second client. Permessage-deflate stays off unless that client offers it.
- [ ] Call goose-http for `POST /info` and `POST /exchange`. `exchange::body` and the info builders already return the JSON. The ordinary HTTP client is on goose-http `main` today, so this does not wait on the websocket pull request. Tests keep using the saved bodies in `tests/fixtures/`.
- [ ] Create `Macho0x/goose-hyperliquid` and tag `v0.1` when this package should be public. `VERSION` is already `0.1`.
