# Phase 3: SDLC Ecosystem Parity Diff (CC10x vs CC100x)

Date: 2026-02-09
Status: done
Method: functional-model-to-functional-model comparison
Inputs:
- `10-CC10X-FUNCTIONAL-BASELINE.md`
- `20-CC100X-FUNCTIONAL-TARGET.md`
- `40-AGENT-TEAMS-CORRECTNESS.md`
- `50-CROSS-CUTTING-PROTOCOL-AUDIT.md`

## 1) Lifecycle Parity Matrix

| Surface | CC10x Baseline | CC100x Target | Parity Verdict |
|---|---|---|---|
| Entry point | Router-only (`cc10x-router`) | Lead-only (`cc100x-lead`) | PRESERVED (renamed + delegate mode) |
| Routing priorities | ERROR > PLAN > REVIEW > DEFAULT | ERROR > PLAN > REVIEW > DEFAULT | PRESERVED |
| SDLC workflows | PLAN/BUILD/REVIEW/DEBUG | PLAN/BUILD/REVIEW/DEBUG | PRESERVED |
| Memory model | Load-first, auto-heal, final persist | Load-first, auto-heal, final persist | PRESERVED |
| Task DAG orchestration | Required, forward-only dependencies | Required, forward-only dependencies | PRESERVED |
| Memory update task | Mandatory final task per workflow | Mandatory final task per workflow | PRESERVED |
| Router contract validation | Contract-first with remediation loop | Contract-first with remediation loop | PRESERVED + EXPANDED |
| Research protocol | Triggered, prerequisite, persisted | Triggered, prerequisite, persisted | PRESERVED + EXPANDED |
| Lifecycle continuity | Plan/build/review/debug connected by tasks/memory | Same + teammate messaging | PRESERVED + EXPANDED |

## 2) Intentional Agent Teams Shifts

These are architecture migrations and are not regressions by default.

1. Subagent chaining -> teammate orchestration with peer messaging.
2. Lead runs in strict delegate mode.
3. BUILD moved to pair-build loop (`builder <-> live-reviewer`) before downstream gates.
4. REVIEW moved from single reviewer to specialist triad + challenge round.
5. DEBUG moved from single investigator-fix to competing-hypothesis investigation, then builder fix.
6. Explicit team lifecycle controls added (recovery, shutdown, no nested teams).

Evidence:
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:21`
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:36`
- `plugins/cc100x/skills/pair-build/SKILL.md:10`
- `plugins/cc100x/skills/review-arena/SKILL.md:10`
- `plugins/cc100x/skills/bug-court/SKILL.md:10`

## 3) Cross-Workflow Coupling Check

### Plan -> Build

- CC10x: explicit plan-file gate before implementation.
- CC100x: explicit plan-file gate remains in lead + builder + pair-build protocol.

Verdict: PRESERVED.

### Build -> Quality -> Verify

- CC10x: `builder -> (code-reviewer || hunter) -> verifier`.
- CC100x: `builder <-> live-reviewer -> hunter -> verifier`.

Verdict: FUNCTIONALLY SHIFTED.

### Debug -> Fix -> Quality -> Verify

- CC10x: `bug-investigator (fixes) -> code-reviewer -> verifier`.
- CC100x: `investigators (evidence only) -> builder (fix) -> quality-reviewer -> verifier`.

Verdict: FUNCTIONALLY SHIFTED.

### Read-only outputs -> memory durability

- Both systems enforce workflow-final memory persistence for read-only outputs.

Verdict: PRESERVED.

## 4) Risk Candidate Resolution

| Risk | Resolution | Final Status |
|---|---|---|
| R1 BUILD review-depth equivalence | Not equivalent. CC10x had full post-build code-reviewer breadth; CC100x pair-build path has focused live review and no full post-build multi-dimensional review gate. | CONFIRMED FINDING (MAJOR) |
| R2 DEBUG post-fix review breadth | Not equivalent. CC10x debug always runs code-reviewer (security+quality+performance); CC100x debug defaults to quality-reviewer-only and lead task graph hardcodes it. | CONFIRMED FINDING (MAJOR) |
| R3 Investigators no longer write fixes | Cleared. Although execution ownership moved to builder, evidence transfer is explicit and structured (root cause + repro + recommended regression test + contract fields). | CLEARED (INTENTIONAL SHIFT) |

Primary evidence:
- `reference/cc10x-router-SKILL.md:34`
- `reference/cc10x-router-SKILL.md:35`
- `reference/cc10x-agents/code-reviewer.md:51`
- `reference/cc10x-agents/code-reviewer.md:53`
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:42`
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:305`
- `plugins/cc100x/skills/pair-build/SKILL.md:127`
- `plugins/cc100x/skills/bug-court/SKILL.md:147`
- `plugins/cc100x/agents/investigator.md:80`
- `plugins/cc100x/skills/bug-court/SKILL.md:141`

## 5) Non-Functional Drift Note

Root documentation may drift from runtime behavior. Per trust policy, only functional skills/agents were used as truth during this parity decision.

## 6) Phase 3 Exit State

Completed:
- SDLC surface parity map
- Intentional migration classification
- Coupling checks
- Risk conversion to confirmed/cleared outcomes

Output linkage:
- Confirmed findings are in `03-FINDINGS.md`
- Unification decision is in `04-UNIFICATION-DECISION.md`
