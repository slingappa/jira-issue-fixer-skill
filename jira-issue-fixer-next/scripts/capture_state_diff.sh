#!/usr/bin/env bash
set -euo pipefail

# Capture state snapshots and produce a normalized diff.
#
# Example:
#   capture_state_diff.sh \
#     --before-cmd "<state dump cmd before sequence>" \
#     --after-cmd "<state dump cmd after sequence>" \
#     --out-dir /tmp/state-diff \
#     --label shell-exit-vs-boot

BEFORE_CMD=""
AFTER_CMD=""
OUT_DIR="$PWD"
LABEL="state"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --before-cmd)
      BEFORE_CMD="${2:-}"
      shift 2
      ;;
    --after-cmd)
      AFTER_CMD="${2:-}"
      shift 2
      ;;
    --out-dir)
      OUT_DIR="${2:-}"
      shift 2
      ;;
    --label)
      LABEL="${2:-}"
      shift 2
      ;;
    -h|--help)
      cat <<USAGE
Capture before/after state and produce a unified diff.

Required:
  --before-cmd <command>
  --after-cmd <command>

Optional:
  --out-dir <dir>   Output directory (default: current directory)
  --label <name>    Prefix for output files (default: state)
USAGE
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$BEFORE_CMD" || -z "$AFTER_CMD" ]]; then
  echo "--before-cmd and --after-cmd are required" >&2
  exit 1
fi

mkdir -p "$OUT_DIR"

BEFORE_RAW="$OUT_DIR/${LABEL}.before.raw.log"
AFTER_RAW="$OUT_DIR/${LABEL}.after.raw.log"
BEFORE_TXT="$OUT_DIR/${LABEL}.before.txt"
AFTER_TXT="$OUT_DIR/${LABEL}.after.txt"
DIFF_FILE="$OUT_DIR/${LABEL}.diff"

echo "Capturing before snapshot..."
bash -lc "$BEFORE_CMD" > "$BEFORE_RAW" 2>&1

echo "Capturing after snapshot..."
bash -lc "$AFTER_CMD" > "$AFTER_RAW" 2>&1

perl -pe 's/\e\[[0-9;?]*[ -\/]*[@-~]//g; s/\e[@-_]//g' "$BEFORE_RAW" > "$BEFORE_TXT"
perl -pe 's/\e\[[0-9;?]*[ -\/]*[@-~]//g; s/\e[@-_]//g' "$AFTER_RAW" > "$AFTER_TXT"

set +e
diff -u "$BEFORE_TXT" "$AFTER_TXT" > "$DIFF_FILE"
diff_rc=$?
set -e

if [[ "$diff_rc" -eq 0 ]]; then
  echo "No state difference detected."
elif [[ "$diff_rc" -eq 1 ]]; then
  echo "State difference written to: $DIFF_FILE"
else
  echo "diff command failed" >&2
  exit 2
fi

echo "Artifacts:"
echo "  before_raw : $BEFORE_RAW"
echo "  after_raw  : $AFTER_RAW"
echo "  before_txt : $BEFORE_TXT"
echo "  after_txt  : $AFTER_TXT"
echo "  diff       : $DIFF_FILE"
