#!/usr/bin/env bash
# =============================================================================
#  SnapBack — Compatibility redirect for older client update checks
# =============================================================================
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
if [ -f "$DIR/install-snapback.command" ]; then
    exec bash "$DIR/install-snapback.command" "$@"
else
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/arunofhyd/SnapBack/main/install-snapback.command)"
fi
