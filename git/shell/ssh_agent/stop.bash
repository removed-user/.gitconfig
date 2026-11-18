function start_ssh_agent() {
ssh-agent -k
[[ $? != 0 ]] && kill "$SSH_AGENT_PID"
rm -f "$SSH_AUTH_SOCK"
}
