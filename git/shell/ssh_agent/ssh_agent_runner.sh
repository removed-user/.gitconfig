#!/bin/dash
main() (
message() { (
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m' 
CLR='\033[0m'

cmd="${1}";  [ $# -gt 0 ] && shift; MESSAGE="${@}"
   case $cmd in
   msg) printf '%b%s%b: %s\n' "${GREEN}" '[STATUS]' "${CLR}" "${MESSAGE}" >&2;;
   err) printf '%b%s%b: %s\n' "${RED}" '[ERROR]' "${CLR}" "${MESSAGE}" >&2;;
   fx) printf '%b%s%b: %s\n' "${ORANGE}" '[FIXING]' "${CLR}" "${MESSAGE}" >&2;;
esac 
); }
err() ( message err "$@"; )
msg() ( message msg "$@"; )
fx() ( message fx "$@"; )


 ## Get/Set Environment + PID
  set_env() {
      set_once() { RAN_SET_ONCE=y;
         GIT_SSH_AUTH_SOCK=/run/user/"$(id -u)"/git_ssh_agent.sock
         PIDFILE=/run/user/"$(id -u)"/git_ssh_agent.pid
         EXTERNAL_AUTH_SOCK="${SSH_AUTH_SOCK:-}"
         EXTERNAL_AGENT_PID="${SSH_AGENT_PID:-}";
         }; [ -z "${RAN_SET_ONCE}" ] && set_once || true
    SSH_AUTH_SOCK="${GIT_SSH_AUTH_SOCK:-}"
    [ -n "${GIT_SSH_AGENT_PID}" ] && SSH_AGENT_PID="${GIT_SSH_AGENT_PID:-}" export GIT_SSH_AGENT_PID SSH_AGENT_PID || unset GIT_SSH_AGENT_PID SSH_AGENT_PID
    export GIT_SSH_AUTH_SOCK SSH_AUTH_SOCK
    export SSH_SK_PROVIDER='' SSH_ASKPASS='' SSH_ASKPASS_REQUIRE=never DISPLAY=''
   }


status() {
HAS_PIDFILE=n; HAS_SOCKET=n; PID_SET=n; VALID_PID=n; STALE_PID=n; ORPHAN=n;  RUNNING=n; KEYS_LOADED=n; STALE_SOCKET=n
      pidfile_exists() { HAS_PIDFILE=n; [ -r "$PIDFILE" ] && HAS_PIDFILE=y || HAS_PIDFILE=n; }
      socket_exists() { HAS_SOCKET=n; [ -S "$GIT_SSH_AUTH_SOCK" ] && HAS_SOCKET=y || HAS_SOCKET=n ; }

   get_pid() {
      pid_set() { case "${GIT_SSH_AGENT_PID:-}" in ''|0*|*[!0-9]*) unset GIT_SSH_AGENT_PID PID_SOURCE; PID_SET=n ;; [1-9]*) PID_SET=y PID_SOURCE="${1:-}";; esac; }
      try_read_pidfile() { GIT_SSH_AGENT_PID=""; case "$HAS_PIDFILE" in n) PID_SET=n ;; y) read -r GIT_SSH_AGENT_PID < "$PIDFILE" || true ;; *) return 1 ;; esac; pid_set "pidfile"; }
      try_find() {  GIT_SSH_AGENT_PID=$(find_git_agent_pid cmd | awk -F ':' '{print $2}'); pid_set "found"; }
    pidfile_exists
    try_read_pidfile
    [ "$PID_SET" = y ] || try_find || true
    [ "$PID_SET" = y ] || RUNNING=n
   } 
   
   pid_status() {
        [ "$PID_SET" = y ] || return 1
         validate_pid() { export VALID_PID=n STALE_PID=n; [ -n "$(find_git_agent_pid pid "$GIT_SSH_AGENT_PID")" ] && export VALID_PID=y STALE_PID=n || export STALE_PID=y VALID_PID=n; }
         check_orphans() { ORPHAN=n; try_find; ORPHAN="${PID_SET}"; }

    case "${PID_SOURCE:-}" in
           pidfile) validate_pid; if [ "$STALE_PID" = y ]; then check_orphans; fi ;;
           found) VALID_PID=n STALE_PID=n ORPHAN=y ;;
              '') check_orphans ;;
    esac
}
agent_status() { RUNNING=n; KEYS_LOADED=n; set_env || return 1; git_add -l >/dev/null 2>&1; case $? in 0) RUNNING=y; KEYS_LOADED=y; return 0 ;; 1) RUNNING=y; KEYS_LOADED=n; return 0 ;; 2) RUNNING=n; return 0 ;; *) return 1 ;; esac;  }

socket_status() {
    socket_exists
    STALE_SOCKET=y
    [ "$HAS_SOCKET" = y ] && [ "$PID_SET" = y ] && [ -d "/proc/$GIT_SSH_AGENT_PID/fd" ] || return 0

    ls -l "/proc/$GIT_SSH_AGENT_PID/fd" 2>/dev/null | awk -v sock="$GIT_SSH_AUTH_SOCK" '
        NR == FNR { if ($NF ~ /^socket:\[[0-9]+\]$/) { sub(/^socket:\[/, "", $NF); sub(/\]$/, "", $NF); inodes[$NF] = 1 }; next }
        FNR > 1 && $8 == sock && ($7 in inodes) { found = 1; exit }
        END { exit !found }
    ' - /proc/net/unix && STALE_SOCKET=n
}


#socket_status() { socket_exists; STALE_SOCKET=n
    # 1. Get the socket inode from /proc/net/unix
#    inode=$(awk -v sock="$GIT_SSH_AUTH_SOCK" 'NR > 1 && $8 == sock { print $7; exit }' /proc/net/unix)
#    if [ -z "$inode" ]; then STALE_SOCKET=y; return 0; fi
    # 2. Check if our already-found GIT_SSH_AGENT_PID actually holds that socket inode open
#    if [ "$PID_SET" = y ] && [ -d "/proc/$GIT_SSH_AGENT_PID/fd" ]; then for fd in /proc/"$GIT_SSH_AGENT_PID"/fd/*; do [ -L "$fd" ] || continue; case "$(readlink "$fd" 2>/dev/null)" in "socket:[$inode]") return 0 ;; esac; done; fi
    # Socket exists on disk, but is either unbound or owned by the wrong PID
#    STALE_SOCKET=y
# }


   find_git_agent_pid() { (
     # Usage:
      # find_git_agent_pid cmd                   -> Goal B: find rogue/orphaned processes by exact command
      # find_git_agent_pid pid "$PID"            -> Goal A & C: verify pidfile PID or confirm kill
      mode="${1:-pid}"; expected_pid="${2:-}"
      # intentional spaces below (because of argv formatting)
      target_cmd="ssh-agent -P  -sa $GIT_SSH_AUTH_SOCK"

        ps -eo pid=,args= | awk -v mode="$mode" -v expected_pid="$expected_pid" -v target_cmd="$target_cmd" '
           /[s]sh-agent/ {
            pid = $1
            sub(/^[ \t]*[0-9]+[ \t]+/, "")

            pid_match = (expected_pid != "" && pid == expected_pid)
            cmd_match = ($0 == target_cmd)
        
         if (mode == "pid" && pid_match) { print "PID:" pid; exit }
           else if (mode == "cmd" && cmd_match) { print "CMD:" pid; exit } }'
     ); }
     
}

## Startup and Wrappers
  ## Generic: Inject env into ssh-* on every call; for testing/checking states
     git_agent() { ( set_env; SSH_AUTH_SOCK="$GIT_SSH_AUTH_SOCK" SSH_AGENT_PID="$GIT_SSH_AGENT_PID" ssh-agent "$@"; ); }
     git_add() { ( set_env; SSH_AUTH_SOCK="$GIT_SSH_AUTH_SOCK" SSH_AGENT_PID="$GIT_SSH_AGENT_PID" ssh-add "$@"; ); }
   ### Execution: for "actual usage"
    #### Adds to the env set by git_add; Sets options for command, and adds the key recieved on stdin
     git_add_key() { ( git_add -H "${HOME}/.ssh/known_hosts/known_hosts-github" -H "${HOME}/.ssh/known_hosts/known_hosts-gitlab" -h github.com -h gitlab.com -E sha256 -t 4H -S '' -s ''  - ; ) }
    #### Adds to the env set by git_agent; Sets options for command, starts agent, and creates "${PIDFILE}"
     git_agent_start() { ( set_env; git_agent -P '' -sa "$GIT_SSH_AUTH_SOCK" | awk 'NR == 2{gsub(/SSH_AGENT_PID=|;/, ""); print $1}' > "$PIDFILE"; ); }
   ### Shutdown/Cleanup
     cleanup_socket() { ( socket_exists && rm -f "${GIT_SSH_AUTH_SOCK}" || return 0; ); export HAS_SOCKET=n; }   
     cleanup_pidfile() { ( pidfile_exists && rm -f "$PIDFILE" || return 0; ); export HAS_PIDFILE=n; }


git_agent_stop() { set_env; 
   # Safety checks:
         # Never affect External ssh-agent(s) Socket ot Process
      run_checks() ( assert_not_equal() { if [ -n "$1" ] && [ "$2" = "$1" ]; then printf '%s\n\t%s\n' 'Refusing to stop agent:' "$3" >&2; exit 1; fi; }; assert_not_equal "${EXTERNAL_AUTH_SOCK:-}" "${GIT_SSH_AUTH_SOCK}" 'Socket matches External SSH_AUTH_SOCK' ; assert_not_equal "${EXTERNAL_AGENT_PID:-}" "${GIT_SSH_AGENT_PID}" 'PID matches External SSH_AGENT_PID'; )
      kill_agent() { (  set_env;git_add -D >/dev/null 2>&1 || true && git_agent -k >/dev/null 2>&1; ); }
      confirm_kill() { [ -n "${GIT_SSH_AGENT_PID:-}" ] || return 0; i=0; while [ "$i" -lt 10 ]; do if [ -z "$(find_git_agent_pid pid "$GIT_SSH_AGENT_PID")" ]; then unset GIT_SSH_AGENT_PID SSH_AGENT_PID; return 0;  fi; sleep 0.1; i=$((i + 1)); done; err 'ssh-agent (PID: '"${GIT_SSH_AGENT_PID}"') failed to terminate within 1s\n' ; return 1; }
      cleanup() { cleanup_socket; cleanup_pidfile; }
   run_checks && kill_agent && confirm_kill && cleanup 
  }

    handle_state() {
[ "$ORPHAN" = y ] && { err 'Found Orphan: '"${GIT_SSH_AGENT_PID}"; kill_agent && confirm_kill; fx "Killed it"; } || true; status
[ "$STALE_SOCKET" = y ] && { err "Stale Socket"; cleanup_socket; fx "Deleted"; } || true; status
[ "$STALE_PID" = y ] && { err "Stale Pidfile"; cleanup_pidfile;  fx "Deleted"; } || true; status


        case "${GOAL}" in
            start)
                [ "$VALID_PID" = y ] && agent_status || true;

                if [ "$RUNNING" = y ] && [ "$VALID_PID" = y ]; then
                    msg "ssh-agent already running (PID: $GIT_SSH_AGENT_PID, keys loaded: $KEYS_LOADED)"
                    GOAL_REACHED=y
                    return 0
                fi

                msg "Starting isolated ssh-agent..."
                git_agent_start
                status
                if [ "$RUNNING" = y ]; then
                    msg "ssh-agent started (PID: $GIT_SSH_AGENT_PID)"
                else
                    err "Failed to start ssh-agent"
                    return 1
                fi
                ;;

            stop)
                if [ -z "${GIT_SSH_AGENT_PID}" ] && [ "$PID_SET" = n ]; then msg "ssh-agent is already stopped"; return 0; fi
                    msg "Stopping ssh-agent (PID: $GIT_SSH_AGENT_PID)"

                git_agent_stop
                status
                    [ "$HAS_PIDFILE" = y ] && { msg "Removing Pidfile"; cleanup_pidfile && msg "Success" || err "Failed"; }
                    [ "$HAS_SOCKET" = y ]  && { msg "Removing Socket"; cleanup_socket && msg "Success" || err "Failed"; }
                    
                if [ "$RUNNING" = n ] && [ "$HAS_SOCKET" = n ] && [ "$HAS_PIDFILE" = n ]; then
                    msg "ssh-agent stopped and cleaned up"
                    GOAL_REACHED=y
                else
                    err "Cleanup incomplete (RUNNING=$RUNNING, HAS_SOCKET=$HAS_SOCKET, HAS_PIDFILE=$HAS_PIDFILE)"
                    status
                fi
                ;;
        esac
    }

dispatch() { (
  cmd="${1:-}"; case "$cmd" in
  start|stop) GOAL="$cmd"; GOAL_REACHED=n; [ $# -gt 0 ] && shift; handle_state ;;
           *) printf 'Usage: %s {start|stop}\n' "${0##*/}" >&2; exit 1;; esac
); }


set_env
status
dispatch "$@"
# exec_ssh() ( 
# unset GOAL PIDFILE EXTERNAL_AUTH_SOCK EXTERNAL_AGENT_PID HAS_SOCKET HAS_PIDFILE RUNNING KEYS_LOADED VALID_PID STALE_PID ORPHAN PID_SET PID_SOURCE#exec /usr/bin/ssh "$@" 
# )
)

main "$@"
}
