#!/bin/sh
: "${GIT_SSH_AUTH_SOCK:=/run/user/$(id -u)/git_ssh_agent.sock}"


: "${SSH_AUTH_SOCK:+${PREV_SSH_AUTH_SOCK:=$SSH_AUTH_SOCK}}"
: "${SSH_AGENT_PID:+${PREV_SSH_AGENT_PID:=$SSH_AGENT_PID}}"

[ -n "$PREV_SSH_AUTH_SOCK" ] && export PREV_SSH_AUTH_SOCK
[ -n "$PREV_SSH_AGENT_PID" ] && export PREV_SSH_AGENT_PID

export GIT_SSH_AUTH_SOCK

git_agent_start() {
    SSH_AUTH_SOCK="$GIT_SSH_AUTH_SOCK" ssh-add -l >/dev/null 2>&1
    if [ $? -eq 2 ]; then
        rm -f "$GIT_SSH_AUTH_SOCK"
        eval "$(ssh-agent -sa "$GIT_SSH_AUTH_SOCK" | sed \
            -e 's/SSH_AUTH_SOCK/GIT_SSH_AUTH_SOCK/g' \
            -e 's/SSH_AGENT_PID/GIT_SSH_AGENT_PID/g')" >/dev/null
    fi
}

git_agent_start
