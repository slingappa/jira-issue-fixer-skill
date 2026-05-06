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
7. Optional: checker command if repo uses non-standard patch checker

If checker is not provided:
- Try auto-detection with `scripts/detect_checkpatch_cmd.sh`.
- If detection fails, ask user before check-in/commit.

## Workflow

1. **Baseline and alignment**
- Verify active repo(s) are the ones used by runtime image.
- Verify build output path used by runtime command.
- Record the exact failure signature.

2. **Reproduce first**
- Reproduce manually once with user-provided sequence.
- For interactive flows, first capture `session.log` and `timing.log` using
  `script --timing` (use `scripts/capture_repro_session.sh`).
- This pre-fix capture is mandatory: it must contain the failure signature.
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
- Re-run the same scripted repro path and capture a post-fix `session.log`/`timing.log`.
- Confirm pre-fix logs contain the failure signature and post-fix logs do not.
- Confirm expected boot path continues in post-fix logs.
- Use `scripts/repro_before_after_check.sh` for signature verification.

6. **Commit hygiene**
- Keep commit focused to minimal files.
- Include problem/root-cause/fix in commit message.
- Include Signed-off-by when required.
- Resolve checker command before check-in:
  - use user-provided checker, else auto-detect with `scripts/detect_checkpatch_cmd.sh`.
  - if unresolved, ask user and do not check in.
- Run checker after validation and before check-in:
  - use `scripts/patchcheck_wrapper.sh` for edk2-like repos.
  - use detected checker command for other known repos (Linux/U-Boot/Zephyr).

## Output Contract
Return:
1. Repro evidence (before/after)
2. Root cause statement
3. Exact files changed
4. Validation evidence
5. Paths to pre-fix and post-fix `session.log`/`timing.log`
6. Explicit signature check result (pre contains failure, post does not)
7. Commit hash + patch-check result

## References
- Detailed playbook: [references/debug_playbook.md](references/debug_playbook.md)

## Scripts
- Repro capture helper: [scripts/capture_repro_session.sh](scripts/capture_repro_session.sh)
- Repro automation wrapper: [scripts/run_repro_menu_boot.sh](scripts/run_repro_menu_boot.sh)
- Interactive expect flow: [scripts/repro_menu_boot.expect](scripts/repro_menu_boot.expect)
- Before/after signature check: [scripts/repro_before_after_check.sh](scripts/repro_before_after_check.sh)
- Checker auto-detect: [scripts/detect_checkpatch_cmd.sh](scripts/detect_checkpatch_cmd.sh)
- PatchCheck helper: [scripts/patchcheck_wrapper.sh](scripts/patchcheck_wrapper.sh)
