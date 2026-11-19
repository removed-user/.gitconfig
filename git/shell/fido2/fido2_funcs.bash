#!/usr/bin/env bash
function print_devices() {
fido2-token -L | awk -F ':' '{print $1}'
}

function main() {
  local RP=$(fido2-token -L -r "${device}" | awk -F ' ' '{print $3}')

  local cred_id=$(fido2-token -L -k "${RP}" "${device}" | awk -F ' ' '{print $2}')

  function del_key() {
    fido2-token -D -i "${cred_id}" "${device}"
  }

  # if [[ "${num_doms[@]}" -gt 1 ]]; then
  #   echo cant handle excess keys
  # fi
  # exit 1
  # get_cred_id
}
main $1
