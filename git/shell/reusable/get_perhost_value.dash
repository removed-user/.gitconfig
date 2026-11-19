#!/bin/dash 
get_perhost_value ()
{
    local config_file="${1}";
    local git_key="${2}";
    local out_var="${3}";
    local value;
    value=$(git config --file "${config_file}" --get "${git_key}");
    if [ -z "${value}" ]; then
        printf 'Skipping %s: missing %s\n' "${config_file}" "${git_key}" 1>&2;
        return 1;
    fi;
    printf -v "${out_var}" '%s' "${value}"
}
