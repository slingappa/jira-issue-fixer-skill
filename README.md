# jira-issue-fixer skill repo

This repository packages the `jira-issue-fixer-next` Codex skill as a standalone installable bundle.

## What this skill does

The skill guides end-to-end Jira issue execution for local codebases:
1. Validate issue context and active build/runtime paths.
2. Capture interactive repro evidence (`session.log` + `timing.log`) with `script --timing`.
3. Reproduce failures deterministically (including interactive firmware/menu flows).
4. Add targeted instrumentation to isolate root cause.
5. Implement a minimal, safe fix.
6. Rebuild and validate with the same failing sequence.
7. Produce clean, patch-checkable commits.

## Repository layout

- `install.sh`: installer for the skill
- `jira-issue-fixer-next/SKILL.md`: skill instructions
- `jira-issue-fixer-next/agents/openai.yaml`: UI metadata
- `jira-issue-fixer-next/references/debug_playbook.md`: detailed workflow + guardrails
- `jira-issue-fixer-next/scripts/capture_repro_session.sh`: capture `session.log` and `timing.log`
- `jira-issue-fixer-next/scripts/run_repro_menu_boot.sh`: wrapper for interactive repro automation
- `jira-issue-fixer-next/scripts/repro_menu_boot.expect`: expect automation template
- `jira-issue-fixer-next/scripts/repro_before_after_check.sh`: verify pre-fix failure exists and post-fix failure is gone
- `jira-issue-fixer-next/scripts/detect_checkpatch_cmd.sh`: detect checker command for known repos
- `jira-issue-fixer-next/scripts/patchcheck_wrapper.sh`: helper for edk2 PatchCheck usage

## Clone

SSH:

```bash
GIT_SSH_COMMAND='ssh -i ~/.ssh/slingappa_git/id_rsa -o IdentitiesOnly=yes' \
git clone git@github.com:slingappa/jira-issue-fixer-skill.git
cd jira-issue-fixer-skill
```

HTTPS:

```bash
git clone https://github.com/slingappa/jira-issue-fixer-skill.git
cd jira-issue-fixer-skill
```

## Install

```bash
./install.sh --force
```

Optional destination:

```bash
./install.sh --dest /path/to/skills --force
```

## Recommended prompt template (final)

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
- Artifact/runtime paths not embedded in command:
  <EXTRA_ARTIFACT_OR_RUNTIME_PATHS>

Exact failing sequence:
1) <STEP_1>
2) <STEP_2>
...
N) <STEP_N>

Constraints and required behavior:
- First capture pre-fix logs using script --timing:
  - output dir: <LOG_OUTPUT_DIR>
  - files: session.log, timing.log
- Reproduce failure in pre-fix logs (mandatory).
- Automate repro sequence and keep it deterministic.
- Isolate root cause with minimal instrumentation.
- Implement minimal safe fix only.
- Rebuild using provided build script.
- Capture post-fix logs with the exact same sequence.
- Run before/after signature check:
  - pre-log must contain failure signature
  - post-log must not contain failure signature
- Confirm positive boot progression in post-fix logs.
- Resolve checker automatically for known repos; if unresolved, ask before check-in.
- If checker command is provided, use it instead of auto-detection.
- Run checker and pass before check-in.
- Create clean commit with Problem/Root cause/Fix and Signed-off-by.
- Keep temporary diagnostics out of final fix commit.
- Do not modify unrelated files.
- Treat provided commands/paths as authoritative; ask for path clarification only if missing/ambiguous.

Expected final output:
1) Root-cause summary
2) Files changed
3) Pre/post log paths and signature-check results
4) Validation/build/checker results
5) Final commit hash
```
