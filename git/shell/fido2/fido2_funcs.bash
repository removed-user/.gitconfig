#!/usr/bin/env bash
function print_devices() {
    fido2-token -L | awk -F ':' '{print $1}'
    }

function get_relying_parties() {
    fido2-token -L -r "${AUTHENTICATOR_DEVICE}" | awk -F ' ' '{print $3}'
    # Outputs...
    # <index[1]> <rp_id[key]> <rp_id[value]>
    # 00: rp_id: ssh:
    }

function get_credential_id() {
    fido2-token -L -k "${RELYING_PARTY}" "${AUTHENTICATOR_DEVICE}" | awk -F ' ' '{print $2}'
    # 00: <CREDENTIAL_ID> <USER_INFO> <ALGORITHM>
    }

function get_relevant_pubkey() {
    CREDENTIAL_ID="$(get_credential_id)"
    fido2-token -I -k "${RELYING_PARTY}" -i "${CREDENTIAL_ID}" "${AUTHENTICATOR_DEVICE}"
    }

function del_key() {
    fido2-token -D -i "${CREDENTIAL_ID}" "${AUTHENTICATOR_DEVICE}"
    }


  # if [[ "${num_doms[@]}" -gt 1 ]]; then
  #   echo cant handle excess keys
  # fi
  # exit 1
  # get_cred_id
