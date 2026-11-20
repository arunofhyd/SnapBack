#!/usr/bin/env bash
# =============================================================================
#  build_app.sh — Fast Local Development & Bundle Builder for SnapBack
# =============================================================================
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
bash "$DIR/install-snapback.command" "$@"
