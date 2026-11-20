#!/bin/dash
agent_pre_checks() (
if [ -n "${GIT_SSH_AGENT_ENV}" ]; 
then 
   if [ -f "${GIT_SSH_AGENT_ENV}" ]
echo "tmp ignore this"
fi
fi
)

start_agent() (
GIT_SSH_AUTH_SOCK=/run/user/"$(id -u)"/git_ssh_agent.sock
SSH_AUTH_SOCK="$GIT_SSH_AUTH_SOCK" ssh-agent -sa "$GIT_SSH_AUTH_SOCK" | sed 's#SSH_#GIT_&#g' > "$GIT_SSH_AGENT_ENV"
)

test_socket() (
SSH_AUTH_SOCK="$GIT_SSH_AUTH_SOCK" \
ssh-add -l >/dev/null 2>&1
    if [ $? -eq 2 ]; then
        rm -f "$GIT_SSH_AUTH_SOCK"
    fi
)

git_agent_start() (
: "${GIT_SSH_AGENT_ENV:=/run/user/$(id -u)/git_ssh_agent.env}"

)
git_agent_start

git_agent_status() {
    [ -r "$GIT_SSH_AGENT_ENV" ] && . "$GIT_SSH_AGENT_ENV"

    # 1. Require a readable PID file
    [ -r "$GIT_SSH_AGENT_ENV" ] || return 1
    read -r pid < "$GIT_SSH_AGENT_ENV"
    [ -n "$pid" ] || return 1

    # 2. Verify the PID is alive and is specifically an ssh-agent bound to our socket path
    case "$(ps -p "$pid" -o args= 2>/dev/null)" in
        *ssh-agent*"-a $GIT_SSH_AUTH_SOCK"*|*ssh-agent*"-sa $GIT_SSH_AUTH_SOCK"*) ;;
        *) return 1 ;;
    esac

    # 3. Confirm the socket itself is live and responsive
    env -i SSH_AUTH_SOCK="$GIT_SSH_AUTH_SOCK" ssh-add -l >/dev/null 2>&1
    [ $? -ne 2 ] || return 1

    export GIT_SSH_AGENT_PID="$pid"
    return 0
}
