#!/bin/dash

 ## Get/Set Environment + PID
  set_env() {         
         PIDFILE=/run/user/"$(id -u)"/git_agent/git_ssh_agent.pid
         export GIT_SSH_AUTH_SOCK=/run/user/"$(id -u)"/git_agent/git_ssh_agent.sock
         export SSH_SK_PROVIDER='' SSH_ASKPASS='' SSH_ASKPASS_REQUIRE=never DISPLAY=''
         };

set_env

[ -z "$GIT_SSH_AGENT_PID" ] && if [ -r "$PIDFILE" ]; then
read -r GIT_SSH_AGENT_PID < "$PIDFILE"; else 
( exec ./git_agent_runner.sh )
fi

   ### Adds to the env set by (internal) git_add; Sets options for command, and adds the key(s) recieved on stdin
    git_add_key() { ( 
     git_add() { ( set_env; SSH_AUTH_SOCK="$GIT_SSH_AUTH_SOCK" SSH_AGENT_PID="$GIT_SSH_AGENT_PID" ssh-add "$@"; ); }
       git_add -t 4H -s '' -S '' \
         -H "${HOME}/.ssh/known_hosts/known_hosts-github" \
         -H "${HOME}/.ssh/known_hosts/known_hosts-gitlab" \
           -h github.com \
           -h gitlab.com \
             -E sha256 - \
    ; ) }

exec_ssh() { ( set_env; unset GOAL PIDFILE EXTERNAL_AUTH_SOCK EXTERNAL_AGENT_PID HAS_SOCKET HAS_PIDFILE RUNNING KEYS_LOADED VALID_PID STALE_PID ORPHAN PID_SET PID_SOURCE GOAL_REACHED attempts
exec /usr/bin/ssh -o User=git -o BatchMode=yes "$@";
); }
## -a -k -T -x -o ClearAllForwardings=yes


set_args() { (
  SSH_ARGS=""
    opt() { printf -v SSH_ARGS '%s -o %q' "${SSH_ARGS}" "$1"; }


set_host_keys() { files="";
  HOSTLIST="gitlab github"
   for host in ${HOSTLIST}; do
     if [ -r "${HOME}/.ssh/known_hosts/known_hosts-${host}" ]; then  files="${files:+${files} }%d/.ssh/known_hosts/known_hosts-${host}";
       fi; done; KH_FILES="${files}"

         if [ -n "${KH_FILES}" ]; then
opt "GlobalKnownHostsFile=${KH_FILES}"
opt "UserKnownHostsFile=${KH_FILES}"
## Refuses to connect to unknown or changed host keys
opt StrictHostKeyChecking=yes
         else 
## Fallback, allow new keys on new hosts
opt StrictHostKeyChecking=accept-new
         fi; }; set_host_keys }




#  if [ "$KEYS_LOADED" = n ]; then git_add_key; fi
#  [ $# -gt 0 ] && exec_ssh "$@"
#  fi
