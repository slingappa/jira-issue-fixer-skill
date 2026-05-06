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
MATCH_MODE="both"

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
    --match-mode)
      MATCH_MODE="${2:-}"
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
  --match-mode <line|normalized|both>
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
if [[ "$MATCH_MODE" != "line" && "$MATCH_MODE" != "normalized" && "$MATCH_MODE" != "both" ]]; then
  echo "--match-mode must be line, normalized, or both" >&2
  exit 1
fi

strip_ansi() {
  perl -pe 's/\e\[[0-9;?]*[ -\/]*[@-~]//g; s/\e[@-_]//g' "$1"
}

normalize_ws_file() {
  local in_file="$1"
  local out_file="$2"
  tr '\n' ' ' < "$in_file" | sed -E 's/[[:space:]]+/ /g; s/^ //; s/ $//' > "$out_file"
}

regex_match() {
  local regex="$1"
  local line_file="$2"
  local norm_file="$3"
  local compact_file="$4"
  local compact_re
  compact_re="$(printf "%s" "$regex" | tr -d '[:space:]')"
  case "$MATCH_MODE" in
    line)
      rg -n -e "$regex" "$line_file" >/dev/null
      ;;
    normalized)
      rg -n -e "$regex" "$norm_file" >/dev/null || rg -n -e "$compact_re" "$compact_file" >/dev/null
      ;;
    both)
      rg -n -e "$regex" "$line_file" >/dev/null || rg -n -e "$regex" "$norm_file" >/dev/null || rg -n -e "$compact_re" "$compact_file" >/dev/null
      ;;
  esac
}

PRE_TXT="$(mktemp)"
POST_TXT="$(mktemp)"
PRE_NORM="$(mktemp)"
POST_NORM="$(mktemp)"
PRE_COMPACT="$(mktemp)"
POST_COMPACT="$(mktemp)"
trap 'rm -f "$PRE_TXT" "$POST_TXT" "$PRE_NORM" "$POST_NORM" "$PRE_COMPACT" "$POST_COMPACT"' EXIT

strip_ansi "$PRE_LOG" > "$PRE_TXT"
strip_ansi "$POST_LOG" > "$POST_TXT"
normalize_ws_file "$PRE_TXT" "$PRE_NORM"
normalize_ws_file "$POST_TXT" "$POST_NORM"
tr -d '[:space:]' < "$PRE_TXT" > "$PRE_COMPACT"
tr -d '[:space:]' < "$POST_TXT" > "$POST_COMPACT"

if ! regex_match "$FAIL_RE" "$PRE_TXT" "$PRE_NORM" "$PRE_COMPACT"; then
  echo "FAIL: pre-log does not contain failure signature" >&2
  exit 2
fi

echo "PASS: pre-log contains failure signature"

if regex_match "$FAIL_RE" "$POST_TXT" "$POST_NORM" "$POST_COMPACT"; then
  echo "FAIL: post-log still contains failure signature" >&2
  exit 3
fi

echo "PASS: post-log does not contain failure signature"

if [[ -n "$SUCCESS_RE" ]]; then
  if regex_match "$SUCCESS_RE" "$POST_TXT" "$POST_NORM" "$POST_COMPACT"; then
    echo "PASS: post-log contains success signature"
  else
    echo "WARN: post-log does not contain success signature regex" >&2
  fi
fi

echo "Before/after signature check complete."
