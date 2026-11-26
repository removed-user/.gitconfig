#### Generic

- `[-q]`:    Quiet
- `[-v]`:    Verbose (upto 3x)
- `[-f]`:     File (input/output depending on what its combined with)
- `[-O]`:    Specify Option=value (Combos: -M, -Y, -I)
- `[-w]`:    Allowed_Providers (fido auth)

### Key Creation Specific

- `[-t]`:  Type

    - ecdsa
    - ecdsa-sk
    - ed25519
    - ed25519-sk
    - mldsa44-ed25519
    - rsa

- `[-E]`:  fingerprint_hash 
    - md5
    - sha256

- `[-K]`:  Download resident Keys from FIDO Authenticator
- `[-y]`:  Read privkey file; print pubkey > stdout

- `[-b]`:  bits (Only relevant for some Key types)

#### Comment

- `[-C]`:  comment
- `[-c]`:  change comment (on pubkey files only, not embedded keys)

#### Key Reformatting

- `[-i]`:   Import a pubkey or privkey (to RFC4716) from other formats

- `[-e]`:  Export a pubkey from a pubkey or privkey to other formats

- `[-m]`:  Key Format
Options:
    - RFC4716 (Default)
    - PEM
    - PKCS#8

#### KRL

- `[-k]`:  Generate KRL  (-f, -u, -s, -z))

- `[-u]`:  Update KRL  (-k: adds )

- `[-z]`:  KRL (Version_Number)

- `[-Q]`:  Query Revocation of a key 
     - (-l: print krl contents) 

#### Signatures

- `[-Y]`: (Many sub-options Always Signature related)

    - `[-U]`:  Look to ssh-agent for CA-Key

    - `[-n]`:  Principles

        - find-principals 
            - `[-s]` signature_file 
            - `[-f]` allowed_signers_file

        - match-principals 
            - `[-f]` allowed_signers_file 
            - `[-I]` signer_identity

        - check-novalidate 
            - `[-n]` namespace 
            - `[-s]` signature_file

        - sign 
            - `[-f]` key_file 
            - `[-I]` signer_identity 
            - `[-n]` namespace

        - verify 
        - `[-f]`: allowed_signers_file
        - `[-I]`: signer_identity
        - `[-n]` namespace
        - `[-s]` signature_file 
            - `[-V]`: validity_interval
                - `-V 20261117:20261217`
                - `-V -5m:+24h`


### Hosts
- `[-H]`: Hash a Known_Hosts file `-f known_hosts`

- `[-R]`: Remove all keys belonging to `hostname` from a `-f Known_Hosts`

- `[-r]`:  Print SSH Fingerprint record hostname for a pubkey  (-g, -f) 

- `[-F]`:  Search for  `Hostname` in `-f known_hosts`

### CA-Key

- `[-I]`:  Certificate_Identity 

 `- `[-hU]` - `[-D pkcs11_provider]`- `[-n principals]``

- `[-z]`: Certificate (Serial_Number) 

- `[-L]`:  Print contents of certificates `-f cert`

- `[-s]`:  Sign Pubkey Using CA-Key 
    - `[-U]`:  Look to ssh-agent for CA-Key

#### password

- `[-p]`:    Request change Password
- `[-N]`:    new_passphrase
- `[-P]`:    old_passphrase
- `[-Z]`:    cipher (for private key file)
- `[-a]`:  Encryption  (KDF) Rounds

#### Misc 

- `[-D]`:  Download pubkeys provided by a PKCS#11.so 

- `[-A]`:  Generate one of every host key

- `[-B]`:  Show the bubblebabble

- `[-M]`: 
 - generate 
    - MODULI GENERATION
        - generate diffie-hellman-group-exchange (DH-GEX) parameters
    - screen 
        - test safety of moduli

### Env

SSH_SK_PROVIDER
