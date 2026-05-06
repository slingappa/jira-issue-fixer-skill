#!/usr/bin/env bash
set -euo pipefail

# Capture interactive repro with terminal I/O timing logs.
# Usage:
#   capture_repro_session.sh --cmd "<runtime command>" [--out-dir <dir>]
#
# Outputs:
#   <out-dir>/session.log
#   <out-dir>/timing.log

CMD=""
OUT_DIR="${PWD}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --cmd)
      CMD="${2:-}"
      shift 2
      ;;
    --out-dir)
      OUT_DIR="${2:-}"
      shift 2
      ;;
    -h|--help)
      cat <<USAGE
Capture interactive repro logs using script(1).

Required:
  --cmd <runtime-command>

Optional:
  --out-dir <dir>   Output directory (default: current directory)

Example:
  capture_repro_session.sh \
    --cmd "cd /abs/path/to/runtime && ./QEMU-or-target-binary <args>" \
    --out-dir /abs/path/to/log-output-dir
USAGE
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$CMD" ]]; then
  echo "--cmd is required" >&2
  exit 1
fi

mkdir -p "$OUT_DIR"
SESSION_LOG="$OUT_DIR/session.log"
TIMING_LOG="$OUT_DIR/timing.log"

rm -f "$SESSION_LOG" "$TIMING_LOG"

echo "Capturing interactive session..."
echo "  session: $SESSION_LOG"
echo "  timing : $TIMING_LOG"

echo "Run the exact repro key sequence in the spawned session."
echo "Exit the target process or press Ctrl-C to finish capture."

script --timing="$TIMING_LOG" -q "$SESSION_LOG" -c "$CMD"

echo "Capture complete."
echo "session.log: $SESSION_LOG"
echo "timing.log : $TIMING_LOG"
