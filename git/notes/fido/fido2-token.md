rp_id:      UTF-8 relying party id
cred_id: base64-encoded credential id

### List (`-L`) 
- `[-L]`: List all detected FIDO2 authenticators
    - `[-r]`: Lists all Relying Parties (RPs) that have resident credentials stored on the device.
    - `[-e]`: Lists all biometric enrollments on the device.
    - `[-b]`: Lists all CTAP 2.1 `largeBlobs` stored on the device.
    - `[-k]`: `rp_id` Lists all resident credentials associated with a specific `rp_id` (e.g., `ssh:`)
   
### Inspect (`-I`)
- `[-I]`: Retrieves general device information (AAGUID, firmware, options, PIN retries).
    - `[-t]`: `ppuat_path`: Uses a CTAP 2.2 persistent PIN/UV auth token to decrypt restricted info.
    - `[-c]`: Retrieves resident credential storage metadata (existing vs. remaining slots).


- `-k` `rp_id` `-i` `cred_id`: Prints the base64 credential ID and PEM-encoded public key for a specific resident credential.

### Set & Configure (`-S`) device
- `[-S]`:  Sets an initial PIN on a device that does not have one yet.
    - `[-C]`: Changes an existing PIN.
    - `[-f]`: Forces a PIN change on the next use.
    - `[-l]`: (pin_length) Sets the minimum required PIN length.
    - `[-m]`: (rp_id)  Sets a comma-separated list of Relying Party IDs permitted to query the minimum PIN length.
    - `[-u]`: Enables the CTAP 2.1 "always require user verification" feature.
    - `[-a]`:  Enables CTAP 2.1 Enterprise Attestation.
    - `[-e]`: Create a biometric enrollment.
        - `[-i]` `template_id` `-n` `template_name`: Sets a friendly name for an existing biometric template.

    - `[-c]`: Targets resident credential metadata
        - `[-i]` `cred_id` `-k` `user_id` `-n` `name` `-p` `display_name` device: Updates the UTF-8 `name` and `display_name` metadata of a resident credential.

### Delete (`-D`)

- `[-D]`: Base delete action (requires flag)

- `[-i]`: `cred_id`: Deletes a resident credential using its base64-encoded `cred_id`.
- `[-u]`: Disables the CTAP 2.1 "always require user verification" feature.
- `-e` `-i` `template_id`: Deletes a biometric enrollment using its base64-encoded `template_id`.

### Reset (`-R`)
- `[-R]`: Performs a factory reset of the FIDO2 application without a confirmation prompt (typically requires unplugging/replugging and touching within 5–30 seconds).


### Blobs & Tokens (`-G`, `-S -b`, `-D -b`)
- `[-G]`: Base retrieval action (requires flag)
    - `[-t]` `ppuat_path`: Retrieves a CTAP 2.2 persistent PIN/UV auth token with read-only credential management permissions and saves it to `ppuat_path`.

    - `[-b]` `blob_path`: Gets a CTAP 2.1 `largeBlob` and saves it to `blob_path`.

- `[-S]`: *(Also used for blobs)*
    - `[-b]` `blob_path`: Sets a CTAP 2.1 `largeBlob` from `blob_path`.

- `[-D]`: *(Also used for blobs)*
    - `[-b]`: Deletes a CTAP 2.1 `largeBlob`.

- **Optional `-b` Target Modifiers** *(apply to `-G -b`, `-S -b`, and `-D -b`)*:
    - `[-k]` `key_path`: Specifies the key file used to encrypt/decrypt the blob.
    - `[-n]` `rp_id`: Targets the blob associated with a specific Relying Party ID.
        - `[-i]` `cred_id`: Further narrows the target to a specific credential under that `rp_id` (requires `-n`).

### General Flags
- `[-d]`: Verbose debugging output
- `[-V]`: Print `fido2-token` version
