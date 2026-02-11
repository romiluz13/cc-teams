# CC100x Borrow Strategy: Neural Harmony

## 0) Purpose
Integrate the best ideas from external orchestration systems into CC100x **without** creating chaos, duplication, or architectural drift.

This is a **fit-first strategy**: every borrowed idea must feel natively CC100x.

---

## 1) Non-Negotiable Constraints
1. Agent Teams remains the architecture foundation.
2. `cc100x-lead` remains the only entry point.
3. No mandatory runtime hooks.
4. No skill/agent explosion by default.
5. Backward-compatible upgrades first; strict mode only after validation.
6. Builder-only write ownership remains enforced.
7. Every workflow remains task-DAG-driven and contract-gated.

---

## 2) Current Baseline (Already Strong)
CC100x already has:
1. Team lifecycle gating (`TEAM_CREATED` / `TEAM_SHUTDOWN`).
2. Contract-first progression with remediation loops.
3. Artifact governance (`REM-EVIDENCE` for unauthorized artifact claims).
4. Orphan-task recovery and workflow identity stamping.
5. Idle escalation ladder + communication discipline.
6. Protocol lint and runbook checks.

Strategy implication:
Do not replace these. Only close real gaps and tighten weak edges.

---

## 3) Source-Informed Borrow Map

## 3.1 Gastown (steveyegge/gastown)
Borrow:
1. Redundant completion observation (more than one completion check path).
2. Explicit operational-state vocabulary.
3. Session handoff contract discipline.
4. Severity-based escalation model for blocked runs.

Reject:
1. Full town/rig/beads platform model.
2. Daemon/deacon/witness architecture.
3. Hook-dependent core behavior.

## 3.2 Superpowers (obra/superpowers)
Borrow:
1. Strong phase discipline (clarify -> plan -> execute -> verify).
2. Strict TDD + evidence-first behavior.
3. Parallel execution only where dependencies allow.

Reject:
1. Subagent-specific assumptions replacing Agent Teams collaboration.
2. Worktree-heavy flow as a hard requirement for CC100x runtime.

## 3.3 Get Shit Done (glittercowboy/get-shit-done)
Borrow:
1. Human verification gate quality (explicit UAT-style check after execution).
2. Quick-path vs full-path mode selection by scope.
3. Persistent planning/state artifacts for long sessions.

Reject:
1. Permission bypass as a default doctrine.
2. Command-layer complexity that duplicates existing CC100x workflow logic.

## 3.4 BMAD Method
Borrow:
1. Scale-adaptive workflow depth (small work vs complex work).
2. Clear stage transitions and quality checkpoints.
3. Enterprise-style test architecture ideas as optional policy overlays.

Reject:
1. Large role taxonomy transplanted into CC100x.
2. Ceremony-heavy process that slows autonomous execution.

## 3.5 Agent-OS Concepts
Borrow:
1. Governed change loop concept (propose -> validate -> apply).
2. Determinism and replay mindset for orchestration state changes.
3. Auditability mindset for orchestration transitions.

Reject:
1. Runtime/kernel re-architecture.
2. Capability-system rewrite beyond CC100x scope.

---

## 4) Fit Rules (Harmony Filter)
Any candidate borrow must pass all:
1. **Native Fit:** can be expressed as CC100x workflow/task/contract behavior.
2. **No Role Inflation:** no new agents/skills unless existing roles cannot carry the behavior.
3. **No Duplicate Authority:** one source of truth for each rule (skill OR runbook OR lint), not conflicting copies.
4. **Operational Simplicity:** easier to execute correctly under pressure.
5. **Deterministic Failure Path:** when it fails, failure is explicit and recoverable.

If any rule fails, reject or defer.

---

## 5) Execution Plan (No Chaos)

## Phase S1: Governance + State Vocabulary
Goal:
Unify runtime state semantics and escalation language.

Target files:
1. `plugins/cc100x/skills/cc100x-lead/SKILL.md`
2. `docs/cc100x-excellence/EXPECTED-BEHAVIOR-RUNBOOK.md`
3. `scripts/lint-cc100x-protocol-integrity.sh`

Changes:
1. Normalize state terms:
   - `working`
   - `idle-blocked`
   - `idle-unresponsive`
   - `stalled`
2. Add severity-based escalation labels for blocked scenarios:
   - `low`, `medium`, `high`, `critical`
3. Define deterministic escalation actions by severity.

No new agents/skills.

## Phase S2: Session Handoff + Resume Integrity
Goal:
Make interruption/recovery behavior explicit and repeatable.

Target files:
1. `plugins/cc100x/skills/cc100x-lead/SKILL.md`
2. `docs/cc100x-excellence/EXPECTED-BEHAVIOR-RUNBOOK.md`
3. `docs/cc100x-excellence/BENCHMARK-CASES.md`

Changes:
1. Add mandatory handoff payload schema in workflow notes.
2. Add resume checklist for restoring task context without stale assumptions.
3. Add scenario tests for mid-execution interruption + recovery.

No hooks required.

## Phase S3: Adaptive Depth (Quick vs Full)
Goal:
Auto-select workflow depth based on scope/risk without changing architecture.

Target files:
1. `plugins/cc100x/skills/cc100x-lead/SKILL.md`
2. `docs/cc100x-excellence/MASTER-PLAN.md`
3. `docs/cc100x-excellence/EXPECTED-BEHAVIOR-RUNBOOK.md`

Changes:
1. Add deterministic depth selector:
   - Quick path: small bounded changes.
   - Full path: high-risk or cross-system work.
2. Keep same agents; only vary orchestration depth and gate strictness.
3. Ensure quick path still honors contracts, verifier, and memory update.

No new agents/skills by default.

## Phase S4: Completeness Validation Gate
Goal:
Prove no conflicts, no duplication, no logical redundancy.

Target files:
1. `scripts/lint-cc100x-protocol-integrity.sh`
2. `docs/cc100x-excellence/EXPECTED-BEHAVIOR-RUNBOOK.md`
3. `docs/cc100x-excellence/DECISION-LOG.md`

Changes:
1. Add explicit checks for:
   - duplicate contradictory rules
   - missing gate references
   - inconsistent state labels
   - unresolved remediation routes
2. Add final “Harmony Report” checklist and required pass criteria.
3. Record decision-log entry for each approved phase.

---

## 6) Anti-Duplication Design
Single-source ownership:
1. Runtime behavior rules: `cc100x-lead/SKILL.md`
2. Human validation criteria: `EXPECTED-BEHAVIOR-RUNBOOK.md`
3. Regression guardrails: `lint-cc100x-protocol-integrity.sh`
4. Governance trace: `DECISION-LOG.md`

If the same rule appears in two places, one must be declared canonical and the other references it.

---

## 7) Completeness Validation (Final Gate)
Before production merge, all must be true:
1. `npm run check:cc100x` passes.
2. Runbook gate sequence is consistent with lead runtime.
3. No unresolved orphan/stale workflow tasks in tested scenarios.
4. No unauthorized artifact claims pass silently.
5. No duplicate/conflicting rule definitions across lead/runbook/lint.
6. REVIEW and DEBUG full paths are exercised at least once in live validation.
7. Decision log has explicit `APPROVED` entries for S1-S4.

If any fails:
Block release and open a targeted remediation task.

---

## 8) Definition of “Perfect Harmony”
System is “harmonious” when:
1. Each workflow phase has one clear owner and one clear gate.
2. Every handoff is explicit, reversible, and evidence-backed.
3. Parallelism increases throughput without increasing ambiguity.
4. Recovery from interruption is deterministic.
5. A new reviewer can read the protocol and predict runtime behavior correctly.

---

## 9) Immediate Next Step
Execute Phase S1 first (state + escalation normalization), then run full checks before S2.
