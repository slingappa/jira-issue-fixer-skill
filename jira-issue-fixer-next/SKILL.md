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
8. Optional: extra artifact/runtime paths (if not already embedded in commands)
9. Optional but strongly recommended: Jira attachments/logs/docs
10. Optional but strongly recommended: Jira comments with additional repro/debug hints

## Path Policy
- Treat user-provided commands and paths as authoritative.
- Assume commands include required absolute paths when provided that way.
- Accept additional artifact/runtime paths from prompt and use them directly.
- Ask for path clarification only when required paths are missing or ambiguous.

If checker is not provided:
- Try auto-detection with `scripts/detect_checkpatch_cmd.sh`.
- If detection fails, ask user before check-in/commit.

## Workflow

0. **Skill dependency preflight (mandatory)**
- Use `jira-api` skill for Jira ingestion (fields/comments/attachments metadata).
- If `jira-api` skill is not installed or unavailable:
  - prompt user to install it first, then continue,
  - recommend using `skill-installer` to install `jira-api`.
- Do not proceed with unattended Jira intake until this dependency is resolved,
  unless the user explicitly provides a full local Jira export.

1. **Jira intake first (mandatory)**
- Use `jira-api` skill to gather Jira fields before debugging:
  - summary, description, acceptance criteria, environment, status/metadata,
  - comments/history,
  - attachment list and references.
- Read the full Jira issue content before debugging:
  - summary, description, acceptance criteria, environment notes,
  - listed reproduction steps,
  - comments/history (new repro hints often appear there).
- Review attached artifacts (logs, screenshots, docs, trace files) and extract:
  - failure signatures,
  - alternate/updated repro steps,
  - environment/runtime differences.
- Use Jira evidence to refine reproduction and tracing plan before code changes.

2. **Baseline and alignment**
- **MANDATORY branch safety rule (pre-fix)**:
  - create/use a dedicated local working branch before any instrumentation,
    build, or code edits,
  - do not modify the user's current branch directly.
- Verify active repo(s) are the ones used by runtime image.
- Verify build output path used by runtime command.
- Record the exact failure signature.

3. **Reproduce first**
- Reproduce manually once with user-provided sequence.
- For interactive flows, first capture `session.log` and `timing.log` using
  `script --timing` (use `scripts/capture_repro_session.sh`).
- This pre-fix capture is mandatory: it must contain the failure signature.
- For interactive flows, immediately automate with `scripts/repro_menu_boot.expect` + wrapper.
- Ensure deterministic pass/fail exit code and log file.
- **MANDATORY reproducibility scoring (pre-fix)**:
  - run the same failing sequence at least 3 times with
    `scripts/repro_stability_check.sh`,
  - require pre-fix failure rate >= 0.67 before coding.
  - enforce per-run timeout (`--run-timeout-sec`) so unattended runs cannot hang.
  - use robust signature matching for wrapped terminal output (`--match-mode both`).

4. **Isolate root cause**
- **MANDATORY pre-fix instrumentation tracing**:
  - add trace markers before any functional code change,
  - run failing sequence with tracing enabled,
  - capture pre-fix trace evidence from logs/serial output.
- **Two-pass trace gate (mandatory)**:
  - pass 1: broad trace map over candidate path,
  - pass 2: narrow trace proving exact reject branch and condition.
- Trace-first gate (mandatory): do not implement a fix until trace evidence
  identifies the exact failing branch/path.
- Start with narrow, high-signal instrumentation.
- Prefer serial-visible markers if DEBUG output may be suppressed.
- Place markers at decision branches, not broad spam logging.
- Build a mandatory hypothesis matrix (minimum 3 hypotheses) and falsify
  non-winning hypotheses before implementing the fix:
  `references/hypothesis_matrix_template.md`.
- Capture and report:
  - the failing function/path,
  - the exact reject branch/reason from trace markers,
  - why this branch explains the user-visible failure.
- Capture state diffs around trigger sequence when possible (memory map/boot
  vars/device handles) using `scripts/capture_state_diff.sh`.

5. **Implement minimal safe fix**
- Fix root cause only; avoid opportunistic refactors.
- Preserve behavior outside failing path.
- Keep temporary diagnostics out of final fix unless user asks.
- Do not rely on known-good historical patches; derive the fix from current
  trace evidence in this codebase.
- Keep patch minimal; if change spans multiple functions/files, justify why
  narrower fix is unsafe/incomplete.

6. **Validate**
- Rebuild with authoritative user build script.
- Re-run the same scripted repro path and capture a post-fix `session.log`/`timing.log`.
- Confirm pre-fix logs contain the failure signature and post-fix logs do not.
- Confirm expected boot path continues in post-fix logs.
- Use `scripts/repro_before_after_check.sh` for signature verification.
- **MANDATORY reproducibility scoring (post-fix)**:
  - run same sequence at least 3 times with `scripts/repro_stability_check.sh`,
  - require post-fix failure rate == 0.00.
  - keep per-run timeout enabled to prevent blocked sessions.
- Run negative-path regression checks:
  - direct-success path still succeeds,
  - shell-enter/exit path succeeds,
  - at least one unrelated boot option still behaves.

7. **Commit hygiene**
- Keep commit focused to minimal files.
- Include Problem/Trigger Sequence/Trace Evidence/Root Cause/Fix/Validation/Risk
  sections in commit message.
- Mandatory signoff rule:
  - do not add `Signed-off-by` in agent-created commits.
  - user must explicitly run their own final test/signoff flow and add signoff.
- Resolve checker command before check-in:
  - use user-provided checker, else auto-detect with `scripts/detect_checkpatch_cmd.sh`.
  - if unresolved, ask user and do not check in.
- Run checker after validation and before check-in:
  - use `scripts/patchcheck_wrapper.sh` for edk2-like repos.
  - use detected checker command for other known repos (Linux/U-Boot/Zephyr).

## Output Contract
Return:
1. Repro evidence (before/after)
2. Pre-fix trace evidence summary (function/path + reject reason)
3. Root cause statement tied to trace evidence
4. Hypothesis matrix result (winner + falsified alternatives)
5. Exact files changed (and why minimal)
6. Validation evidence
7. Paths to pre-fix and post-fix `session.log`/`timing.log`
8. Explicit signature check result (pre contains failure, post does not)
9. Pre/post reproducibility rates (N runs each)
10. State-diff artifacts (if captured) and interpretation
11. Commit hash + patch-check result
12. Quality gate score from `scripts/quality_gate_report.sh` with ready/not-ready

## References
- Detailed playbook: [references/debug_playbook.md](references/debug_playbook.md)
- Hypothesis matrix template: [references/hypothesis_matrix_template.md](references/hypothesis_matrix_template.md)

## Scripts
- Repro capture helper: [scripts/capture_repro_session.sh](scripts/capture_repro_session.sh)
- Repro automation wrapper: [scripts/run_repro_menu_boot.sh](scripts/run_repro_menu_boot.sh)
- Interactive expect flow: [scripts/repro_menu_boot.expect](scripts/repro_menu_boot.expect)
- Before/after signature check: [scripts/repro_before_after_check.sh](scripts/repro_before_after_check.sh)
- Repro stability scoring: [scripts/repro_stability_check.sh](scripts/repro_stability_check.sh)
- State diff capture: [scripts/capture_state_diff.sh](scripts/capture_state_diff.sh)
- Quality score report: [scripts/quality_gate_report.sh](scripts/quality_gate_report.sh)
- Checker auto-detect: [scripts/detect_checkpatch_cmd.sh](scripts/detect_checkpatch_cmd.sh)
- PatchCheck helper: [scripts/patchcheck_wrapper.sh](scripts/patchcheck_wrapper.sh)
