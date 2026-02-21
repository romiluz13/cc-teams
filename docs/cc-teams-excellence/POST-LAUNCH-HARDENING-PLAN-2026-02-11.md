# CC-Teams Post-Launch Hardening Plan (2026-02-11)

## Goal
Strengthen CC-Teams production reliability without changing its orchestration architecture:
- Keep Agent Teams as the core runtime model.
- Keep `cc-teams-lead` as the only entry point.
- Keep no-hook default behavior.
- Tighten evidence, artifact governance, and remediation determinism.

## Guardrails
1. No new agents in this pass.
2. No new workflow branches in this pass.
3. No nested teams, no fallback orchestration runtimes.
4. Every change must be reversible and covered by existing protocol checks.

## Upgrade Scope

### Track A - Contract Evidence Hardening
Files:
- `plugins/cc-teams/skills/router-contract/SKILL.md`
- `plugins/cc-teams/skills/cc-teams-lead/SKILL.md`
- `plugins/cc-teams/agents/*.md`

Changes:
1. Add contract schema versioning (`CONTRACT_VERSION: "2.3"`).
2. Add explicit artifact claims (`CLAIMED_ARTIFACTS`).
3. Add explicit command proof list (`EVIDENCE_COMMANDS`).
4. Require lead-side validation of:
   - unauthorized/missing claimed artifacts,
   - narrative claim vs contract mismatch,
   - missing command evidence for evidence-required roles.

Expected impact:
- Removes ambiguity between teammate narrative and actual evidence.
- Prevents "claimed output" drift.
- Improves deterministic remediation routing (`REM-EVIDENCE` vs `REM-FIX`).

### Track B - Governance/Lint Enforcement
Files:
- `scripts/lint-cc-teams-artifact-policy.sh`

Changes:
1. Enforce presence of `CONTRACT_VERSION`, `CLAIMED_ARTIFACTS`, and `EVIDENCE_COMMANDS` in all agent Router Contract templates.
2. Enforce lead and router-contract skill references for these fields.

Expected impact:
- Prevents silent regression of new contract guarantees.
- Keeps prompt and policy alignment intact across future edits.

### Track C - Internal Docs Alignment
Files:
- `docs/cc-teams-excellence/EXPECTED-BEHAVIOR-RUNBOOK.md`
- `docs/functional-governance/protocol-manifest.md`
- `docs/cc-teams-excellence/DECISION-LOG.md`

Changes:
1. Add runbook checks for contract evidence/artifact fields.
2. Update protocol manifest canon with contract schema + evidence/artifact fields.
3. Record this hardening round as a governed decision entry.

Expected impact:
- No doc/runtime contradiction for production operators.
- Compaction-safe traceability for future upgrades.

## Validation Plan
1. Run `npm run check:cc-teams`.
2. Confirm no protocol/lint regressions.
3. Confirm no workflow topology changes were introduced.
4. Confirm only targeted files changed.

## Rollback Plan
If any regression appears:
1. Revert Track B lint changes first (to unblock hotfix velocity).
2. Revert Track A lead validation additions if they cause false positives.
3. Keep `CONTRACT_VERSION` + fields in docs but downgrade to advisory until fixed.

## Release Notes (Patch)
- Contract schema hardened to v2.3.
- Lead validates explicit artifact/evidence contract fields.
- Lint now enforces contract evidence fields across all agents.
- Runbook and protocol manifest aligned to runtime behavior.
