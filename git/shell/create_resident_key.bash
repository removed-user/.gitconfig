#!/bin/bash

get_perhost_value() {
  local config_file="${1}"
  local git_key="${2}"
  local out_var="${3}"
  local value

  value="$(git config --file "${config_file}" --get "${git_key}")"

  if [ -z "${value}" ]; then
    printf 'Skipping %s: missing %s\n' "${config_file}" "${git_key}" >&2
    return 1
  fi

  printf -v "${out_var}" '%s' "${value}"
}

create_resident_key() {
  local PERHOST_CONFIG="${1}"
  local KEY_TYPE="${KEY_TYPE:-ed25519-sk}"
  local APPLICATION PERHOST_USERNAME ENTITY_CONTEXT

  get_perhost_value "${PERHOST_CONFIG}" "host.name" APPLICATION || return 1
  get_perhost_value "${PERHOST_CONFIG}" "user.username" PERHOST_USERNAME || return 1
  get_perhost_value "${PERHOST_CONFIG}" "entity.context" ENTITY_CONTEXT || return 1

  local COMMENT="${COMMENT:-Account Key for ${APPLICATION} (${ENTITY_CONTEXT})}"

  ssh-keygen \
    -N '' \
    -t "${KEY_TYPE}" \
    -C "${COMMENT}" \
    -O user="${ENTITY_CONTEXT}:${PERHOST_USERNAME}" \
    -O resident \
    -O application="ssh:${APPLICATION}" \
    -f "${HOME}/.ssh/id_${KEY_TYPE}_${ENTITY_CONTEXT}_${APPLICATION}"
}

create_all_resident_keys() {
  local PERHOST_DIR="${HOME}/.config/git/host/perhost"

  for cfg in "${PERHOST_DIR}"/*; do
    [ -f "${cfg}" ] || continue
    create_resident_key "${cfg}"
  done
}
