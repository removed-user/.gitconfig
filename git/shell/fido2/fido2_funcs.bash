#!/usr/bin/env bash
function print_devices() {
    fido2-token -L | awk -F ':' '{print $1}'
    }

function del_key() {
    fido2-token -D -i "${CREDENTIAL_ID}" "${AUTHENTICATOR_DEVICE}"
    }

function get_relying_party() {
    fido2-token -L -r "${AUTHENTICATOR_DEVICE}" | awk -F ' ' '{print $3}'
    # Outputs...
    # index[1] rp_id[key] rp_id[value]
    # 00: rp_id: ssh:
    # 01: rp_id: github.com
    }



function main() {
local CREDENTIAL_ID=$(fido2-token -L -k "${RELYING_PARTY}" "${AUTHENTICATOR_DEVICE}" | awk -F ' ' '{print $2}')

  # if [[ "${num_doms[@]}" -gt 1 ]]; then
  #   echo cant handle excess keys
  # fi
  # exit 1
  # get_cred_id
}
main $1
