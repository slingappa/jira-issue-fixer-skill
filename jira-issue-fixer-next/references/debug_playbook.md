# Debug Playbook (Interactive Firmware/Boot Issues)

## A. Context Integrity
- Create a dedicated local working branch before any debug/edit action.
- Keep user's original branch untouched during skill execution.
- Confirm the runtime image path and build output are the same file.
- Confirm branch/reset state before assuming previous fixes exist.
- Confirm exact failing sequence and direct-success sequence.

## B. Repro Automation Strategy
- For interactive failures, first capture `session.log` and `timing.log` using:
  - `script --timing=timing.log -q session.log -c \"<runtime command>\"`
- Use captured logs to tune menu navigation offsets/timing before code changes.
- Use deterministic automation for menu-driven flows.
- Start with user-provided keysteps; tune menu offsets only as needed.
- Parameterize key counts and timing via env vars.
- Keep logs in one stable location for grep-based signature checks.

## C. Instrumentation Ladder
Trace gate:
- No behavior change until trace evidence identifies the exact failing branch.
- Pre-fix tracing is mandatory and must be captured from a failing run.
- Prefer branch-specific tags so reject reason is unambiguous.

1. Add branch tags around suspected reject paths.
2. If DEBUG output is hidden, use serial writes.
3. Narrow to one branch reason before changing behavior.
4. Record trace-to-failure mapping explicitly (branch -> user-visible error).

## D. Fix Strategy
- Prefer preflight validation + existing execution path over large rewrites.
- Preserve safety checks; remove only false reject gates.
- Keep change set minimal and reviewable.

## E. Validation Bar
- Capture pre-fix logs and confirm failure signature exists.
- Capture post-fix logs with the same sequence and confirm failure signature is absent.
- Same failing sequence must now pass.
- Signature must disappear from logs.
- Positive path must continue (boot progression observed).

## F. Commit Standards
- One focused commit per logical fix.
- Message sections: Problem / Root cause / Fix.
- Do not add `Signed-off-by` in agent-created commits.
- User performs final explicit test/signoff and adds signoff themselves.
- Resolve checker command before check-in:
  - prefer user-provided checker command.
  - else auto-detect for known repos (Linux, edk2, U-Boot, Zephyr).
  - if still unresolved, ask user and block check-in.
- Run patch checker and report outcome before check-in.
