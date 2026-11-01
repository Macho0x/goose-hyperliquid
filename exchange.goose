// The JSON body posted to /exchange. The test checks the bytes.
// A socket is the caller's job.

import json;

namespace exchange;

fn body(action: u8[:], nonce: i64, signature: u8[:], has_vault: bool, vault: u8[:], has_expiry: bool, expiry: i64) -> u8[>..] {
    var out: u8[>..] = [];
    out.push('{');
    json::format_key(out, "action");
    out.append(action);
    out.push(',');
    json::format_key(out, "nonce");
    json::format_int(out, nonce);
    out.push(',');
    json::format_key(out, "signature");
    json::format_string(out, signature);
    if has_vault {
        out.push(',');
        json::format_key(out, "vaultAddress");
        json::format_string(out, vault);
    }
    if has_expiry {
        out.push(',');
        json::format_key(out, "expiresAfter");
        json::format_int(out, expiry);
    }
    out.push('}');
    return out;
}
