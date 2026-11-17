## ssh-agent
    [-a]: bind agent to Unix_Socket address

    [-k]: kill agent with "${SSH_AGENT_PID}"

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
    
## ssh-add

#### Load key

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

#### Allowed Providers

    [-S]: Allowed Providers (fido Auth)
    
    [-s]: Allowed Providers (pkcs#11 libraries)

#### Hosts

    [-H]: Known Hosts Files
        (1+ invocations:ex:`-H 1 -H 2`)

    [-h]: Destination Constraint

#### Misc

    [-t]: Lifespan of added key identities

    [-v]: verbose (up to 3x)

    [-q]: quiet

    [-c]: Require ssh-askpass authentication 
         (for each use)

    [-E]: Use Hash Alg for Fingerprint (md5, sha256)

#### ENV

    SSH_AUTH_SOCK
    SSH_SK_PROVIDER
    SSH_ASKPASS
    SSH_ASKPASS_REQUIRE
    DISPLAY
    
#### Exit codes
0 success
1 fail
2 couldn't contact agent
