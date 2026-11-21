ssh_add() (
# The Ai insists the -s flags are an issue... seems standard will see
ssh-add \
  -H "/home/user/.ssh/known_hosts/known_hosts-github" \
  -H "/home/user/.ssh/known_hosts/known_hosts-gitlab" \
  -h github.com \
  -h gitlab.com \
  -E sha256 \
  -t 4H \
  -S '' \
  -s ''  \
  -
  )
