#!/bin/bash
create_resident_key() {
  local PERHOST_CONFIG="${1}"
  local KEY_TYPE="${KEY_TYPE:-ed25519-sk}"

source ./reusable/get_perhost_value.bash

local APPLICATION="$(get_perhost_value "${PERHOST_CONFIG}"  host.name)"
local PERHOST_USERNAME="$(get_perhost_value "${PERHOST_CONFIG}"  user.username)"
local COMMENT="${COMMENT:-Account Key for ${APPLICATION}}"

ssh-keygen \
    -N '' \
    -t "${KEY_TYPE}" \
    -C "${COMMENT}" \
    -O user="${ENTITY_CONTEXT}:${PERHOST_USERNAME}" \
    -O resident \
    -O application=ssh:"${APPLICATION}" \
    -f "${HOME}/.ssh/id_${KEY_TYPE}_${ENTITY_CONTEXT}_${APPLICATION}"
}

create_all_resident_keys() {
local PERHOST_DIR="${HOME}/.config/git/host/perhost"

for cfg in "${PERHOST_DIR}"/*; do
    [ -f "${cfg}" ] || continue
    create_resident_key "${cfg}"
  done
}
