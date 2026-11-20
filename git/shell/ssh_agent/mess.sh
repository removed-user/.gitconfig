#!/bin/dash
agent_pre_checks() (
if [ -n "${GIT_SSH_AGENT_ENV}" ]; 
then 
   if [ -f "${GIT_SSH_AGENT_ENV}" ]
echo "tmp ignore this"
fi
fi
)

start_agent() (
GIT_SSH_AUTH_SOCK=/run/user/"$(id -u)"/git_ssh_agent.sock
SSH_AUTH_SOCK="$GIT_SSH_AUTH_SOCK" ssh-agent -sa "$GIT_SSH_AUTH_SOCK" | sed 's#SSH_#GIT_&#g' > "$GIT_SSH_AGENT_ENV"
)

test_socket() (
SSH_AUTH_SOCK="$GIT_SSH_AUTH_SOCK" \
ssh-add -l >/dev/null 2>&1
    if [ $? -eq 2 ]; then
        rm -f "$GIT_SSH_AUTH_SOCK"
    fi
)

git_agent_start() (
: "${GIT_SSH_AGENT_ENV:=/run/user/$(id -u)/git_ssh_agent.env}"

)
git_agent_start
