#!/usr/bin/env bash
set -euo pipefail

# Wrapper for repro_menu_boot.expect
# Required:
#   REPRO_CMD
# Optional:
#   REPRO_LOG, BOOT_MENU_DOWN, SHELL_MENU_DOWN, TARGET_MENU_DOWN, MENU_SETTLE_MS

REPRO_LOG="${REPRO_LOG:-/tmp/repro-menu-boot.log}"
mkdir -p "$(dirname "$REPRO_LOG")"
rm -f "$REPRO_LOG"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

set +e
expect "$SCRIPT_DIR/repro_menu_boot.expect"
rc=$?
set -e

echo "expect exit code: $rc"
echo "signature scan:"
rg -n "REPRO:|TRACE_|Memory starting at|Aborted\. Press any key to exit\." "$REPRO_LOG" || true

exit "$rc"
