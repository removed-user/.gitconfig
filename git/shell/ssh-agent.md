## ssh-agent
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
    
## ssh-add
    [-K]: Load resident keys into ssh-agent


#### List Keys

    [-L]: List pubkey params of all identities represented by agent

    [-l]: List fingerprints of all identities represented by agent


#### Delete Keys

    [-D]: Delete all identities from ssh-agent

    [-d]: Delete listed identities from ssh-agent
         (Use `-` for `stdin`)

#### Agent Locking

    [-x]: Lock agent
    
    [-x]: Unlock agent
    
#### Misc
    [-v]: verbose (up to 3x)

    [-t]: Lifespan of added key identities

    [-S]: Allowed Providers (fido Auth)

    [-H]: Known Hosts 
        (1+ invocations:ex:`-H 1 -H 2`)
