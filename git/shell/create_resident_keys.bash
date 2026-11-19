#!/bin/bash
create_resident_key() {
  local PERHOST_CONFIG="${1}"
  local KEY_TYPE="${KEY_TYPE:-ed25519-sk}"

get_cfg() {
        local key="${1}"
        local val="$(git config --file "${PERHOST_CONFIG}" --get "${key}" || true)"
        if [ -z "${val}" ]; then
printf 'Config File: %s\n\tMissing Key: %s\n' "${PERHOST_CONFIG}" "${key}" >&2
            return 1
        else
        printf "${val}"
        fi
    }



  

local APPLICATION="$(git config --file "${PERHOST_CONFIG}" --get host.name)"

if [ -z "${APPLICATION}" ]; then
printf 'Skipping %s: missing %s\n' "${PERHOST_CONFIG}" host.name >&2
   return 1
fi

local PERHOST_USERNAME="$(git config --file "${PERHOST_CONFIG}" --get user.username)"
  
if [ -z "${PERHOST_USERNAME}" ]; then
printf 'Skipping %s: missing %s\n' "${PERHOST_CONFIG}" user.username >&2
   return 1
fi

#ENTITY_CONTEXT
# host.name
local COMMENT="${COMMENT:-Account Key for ${APPLICATION}}"

ssh-keygen \
    -N '' \
    -t "${KEY_TYPE}" \
    -C "${COMMENT}" \
    -O user="${PERHOST_USERNAME}" \
    -O resident \
    -O application=ssh:"${APPLICATION}" \
    -f "${HOME}/.ssh/id_${KEY_TYPE}_${APPLICATION}"
}

create_all_resident_keys() {
local PERHOST_DIR="${HOME}/.config/git/host/perhost"

for cfg in "${PERHOST_DIR}"/*; do
    [ -f "${cfg}" ] || continue
    create_resident_key "${cfg}"
  done
}
