#!/usr/bin/env bash
set -euo pipefail

# Verify before/after repro logs:
# - pre-fix log must contain failure signature
# - post-fix log must not contain failure signature
# Optional: post-fix log should contain success signature
#
# Usage:
#   repro_before_after_check.sh \
#     --pre-log /path/pre/session.log \
#     --post-log /path/post/session.log \
#     --failure-re "Memory starting at .*marked as free, but EFI would not allocate" \
#     [--success-re "Booting `Ubuntu'"]

PRE_LOG=""
POST_LOG=""
FAIL_RE='Memory starting at .*marked as free, but EFI would not allocate'
SUCCESS_RE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --pre-log)
      PRE_LOG="${2:-}"
      shift 2
      ;;
    --post-log)
      POST_LOG="${2:-}"
      shift 2
      ;;
    --failure-re)
      FAIL_RE="${2:-}"
      shift 2
      ;;
    --success-re)
      SUCCESS_RE="${2:-}"
      shift 2
      ;;
    -h|--help)
      cat <<USAGE
Verify before/after reproduction logs.

Required:
  --pre-log <path>
  --post-log <path>

Optional:
  --failure-re <regex>
  --success-re <regex>
USAGE
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$PRE_LOG" || -z "$POST_LOG" ]]; then
  echo "--pre-log and --post-log are required" >&2
  exit 1
fi

if [[ ! -f "$PRE_LOG" ]]; then
  echo "Missing pre-log: $PRE_LOG" >&2
  exit 1
fi

if [[ ! -f "$POST_LOG" ]]; then
  echo "Missing post-log: $POST_LOG" >&2
  exit 1
fi

strip_ansi() {
  perl -pe 's/\e\[[0-9;?]*[ -\/]*[@-~]//g; s/\e[@-_]//g' "$1"
}

PRE_TXT="$(mktemp)"
POST_TXT="$(mktemp)"
trap 'rm -f "$PRE_TXT" "$POST_TXT"' EXIT

strip_ansi "$PRE_LOG" > "$PRE_TXT"
strip_ansi "$POST_LOG" > "$POST_TXT"

if ! rg -n -e "$FAIL_RE" "$PRE_TXT" >/dev/null; then
  echo "FAIL: pre-log does not contain failure signature" >&2
  exit 2
fi

echo "PASS: pre-log contains failure signature"

if rg -n -e "$FAIL_RE" "$POST_TXT" >/dev/null; then
  echo "FAIL: post-log still contains failure signature" >&2
  exit 3
fi

echo "PASS: post-log does not contain failure signature"

if [[ -n "$SUCCESS_RE" ]]; then
  if rg -n -e "$SUCCESS_RE" "$POST_TXT" >/dev/null; then
    echo "PASS: post-log contains success signature"
  else
    echo "WARN: post-log does not contain success signature regex" >&2
  fi
fi

echo "Before/after signature check complete."
