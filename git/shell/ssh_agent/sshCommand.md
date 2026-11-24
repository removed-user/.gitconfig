### 1. Recommended Hardening Options for Git

| Option | Recommended Value | Effect on Git |
| :--- | :--- | :--- |
| **`BatchMode`** | `yes` | Prevents interactive prompts (passphrases, host key confirmation) from hanging scripts. |
| **`ClearAllForwardings`** | `yes` | Cancels all local, remote, dynamic, and agent forwardings (`LocalForward`, `RemoteForward`, `DynamicForward`, `ForwardAgent`). |
| **`ForwardAgent`** | `no` | Prevents a compromised Git host from using your local `ssh-agent` to authenticate elsewhere. |
| **`ForwardX11`** | `no` | Equivalent to `-x`; blocks X11 forwarding. |
| **`RequestTTY`** | `no` | Equivalent to `-T`; disables PTY allocation (Git uses raw pipes). |
| **`EnableEscapeCommandline`** | `no` | Disables the `~C` runtime command line (prevents adding port forwards mid-session). |
| **`EscapeChar`** | `none` | Disables `~` escape sequences so binary Git packfile data can never trigger SSH escape commands. |
| **`PermitLocalCommand`** | `no` | Blocks execution of arbitrary local commands via `LocalCommand` in config files. |
| **`GSSAPIAuthentication`** | `no` | Skips Kerberos/GSSAPI auth attempts, avoiding delays and exposure on public Git hosts. |
| **`GSSAPIDelegateCredentials`** | `no` | Equivalent to `-k`; prevents forwarding Kerberos tickets. |
| **`PasswordAuthentication`** | `no` | Disables password auth (Git hosts use SSH keys; `BatchMode=yes` also enforces this). |
| **`KbdInteractiveAuthentication`** | `no` | Disables keyboard-interactive challenges. |
| **`HostbasedAuthentication`** | `no` | Disables `.rhosts`/host-based authentication. |
| **`IdentitiesOnly`** | `yes` | Forces SSH to only use keys explicitly configured or loaded in your designated `IdentityAgent`, preventing agent key-enumeration leaks. |
| **`IdentityAgent`** | `/path/to/sock` | Points SSH strictly to your isolated `git_ssh_agent.sock` (or set via `SSH_AUTH_SOCK`). |
| **`StrictHostKeyChecking`** | `yes` | Refuses to connect to unknown or changed host keys (safe when paired with pre-populated `UserKnownHostsFile`). |
| **`UpdateHostKeys`** | `no` | Prevents servers from silently adding/rotating keys in your `known_hosts` files. |
| **`AddKeysToAgent`** | `no` | Prevents SSH from automatically adding unencrypted disk keys into your agent. |
| **`Tunnel`** | `no` | Disables `tun`/`tap` layer-2/3 VPN tunneling. |

---

### 2. Avoid — Will Break Git or Your Wrapper

| Option | Why it breaks Git |
| :--- | :--- |
| **`StdinNull`** | Equivalent to `-n`; redirects `stdin` to `/dev/null`, breaking `git fetch`/`push` packfile streaming. |
| **`ForkAfterAuthentication`** | Equivalent to `-f`; backgrounds SSH before running the remote command, severing Git's `stdin`/`stdout` pipe. |
| **`SessionType`** | Setting `none` (equivalent to `-N`) prevents executing `git-upload-pack` / `git-receive-pack`. Keep default (`default`). |
| **`RemoteCommand`** | Overrides the `git-upload-pack` / `git-receive-pack` command that Git passes to SSH. Leave unset. |
| **`NoHostAuthenticationForLocalhost`** | Weakens host verification if testing against local Git servers; keep `no`. |
