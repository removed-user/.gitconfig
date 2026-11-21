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

#### Allowed Providers

    [-S]: Allowed Providers (fido Auth)
    
    [-s]: Allowed Providers (pkcs#11 libraries)

#### Hosts

    [-H]: Known Hosts Files
        (1+ invocations:ex:`-H 1 -H 2`)

    [-h]: Destination Constraint

#### Agent Locking

    [-x]: Lock agent
    
    [-x]: Unlock agent

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
