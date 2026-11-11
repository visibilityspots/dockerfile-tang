#!/bin/sh
set -e

if [ ! -d "${JWKDIR}" ] || [ ! -w "${JWKDIR}" ]; then
    echo "jwkdir ${JWKDIR} does not exist or is not writable" >&2
    exit 1
fi

# Generate a signing and an exchange key on first start only. Existing keys,
# including rotated ones (.<thumbprint>.jwk), are never touched.
if ! ls "${JWKDIR}"/*.jwk >/dev/null 2>&1; then
    echo "no keys in ${JWKDIR}, generating"
    /usr/libexec/tangd-keygen "${JWKDIR}"
fi

exec /usr/libexec/tangd -l -p "${PORT}" "${JWKDIR}"
