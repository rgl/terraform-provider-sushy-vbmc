#!/bin/bash
set -euo pipefail

cat >sushy-vbmc-emulator.cfg <<EOF
SUSHY_EMULATOR_ALLOWED_INSTANCES="$SUSHY_EMULATOR_ALLOWED_INSTANCES"
SUSHY_EMULATOR_LISTEN_IP="0.0.0.0"
EOF

exec sushy-emulator --config "$PWD/sushy-vbmc-emulator.cfg" "$@"
