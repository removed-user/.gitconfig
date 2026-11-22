#!/bin/dash
main() (

GIT_SSH_AUTH_SOCK=/run/user/"$(id -u)"/git_ssh_agent.sock
GIT_SSH_AGENT_PID="${GIT_SSH_AGENT_PID:-}"

PIDFILE=/run/user/"$(id -u)"/git_ssh_agent.pid
EXTERNAL_AUTH_SOCK="${SSH_AUTH_SOCK:-}"
EXTERNAL_AGENT_PID="${SSH_AGENT_PID:-}"

socket_exists() { HAS_SOCKET=0; [ -S "$GIT_SSH_AUTH_SOCK" ] && HAS_SOCKET=1 || HAS_SOCKET=0 ; }
pidfile_exists() { HAS_PIDFILE=0; [ -r "$PIDFILE" ] && HAS_PIDFILE=1 || HAS_PIDFILE=0; }

get_pid() { pidfile_exists && read -r GIT_SSH_AGENT_PID < "$PIDFILE"; }

 ## Get/Set Environment + PID
  set_env() {
    SSH_AUTH_SOCK="${GIT_SSH_AUTH_SOCK:-}"
    [ -n "${GIT_SSH_AGENT_PID}" ] && SSH_AGENT_PID="${GIT_SSH_AGENT_PID:-}" export GIT_SSH_AGENT_PID SSH_AGENT_PID || unset GIT_SSH_AGENT_PID SSH_AGENT_PID
    export GIT_SSH_AUTH_SOCK SSH_AUTH_SOCK
    export SSH_SK_PROVIDER='' SSH_ASKPASS='' SSH_ASKPASS_REQUIRE=never DISPLAY=''
   }

   find_git_agent_pid() { (
    # Usage:
      # find_git_agent_pid cmd                   -> Goal B: find rogue/orphaned processes by exact command
      # find_git_agent_pid pid "$PID"            -> Goal A & C: verify pidfile PID or confirm kill
      # find_git_agent_pid any "$PID"            -> Either: Match any process with the exact command
      mode="${1:-pid}"
      expected_pid="${2:-}"
      # intentional spaces below (because of argv formatting)
      target_cmd="ssh-agent -P  -sa $GIT_SSH_AUTH_SOCK"

      ps -eo pid=,args= | awk -v mode="$mode" -v expected_pid="$expected_pid" -v target_cmd="$target_cmd" '
         /[s]sh-agent/ {
          pid = $1
          sub(/^[ \t]*[0-9]+[ \t]+/, "")

            pid_match = (expected_pid != "" && pid == expected_pid)
            cmd_match = ($0 == target_cmd)
        
       if (mode == "pid" && pid_match) { print "PID:" pid }
         else if (mode == "cmd" && cmd_match) { print "CMD:" pid }
           else if (mode == "any" && (pid_match || cmd_match)) { print "ANY:" pid }
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
run_checks() (
   assert_not_equal() { if [ -n "$1" ] && [ "$2" = "$1" ]; then printf '%s\n\t%s\n' 'Refusing to stop agent:' "$3" >&2; exit 1; fi; }; assert_not_equal "${EXTERNAL_AUTH_SOCK:-}" "${GIT_SSH_AUTH_SOCK}" 'Socket matches External SSH_AUTH_SOCK' ; assert_not_equal "${EXTERNAL_AGENT_PID:-}" "${GIT_SSH_AGENT_PID}" 'PID matches External SSH_AGENT_PID'
)

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
        *)      printf 'Usage: %s {start|stop|status} [args...]\n' "${0##*/}" >&2; exit 1 ;;
    esac
)

dispatch "$@"
); }

main "$@"
