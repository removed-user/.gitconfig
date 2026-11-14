[alias]

    ssh-yubikey = "!f() { \
        KEY=\"$HOME/.ssh/$1\"; \
        shift; \
        if [ ! -f \"$KEY\" ]; then \
            echo \"Extracting YubiKey resident keys...\" >&2; \

            (cd \"$HOME/.ssh\" && ssh-keygen -K); \
        fi; \
        exec ssh -i \"$KEY\" -o IdentitiesOnly=yes \"$@\"; \
    }; f"
    
[core]
    sshCommand = git ssh-yubikey id_ed25519_sk_rk_github
