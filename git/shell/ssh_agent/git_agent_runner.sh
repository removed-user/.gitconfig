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
         [ -n "${RUN_SET_ONCE}" ] && { unset RUN_SET_ONCE;
         [ ! -d '/run/user/'"$(id -u)"'/git_agent' ] && mkdir -p '/run/user/'"$(id -u)"'/git_agent'
         
         GIT_SSH_AUTH_SOCK=/run/user/"$(id -u)"/git_agent/git_ssh_agent.sock
         PIDFILE=/run/user/"$(id -u)"/git_agent/git_ssh_agent.pid
         EXTERNAL_AUTH_SOCK="${SSH_AUTH_SOCK:-}"
         EXTERNAL_AGENT_PID="${SSH_AGENT_PID:-}";
         };
         
    SSH_AUTH_SOCK="${GIT_SSH_AUTH_SOCK:-}"
    [ -n "${GIT_SSH_AGENT_PID}" ] && SSH_AGENT_PID="${GIT_SSH_AGENT_PID:-}" export GIT_SSH_AGENT_PID SSH_AGENT_PID || unset GIT_SSH_AGENT_PID SSH_AGENT_PID
    export GIT_SSH_AUTH_SOCK SSH_AUTH_SOCK
    export SSH_SK_PROVIDER='' SSH_ASKPASS='' SSH_ASKPASS_REQUIRE=never DISPLAY=''
   }


status() {
HAS_PIDFILE=n; HAS_SOCKET=n; PID_SET=n; VALID_PID=n; STALE_PID=n; ORPHAN=n;  RUNNING=n; KEYS_LOADED=n; STALE_SOCKET=n
      pidfile_exists() { HAS_PIDFILE=n; [ -r "$PIDFILE" ] && HAS_PIDFILE=y || HAS_PIDFILE=n; [ "$HAS_PIDFILE" = y ]; }
      socket_exists() { HAS_SOCKET=n; [ -S "$GIT_SSH_AUTH_SOCK" ] && HAS_SOCKET=y || HAS_SOCKET=n; [ "$HAS_SOCKET" = y ]; }
      pid_set() { case "${GIT_SSH_AGENT_PID:-}" in ''|0*|*[!0-9]*) unset GIT_SSH_AGENT_PID PID_SOURCE; PID_SET=n ;; [1-9]*) PID_SET=y PID_SOURCE="${1:-}";; esac; }

   get_pid() {
      try_read_pidfile() { GIT_SSH_AGENT_PID=""; case "$HAS_PIDFILE" in n) PID_SET=n ;; y) read -r GIT_SSH_AGENT_PID < "$PIDFILE" || true ;; *) return 1 ;; esac; pid_set "pidfile"; }
try_find() {
    IFS=: read -r _ GIT_SSH_AGENT_PID NUM_PIDS <<EOF
$(find_git_agent_pid cmd)
EOF
    : "${NUM_PIDS:=0}"; pid_set "found"; }

    #  try_find() {  GIT_SSH_AGENT_PID=$(find_git_agent_pid cmd | awk -F ':' '{print $2}'); pid_set "found"; }
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
   STALE_SOCKET=n
   socket_exists || return 0
   STALE_SOCKET=y

    awk -v sock="${GIT_SSH_AUTH_SOCK}" 'NR > 1 { flags = $4; st = $6; path = $8
            if (path == sock && flags == "00010000" && st == "01") { found = 1; exit; } }
        END { exit !found }' /proc/net/unix && STALE_SOCKET=n
}

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
        
           if ((mode == "pid" && pid_match) || (mode == "cmd" && cmd_match)) { if (!count++) first_pid = pid
            }
        }
        END { if (count > 0) print toupper(mode) ":" first_pid ":" count }'
        ); }

case $1 in
pid) get_pid && pid_status ;;
sock) socket_status ;;
all)  get_pid && pid_status; socket_status; agent_status ;;
esac
}

## Startup and Wrappers
  ## Generic: Inject env into ssh-* on every call; for testing/checking states
     git_agent() { ( set_env; SSH_AUTH_SOCK="$GIT_SSH_AUTH_SOCK" SSH_AGENT_PID="$GIT_SSH_AGENT_PID" ssh-agent "$@"; ); }
     git_add() { ( set_env; SSH_AUTH_SOCK="$GIT_SSH_AUTH_SOCK" SSH_AGENT_PID="$GIT_SSH_AGENT_PID" ssh-add "$@"; ); }
   ### Execution: for "actual usage"
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
      confirm_kill() { [ -n "${GIT_SSH_AGENT_PID:-}" ] || { PID_SET=n && return 0; }; i=0; while [ "$i" -lt 10 ]; do if [ -z "$(find_git_agent_pid pid "$GIT_SSH_AGENT_PID")" ]; then PID_SET=n; unset GIT_SSH_AGENT_PID SSH_AGENT_PID; return 0;  fi; sleep 0.1; i=$((i + 1)); done; err 'ssh-agent (PID: '"${GIT_SSH_AGENT_PID}"') failed to terminate within 1s\n' ; return 1; }
  }

    handle_state() {
[ "$ORPHAN" = y ]       && { err 'Found Orphan:   '"${GIT_SSH_AGENT_PID}"; git_agent_stop && fx "Killed it"; } && { status pid ; status sock; } || true
[ "$STALE_SOCKET" = y ] && { err "Stale Socket";  cleanup_socket    && fx "Deleted"; } && status sock || true
[ "$STALE_PID" = y ]    && { err "Stale Pidfile"; cleanup_pidfile   && fx "Deleted"; } && status pid || true



        case "${GOAL}" in
            start)
                if [ "$VALID_PID" = y ]; then 
                agent_status || true;
                    msg "ssh-agent already running (PID: $GIT_SSH_AGENT_PID, keys loaded: $KEYS_LOADED)"
                    GOAL_REACHED=y
                    return 0
                fi

                msg "Starting isolated ssh-agent..."
                git_agent_start
                status pid
                if [ "$VALID_PID" = y ]; then
                    msg "ssh-agent started (PID: $GIT_SSH_AGENT_PID)"
                else
                    err "Failed to start ssh-agent"
                    return 1
                fi
                ;;

            stop)
                if [ -z "${GIT_SSH_AGENT_PID}" ] && [ "$PID_SET" = n ]; then GOAL_REACHED=y; msg "ssh-agent is already stopped"; return 0; fi

                msg "Stopping ssh-agent (PID: $GIT_SSH_AGENT_PID)"
                git_agent_stop
                   run_checks
                   kill_agent
                   confirm_kill 
                    [ "$HAS_PIDFILE" = y ] && { msg "Removing Pidfile"; cleanup_pidfile && msg "Success" || err "Failed"; }
                    [ "$HAS_SOCKET" = y ]  && { msg "Removing Socket"; cleanup_socket && msg "Success" || err "Failed"; }
                    
                 if [ "${PID_SET}" = n ] && [ "$HAS_SOCKET" = n ] && [ "$HAS_PIDFILE" = n ]; then GOAL_REACHED=y; return 0; fi ;;
        esac
    }

dispatch() { (
  case "${1:-}" in
    stop) GOAL=stop; shift ;;
       *) GOAL=start ;;
  esac

GOAL_REACHED=n; attempts=0
  until [ "$GOAL_REACHED" = y ]; do attempts=$((attempts + 1))
      if [ "$attempts" -gt 4 ]; then err "Failed to '"${GOAL}"' after 4 attempts"; exit 1; fi
      set_env
      status all
      handle_state || exit 1
  done

msg 'Reached '"${GOAL}"' state'

); }
RUN_SET_ONCE=y
dispatch "$@"
)
main "$@"
