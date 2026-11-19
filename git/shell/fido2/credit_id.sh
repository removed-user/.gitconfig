AUTHENTICATOR_DEVICE=/dev/hidrawX
CRED_ID=$(fido2-token -L -k 'ssh:' "${AUTHENTICATOR_DEVICE}" | grep "user@host" | awk '{print $1}')
fido2-token -I -k 'ssh:' -i "${CRED_ID}" "${AUTHENTICATOR_DEVICE}"
