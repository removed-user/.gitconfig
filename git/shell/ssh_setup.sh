pgrep ssh-agent

if ! ssh-add -l >/dev/null 2>&1; then ssh-add -K; fi
