#!/bin/dash
git_agent_start() {
: "${GIT_SSH_AUTH_SOCK:=/run/user/$(id -u)/git_ssh_agent.sock}"
export GIT_SSH_AUTH_SOCK
AGENT_START_CMD="$(ssh-agent -sa "$GIT_SSH_AUTH_SOCK" |\
sed \
    -e 's/SSH_AUTH_SOCK/GIT_SSH_AUTH_SOCK/g' \
    -e 's/SSH_AGENT_PID/GIT_SSH_AGENT_PID/g')"

env -i SSH_AUTH_SOCK="$GIT_SSH_AUTH_SOCK" ssh-add -l >/dev/null 2>&1
    if [ $? -eq 2 ]; then
        rm -f "$GIT_SSH_AUTH_SOCK"
            eval "${AGENT_START_CMD}" >/dev/null
    fi
}

git_agent_start() (
if [ -n "${GIT_SSH_AGENT_ENV}" ]; 
then 
   if [ -f "${GIT_SSH_AGENT_ENV}" ]
read snippets

    : "${GIT_SSH_AGENT_ENV:=/run/user/$(id -u)/git_ssh_agent.env}"

 
 GIT_SSH_AUTH_SOCK=/run/user/"$(id -u)"/git_ssh_agent.sock
    export GIT_SSH_AUTH_SOCK

    if ! ( unset SSH_AGENT_PID; SSH_AUTH_SOCK="$GIT_SSH_AUTH_SOCK" ssh-add -l >/dev/null 2>&1 );
    then
        [ $? -eq 2 ] && (
            unset SSH_AUTH_SOCK SSH_AGENT_PID
            rm -f "$GIT_SSH_AUTH_SOCK"
            ssh-agent -sa "$GIT_SSH_AUTH_SOCK" | \
                sed \
                    -e 's/SSH_AUTH_SOCK/GIT_SSH_AUTH_SOCK/g' \
                    -e 's/SSH_AGENT_PID/GIT_SSH_AGENT_PID/g' > "$GIT_SSH_AGENT_ENV"
        )
    fi

    [ -r "$GIT_SSH_AGENT_ENV" ] && . "$GIT_SSH_AGENT_ENV"
)
git_agent_start
