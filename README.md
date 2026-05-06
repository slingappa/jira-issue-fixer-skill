# Jira Issue Fixer Skill

Installable Codex skill bundle: `jira-issue-fixer-next`.

This skill is built for Jira issues that require strict reproducibility, trace-first root-cause analysis, and safe commit hygiene.

Expectation from this skill is with a well crafted prompt with detailed precise reproduction steps, build/execution instructions, skill should be able to fix the issue unattended after actually verifying the fix.

## Overview

High-level methodology used by this skill:
1. Jira intake first:
   collect issue fields/comments/attachments via `jira-api` and extract failure signatures, repro details, and constraints.
2. Safe working setup:
   create a dedicated local branch and verify build/runtime paths match the image under test.
3. Deterministic reproduction:
   capture pre-fix evidence (`session.log`/`timing.log`) and establish reproducibility scoring with multi-run checks (default >=3 runs, target pre-fix failure rate >= 0.67).
4. Trace-first root cause isolation:
   run multi-pass instrumentation operations (mandatory two-pass tracing: broad path map, then exact reject branch/condition proof), and complete a 3-hypothesis matrix before coding.
5. Minimal, evidence-driven fix:
   implement only the change required to remove the proven reject path while preserving existing safety checks.
6. Same-path validation:
   rebuild, replay the same sequence, prove failure signature removal, and run post-fix reproducibility scoring (default >=3 runs, target post-fix failure rate == 0.00) plus negative-path checks.
7. Commit and quality gates:
   run repo checker, compute gate-based confidence scoring (`quality_gate_report.sh`) with ready/not-ready output, and produce focused commit metadata for user-owned final signoff.

## Why this skill exists

Many issue-fixing attempts fail because they skip one of these:
- deterministic reproduction,
- pre-fix trace evidence,
- same-path post-fix validation,
- clean commit gates.
- multi-run stability proof.

This skill enforces all four.

## Core guarantees

When used correctly, the skill enforces:
1. Work starts on a dedicated local branch (current branch is preserved).
2. Pre-fix failing run is captured (`session.log`, `timing.log` for interactive flows).
3. Pre-fix tracing identifies the exact failing function/path and reject reason.
4. No functional fix is implemented before trace evidence is captured.
5. Post-fix run uses the same sequence and proves failure signature is gone.
6. Checker runs and passes before check-in.
7. Agent commits omit `Signed-off-by`; user adds signoff after explicit final testing.
8. Fix decisions are evidence-driven from current traces; no dependency on any
   known-good historical patch.
9. Two-pass trace gate + hypothesis matrix must be completed before coding.
10. Pre/post reproducibility rates are measured (not guessed).

## What you need to provide

Minimum input:
- Jira URL/key
- repo path(s)
- build command/script
- runtime command
- exact failing sequence

Important:
- Include Jira issue details completely (description + comments).
- Include attached logs/docs if available; these often contain better repro and tracing clues.

Optional input:
- checker command (if non-standard)
- extra artifact/runtime paths not embedded in commands
- failure signature regex and success signature regex

## Jira API dependency (mandatory)

- This skill expects `jira-api` skill to be available and uses it for Jira issue
  field collection (description/comments/attachments metadata).
- If `jira-api` is not installed, the agent must prompt to install it before
  unattended execution.
- Recommended install path:

```bash
Use $skill-installer to install jira-api skill.
```

## Install

```bash
cd /path/to/jira-issue-fixer-skill
./install.sh --force
```

Custom install destination:

```bash
./install.sh --dest /path/to/skills --force
```

## Commit policy for this repo

This skill repository requires signoff lines in commit messages.

Use:

```bash
git commit -s -m "<message>"
```

Optional convenience alias:

```bash
git config alias.cs "commit -s"
```

## Repo layout

- `install.sh`
- `jira-issue-fixer-next/SKILL.md`
- `jira-issue-fixer-next/agents/openai.yaml`
- `jira-issue-fixer-next/references/debug_playbook.md`
- `jira-issue-fixer-next/references/hypothesis_matrix_template.md`
- `jira-issue-fixer-next/scripts/capture_repro_session.sh`
- `jira-issue-fixer-next/scripts/run_repro_menu_boot.sh`
- `jira-issue-fixer-next/scripts/repro_menu_boot.expect`
- `jira-issue-fixer-next/scripts/repro_before_after_check.sh`
- `jira-issue-fixer-next/scripts/repro_stability_check.sh`
- `jira-issue-fixer-next/scripts/capture_state_diff.sh`
- `jira-issue-fixer-next/scripts/quality_gate_report.sh`
- `jira-issue-fixer-next/scripts/detect_checkpatch_cmd.sh`
- `jira-issue-fixer-next/scripts/patchcheck_wrapper.sh`

## Recommended prompt (copy/paste)

```text
Use $jira-issue-fixer-next and run unattended end-to-end unless a mandatory gate is missing.

Jira:
<JIRA_URL_OR_KEY>

Primary repo:
<PRIMARY_REPO_PATH>

Build workspace:
<BUILD_WORKSPACE_PATH>

Build script:
<BUILD_SCRIPT_PATH>

Runtime command:
<EXACT_RUNTIME_COMMAND>

Optional checker command:
<CHECKER_CMD_IF_NON_STANDARD>

Optional extra paths:
<EXTRA_ARTIFACT_OR_RUNTIME_PATHS>

Exact failing sequence:
1) <STEP_1>
2) <STEP_2>
...
N) <STEP_N>

Mandatory behavior:
- Use jira-api skill to fetch Jira fields/comments/attachments metadata first.
- If jira-api skill is unavailable, stop and ask me to install it before continuing.
- Read full Jira content first (description, repro, comments, attachments) and use it to drive repro/tracing.
- Create a dedicated local working branch before any debug/edit.
- Capture pre-fix failing run logs (session.log, timing.log for interactive flows).
- Run at least 3 pre-fix reproductions and record fail rate (target >= 0.67).
  - enforce per-run timeout to avoid unattended hangs.
  - use robust matching mode for wrapped/split terminal signatures.
- Build a 3-hypothesis matrix and falsify non-winning hypotheses before code changes.
- Add pre-fix tracing and identify exact failing function/path + reject reason.
- Enforce two-pass tracing (broad path map, then exact reject-branch proof).
- Do not implement behavior change before trace evidence is captured.
- Do not assume a known-good historical fix exists; derive fix from current
  code + trace evidence only.
- Implement minimal safe fix only.
- Capture post-fix logs using the same sequence.
- Run at least 3 post-fix reproductions and record fail rate (target == 0.00).
  - keep per-run timeout enabled.
- Capture state diff artifacts around trigger sequence when possible.
- Prove failure signature exists pre-fix and is absent post-fix.
- Resolve checker (provided or auto-detected), run checker, and pass before check-in.
- Omit Signed-off-by in agent commit; I will do final test/signoff and add Signed-off-by myself.
- Do not modify unrelated files.

Final report must include:
1) Pre-fix trace evidence (function/path + reject reason)
2) Root cause tied to that evidence
3) Files changed
4) Pre/post log paths and signature check result
5) Build/checker validation result
6) Quality gate score + ready/not-ready flag
7) Final commit hash
```

## Checker auto-detection (if checker not provided)

The skill attempts to auto-detect for common repos:
- edk2: `python3 BaseTools/Scripts/PatchCheck.py`
- Linux/U-Boot: `./scripts/checkpatch.pl --no-tree`
- Zephyr: `python3 scripts/ci/check_compliance.py`

If not detected, the skill must ask before check-in.

## Path handling policy

- Provided commands/paths are treated as authoritative.
- If commands already contain absolute paths, skill proceeds without re-asking.
- Skill asks only when required paths are missing or ambiguous.

## Quick troubleshooting

- Problem: skill can’t reproduce issue.
  - Fix: make runtime command and repro sequence more explicit (keys, menu labels, delays).

- Problem: checker step is blocked.
  - Fix: provide explicit checker command in prompt.

- Problem: post-fix still fails intermittently.
  - Fix: tune automation timing/menu offsets and enforce stability thresholds with `repro_stability_check.sh`.

- Problem: trace output not visible.
  - Fix: use serial-visible markers and rerun pre-fix traced capture.

- Problem: unattended run appears hung in stability loop.
  - Fix: set `--run-timeout-sec` and ensure boot prompt/fail window timeouts are set (`BOOT_PROMPT_TIMEOUT_SEC`, `FAIL_WINDOW_TIMEOUT_SEC`).

- Problem: failure regex misses split terminal lines.
  - Fix: use `--match-mode both` and whitespace-tolerant regex.
