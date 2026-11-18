function create_resident_key() {
  local COMMENT="${COMMENT:-'Account Key for '${APPLICATION}}"
  local KEY_TYPE="${KEY_TYPE:-ed25519-sk}"
  local APPLICATION="${APPLICATION:-github.com}"
  
  local HOST_NAME="${APPLICATION%%.*}"
  local PERHOST_CONFIG="${HOME}/.config/git/host/perhost/${HOST_NAME}"
  local PERHOST_USERNAME="$(git config --file "${PERHOST_CONFIG}" --get user.username)"

  if [ -z "${PERHOST_USERNAME}" ]; then
    printf 'Error: No user.username found in %s\n' "${PERHOST_CONFIG}" >&2
    return 1
  fi

  ssh-keygen \
    -N '' \
    -t "${KEY_TYPE}" \
    -C "${COMMENT}" \
    -O user="${PERHOST_USERNAME}" \
    -O resident \
    -O application=ssh:"${APPLICATION}" \
    -f ~/.ssh/id_"${KEY_TYPE}"_"${APPLICATION}"
}
