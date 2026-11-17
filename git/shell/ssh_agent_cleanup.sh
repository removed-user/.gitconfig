#!/bin/sh
GIT_SSH_AUTH_SOCK="${GIT_SSH_AUTH_SOCK:=/run/user/$(id -u)/git_ssh_agent.sock}"

git_agent_cleanup() {
    if [ -n "$GIT_SSH_AGENT_PID" ]; then
        SSH_AGENT_PID="$GIT_SSH_AGENT_PID" ssh-agent -k >/dev/null 2>&1
    elif [ -S "$GIT_SSH_AUTH_SOCK" ]; then
        # Fallback if GIT_SSH_AGENT_PID was lost in another subshell
        pkill -f "ssh-agent.*$GIT_SSH_AUTH_SOCK" >/dev/null 2>&1
    fi

    rm -f "$GIT_SSH_AUTH_SOCK"
    unset GIT_SSH_AGENT_PID
}

git_agent_cleanup
