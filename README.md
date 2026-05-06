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

## Recommended prompt template

```text
Use $jira-issue-fixer-next.
Jira: <JIRA_URL_OR_KEY>
Repos: <ABS_PATHS>
Build script: <ABS_PATH>
Run command: <EXACT_RUNTIME_CMD>
Repro steps: <NUMBERED_STEPS>
Capture `session.log` and `timing.log` using script --timing before automation.
Capture post-fix `session.log` and `timing.log` with same sequence and prove failure signature is gone.
Reproduce first, automate repro, isolate root cause with minimal instrumentation,
implement minimal fix, validate with same repro path, and commit cleanly.
```
