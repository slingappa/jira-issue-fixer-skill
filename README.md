# Jira Issue Fixer Skill

Installable Codex skill bundle: `jira-issue-fixer-next`.

This skill is built for Jira issues that require strict reproducibility, trace-first root-cause analysis, and safe commit hygiene.

Expectation from this skill is with a well crafted prompt with detailed precise reproduction steps, build instructions, skill should be able to fix the issue unattended.

## Why this skill exists

Many issue-fixing attempts fail because they skip one of these:
- deterministic reproduction,
- pre-fix trace evidence,
- same-path post-fix validation,
- clean commit gates.

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
- `jira-issue-fixer-next/scripts/capture_repro_session.sh`
- `jira-issue-fixer-next/scripts/run_repro_menu_boot.sh`
- `jira-issue-fixer-next/scripts/repro_menu_boot.expect`
- `jira-issue-fixer-next/scripts/repro_before_after_check.sh`
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
- Read full Jira content first (description, repro, comments, attachments) and use it to drive repro/tracing.
- Create a dedicated local working branch before any debug/edit.
- Capture pre-fix failing run logs (session.log, timing.log for interactive flows).
- Add pre-fix tracing and identify exact failing function/path + reject reason.
- Do not implement behavior change before trace evidence is captured.
- Implement minimal safe fix only.
- Capture post-fix logs using the same sequence.
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
6) Final commit hash
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
  - Fix: tune automation timing/menu offsets and re-capture pre/post logs.

- Problem: trace output not visible.
  - Fix: use serial-visible markers and rerun pre-fix traced capture.
