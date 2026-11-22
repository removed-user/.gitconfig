#!/bin/dash
main() (

RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m' 
CLR='\033[0m'


 ## Get/Set Environment + PID
  set_env() {
      set_once() { RAN_SET_ONCE=1;
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
   socket_exists() { HAS_SOCKET=0; [ -S "$GIT_SSH_AUTH_SOCK" ] && HAS_SOCKET=1 || HAS_SOCKET=0 ; }

   get_pid() {
      pidfile_exists() { HAS_PIDFILE=0; [ -r "$PIDFILE" ] && HAS_PIDFILE=1 || HAS_PIDFILE=0; }
      pid_set() { case "${GIT_SSH_AGENT_PID:-}" in ''|0*|*[!0-9]*) unset GIT_SSH_AGENT_PID PID_SOURCE; PID_SET=0 ;; [1-9]*) PID_SET=1 PID_SOURCE="${1:-}";; esac; }
      try_read_pidfile() { GIT_SSH_AGENT_PID=""; case "$HAS_PIDFILE" in 0) PID_SET=0 ;; 1) read -r GIT_SSH_AGENT_PID < "$PIDFILE" || true ;; *) return 1 ;; esac; pid_set "pidfile"; }
      try_find() {  GIT_SSH_AGENT_PID=$(find_git_agent_pid cmd | awk -F ':' '{print $2}'); pid_set "found"; }
    pidfile_exists
    try_read_pidfile
    [ "$PID_SET" -eq 1 ] || check_orphans || true
    [ "$PID_SET" -eq 1 ] || RUNNING=0
   } 
   
   pid_status() {
        [ "$PID_SET" -eq 1 ] || return 1
         validate_pid() { VALID_PID=0 STALE_PID=0; [ -n "$(find_git_agent_pid pid "$GIT_SSH_AGENT_PID")" ] && VALID_PID=1 STALE_PID=0 || STALE_PID=1 VALID_PID=0; }
         check_orphans() { ORPHAN=0; try_find; ORPHAN="${PID_SET}"; }

    case "${PID_SOURCE:-}" in
           pidfile) validate_pid; if [ "$STALE_PID" -eq 1 ]; then check_orphans; fi ;;
           found) VALID_PID=0 STALE_PID=0 ORPHAN=1 ;;
              '') check_orphans ;;
    esac
  }

   find_git_agent_pid() { (
     # Usage:
      # find_git_agent_pid cmd                   -> Goal B: find rogue/orphaned processes by exact command
      # find_git_agent_pid pid "$PID"            -> Goal A & C: verify pidfile PID or confirm kill
      # find_git_agent_pid any "$PID"            -> Either: Match any process with the exact command
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
           else if (mode == "cmd" && cmd_match) { print "CMD:" pid; exit }
             else if (mode == "any" && (pid_match || cmd_match)) { print "ANY:" pid; exit }
       }'
     ); }
     test_agent_process() {
       RUNNING=0; KEYS_LOADED=0; set_env || return 1; git_add -l >/dev/null 2>&1
       case $? in
           0) RUNNING=1; KEYS_LOADED=1; return 0 ;;
           1) RUNNING=1; KEYS_LOADED=0; return 0 ;;
           2) RUNNING=0; return 0 ;;
           *) return 1 ;;
       esac
      }
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
     cleanup_socket() { ( socket_exists && rm -f "${GIT_SSH_AUTH_SOCK}" || return 0; ); export HAS_SOCKET=0; }   
     cleanup_pidfile() { ( pidfile_exists && rm -f "$PIDFILE" || return 0; ); export HAS_PIDFILE=0; }


git_agent_stop() { set_env; 
   # Safety checks:
         # Never affect External ssh-agent(s) Socket ot Process
      run_checks() ( assert_not_equal() { if [ -n "$1" ] && [ "$2" = "$1" ]; then printf '%s\n\t%s\n' 'Refusing to stop agent:' "$3" >&2; exit 1; fi; }; assert_not_equal "${EXTERNAL_AUTH_SOCK:-}" "${GIT_SSH_AUTH_SOCK}" 'Socket matches External SSH_AUTH_SOCK' ; assert_not_equal "${EXTERNAL_AGENT_PID:-}" "${GIT_SSH_AGENT_PID}" 'PID matches External SSH_AGENT_PID'; )
      kill_agent() { (  set_env; git_agent -k >/dev/null 2>&1; ); }
      confirm_kill() { [ -n "${GIT_SSH_AGENT_PID:-}" ] || return 0; i=0; while [ "$i" -lt 10 ]; do if [ -z "$(find_git_agent_pid pid "$GIT_SSH_AGENT_PID")" ]; then unset GIT_SSH_AGENT_PID SSH_AGENT_PID;  return 0;  fi; sleep 0.1; i=$((i + 1)); done; printf 'Error: ssh-agent (PID: %s) failed to terminate within 1s\n' "$GIT_SSH_AGENT_PID" >&2; return 1; }
      cleanup() { cleanup_socket && unset GIT_SSH_AUTH_SOCK; cleanup_pidfile && unset PIDFILE; }
   run_checks && kill_agent && confirm_kill && cleanup 
  }

dispatch() { (
    cmd="${1:-}"
    [ $# -gt 0 ] && shift
    case "$cmd" in
        start)  git_agent_start "$@" ;;
        stop)   git_agent_stop "$@" ;;
        *)      printf 'Usage: %s {start|stop}\n' "${0##*/}" >&2; exit 1 ;;
    esac
); }

set_env
status
dispatch "$@"
)

main "$@"
