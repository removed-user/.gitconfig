#!/bin/bash
create_resident_key() {
#!/bin/bash
_coninue() {
read -p "continue? (Y/N): " choice
case "${choice}" in 
  Y|[yY][eE][sS] ) 
return 0
    ;;
  N|[nN][oO] ) 
    echo "Exiting."
    continue
    ;;
  * ) 
    echo "Invalid input"
    exit 1
    ;;
esac
}

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
local PERHOST_USERNAME="$(get_perhost_value "${PERHOST_CONFIG}"  user.username)"
local COMMENT="${COMMENT:-Account Key for ${APPLICATION}}"
local DEVICE=$(fido2-token -L | awk -F ':' '{print $1}')

printf '%s\n\t' KEY_TYPE="${KEY_TYPE}" COMMENT="${COMMENT}" user="${PERHOST_USERNAME}" "' -O resident'" "-O application='ssh:'${APPLICATION}" "${HOME}/.ssh/id_${KEY_TYPE}_${APPLICATION}"
printf 'Creating Key on '"${DEVICE}"' for '"${PERHOST_CONFIG}"
_continue 
ssh-keygen \
    -N '' \
    -t "${KEY_TYPE}" \
    -C "${COMMENT}" \
    -O user="${PERHOST_USERNAME}" \
    -O device="${DEVICE}"
    -O resident \
    -O application=ssh:"${APPLICATION}" \
    -f "${HOME}/.ssh/id_${KEY_TYPE}_${APPLICATION}"
}

create_all_resident_keys() {
local PERHOST_DIR="${HOME}/.config/git/host/perhost"
[ ! -e "${PERHOST_DIR}" ] && echo 'missing '"${PERHOST_DIR}" && exit 1

for cfg in "${PERHOST_DIR}"/*; do
    [ -f "${cfg}" ] || continue
    create_resident_key "${cfg}"
  done
}
