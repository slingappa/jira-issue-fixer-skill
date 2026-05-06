#!/usr/bin/env bash
set -euo pipefail

# Run the same repro command multiple times and compute fail/pass rates.
#
# Usage:
#   repro_stability_check.sh \
#     --run-cmd "<command>" \
#     --runs 3 \
#     --expect fail \
#     --failure-re "Memory starting at .*EFI would not allocate" \
#     --log-dir /tmp/prefix-runs \
#     --min-failure-rate 0.67

RUN_CMD=""
RUNS=3
EXPECT_MODE="fail"
FAIL_RE=""
SUCCESS_RE=""
LOG_DIR=""
MIN_FAILURE_RATE=""
MAX_FAILURE_RATE=""
MIN_SUCCESS_RATE=""
SUMMARY_FILE=""
RUN_TIMEOUT_SEC="${RUN_TIMEOUT_SEC:-420}"
MATCH_MODE="both"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --run-cmd)
      RUN_CMD="${2:-}"
      shift 2
      ;;
    --runs)
      RUNS="${2:-}"
      shift 2
      ;;
    --expect)
      EXPECT_MODE="${2:-}"
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
    --log-dir)
      LOG_DIR="${2:-}"
      shift 2
      ;;
    --min-failure-rate)
      MIN_FAILURE_RATE="${2:-}"
      shift 2
      ;;
    --max-failure-rate)
      MAX_FAILURE_RATE="${2:-}"
      shift 2
      ;;
    --min-success-rate)
      MIN_SUCCESS_RATE="${2:-}"
      shift 2
      ;;
    --summary-file)
      SUMMARY_FILE="${2:-}"
      shift 2
      ;;
    --run-timeout-sec)
      RUN_TIMEOUT_SEC="${2:-}"
      shift 2
      ;;
    --match-mode)
      MATCH_MODE="${2:-}"
      shift 2
      ;;
    -h|--help)
      cat <<USAGE
Run repeated repro attempts and report fail/pass rates.

Required:
  --run-cmd <command>
  --expect <fail|pass>

Optional:
  --runs <N>                  (default: 3)
  --failure-re <regex>        Failure signature regex (preferred)
  --success-re <regex>        Success signature regex
  --log-dir <dir>             Output logs directory
  --min-failure-rate <0..1>   Assert lower bound
  --max-failure-rate <0..1>   Assert upper bound
  --min-success-rate <0..1>   Assert lower bound
  --summary-file <path>       Write key=value summary
  --run-timeout-sec <sec>     Per-run timeout (default: 420)
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

if [[ -z "$RUN_CMD" ]]; then
  echo "--run-cmd is required" >&2
  exit 1
fi
if [[ "$EXPECT_MODE" != "fail" && "$EXPECT_MODE" != "pass" ]]; then
  echo "--expect must be fail or pass" >&2
  exit 1
fi
if ! [[ "$RUNS" =~ ^[0-9]+$ ]] || [[ "$RUNS" -lt 1 ]]; then
  echo "--runs must be a positive integer" >&2
  exit 1
fi
if ! [[ "$RUN_TIMEOUT_SEC" =~ ^[0-9]+$ ]] || [[ "$RUN_TIMEOUT_SEC" -lt 1 ]]; then
  echo "--run-timeout-sec must be a positive integer" >&2
  exit 1
fi
if [[ "$MATCH_MODE" != "line" && "$MATCH_MODE" != "normalized" && "$MATCH_MODE" != "both" ]]; then
  echo "--match-mode must be line, normalized, or both" >&2
  exit 1
fi

if [[ -z "$LOG_DIR" ]]; then
  LOG_DIR="/tmp/repro-stability-$(date +%Y%m%d-%H%M%S)"
fi
mkdir -p "$LOG_DIR"

check_rate_bound() {
  local lhs="$1"
  local op="$2"
  local rhs="$3"
  awk -v a="$lhs" -v b="$rhs" "BEGIN{exit !(a ${op} b)}"
}

strip_ansi_file() {
  local in_file="$1"
  local out_file="$2"
  perl -pe 's/\e\[[0-9;?]*[ -\/]*[@-~]//g; s/\e[@-_]//g' "$in_file" > "$out_file"
}

normalize_ws_file() {
  local in_file="$1"
  local out_file="$2"
  tr '\n' ' ' < "$in_file" | sed -E 's/[[:space:]]+/ /g; s/^ //; s/ $//' > "$out_file"
}

run_with_timeout() {
  local tsec="$1"
  local cmd="$2"
  local out_file="$3"
  if command -v timeout >/dev/null 2>&1; then
    timeout --foreground "${tsec}s" bash -lc "$cmd" >"$out_file" 2>&1
  else
    bash -lc "$cmd" >"$out_file" 2>&1
  fi
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

failure_count=0
success_count=0
timeout_count=0

echo "Running stability check:"
echo "  runs      : $RUNS"
echo "  expect    : $EXPECT_MODE"
echo "  logs      : $LOG_DIR"
echo "  timeout   : ${RUN_TIMEOUT_SEC}s"
echo "  match     : $MATCH_MODE"
if ! command -v timeout >/dev/null 2>&1; then
  echo "  warn      : timeout command not found; per-run timeout not enforced"
fi

for i in $(seq 1 "$RUNS"); do
  raw_log="$LOG_DIR/run_${i}.log"
  txt_log="$LOG_DIR/run_${i}.txt"
  norm_log="$LOG_DIR/run_${i}.norm.txt"
  compact_log="$LOG_DIR/run_${i}.compact.txt"
  echo "[run $i/$RUNS] executing..."

  set +e
  run_with_timeout "$RUN_TIMEOUT_SEC" "$RUN_CMD" "$raw_log"
  rc=$?
  set -e

  strip_ansi_file "$raw_log" "$txt_log"
  normalize_ws_file "$txt_log" "$norm_log"
  tr -d '[:space:]' < "$txt_log" > "$compact_log"

  run_failure=0
  run_success=0
  run_timeout=0

  if [[ "$rc" -eq 124 ]]; then
    run_timeout=1
    timeout_count=$((timeout_count + 1))
  fi

  if [[ -n "$FAIL_RE" ]]; then
    if regex_match "$FAIL_RE" "$txt_log" "$norm_log" "$compact_log"; then
      run_failure=1
    fi
  else
    if [[ "$rc" -ne 0 ]]; then
      run_failure=1
    fi
  fi

  if [[ -n "$SUCCESS_RE" ]]; then
    if regex_match "$SUCCESS_RE" "$txt_log" "$norm_log" "$compact_log"; then
      run_success=1
    fi
  else
    if [[ "$rc" -eq 0 ]]; then
      run_success=1
    fi
  fi

  # If a failure signature is detected and success is inferred only from rc==0,
  # treat the run as not successful.
  if [[ "$run_failure" -eq 1 && -z "$SUCCESS_RE" ]]; then
    run_success=0
  fi

  failure_count=$((failure_count + run_failure))
  success_count=$((success_count + run_success))

  echo "[run $i/$RUNS] rc=$rc timeout=$run_timeout failure=$run_failure success=$run_success"
done

failure_rate="$(awk -v n="$failure_count" -v d="$RUNS" 'BEGIN{printf "%.4f", n/d}')"
success_rate="$(awk -v n="$success_count" -v d="$RUNS" 'BEGIN{printf "%.4f", n/d}')"

echo "Summary:"
echo "  failure_count : $failure_count/$RUNS"
echo "  success_count : $success_count/$RUNS"
echo "  timeout_count : $timeout_count/$RUNS"
echo "  failure_rate  : $failure_rate"
echo "  success_rate  : $success_rate"

if [[ -n "$SUMMARY_FILE" ]]; then
  mkdir -p "$(dirname "$SUMMARY_FILE")"
  cat > "$SUMMARY_FILE" <<EOF
runs=$RUNS
expect=$EXPECT_MODE
failure_count=$failure_count
success_count=$success_count
timeout_count=$timeout_count
failure_rate=$failure_rate
success_rate=$success_rate
log_dir=$LOG_DIR
EOF
fi

if [[ -n "$MIN_FAILURE_RATE" ]]; then
  if ! check_rate_bound "$failure_rate" ">=" "$MIN_FAILURE_RATE"; then
    echo "FAIL: failure_rate $failure_rate is below min $MIN_FAILURE_RATE" >&2
    exit 2
  fi
fi
if [[ -n "$MAX_FAILURE_RATE" ]]; then
  if ! check_rate_bound "$failure_rate" "<=" "$MAX_FAILURE_RATE"; then
    echo "FAIL: failure_rate $failure_rate is above max $MAX_FAILURE_RATE" >&2
    exit 3
  fi
fi
if [[ -n "$MIN_SUCCESS_RATE" ]]; then
  if ! check_rate_bound "$success_rate" ">=" "$MIN_SUCCESS_RATE"; then
    echo "FAIL: success_rate $success_rate is below min $MIN_SUCCESS_RATE" >&2
    exit 4
  fi
fi

echo "Stability check passed."
