---
name: jira-issue-fixer-next
description: End-to-end Jira issue fixer for local repos. Use when given a Jira issue URL/key and checked-out source trees to reproduce, debug, implement, validate, and commit a minimal fix with patch-checkable history.
---

# Jira Issue Fixer Next

## Required Inputs
Collect these before implementation:
1. Jira URL/key
2. Active repo path(s)
3. Build script/command
4. Runtime command used for repro
5. Exact numbered repro sequence
6. Expected vs observed behavior

If any are missing, ask explicitly.

## Workflow

1. **Baseline and alignment**
- Verify active repo(s) are the ones used by runtime image.
- Verify build output path used by runtime command.
- Record the exact failure signature.

2. **Reproduce first**
- Reproduce manually once with user-provided sequence.
- For interactive flows, immediately automate with `scripts/repro_menu_boot.expect` + wrapper.
- Ensure deterministic pass/fail exit code and log file.

3. **Isolate root cause**
- Start with narrow, high-signal instrumentation.
- Prefer serial-visible markers if DEBUG output may be suppressed.
- Place markers at decision branches, not broad spam logging.

4. **Implement minimal safe fix**
- Fix root cause only; avoid opportunistic refactors.
- Preserve behavior outside failing path.
- Keep temporary diagnostics out of final fix unless user asks.

5. **Validate**
- Rebuild with authoritative user build script.
- Re-run same scripted repro path.
- Confirm failure signature is gone and expected boot path continues.

6. **Commit hygiene**
- Keep commit focused to minimal files.
- Include problem/root-cause/fix in commit message.
- Include Signed-off-by when required.
- Run patch checker (`scripts/patchcheck_wrapper.sh` for edk2-like trees).

## Output Contract
Return:
1. Repro evidence (before/after)
2. Root cause statement
3. Exact files changed
4. Validation evidence
5. Commit hash + patch-check result

## References
- Detailed playbook: [references/debug_playbook.md](references/debug_playbook.md)

## Scripts
- Repro automation wrapper: [scripts/run_repro_menu_boot.sh](scripts/run_repro_menu_boot.sh)
- Interactive expect flow: [scripts/repro_menu_boot.expect](scripts/repro_menu_boot.expect)
- PatchCheck helper: [scripts/patchcheck_wrapper.sh](scripts/patchcheck_wrapper.sh)
