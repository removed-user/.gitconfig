#!/bin/dash
message() { ( RED='\033[0;31m'; GREEN='\033[0;32m'; CLR='\033[0m'; cmd="${1}"; [ $# -gt 0 ] && shift; MESSAGE="${*}"; case $cmd in msg) printf '%b%s%b: %s\n' "${GREEN}" '[STATUS]' "${CLR}" "${MESSAGE}" >&2;; err) printf '%b%s%b: %s\n' "${RED}" '[ERROR]' "${CLR}" "${MESSAGE}" >&2;; esac; ); }
err() { message err "$@"; exit 1; }
msg() { message msg "$@"; }

str_to_hex() {
    printf '%s' "$1" | xxd -p | tr -d '\n'
}

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

    PERHOST_FILE="${HOME}/.config/git/host/perhost/${HOST}"
    [ -r "${PERHOST_FILE}" ] || err 'Missing File: '"${PERHOST_FILE}"

    USERNAME="$(git config get --file="${PERHOST_FILE}" user.name)"
    APPLICATION='ssh:'"$(get_perhost_value "${PERHOST_FILE}" host.name)"

    # Workaround githubs broken parser
    if [ "${APPLICATION}" = "ssh:github" ] || [ "${APPLICATION}" = "ssh:github.com" ]; then
        APPLICATION="ssh:"
    fi

    CREDENTIAL_ID=$(
        fido2-token -L -k "${APPLICATION}" "${AUTHENTICATOR_DEVICE}" | \
        awk -v USERNAME="${USERNAME}" '{
            id = $2
            user = ""
            cmd = "printf \"%s\" \"" $4 "\" | base64 -d"
            cmd | getline user
            close(cmd)
            if (user == USERNAME) { found = 1; print id }
        }
        END {
            if (!found) { print "Error: matching credential not found" > "/dev/stderr"; exit 1 }
        }'
    ) || exit 1

    # 1. Extract PEM body, decode with base64 -d, and hex-encode with xxd
    SPKI_HEX="$(
        fido2-token -I -k "${APPLICATION}" -i "${CREDENTIAL_ID}" "${AUTHENTICATOR_DEVICE}" | \
        awk '/-----BEGIN PUBLIC KEY-----/{flag=1; next} /-----END PUBLIC KEY-----/{flag=0} flag' | \
        base64 -d | xxd -p | tr -d '\n' | tr 'A-F' 'a-f'
    )"
    [ -n "${SPKI_HEX}" ] || err 'Failed to extract public key from token'

    # 2. Identify algorithm, strip ASN.1 DER prefix, and set OpenSSH key parameters
    ED25519_PREFIX="302a300506032b6570032100"
    ECDSA_P256_PREFIX="3059301306072a8648ce3d020106082a8648ce3d030107034200"

    case "${SPKI_HEX}" in
        "${ED25519_PREFIX}"*)
            KEYTYPE="sk-ssh-ed25519@openssh.com"
            CURVE=""
            RAW_PUB_HEX="${SPKI_HEX#"${ED25519_PREFIX}"}"
            ;;
        "${ECDSA_P256_PREFIX}"*)
            KEYTYPE="sk-ecdsa-sha2-nistp256@openssh.com"
            CURVE="nistp256"
            RAW_PUB_HEX="${SPKI_HEX#"${ECDSA_P256_PREFIX}"}"
            ;;
        *)
            err "Unsupported SPKI public key header: ${SPKI_HEX}"
            ;;
    esac

    # 3. Prepare hex-encoded inputs for awk
    KEYTYPE_HEX="$(str_to_hex "${KEYTYPE}")"
    CURVE_HEX="$(str_to_hex "${CURVE}")"
    APP_HEX="$(str_to_hex "${APPLICATION}")"
    CRED_ID_HEX="$(printf '%s' "${CREDENTIAL_ID}" | base64 -d | xxd -p | tr -d '\n')"
    COMMENT_HEX="$(str_to_hex "${USERNAME}@${HOST}")"

    # 4. Assemble OpenSSH wire format in awk, convert to binary, and base64 encode
    OPENING='-----BEGIN OPENSSH PRIVATE KEY-----'
    ENDING='-----END OPENSSH PRIVATE KEY-----'

    printf '%s\n' "${OPENING}"
    awk -v keytype_hex="${KEYTYPE_HEX}" \
        -v curve_hex="${CURVE_HEX}" \
        -v pub_hex="${RAW_PUB_HEX}" \
        -v app_hex="${APP_HEX}" \
        -v cred_hex="${CRED_ID_HEX}" \
        -v comment_hex="${COMMENT_HEX}" '
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
    BEGIN {
        key_type = ssh_str(keytype_hex)
        pub_fields = (curve_hex != "" ? ssh_str(curve_hex) : "") ssh_str(pub_hex)
        app_blob = ssh_str(app_hex)
        pub_blob = key_type pub_fields app_blob

        checkint = "deadbeefdeadbeef"
        flags = "01"

        priv_body = checkint \
                    key_type \
                    pub_fields \
                    app_blob \
                    flags \
                    ssh_str(cred_hex) \
                    ssh_str("") \
                    ssh_str(comment_hex)

        byte_len = length(priv_body) / 2
        pad_len = (8 - (byte_len % 8)) % 8
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
    printf '%s\n' "${ENDING}"
); }

main "$@"
