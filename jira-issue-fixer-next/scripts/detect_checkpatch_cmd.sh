#!/usr/bin/env bash
set -euo pipefail

# Detect a patch checker command for known repositories.
# Prints a shell command to stdout and exits 0 on success.
# Exits non-zero if detection fails.
#
# Usage:
#   detect_checkpatch_cmd.sh --repo /abs/path/to/repo

REPO=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      REPO="${2:-}"
      shift 2
      ;;
    -h|--help)
      cat <<USAGE
Detect patch checker command for known repos.

Required:
  --repo <path>

Output:
  checker command on stdout
USAGE
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$REPO" || ! -d "$REPO" ]]; then
  echo "Invalid --repo path: $REPO" >&2
  exit 1
fi

cd "$REPO"

# edk2
if [[ -f BaseTools/Scripts/PatchCheck.py ]]; then
  echo "python3 BaseTools/Scripts/PatchCheck.py"
  exit 0
fi

# Linux kernel / U-Boot style
if [[ -x scripts/checkpatch.pl ]]; then
  echo "./scripts/checkpatch.pl --no-tree"
  exit 0
fi

if [[ -x linux/scripts/checkpatch.pl ]]; then
  echo "./linux/scripts/checkpatch.pl --no-tree"
  exit 0
fi

# Zephyr can carry checkpatch helper in scripts.
if [[ -x scripts/ci/check_compliance.py ]]; then
  echo "python3 scripts/ci/check_compliance.py"
  exit 0
fi

if [[ -f scripts/ci/check_compliance.py ]]; then
  echo "python3 scripts/ci/check_compliance.py"
  exit 0
fi

echo "Unable to auto-detect patch checker for repo: $REPO" >&2
exit 2
