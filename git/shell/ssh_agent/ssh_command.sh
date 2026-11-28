#!/bin/dash
main() (
. "${GIT_CONFIG_DIR}/shell/ssh_agent/common.dash"
message() { ( RED='\033[0;31m'; GREEN='\033[0;32m'; CLR='\033[0m'; cmd="${1}";  [ $# -gt 0 ] && shift; MESSAGE="${*}"; case $cmd in msg) printf '%b%s%b: %s\n' "${GREEN}" '[STATUS]' "${CLR}" "${MESSAGE}" >&2;; err) printf '%b%s%b: %s\n' "${RED}" '[ERROR]' "${CLR}" "${MESSAGE}" >&2;; esac; ); }; err() ( message err "$@"; ); msg() ( message msg "$@"; );

print_startup_info() {
    caller_name=$(ps -p "$PPID" -o comm= 2>/dev/null)
    caller_args=$(ps -p "$PPID" -o args= 2>/dev/null)

    printf '=== SSH Wrapper Startup ===\n' >&2
    printf '  Script : %s (PID: %s)\n' "${0##*/}" "$$" >&2
    printf '  Caller : %s (PPID: %s)\n' "${caller_name:-unknown}" "$PPID" >&2
    printf '  Command: %s\n' "${caller_args:-unknown}" >&2
    printf '  Args   : %s\n' "${*:-none}" >&2
    printf '===========================\n' >&2
}

case "${caller_name}" in
    *git*) ;;
    *) print_startup_info ;;
esac

 ## Get/Set Environment + PID
    set_env

[ -z "$GIT_SSH_AGENT_PID" ] && if [ -r "$PIDFILE" ]; then
read -r GIT_SSH_AGENT_PID < "$PIDFILE"; else 
( exec "${HOME}"/.config/git/shell/ssh_agent/git_agent_runner.sh )
fi

   ### Adds to the env set by (internal) git_add; Sets options for command, and adds the key(s) recieved on stdin
    git_add_key() { ( 
     git_add() { ( set_env; SSH_AUTH_SOCK="$GIT_SSH_AUTH_SOCK" SSH_AGENT_PID="$GIT_SSH_AGENT_PID" ssh-add "$@"; ); }
       git_add -t 4H -s '' -S '' \
         -H "${HOME}/.ssh/known_hosts/known_hosts-github" \
         -H "${HOME}/.ssh/known_hosts/known_hosts-gitlab" \
           -h github.com \
           -h gitlab.com \
             -E sha256 -  ; ) }

exec_ssh() { ( set_env; unset GOAL PIDFILE EXTERNAL_AUTH_SOCK EXTERNAL_AGENT_PID HAS_SOCKET HAS_PIDFILE RUNNING KEYS_LOADED VALID_PID STALE_PID ORPHAN PID_SET PID_SOURCE GOAL_REACHED attempts
  set_args
    eval "set -- ${SSH_ARGS} \"\$@\""
      SSH_AGENT_PID="$GIT_SSH_AGENT_PID" SSH_AUTH_SOCK="$GIT_SSH_AUTH_SOCK" \
   exec /usr/bin/ssh "$@";
   ); }


set_args() {
### Hardened SSH Options for Git
#### Most should be standard ssh config; But!
##### Setting it here makes it work without a well configured host

SSH_ARGS=""
opt() {
  # Escapes any ' as '\'' and wraps the entire option in single quotes
  val=$(printf '%s' "$1" | sed "s/'/'\\\\''/g")
  SSH_ARGS="${SSH_ARGS} -o '${val}'"
}
### opt() { printf -v SSH_ARGS '%s -o %q' "${SSH_ARGS}" "$1"; }




# Situational
## Prevents servers from silently adding/rotating keys in your `known_hosts`
opt UpdateHostKeys=no
## Prevents SSH from automatically adding unencrypted disk keys into your agent. 
opt AddKeysToAgent=no
## Redundant Redundancy is redundant

opt User=git
opt BatchMode=yes

opt Tunnel=no
opt StdinNull=no
opt RequestTTY=no
opt ForwardX11=no
opt ForwardAgent=no
opt EscapeChar=none
opt RemoteCommand=none
opt ClearAllForwardings=yes
opt GSSAPIAuthentication=no
opt PermitLocalCommand=no
opt PasswordAuthentication=no
opt GSSAPIDelegateCredentials=no
opt EnableEscapeCommandline=no
opt KbdInteractiveAuthentication=no
opt IdentityAgent=/run/user/"${_UID_}"/git_agent/git_ssh_agent.sock

opt SessionType=default
opt ForkAfterAuthentication=no
opt HostbasedAuthentication=no
opt NoHostAuthenticationForLocalhost=no
opt ControlMaster=no
opt IdentityFile=none

opt ProxyCommand=none
opt ProxyJump=none
opt PKCS11Provider=none
opt KnownHostsCommand=none
opt PreferredAuthentications=publickey
opt PubkeyAuthentication=yes
opt CanonicalizeHostname=no
opt VerifyHostKeyDNS=no
opt VisualHostKey=no
opt ControlPath=none
opt ControlPersist=no

opt LocalCommand=none
opt PermitRemoteOpen=none
opt GatewayPorts=no
opt ExitOnForwardFailure=yes
opt ForwardX11Trusted=no
opt ForwardX11Timeout=1
opt XAuthLocation=none
opt NumberOfPasswordPrompts=0
opt ProxyUseFdpass=no
opt StreamLocalBindUnlink=no




set_host_keys() { files=""; for host in ${HOSTLIST}; do if [ -r "${HOME}/.ssh/known_hosts/known_hosts-${host}" ]; then files="${files:+${files} }%d/.ssh/known_hosts/known_hosts-${host}"; fi; done; KH_FILES="${files}"; }; 
HOSTLIST="gitlab github" 
HOSTLIST="${HOSTLIST}" set_host_keys

if [ -n "${KH_FILES}" ]; then
   opt "GlobalKnownHostsFile=${KH_FILES}"
   opt "UserKnownHostsFile=${KH_FILES}"
   ## Refuses to connect to unknown or changed host keys
   opt StrictHostKeyChecking=yes
else 
   ## Fallback, allow new keys on new hosts
   opt StrictHostKeyChecking=accept-new
fi; 
}

case "$KEYS_LOADED" in
n)  git_add_key        ;;
y)                     ;;
esac

if [ $# -gt 0 ]; then 
exec_ssh "$@"
fi
)
main "$@"
