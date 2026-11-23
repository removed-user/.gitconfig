socket_status() {
    socket_exists
    STALE_SOCKET=y
    [ "$HAS_SOCKET" = y ] || return 0

    # Check /proc/net/unix for an active listener on $GIT_SSH_AUTH_SOCK
    awk -v s="$GIT_SSH_AUTH_SOCK" 'NR>1 && $8==s && $6=="01" { found=1; exit } END { exit !found }' /proc/net/unix && STALE_SOCKET=n
}
