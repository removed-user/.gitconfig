#!/bin/sh
git_agent_stop() {
GIT_SSH_AUTH_SOCK="${GIT_SSH_AUTH_SOCK:=/run/user/$(id -u)/git_ssh_agent.sock}"
# Safety checks:

   # Safety check: Never remove the external SSH_AUTH_SOCK
    if [ -n "${SSH_AUTH_SOCK:-}" ] && [ "${GIT_SSH_AUTH_SOCK}" = "$SSH_AUTH_SOCK" ]; then
          printf '%s\n' "Refusing to stop agent: socket matches active SSH_AUTH_SOCK" >&2
          return 1
        fi
       
   # Safety check: Never kill the active external SSH_AGENT_PID
    if [ -n "${GIT_SSH_AGENT_PID:-}" ]; then
        if [ -n "${SSH_AGENT_PID:-}" ] && [ "$GIT_SSH_AGENT_PID" = "$SSH_AGENT_PID" ]; then
            printf '%s\n' "Refusing to stop agent: PID matches active SSH_AGENT_PID" >&2
            return 1
        fi


kill_agent() (
    SSH_AUTH_SOCK="$GIT_SSH_AUTH_SOCK"
    SSH_AGENT_PID="$GIT_SSH_AGENT_PID"
    export SSH_AUTH_SOCK SSH_AGENT_PID
    ssh-agent -k >/dev/null 2>&1
) 


    
 
    if [ -n "$GIT_SSH_AGENT_PID" ]; then
kill_agent || true
    fi
    
    if [ -S "$GIT_SSH_AUTH_SOCK" ]; then

    rm -f "$GIT_SSH_AUTH_SOCK" || true
    kill "$GIT_SSH_AGENT_PID" || true
    unset GIT_SSH_AGENT_PID GIT_SSH_AUTH_SOCK
}
git_agent_stop
