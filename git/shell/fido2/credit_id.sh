AUTHENTICATOR=/dev/hidrawX
CRED_ID=$(fido2-token -L -k 'ssh:' "${AUTHENTICATOR}" | grep "user@host" | awk '{print $1}')
