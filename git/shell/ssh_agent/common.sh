#!/bin/dash

  set_env() {         
         _UID_="$(id -u)"
         PIDFILE=/run/user/"${_UID_}"/git_agent/git_ssh_agent.pid
         export GIT_SSH_AUTH_SOCK=/run/user/"${_UID_}"/git_agent/git_ssh_agent.sock
         SSH_ASKPASS='' SSH_ASKPASS_REQUIRE=never DISPLAY='' SSH_PKCS11_PROVIDER=''
[ -x /lib/openssh/ssh-sk-helper ] && export SSH_SK_PROVIDER='/lib/openssh/ssh-sk-helper'
[ -x /usr/lib/openssh/ssh-sk-helper ] && export SSH_SK_PROVIDER='/lib/openssh/ssh-sk-helper'

         
[ -d "${HOME}/.config/git" ] && GIT_CONFIG_DIR="${HOME}/.config/git"
[ -d "${HOME}/.config/git/git" ] && GIT_CONFIG_DIR="${HOME}/.config/git/git"
export GIT_CONFIG_DIR
}; 
     git_agent() { ( set_env; SSH_AUTH_SOCK="$GIT_SSH_AUTH_SOCK" SSH_AGENT_PID="$GIT_SSH_AGENT_PID" ssh-agent "$@"; ); }
     git_add() { ( set_env; SSH_AUTH_SOCK="$GIT_SSH_AUTH_SOCK" SSH_AGENT_PID="$GIT_SSH_AGENT_PID" ssh-add "$@"; ); }
