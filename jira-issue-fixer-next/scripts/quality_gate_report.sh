#!/usr/bin/env bash
set -euo pipefail

# Produce a confidence score from mandatory quality gates.

TRACE_PASS1="no"
TRACE_PASS2="no"
HYPOTHESIS_DONE="no"
CHAIN_COMPLETE="no"
MINIMAL_DIFF="no"
CHECKER_PASS="no"
PRE_FAIL_RATE=""
POST_FAIL_RATE=""
POST_SUCCESS_RATE=""
OUT_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --trace-pass1) TRACE_PASS1="${2:-}"; shift 2 ;;
    --trace-pass2) TRACE_PASS2="${2:-}"; shift 2 ;;
    --hypothesis-done) HYPOTHESIS_DONE="${2:-}"; shift 2 ;;
    --chain-complete) CHAIN_COMPLETE="${2:-}"; shift 2 ;;
    --minimal-diff) MINIMAL_DIFF="${2:-}"; shift 2 ;;
    --checker-pass) CHECKER_PASS="${2:-}"; shift 2 ;;
    --pre-fail-rate) PRE_FAIL_RATE="${2:-}"; shift 2 ;;
    --post-fail-rate) POST_FAIL_RATE="${2:-}"; shift 2 ;;
    --post-success-rate) POST_SUCCESS_RATE="${2:-}"; shift 2 ;;
    --out-file) OUT_FILE="${2:-}"; shift 2 ;;
    -h|--help)
      cat <<USAGE
Generate quality gate score for unattended issue fixes.

Required booleans (yes/no):
  --trace-pass1
  --trace-pass2
  --hypothesis-done
  --chain-complete
  --minimal-diff
  --checker-pass

Required rates:
  --pre-fail-rate <0..1>
  --post-fail-rate <0..1>

Optional:
  --post-success-rate <0..1>
  --out-file <path>
USAGE
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

for v in TRACE_PASS1 TRACE_PASS2 HYPOTHESIS_DONE CHAIN_COMPLETE MINIMAL_DIFF CHECKER_PASS; do
  val="${!v}"
  if [[ "$val" != "yes" && "$val" != "no" ]]; then
    echo "$v must be yes/no" >&2
    exit 1
  fi
done

if [[ -z "$PRE_FAIL_RATE" || -z "$POST_FAIL_RATE" ]]; then
  echo "--pre-fail-rate and --post-fail-rate are required" >&2
  exit 1
fi

rate_ge() { awk -v a="$1" -v b="$2" 'BEGIN{exit !(a >= b)}'; }
rate_le() { awk -v a="$1" -v b="$2" 'BEGIN{exit !(a <= b)}'; }

score=0

[[ "$TRACE_PASS1" == "yes" ]] && score=$((score + 15))
[[ "$TRACE_PASS2" == "yes" ]] && score=$((score + 15))
[[ "$HYPOTHESIS_DONE" == "yes" ]] && score=$((score + 10))
[[ "$CHAIN_COMPLETE" == "yes" ]] && score=$((score + 15))
[[ "$MINIMAL_DIFF" == "yes" ]] && score=$((score + 5))
[[ "$CHECKER_PASS" == "yes" ]] && score=$((score + 10))

if rate_ge "$PRE_FAIL_RATE" "0.67"; then score=$((score + 15)); fi
if rate_le "$POST_FAIL_RATE" "0.00"; then score=$((score + 20)); fi
if [[ -n "$POST_SUCCESS_RATE" ]]; then
  if rate_ge "$POST_SUCCESS_RATE" "0.67"; then score=$((score + 5)); fi
fi

if [[ "$score" -gt 100 ]]; then
  score=100
fi

ready="no"
if [[ "$TRACE_PASS1" == "yes" &&
      "$TRACE_PASS2" == "yes" &&
      "$HYPOTHESIS_DONE" == "yes" &&
      "$CHAIN_COMPLETE" == "yes" &&
      "$CHECKER_PASS" == "yes" ]]; then
  if rate_ge "$PRE_FAIL_RATE" "0.67" && rate_le "$POST_FAIL_RATE" "0.00"; then
    ready="yes"
  fi
fi

report=$(
cat <<EOF
quality_score=$score
ready_to_submit=$ready
trace_pass1=$TRACE_PASS1
trace_pass2=$TRACE_PASS2
hypothesis_done=$HYPOTHESIS_DONE
chain_complete=$CHAIN_COMPLETE
minimal_diff=$MINIMAL_DIFF
checker_pass=$CHECKER_PASS
pre_fail_rate=$PRE_FAIL_RATE
post_fail_rate=$POST_FAIL_RATE
post_success_rate=${POST_SUCCESS_RATE:-na}
EOF
)

echo "$report"

if [[ -n "$OUT_FILE" ]]; then
  mkdir -p "$(dirname "$OUT_FILE")"
  printf "%s\n" "$report" > "$OUT_FILE"
fi
