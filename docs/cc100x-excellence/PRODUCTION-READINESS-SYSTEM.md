# CC100x Production Readiness System

## Purpose
Define exactly when CC100x is ready for production, and exactly when to stop pre-production innovation.

This document exists to prevent endless improvement loops and over-engineering drift.

---

## 1) Definition of Production Ready
CC100x is production-ready only when all gates below are true at the same time.

## Gate PR1 - Protocol Integrity
1. `npm run check:cc100x` passes with zero failures.
2. No known protocol lint regressions in lead/runbook/lint ownership layers.

## Gate PR2 - Workflow Completeness
Required live scenarios are executed and passed:
1. PLAN path (plan approval mode)
2. BUILD full chain (builder + live-reviewer + hunter + triad + challenge + verifier + memory + shutdown)
3. REVIEW standalone triad + challenge
4. DEBUG standalone (multi-hypothesis + debate + fix + full post-fix review + verifier)
5. Interruption/resume mid-execution (not only shutdown)

Pass rule:
1. No hard-fail conditions from runbook section 9
2. Team shutdown succeeds (`shutdown_request` + `TeamDelete`) in final state

## Gate PR3 - Evidence Quality
1. Verifier outputs command + exit-code evidence (no speculative pass claims).
2. Router Contract enforcement is strict (missing/malformed contract never silently proceeds).
3. Unauthorized artifact claims are blocked/remediated.

## Gate PR4 - Recovery Reliability
1. Session handoff payload is present for interruption boundaries.
2. Resume checklist executes deterministically from TaskList truth.
3. Recovery proceeds without workflow reset-from-scratch unless explicitly requested.

## Gate PR5 - Governance Approval
1. Decision log contains an explicit Phase E production approval entry.
2. Any known accepted limitations are documented as explicit production constraints.

---

## 2) Definition of "Best Version" (Pre-Prod)
"Best version" does NOT mean "no future improvements." It means:
1. No known critical orchestration flaws.
2. No unresolved hard-fail conditions.
3. No major architectural uncertainty left in core flows.
4. Additional changes are incremental, not foundational.

When these are true, ship.

---

## 3) Over-Engineering Stop Rule
Stop adding pre-prod complexity when any 2 of these are true for two consecutive cycles:
1. New changes do not improve runbook/benchmark outcomes.
2. New changes increase coordination friction (more stalls, more manual rescue).
3. New rules duplicate existing authority or create conflicting behavior.
4. New abstractions require explaining more than executing.

If stop rule triggers:
1. Freeze architecture.
2. Only allow bug fixes, documentation clarity, and observability improvements.
3. Ship to production.

---

## 4) Borrowing Guardrail (Before Any New Idea)
Every candidate idea must pass all checks:
1. Native Fit: aligns with Agent Teams + current CC100x workflow model.
2. Single-Owner Rule: one canonical file owns the rule.
3. Measurable Benefit: expected to improve at least one explicit gate.
4. Reversible: clear rollback path exists.
5. Complexity Budget: can be delivered without role explosion.

Reject if any check fails.

---

## 5) Complexity Budget (Pre-Prod)
Per improvement phase:
1. One core behavior change max.
2. Maximum 6 files touched unless explicitly approved in decision log.
3. No new agents or skills unless benchmark evidence proves necessity.
4. Must keep backward compatibility in deterministic profile.

---

## 6) Release Decision Matrix
Use this matrix when deciding to ship:

1. `READY NOW`
- PR1-PR5 all pass
- No hard-fail conditions
- No unresolved critical known risk

2. `READY WITH DECLARED LIMITS`
- PR1-PR4 pass
- PR5 includes explicit accepted limitation list and mitigation

3. `NOT READY`
- Any of PR1-PR4 fails
- Any hard-fail condition present

---

## 7) Production Freeze Policy
After production:
1. Core orchestration changes require benchmark + runbook evidence and a decision entry.
2. No structural changes without rollback plan and staged rollout.
3. Preference shifts to reliability, observability, and defect prevention.

---

## 8) Current Intent
CC100x should continue bold improvements only until PR1-PR5 are achieved.
After that point, the correct move is production shipment and controlled iteration.
