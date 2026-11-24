#!/bin/dash
message() { (
RED='\033[0;31m'; GREEN='\033[0;32m'; CLR='\033[0m'
cmd="${1}";  [ $# -gt 0 ] && shift; MESSAGE="${@}"
   case $cmd in
   msg) printf '%b%s%b: %s\n' "${GREEN}" '[STATUS]' "${CLR}" "${MESSAGE}" >&2;;
   err) printf '%b%s%b: %s\n' "${RED}" '[ERROR]' "${CLR}" "${MESSAGE}" >&2;;
esac; ); }; err() ( message err "$@"; ); msg() ( message msg "$@"; )
main() { (
AUTHENTICATOR_DEVICES=$(fido2-token -L | awk -F ':' '${print $1}')
case "${#AUTHENTICATOR_DEVICES[@]}" in
              [0]) err 'No Authenticator present'
;; ''|0*|*[!0-9]*) err 'Invalid Input'
;;          [2-9]) err 'More than one Authenticator present; pass `AUTHENTICATOR_DEVICE=` explicitly'
;;           [1]) AUTHENTICATOR_DEVICE="${AUTHENTICATOR_DEVICES[0]}" && unset "${AUTHENTICATOR_DEVICES}"
;; esac; 


PERHOST_FILE="${HOME}"/.config/git/host/perhost/"${HOST}"
[ -r "${PERHOST_FILE}" ] || err 'Missing File: '"${PERHOST_FILE}"

USERNAME="$(git config get --file="${PERHOST_FILE}" user.name)"
APPLICATION='ssh:'"$(get_perhost_value "${PERHOST_FILE}"  host.name)"







## example
fido2-token -L -k "${APPLICATION}" "${AUTHENTICATOR_DEVICE}" |\
awk \
-v USERNAME="${USERNAME}" \
-v APPLICATION="${APPLICATION}" \
'{
### AWK SNIPPETS
END {
    if ( $2 == "" || $4 == "") {
      print "Error: matching credential not found" > "/dev/stderr"
      exit 1
    }
    id = $2
    user = ""
    cmd = "printf \%s\" \"" $4 "\" | base64 -d "
    cmd | getline user; close(cmd)
    close(cmd)
if ( user == USERNAME ) { print id } 
}' 

fido2-token -I -k "${APPLICATION}" -i "${CREDENTIAL_ID}"

); }
main "$@"
