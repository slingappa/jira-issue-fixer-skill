# Jira Issue Fixer Skill

This repo contains an installable Codex skill: `jira-issue-fixer-next`.

The skill is for **end-to-end Jira debugging/fixing** in local repos.
It is designed for issues that need strict reproduction, tracing, validation, and safe commits.

## Who this is for

Use this if you want the agent to:
- reproduce a Jira issue exactly,
- collect pre-fix evidence,
- identify root cause using tracing,
- implement a minimal fix,
- validate with the same repro sequence,
- and prepare a clean commit.

## What the skill enforces

The skill has hard gates (not optional):
- Create a **dedicated local working branch first** (do not modify your current branch directly).
- Capture **pre-fix** `session.log` and `timing.log` for interactive repro.
- Do **pre-fix tracing** before any behavior change.
- Do not implement fix until trace evidence identifies exact failing branch/path.
- Capture **post-fix** logs using the same sequence.
- Verify: pre-fix logs contain failure signature, post-fix logs do not.
- Resolve checker command before check-in (user-provided or auto-detected).
- Omit `Signed-off-by` in agent commits; user adds it after explicit final testing/signoff.

## Repo contents

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

## Install

```bash
cd /path/to/jira-issue-fixer-skill
./install.sh --force
```

Install to a custom location:

```bash
./install.sh --dest /path/to/skills --force
```

## 60-second usage

1. Give Jira URL/key.
2. Give repo path(s).
3. Give build command/script.
4. Give exact runtime command.
5. Give exact failing step sequence.
6. (Optional) Give checker command if non-standard.
7. Ask it to run unattended with trace-first gates.

## Recommended prompt (copy/paste)

```text
Use $jira-issue-fixer-next and run fully unattended end-to-end unless a mandatory gating input is missing.

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

Required behavior:
- Create a dedicated local working branch before any debug/edit.
- Capture pre-fix session.log + timing.log for failing run.
- Add pre-fix tracing and identify exact failing branch/path before any fix.
- Implement minimal safe fix only.
- Capture post-fix session.log + timing.log with the same sequence.
- Prove failure signature exists pre-fix and is absent post-fix.
- Resolve checker and pass checker before check-in.
- Omit Signed-off-by in agent commit; I will test/sign off explicitly after.
- Do not modify unrelated files.

Final report must include:
1) Pre-fix trace evidence (function/path + reject reason)
2) Root cause tied to trace evidence
3) Files changed
4) Pre/post log paths + signature check result
5) Build/checker validation result
6) Final commit hash
```

## Notes

- Commands/paths in the prompt are treated as authoritative.
- The skill only asks for missing/ambiguous paths.
- For known repos, checker can be auto-detected:
  - edk2: `python3 BaseTools/Scripts/PatchCheck.py`
  - Linux/U-Boot: `./scripts/checkpatch.pl --no-tree`
  - Zephyr: `python3 scripts/ci/check_compliance.py`
