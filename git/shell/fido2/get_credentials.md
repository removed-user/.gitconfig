# CRED_ID

```bash

AUTHENTICATOR_DEVICE=/dev/hidrawX
CRED_ID=$(fido2-token -L -k 'ssh:' "${AUTHENTICATOR_DEVICE}" | grep "user@host" | awk '{print $1}')
fido2-token -I -k 'ssh:' -i "${CRED_ID}" "${AUTHENTICATOR_DEVICE}"
```

## List Stored Credentials SSH

### Query FIDO2 device for resident credentials: rp_id (`ssh:`):

```bash
fido2-token -L -k ssh: /dev/hidrawX
```
