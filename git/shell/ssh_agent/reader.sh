#!/bin/dash
main() { (
message() { ( RED='\033[0;31m'; GREEN='\033[0;32m'; CLR='\033[0m'; cmd="${1}";  [ $# -gt 0 ] && shift; MESSAGE="${*}"; case $cmd in msg) printf '%b%s%b: %s\n' "${GREEN}" '[STATUS]' "${CLR}" "${MESSAGE}" >&2;; err) printf '%b%s%b: %s\n' "${RED}" '[ERROR]' "${CLR}" "${MESSAGE}" >&2;; esac; ); }; err() ( message err "$@"; ); msg() ( message msg "$@"; )

AUTHENTICATOR_DEVICES=$(fido2-token -L | awk -F ':' '{print $1}')
DEVICE_COUNT="$(printf '%s\n' "${AUTHENTICATOR_DEVICES}" | awk 'NF {count++} END {print count+0}')"; case "${DEVICE_COUNT}" in [0]) err 'No Authenticator present' ;; ''|0*|*[!0-9]*) err 'Invalid Input' ;; [2-9]) err 'More than one Authenticator present; pass `AUTHENTICATOR_DEVICE=` explicitly' ;; [1]) AUTHENTICATOR_DEVICE="${AUTHENTICATOR_DEVICES}" && unset AUTHENTICATOR_DEVICES ;; esac; 
# Workaround githubs broken parser
github_fix() { if [ "${APPLICATION}" = "ssh:github" ] || [ "${APPLICATION}" = "ssh:github.com" ]; then APPLICATION="ssh:"; fi; }


PERHOST_FILE="${HOME}"/.config/git/host/perhost/"${HOST}"
[ -r "${PERHOST_FILE}" ] || err 'Missing File: '"${PERHOST_FILE}"

USERNAME="$(git config get --file=${PERHOST_FILE} user.name)"
APPLICATION='ssh:'"$(git config get --file=${PERHOST_FILE} host.name)"

github_fix


#----

# Helpers: 
  ## convert ASCII string to hex
    str_to_hex() { ( printf '%s' "$1" | xxd -p | tr -d '\n'; ); }
  ## Convert an integer length into a 4-byte big-endian hex string 
    uint32_hex() { ( printf '%08x' "$1" ); } 
  ## Pack binary string into an OpenSSH wire string (uint32 length + payload) 
    pack_string_hex() { raw_hex="$1"; len=$(( ${#raw_hex} / 2 )); printf '%s%s' "$(uint32_hex "$len")" "$raw_hex"; }

PUBKEY_HEX="$( fido2-token -I -k "${APPLICATION}" -i "${CREDENTIAL_ID}" ${DEVICE:+"$DEVICE"} | xxd -p | tr -d '\\n' )"





CREDENTIAL_ID=$(fido2-token -L -k "${APPLICATION}" "${AUTHENTICATOR_DEVICE}" |\
awk \
-v USERNAME="${USERNAME}" \
'{  id = $2; user = $4
    cmd = "printf \%s\" \"" user "\" | base64 -d "
    cmd | getline username; close(cmd); exit 0
if ( username == USERNAME ) { found = 1; print id } 
END { if (!found) { print "Error: matching credential not found" > "/dev/stderr"; exit 1; }; }' 
)"


# fido2-token -I -k "${APPLICATION}" -i "${CREDENTIAL_ID}" "${AUTHENTICATOR_DEVICE}"





); }
main "$@"


# 1. The Public Key (which fido2-token -I -k 'ssh:' -i "$CRED_ID" outputs in PEM format).
# 2. The Application string (ssh:).
# 3. The Key Handle (cred_id)—decoded from Base64 into raw binary/hex (base64 -d | xxd -p | tr -d '\n').


OPENING='-----BEGIN OPENSSH PRIVATE KEY-----\n'
ENDING='\n-----END OPENSSH PRIVATE KEY-----\n'


