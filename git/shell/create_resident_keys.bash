#!/bin/bash
create_resident_key() {
    get_perhost_value ()
   {
    local CONFIG="${1}";
    local KEY="${2}";
    local value
    value=$(git config --file "${CONFIG}" --get "${KEY}");
    if [ -z "${value}" ]; then
        printf 'Config File: %s\n\tMissing Key: %s\n' "${CONFIG}" "${key}" >&2
        return 1;
    fi;
    printf '%s' "${value}"
   }

local PERHOST_CONFIG="${1}"
local KEY_TYPE="${KEY_TYPE:-ed25519-sk}"
  
local APPLICATION="$(get_perhost_value "${PERHOST_CONFIG}"  host.name)"
local PERHOST_USERNAME="$(get_perhost_value "${PERHOST_CONFIG}"  user.name)"
local COMMENT="${COMMENT:-Account Key for ${APPLICATION}}"
local DEVICE=$(fido2-token -L | awk -F ':' '{print $1}')

if [[ ${APPLICATION} == "github" ]]; 
then 
local CLR='\033[0m'
local ORANGE='"\033[38;2;255;165;0m'
local RED='\033[31m'
printf "${ORANGE} Github fails to properly parse 'ssh:${namespace}' APPLICATION strings ${CLR}" 
printf "${RED} Replacing 'ssh:${APPLICATION}' string with 'ssh:' ${CLR}" 
printf 'Check Github Bug report ticket: #5031545 '
unset APPLICATION
   fi

local -a KEYGEN_OPTS=(
    -N '' 
    -t "${KEY_TYPE}" 
    -C "${COMMENT}" 
    -O user="${PERHOST_USERNAME}" 
    -O device="${DEVICE}"
    -O resident 
    -O application=ssh:"${APPLICATION}" 
    -f "${HOME}/.ssh/id_${KEY_TYPE}_${APPLICATION}"
    )

printf 'Creating Key on '"${DEVICE}"' for '"${PERHOST_CONFIG}"
printf '%s %q\n' "${KEYGEN_OPTS[@]}"




 
ssh-keygen "${KEYGEN_OPTS[@]}"
}

create_all_resident_keys() {
local PERHOST_DIR="${HOME}/.config/git/host/perhost"
[ ! -e "${PERHOST_DIR}" ] && echo 'missing '"${PERHOST_DIR}" && return 1

for cfg in "${PERHOST_DIR}"/*; do
    [ -f "${cfg}" ] || continue
    create_resident_key "${cfg}"
  done
}
