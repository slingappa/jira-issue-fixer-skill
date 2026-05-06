#!/usr/bin/env bash
set -euo pipefail

# Helper for edk2 PatchCheck usage.
# Usage:
#   patchcheck_wrapper.sh --repo /abs/path/to/edk2 --patch <patch-file>
#   patchcheck_wrapper.sh --repo /abs/path/to/edk2 --head-range HEAD~1..HEAD

REPO=""
PATCH=""
RANGE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) REPO="${2:-}"; shift 2 ;;
    --patch) PATCH="${2:-}"; shift 2 ;;
    --head-range) RANGE="${2:-}"; shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$REPO" ]]; then
  echo "--repo is required" >&2
  exit 1
fi

cd "$REPO"

if [[ -n "$PATCH" ]]; then
  python3 BaseTools/Scripts/PatchCheck.py "$PATCH"
  exit $?
fi

if [[ -n "$RANGE" ]]; then
  tmp_patch="/tmp/patchcheck-$$.patch"
  git format-patch --stdout "$RANGE" > "$tmp_patch"
  python3 BaseTools/Scripts/PatchCheck.py "$tmp_patch"
  rm -f "$tmp_patch"
  exit $?
fi

echo "Provide --patch or --head-range" >&2
exit 1
