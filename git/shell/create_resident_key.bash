function create_resident_key() {
  local COMMENT="${COMMENT:-'Account Key for github'}"
  local KEY_TYPE="${KEY_TYPE:-ed25519-sk}"
  local APPLICATION="${APPLICATION:-github.com}"
  local GITHUB_USERNAME=removed-user
  ssh-keygen \
    -N '' \
    -t "${KEY_TYPE}" \
    -C "${COMMENT}" \
    -O user="${GITHUB_USERNAME}" \
    -O resident \
    -O application=ssh:"${APPLICATION}" \
    -f ~/.ssh/id_"${KEY_TYPE}"_"${APPLICATION}"
}

create_resident_key2() {
  local KEY_TYPE="${KEY_TYPE:-ed25519-sk}"
  local APPLICATION="${APPLICATION:-github.com}"
  local COMMENT="${COMMENT:-'Account Key for '${APPLICATION}}"
  
  local HOST_NAME="${APPLICATION%%.*}"
  local HOST_CONFIG="${HOME}/.config/git/host/perhost/${HOST_NAME}"
  local HOST_USERNAME="$(git config --file "${HOST_CONFIG}" --get user.username)"

  if [ -z "${HOST_USERNAME}" ]; then
    printf 'Error: No user.username found in %s\n' "${HOST_CONFIG}" >&2
    return 1
  fi

  ssh-keygen \
    -N '' \
    -t "${KEY_TYPE}" \
    -C "${COMMENT}" \
    -O user="${HOST_USERNAME}" \
    -O resident \
    -O application=ssh:"${APPLICATION}" \
    -f ~/.ssh/id_"${KEY_TYPE}"_"${APPLICATION}"
}
