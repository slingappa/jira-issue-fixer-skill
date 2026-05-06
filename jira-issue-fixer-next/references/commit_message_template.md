# Commit Message Template (Mandatory)

Use this structure for agent-created commits.

Subject:
- `<pkg/component>: concise fix summary`

Body sections (all required):
1. Problem
- User-visible failure and impact.
- Include exact failure signature.

2. Trigger Sequence
- Exact minimal repro sequence.
- Include any required preconditions (menu path, shell round-trip, etc).

3. Trace Evidence
- Function/path and reject branch observed in pre-fix tracing.
- Include marker names/values proving the branch.

4. Root Cause
- Why the code rejected a valid case (or accepted an invalid one).
- Tie directly to trace evidence.

5. Fix
- What was changed and why it is minimal/safe.
- State preserved invariants and what remains unchanged.

6. Validation
- Before/after signature check result.
- Pre/post reproducibility rates.
- Negative-path regression checks.

7. Risk
- Residual risk and why it is acceptable.

Formatting rules:
- Wrap body lines to <= 75 chars.
- Keep each section compact and factual.
- Do not add `Signed-off-by` in agent-created commits.
