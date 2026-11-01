// Morpho reads. The call data is the 4-byte selector. The HTTP client
// carries the eth_call. This file does not open a socket.

import crypto from "../crypto";
import crypto.keccak256;
import ethereum from "../ethereum";
import ethereum.abi;

namespace morpho;

fn market_selector() -> u8[4] { return abi::selector("market(bytes32)"); }

fn params_selector() -> u8[4] { return abi::selector("idToMarketParams(bytes32)"); }
