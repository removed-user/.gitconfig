#!/bin/dash

main() (
GIT_SSH_AUTH_SOCK=/run/user/"$(id -u)"/git_ssh_agent.sock
PIDFILE=/run/user/"$(id -u)"/git_ssh_agent.pid
EXTERNAL_AUTH_SOCK="${SSH_AUTH_SOCK:-}"
EXTERNAL_AGENT_PID="${SSH_AGENT_PID:-}"

socket_exists() { [ -S "$GIT_SSH_AUTH_SOCK" ]; }
pidfile_exists() { [ -r "$PIDFILE" ]; }
get_pid() { pidfile_exists && read -r GIT_SSH_AGENT_PID < "$PIDFILE"; }
git_agent_pid_set() { [ -n "${GIT_SSH_AGENT_PID}" ]; }


## Get/Set Environment + PID
set_env() {
SSH_AUTH_SOCK="${GIT_SSH_AUTH_SOCK:-}"
git_agent_pid_set && SSH_AGENT_PID="${GIT_SSH_AGENT_PID:-}" \
export GIT_SSH_AGENT_PID SSH_AGENT_PID
export GIT_SSH_AUTH_SOCK SSH_AUTH_SOCK
export SSH_SK_PROVIDER='' SSH_ASKPASS='' SSH_ASKPASS_REQUIRE=never DISPLAY=''
}

### Wrapper Inject env into ssh-agent on every call
git_agent() (
set_env
SSH_AUTH_SOCK="$GIT_SSH_AUTH_SOCK" \
SSH_AGENT_PID="$GIT_SSH_AGENT_PID" \
ssh-agent -P '' "$@"
)

    test_agent_process() {
    KEYS_LOADED=0
    STALE_SOCKET=0
    #  set_env || return 1
    ssh-add -l >/dev/null 2>&1
    case $? in
        0) KEYS_LOADED=1; return 0 ;;
        1) KEYS_LOADED=0; return 0 ;;
        2) STALE_SOCKET=1; return 0 ;;
        *) return 1 ;;
    esac
}

socket_exists && test_agent_process

#ps -eo pid,args | awk '/[s]sh-agent/ {print $0}'

git_agent_status() {
    case "$(ps -p "$GIT_SSH_AGENT_PID"  -o args= 2>/dev/null)" in
        *ssh-agent*"-a $GIT_SSH_AUTH_SOCK"*|*ssh-agent*"-sa $GIT_SSH_AUTH_SOCK"*) ;;
        *) return 1 ;;
    esac
}

awk_snippet() (
expected_args="ssh-agent -P  -sa $GIT_SSH_AUTH_SOCK" \
zombies="" \
matched="" \
others=""  \
ps -eo pid,stat,args | awk '/[s]sh-agent/' |\
awk -v target="$expected_args" '
{
pid = $1
stat = $2 
# Rebuild the full command/args string from field 3 onward
cmd = substr($0, index($0, $3))

if (stat ~ /^Z/ || cmd ~ /<defunct>/) {
    print "ZOMBIE:" pid " " cmd
} else if (index(cmd, target) > 0) {
    print "MATCH:" pid " " cmd
} else {
    print "OTHER:" pid " " cmd
}
}'
)

### Startup 
#### Environment set and injected + Create clean PIDFILE
git_agent_start() (
set_env
git_agent -sa "$GIT_SSH_AUTH_SOCK" |\
awk 'NR == 2{gsub(/SSH_AGENT_PID=|;/, ""); print $1}' > "$PIDFILE"
   #   sed -n 2p |\
)

### Shutdown/Cleanup
git_agent_stop() {
set_env
   # Safety checks:
   assert_not_equal() {
    if [ -n "$1" ] && [ "$2" = "$1" ]; then
        printf '%s\n\t%s\n' 'Refusing to stop agent:'  "$3" >&2
        exit 1
    fi
   }

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
   cleanup_socket() { (
       socket_exists && rm -f "${GIT_SSH_AUTH_SOCK}"
       ); unset GIT_SSH_AUTH_SOCK
   }   
   cleanup_pidfile() { (
       pidfile_exists && rm -f "$PIDFILE"
       ); unset PIDFILE
   }   
      # Never remove the external SSH_AUTH_SOCK
assert_not_equal "${EXTERNAL_AUTH_SOCK:-}" "${GIT_SSH_AUTH_SOCK}" 'Socket matches External SSH_AUTH_SOCK'
      # Never kill the external SSH_AGENT_PID
assert_not_equal "${EXTERNAL_AGENT_PID:-}" "${GIT_SSH_AGENT_PID}" 'PID matches External SSH_AGENT_PID'

kill_agent
confirm_kill
cleanup_socket
cleanup_pidfile
}

    # "$@" from main "$@" is handled strictly here:
    case "${1:-}" in
        start)  git_agent_start ;;
        stop)   git_agent_stop ;;
        status) git_agent_status ;;
        *)      printf 'Usage: %s {start|stop|status}\n' "$0" >&2; exit 1 ;;
    esac
)

main "$@"
