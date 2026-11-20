#!/bin/dash
(
GIT_SSH_AUTH_SOCK=/run/user/"$(id -u)"/git_ssh_agent.sock
PIDFILE=/run/user/"$(id -u)"/git_ssh_agent.pid

agent_pre_checks() (
if [ -n "${PIDFILE}" ]; 
then 
   if [ -f "${PIDFILE}" ]
echo "tmp ignore this"
fi
fi
)

start_agent() (
   SSH_AUTH_SOCK="$GIT_SSH_AUTH_SOCK" \
   ssh-agent -sa "$GIT_SSH_AUTH_SOCK" |\
   sed 's#SSH_#GIT_&#g' | head -n2 |\
   awk -F ';' '{print $1}' > "$PIDFILE"
)
test_socket() { [ -S "$GIT_SSH_AUTH_SOCK" ]; }

test_agent_process() (
    SSH_AUTH_SOCK="$GIT_SSH_AUTH_SOCK"\
    ssh-add -l >/dev/null 2>&1
    case $? in
        0|1)
            # 0: Agent running with key
            # 1: Agent running with no keys
            return 0
            ;;
        2)
            # 2: Unable to connect to agent (stale/dead socket)
            if rm -f "$GIT_SSH_AUTH_SOCK"
           then return 1; fi
            ;;
        *)
            # Unexpected error
            return 1
            ;;
    esac
)





git_agent_start() (
: "${PIDFILE:=/run/user/$(id -u)/git_ssh_agent.env}"

)
git_agent_start
read_pid() {
    # 1. Require a readable PID file
    [ -r "$PIDFILE" ] || return 1
    read -r pid < "$PIDFILE"
    [ -n "$pid" ] || return 1
}
git_agent_status() {
    case "$(ps -p "$pid" -o args= 2>/dev/null)" in
        *ssh-agent*"-a $GIT_SSH_AUTH_SOCK"*|*ssh-agent*"-sa $GIT_SSH_AUTH_SOCK"*) ;;
        *) return 1 ;;
    esac

    # 3. Confirm the socket itself is live and responsive
    env -i SSH_AUTH_SOCK="$GIT_SSH_AUTH_SOCK" ssh-add -l >/dev/null 2>&1
    [ $? -ne 2 ] || return 1
    return 0
}







#!/bin/sh
git_agent_stop() {

# Safety checks:
   # Safety check: Never remove the external SSH_AUTH_SOCK
    if [ -n "${SSH_AUTH_SOCK:-}" ] && [ "${GIT_SSH_AUTH_SOCK}" = "$SSH_AUTH_SOCK" ]; then
          printf '%s\n' "Refusing to stop agent: socket matches active SSH_AUTH_SOCK" >&2
          return 1
        fi
       
   # Safety check: Never kill the active external SSH_AGENT_PID
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
confirm_kill() {
if kill -0 "$GIT_SSH_AGENT_PID" 2>/dev/null; then
    printf 'Warning: ssh-agent (PID %s) is still running after SIGTERM\n' "$pid" >&2
else
unset GIT_SSH_AGENT_PID;
fi
}
maybe_remove_socket() { (
    if [ -S "${GIT_SSH_AUTH_SOCK}" ]; then
    rm -f "${GIT_SSH_AUTH_SOCK}" || true
    ); unset GIT_SSH_AUTH_SOCK
}    
    kill_agent
    confirm_kill
    maybe_remove_socket
}
git_agent_stop
)
