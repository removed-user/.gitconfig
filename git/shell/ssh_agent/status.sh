git_agent_status() {
    # 1. Require a readable PID file
    [ -r "$GIT_SSH_AGENT_PID_FILE" ] || return 1
    read -r pid < "$GIT_SSH_AGENT_PID_FILE"
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
