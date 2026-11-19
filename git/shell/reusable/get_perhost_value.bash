#!/bin/bash 
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
