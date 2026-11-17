### Flags
    [-a]: bind agent to Unix_Socket address

    [-y]: Export pubkey in Openssh format

    [-k]: kill agent with "${SSH_AGENT_PID}"

    [-P]: Allowed Providers (pkcs#11 libraries)

    [-c]: print c-shell commands > stdout

    [-s]: print bourne-shell commands > stdout

    [-O]: Set option; one of allow-remote-pkcs11, no-restrict-websafe, websafe-allow

    [-l]: Lifespan of added key identities in the agent

### ENV
    SSH_AGENT_PID
    SSH_AUTH_SOCK
    
### ssh-add
    [-K]: Load resident keys into ssh-agent

    [-D]: Delete all identities from ssh-agent

    [-L]: List pubkey params of all identities represented by agent

    [-l]: List fingerprints of all identities represented by agent




    [-t]: Lifespan of added key identities

    [-S]: Allowed Providers (fido Auth)
    
    [-x]: Lock agent
    
    [-x]: Unlock agent

    [-v]: verbose (up to 3x)
