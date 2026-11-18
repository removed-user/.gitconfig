function create_resident_key() {
  local COMMENT="${COMMENT:-'Personal github account key'}"
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
