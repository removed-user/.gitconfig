#!/bin/dash
message() { ( RED='\033[0;31m'; GREEN='\033[0;32m'; CLR='\033[0m'; cmd="${1}"; [ $# -gt 0 ] && shift; MESSAGE="${*}"; case $cmd in msg) printf '%b%s%b: %s\n' "${GREEN}" '[STATUS]' "${CLR}" "${MESSAGE}" >&2;; err) printf '%b%s%b: %s\n' "${RED}" '[ERROR]' "${CLR}" "${MESSAGE}" >&2;; esac; ); }; err() { message err "$@"; exit 1; }; msg() { message msg "$@"; }

str_to_hex() { printf '%s' "$1" | xxd -p | tr -d '\n'; }

main() { (
    HOST="${1:-github}"
    AUTHENTICATOR_DEVICES=$(fido2-token -L | awk -F ':' '{print $1}')
    DEVICE_COUNT="$(printf '%s\n' "${AUTHENTICATOR_DEVICES}" | awk 'NF {count++} END {print count+0}')"
case "${DEVICE_COUNT}" in
                [2-9]) err 'More than one Authenticator present; pass `AUTHENTICATOR_DEVICE=` explicitly'
    ;;            [0]) err 'No Authenticator present'
    ;; ''|0*|*[!0-9]*) err 'Invalid Input'
    ;;            [1]) AUTHENTICATOR_DEVICE="${AUTHENTICATOR_DEVICES}" && unset AUTHENTICATOR_DEVICES
    ;; esac

    PERHOST_FILE="${HOME}/.config/git/host/perhost/${HOST}"; [ -r "${PERHOST_FILE}" ] || err 'Missing File: '"${PERHOST_FILE}"

    USERNAME="$(git config get --file="${PERHOST_FILE}" user.name)"
    APPLICATION='ssh:'"$(git config get --file="${PERHOST_FILE}" host.name)"

    # Workaround githubs broken parser
    if [ "${APPLICATION}" = "ssh:github" ] || [ "${APPLICATION}" = "ssh:github.com" ]; then  APPLICATION="ssh:"; fi

    CREDENTIAL_ID=$(
        fido2-token -L -k "${APPLICATION}" "${AUTHENTICATOR_DEVICE}" | \
        awk -v USERNAME="${USERNAME}" '{
            id = $2
            user = $4
            cmd = "printf '%s' '" user "' | base64 -d"
            cmd | getline username
            close(cmd)
            if (username == USERNAME) { found = 1; print id }
        }
        END {
            if (!found) { print "Error: matching credential not found" > "/dev/stderr"; exit 1 }
        }'
    ) || exit 1

    # 1. Extract PEM body, decode with base64 -d, and hex-encode with xxd
    SPKI_HEX="$(
        fido2-token -I -k "${APPLICATION}" -i "${CREDENTIAL_ID}" "${AUTHENTICATOR_DEVICE}" | \
        awk '/-----BEGIN PUBLIC KEY-----/{flag=1; next} /-----END PUBLIC KEY-----/{flag=0} flag' | \
        base64 -d | xxd -p | tr -d '\n'
    )"
    [ -n "${SPKI_HEX}" ] || err 'Failed to extract public key from token'

    # 2. Decode CREDENTIAL_ID to hex with base64 -d and xxd
    CRED_ID_HEX="$(printf '%s' "${CREDENTIAL_ID}" | base64 -d | xxd -p | tr -d '\n')"
    APP_HEX="$(str_to_hex "${APPLICATION}")"
    COMMENT_HEX="$(str_to_hex "${USERNAME}@${HOST}")"
    CHECKINT_HEX="$(dd if=/dev/urandom bs=4 count=1 2>/dev/null | xxd -p | tr -d '\n')"

    # 3. Strip SPKI ASN.1 header and assemble OpenSSH wire format in awk
    KEY_BODY="$(
        awk -v spki="${SPKI_HEX}" \
            -v app_hex="${APP_HEX}" \
            -v cred_hex="${CRED_ID_HEX}" \
            -v checkint="${CHECKINT_HEX}" \
            -v comment_hex="${COMMENT_HEX}" '
        function err(msg) {
            print "[ERROR]: " msg > "/dev/stderr"
            exit 1
        }
        function u32(n) {
            return sprintf("%08x", n)
        }
        function ssh_str(hex) {
            return u32(length(hex) / 2) hex
        }
        function ascii_hex(s,    i, out) {
            if (!ord_init) {
                for (i = 0; i < 256; i++) ord[sprintf("%c", i)] = i
                ord_init = 1
            }
            out = ""
            for (i = 1; i <= length(s); i++) {
                out = out sprintf("%02x", ord[substr(s, i, 1)])
            }
            return out
        }
        function parse_spki(spki_hex,    ed_len, ec_len) {
            ed_len = length(ED25519_PREFIX)
            ec_len = length(ECDSA_P256_PREFIX)

            if (index(spki_hex, ED25519_PREFIX) == 1) {
                KEYTYPE     = "sk-ssh-ed25519@openssh.com"
                CURVE       = ""
                RAW_PUB_HEX = substr(spki_hex, ed_len + 1)
                return 1
            }

            if (index(spki_hex, ECDSA_P256_PREFIX) == 1) {
                KEYTYPE     = "sk-ecdsa-sha2-nistp256@openssh.com"
                CURVE       = "nistp256"
                RAW_PUB_HEX = substr(spki_hex, ec_len + 1)
                return 1
            }

            err("Unsupported SPKI public key header: " spki_hex)
            return 0
        }
        BEGIN {
            ED25519_PREFIX    = "302a300506032b6570032100"
            ECDSA_P256_PREFIX = "3059301306072a8648ce3d020106082a8648ce3d030107034200"

            if (!parse_spki(tolower(spki))) exit 1

            key_type   = ssh_str(ascii_hex(KEYTYPE))
            pub_fields = (CURVE != "" ? ssh_str(ascii_hex(CURVE)) : "") ssh_str(RAW_PUB_HEX)
            app_blob   = ssh_str(app_hex)
            pub_blob   = key_type pub_fields app_blob

            checkint = "deadbeefdeadbeef"
            flags    = "01"

            priv_body = checkint \
                        key_type \
                        pub_fields \
                        app_blob \
                        flags \
                        ssh_str(cred_hex) \
                        ssh_str("") \
                        ssh_str(comment_hex)

            byte_len = length(priv_body) / 2
            pad_len  = (8 - (byte_len % 8)) % 8
            for (i = 1; i <= pad_len; i++) {
                priv_body = priv_body sprintf("%02x", i)
            }

            full_hex = ascii_hex("openssh-key-v1") "00" \
                       ssh_str(ascii_hex("none")) \
                       ssh_str(ascii_hex("none")) \
                       ssh_str("") \
                       u32(1) \
                       ssh_str(pub_blob) \
                       ssh_str(priv_body)

            print full_hex
        }' | xxd -r -p | base64 -w 70
    )" || exit 1

    OPENING='-----BEGIN OPENSSH PRIVATE KEY-----'
    ENDING='-----END OPENSSH PRIVATE KEY-----'

    printf '%s\n%s\n%s\n' "${OPENING}" "${KEY_BODY}" "${ENDING}"
); }

main "$@"
