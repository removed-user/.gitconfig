#!/bin/sh
git_agent_stop() {
GIT_SSH_AUTH_SOCK="${GIT_SSH_AUTH_SOCK:=/run/user/$(id -u)/git_ssh_agent.sock}"
PIDFILE=/run/user/"$(id -u)"/git_ssh_agent.pid


# Safety checks:

    if [ -z "$GIT_SSH_AGENT_PID" ]; then
       printf 'Missing pidfile!'
        fi

      if [ -z "$GIT_SSH_AGENT_PID" ]; then
       printf 'Missing pidfile!'
        fi
        
       $GIT_SSH_AGENT_PID

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
fi

kill_agent() { (
    SSH_AUTH_SOCK="$GIT_SSH_AUTH_SOCK"
    SSH_AGENT_PID="$GIT_SSH_AGENT_PID"
    export SSH_AUTH_SOCK SSH_AGENT_PID
    ssh-agent -k >/dev/null 2>&1
) 
    if kill -0 "$GIT_SSH_AGENT_PID" 2>/dev/null; then
    printf 'Warning: ssh-agent (PID %s) is still running after SIGTERM\n' "$pid" >&2
else
unset GIT_SSH_AGENT_PID;
fi
}

    
 


    kill_agent
    
    if [ -S "$GIT_SSH_AUTH_SOCK" ]; then

    rm -f "$GIT_SSH_AUTH_SOCK" || true
    kill "$GIT_SSH_AGENT_PID" || true
    unset GIT_SSH_AUTH_SOCK
}
git_agent_stop
