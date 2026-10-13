#!/usr/bin/bash
set -euo pipefail

cat >sushy-vbmc-emulator.cfg <<EOF
SUSHY_EMULATOR_ALLOWED_INSTANCES="$SUSHY_EMULATOR_ALLOWED_INSTANCES"
SUSHY_EMULATOR_LISTEN_IP="0.0.0.0"
EOF

extra_args=()

if [ "${SUSHY_VBMC_HTTPS:-}" == "snake-oil" ]; then
    unset SUSHY_VBMC_TLS

    KEY_PATH=snake-oil-key.pem
    CRT_PATH=snake-oil-crt.pem

    if [ ! -f "$KEY_PATH" ] || [ ! -f "$CRT_PATH" ]; then
        openssl \
            req \
            -x509 \
            -newkey rsa:2048 \
            -nodes \
            -keyout "$KEY_PATH" \
            -out "$CRT_PATH" \
            -days 365 \
            -subj "/CN=localhost" \
            -addext "subjectAltName=DNS:localhost"
    fi

    extra_args+=(
        --ssl-key "$KEY_PATH"
        --ssl-certificate "$CRT_PATH"
    )
fi

exec sushy-emulator \
    --config "$PWD/sushy-vbmc-emulator.cfg" \
    "${extra_args[@]}" \
    "$@"
