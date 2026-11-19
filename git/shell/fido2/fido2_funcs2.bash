#!/usr/bin/env bash
set -euo pipefail

function print_devices() {
    fido2-token -L | awk -F ': ' '{print $1}'
}

function get_relying_parties() {
    fido2-token -L -r "${AUTHENTICATOR_DEVICE}" | awk '{print $3}'
}

function get_credential_id() {
    fido2-token -L -k "${RELYING_PARTY}" "${AUTHENTICATOR_DEVICE}" | awk '{print $2}'
}

function get_relevant_pubkey() {
    : "${CREDENTIAL_ID:=$(get_credential_id)}"
    fido2-token -I -k "${RELYING_PARTY}" -i "${CREDENTIAL_ID}" "${AUTHENTICATOR_DEVICE}"
}

function del_key() {
    : "${CREDENTIAL_ID:=$(get_credential_id)}"
    fido2-token -D -i "${CREDENTIAL_ID}" "${AUTHENTICATOR_DEVICE}"
}

function usage() {
    cat <<EOF
Usage: $(basename "$0") [-d device] [-r rp_id] [-i cred_id] [-L | -R | -C | -P | -D]

Options:
  -d <device>   Authenticator device path (e.g. /dev/hidraw0)
  -r <rp_id>    Relying party ID (e.g. ssh:)
  -i <cred_id>  Base64 credential ID

Actions (pick one):
  -L            List devices
  -R            List relying parties (requires -d)
  -C            List credential IDs (requires -d, -r)
  -P            Get public key (requires -d, -r; optional -i)
  -D            Delete credential (requires -d, -r or -i)
  -h            Show this help message
EOF
}

function main() {
    local action=""
    AUTHENTICATOR_DEVICE=""
    RELYING_PARTY=""
    CREDENTIAL_ID=""

    while getopts ":d:r:i:LRCPDh" opt; do
        case "${opt}" in
            d) AUTHENTICATOR_DEVICE="${OPTARG}" ;;
            r) RELYING_PARTY="${OPTARG}" ;;
            i) CREDENTIAL_ID="${OPTARG}" ;;
            L) action="list_devices" ;;
            R) action="list_rps" ;;
            C) action="list_creds" ;;
            P) action="get_pubkey" ;;
            D) action="del_key" ;;
            h) usage; exit 0 ;;
            :) echo "Error: -${OPTARG} requires an argument." >&2; usage; exit 1 ;;
            \?) echo "Error: Invalid option -${OPTARG}" >&2; usage; exit 1 ;;
        esac
    done

    case "${action}" in
        list_devices)
            print_devices
            ;;
        list_rps)
            : "${AUTHENTICATOR_DEVICE:?Missing -d <device>}"
            get_relying_parties
            ;;
        list_creds)
            : "${AUTHENTICATOR_DEVICE:?Missing -d <device>}"
            : "${RELYING_PARTY:?Missing -r <rp_id>}"
            get_credential_id
            ;;
        get_pubkey)
            : "${AUTHENTICATOR_DEVICE:?Missing -d <device>}"
            : "${RELYING_PARTY:?Missing -r <rp_id>}"
            get_relevant_pubkey
            ;;
        del_key)
            : "${AUTHENTICATOR_DEVICE:?Missing -d <device>}"
            del_key
            ;;
        *)
            usage
            exit 1
            ;;
    esac
}

main "$@"
