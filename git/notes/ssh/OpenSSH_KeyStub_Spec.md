### OpenSSH FIDO2 (`-sk`) Stub Specification & `ssh-add -` Requirements

#### 1. `ssh-add -` Input & Formatting Rules
* **Argument:** Pass `-` (`ssh-add -`) to read from `stdin`.
* **Headers:** Exact `-----BEGIN OPENSSH PRIVATE KEY-----` and `-----END OPENSSH PRIVATE KEY-----` lines.
* **Line Breaks:** Base64 body wrapped at 70 characters using Unix LF (`\n`), with **no** `\r`.
* **Trailing Newline:** Must end with `\n` immediately after `-----END OPENSSH PRIVATE KEY-----`.

#### 2. `openssh-key-v1` Binary Layout (Before Base64 Encoding)
*Note: `string` = `uint32` big-endian length prefix + raw bytes.*

**Outer Container:**
1. `bytes[15]`: `openssh-key-v1\0`
2. `string`: `"none"` (cipher)
3. `string`: `"none"` (kdf)
4. `string`: `""` (kdf options)
5. `uint32`: `1` (key count)
6. `string`: Public Key Blob (`string` key_type + `string` raw_pubkey + `string` rp_id)
7. `string`: Private Key Section (8-byte aligned blob below)

**Inner Private Section:**
1. `uint32[2]`: `checkint` repeated twice (e.g., `os.urandom(4) * 2`)
2. `string`: `"sk-ssh-ed25519@openssh.com"` (or `"sk-ecdsa-sha2-nistp256@openssh.com"`)
3. `string`: Raw public key bytes (32B for Ed25519; 65B uncompressed point for P-256)
4. `string`: `"ssh:"` (Relying Party ID from FIDO2 credential)
5. `uint8`: Flags (`0x01` = User Presence / touch, `0x04` = User Verification / PIN, `0x05` = both)
6. `string`: Raw Key Handle (`base64.b64decode(credential_id)` from `fido2-token`)
7. `string`: `""` (reserved)
8. `string`: Comment string (e.g., `"fido2"`)
9. `bytes`: Deterministic padding `\x01\x02\x03...` to pad Inner Private Section to an 8-byte boundary
