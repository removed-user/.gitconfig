#!/bin/dash
message() { (
RED='\033[0;31m'; GREEN='\033[0;32m'; CLR='\033[0m'

cmd="${1}";  [ $# -gt 0 ] && shift; MESSAGE="${*}"
   case $cmd in
   msg) printf '%b%s%b: %s\n' "${GREEN}" '[STATUS]' "${CLR}" "${MESSAGE}" >&2;;
   err) printf '%b%s%b: %s\n' "${RED}" '[ERROR]' "${CLR}" "${MESSAGE}" >&2;;
esac; ); }; err() ( message err "$@"; ); msg() ( message msg "$@"; )

main() { (
AUTHENTICATOR_DEVICES=$(fido2-token -L | awk -F ':' '{print $1}')
DEVICE_COUNT="$(printf '%s\n' "${AUTHENTICATOR_DEVICES}" | awk 'NF {count++} END {print count+0}')"
case "${DEVICE_COUNT}" in
              [0]) err 'No Authenticator present'
;; ''|0*|*[!0-9]*) err 'Invalid Input'
;;          [2-9]) err 'More than one Authenticator present; pass `AUTHENTICATOR_DEVICE=` explicitly'
;;           [1]) AUTHENTICATOR_DEVICE="${AUTHENTICATOR_DEVICES}" && unset AUTHENTICATOR_DEVICES
;; esac; 


PERHOST_FILE="${HOME}"/.config/git/host/perhost/"${HOST}"
[ -r "${PERHOST_FILE}" ] || err 'Missing File: '"${PERHOST_FILE}"

USERNAME="$(git config get --file=${PERHOST_FILE} user.name)"
APPLICATION='ssh:'"$(get_perhost_value ${PERHOST_FILE} host.name)"

# Workaround githubs broken parser
if [ "${APPLICATION}" = "ssh:github" ] || [ "${APPLICATION}" = "ssh:github.com" ]; then
APPLICATION="ssh:"
fi

CREDENTIAL_ID=$(
fido2-token -L -k "${APPLICATION}" "${AUTHENTICATOR_DEVICE}" |\
awk \
-v USERNAME="${USERNAME}" \
'{         
    id = $2
    user = ""
    cmd = "printf \%s\" \"" $4 "\" | base64 -d "
    cmd | getline user; close(cmd)
    close(cmd)
if ( user == USERNAME ) { found = 1; print id } 
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


