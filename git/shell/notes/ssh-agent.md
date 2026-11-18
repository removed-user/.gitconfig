## ssh-agent
    [-a]: bind agent to Unix_Socket address

    [-k]: kill agent with "${SSH_AGENT_PID}"

    [-D]: Foreground mode (no-forking)

    [-E]: Fingerprint hash (sha256,md5)

#### Print commands for eval by "${SHELL}" 

    [-c]: c-shell cmds > stdout

    [-s]: bourne-shell cmds > stdout

#### Allowed Providers

    [-P]: Allowed Providers (pkcs#11 libraries)

#### Misc

    [-y]: Export pubkey in Openssh format

    [-t]: Lifespan of added key identities

    [-O]: Set option; One of:
        - allow-remote-pkcs11
        - no-restrict-websafe
        - websafe-allow

### ENV
    SSH_AGENT_PID
    SSH_AUTH_SOCK
