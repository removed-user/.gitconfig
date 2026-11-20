#!/bin/dash
(
GIT_SSH_AUTH_SOCK=/run/user/"$(id -u)"/git_ssh_agent.sock
PIDFILE=/run/user/"$(id -u)"/git_ssh_agent.pid
EXTERNAL_AUTH_SOCK="${SSH_AUTH_SOCK:-}"
EXTERNAL_AGENT_PID="${SSH_AGENT_PID:-}"
socket_exists() { [ -S "$GIT_SSH_AUTH_SOCK" ]; }
pidfile_exists() { [ -r "$PIDFILE" ]; }
git_agent_pid_set() { [ -n "${GIT_SSH_AGENT_PID}" ]; }
get_env() { pidfile_exists && . "$PIDFILE" || echo 'missing pidfile!' >&2; }

test_agent_process() (
set_env
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


git_agent_status() {
    case "$(ps -p "$GIT_SSH_AGENT_PID"  -o args= 2>/dev/null)" in
        *ssh-agent*"-a $GIT_SSH_AUTH_SOCK"*|*ssh-agent*"-sa $GIT_SSH_AUTH_SOCK"*) ;;
        *) return 1 ;;
    esac
}











set_env() {
get_env
SSH_AUTH_SOCK="${GIT_SSH_AUTH_SOCK:-}"
git_agent_pid_set && SSH_AGENT_PID="${GIT_SSH_AGENT_PID:-}" \
export GIT_SSH_AGENT_PID SSH_AGENT_PID
export SSH_AUTH_SOCK GIT_SSH_AUTH_SOCK
export SSH_SK_PROVIDER='' SSH_ASKPASS='' SSH_ASKPASS_REQUIRE=never DISPLAY=''
}

git_agent() (
set_env
SSH_AUTH_SOCK="$GIT_SSH_AUTH_SOCK" \
SSH_AGENT_PID="$GIT_SSH_AGENT_PID" \
ssh-agent -P '' "$@"
)





start_agent() (
set_env
git_agent -sa "$GIT_SSH_AUTH_SOCK" |\
   sed 's#SSH_#GIT_&#g' | head -n2 |\
   awk -F ';' '{print $1}' > "$PIDFILE"
)

git_agent_stop() {
set_env

# Safety checks:
assert_not_equal() {
    if [ -n "$1" ] && [ "$2" = "$1" ]; then
        printf '%s\n\t%s\n' 'Refusing to stop agent:'  "$3" >&2
        return 1
    fi
}
   # Never remove the external SSH_AUTH_SOCK

assert_not_equal "${EXTERNAL_AUTH_SOCK:-}" "${GIT_SSH_AUTH_SOCK}" 'Socket matches External SSH_AUTH_SOCK'

   # Never kill the external SSH_AGENT_PID
assert_not_equal "${EXTERNAL_AGENT_PID:-}" "${GIT_SSH_AGENT_PID}" 'PID matches External SSH_AGENT_PID'

kill_agent() (
set_env
git_agent -k >/dev/null 2>&1
)

confirm_kill() {
if kill -0 "$GIT_SSH_AGENT_PID" 2>/dev/null; then
    printf 'Warning: ssh-agent (PID %s) is still running after SIGTERM\n' "$GIT_SSH_AGENT_PID" >&2
else
unset GIT_SSH_AGENT_PID;
fi
}

maybe_remove_socket() { (
    socket_exists && rm -f "${GIT_SSH_AUTH_SOCK}"
    ); unset GIT_SSH_AUTH_SOCK
}    
    kill_agent
    confirm_kill
    maybe_remove_socket
}
git_agent_stop
)
