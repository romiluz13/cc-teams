# CC-Teams Expected Behavior Runbook (Real E2E Manual Validation)

This runbook defines expected runtime behavior for CC-Teams in real Claude Code sessions.
Use it as the source of truth while you run full end-to-end cycles and mark `V` / `X`.

It is intentionally behavior-first (not synthetic scoring-first).

**Version:** 0.1.8 | **Last Updated:** 2026-02-12

---

## 0. Retrospective Validation Prompt

**Use this section to validate that all orchestration fixes are working correctly.**

Copy this prompt to Claude to run a comprehensive retrospective:

> **Retrospective Validation Prompt:**
>
> "Read `docs/cc-teams-excellence/EXPECTED-BEHAVIOR-RUNBOOK.md` Section 0.1 (Orchestration Fixes Checklist).
> For each of the 11 fixes, verify the fix is correctly implemented in the functional files.
> Report: ✅ FIXED (with evidence) | ⚠️ PARTIAL (explain gap) | ❌ MISSING (explain issue)
> Then check Section 0.2 for any NEW issues not covered in the fixes."

### 0.1 Orchestration Fixes Checklist (v0.1.8)

These 11 flaws were identified and fixed. Verify each is working:

| # | Fix | What To Verify | Functional File | Status |
|---|-----|----------------|-----------------|--------|
| 1.1 | REM-FIX assignee explicit | REM-FIX task assigns to `builder` by default; self-review exception documented | `cc-teams-lead/SKILL.md` ~line 1053 | [ ] |
| 1.2 | TeamDelete failure recovery | After 3 retries: shutdown requests → retry → user decision (manual cleanup / force continue) | `cc-teams-lead/SKILL.md` ~line 1113 | [ ] |
| 1.3 | Reviewer conflict priority | Security > Performance > Quality; ties require user decision | `cc-teams-lead/SKILL.md` ~line 547 | [ ] |
| 1.4 | Contract-diff checkpoint | Verifies CLAIMED_ARTIFACTS, FILES_MODIFIED, EVIDENCE_COMMANDS before verifier | `cc-teams-lead/SKILL.md` ~line 1010 | [ ] |
| 1.5 | Shutdown rejection handling | 5-step explicit process: parse reason → action per type → max 3 cycles → user decision | `cc-teams-lead/SKILL.md` ~line 1098 | [ ] |
| 2.1 | Challenge round termination | Max 3 rounds; all reviewers responded + no new CRITICAL = complete | `cc-teams-lead/SKILL.md` ~line 1020 | [ ] |
| 2.2 | Debate phase termination | Max 3 rounds; all stated final position + no new evidence = proceed to verdict | `bug-court/SKILL.md` ~line 135 | [ ] |
| 2.3 | Live-reviewer sync timeout | Escalation ladder reference: MEDIUM at T+5, HIGH at T+8, CRITICAL at T+10 | `pair-build/SKILL.md` ~line 131 | [ ] |
| 2.4 | Memory Notes preservation | Handoff payload includes `memory_notes_collected` from completed teammates | `cc-teams-lead/SKILL.md` ~line 298 | [ ] |
| 2.5 | Orphan task handling explicit | Do NOT resume; log to Memory Notes; create fresh stamped; delete if blocking | `cc-teams-lead/SKILL.md` ~line 277 | [ ] |
| 2.6 | Bug Court verdict criteria | Clear winner / Tie / All weak / Contested rules defined with user decision format | `bug-court/SKILL.md` ~line 155 | [ ] |

**Verification method:**
1. Read each functional file at the specified location
2. Confirm the fix language exists
3. Confirm behavior is deterministic (not vague)
4. Mark ✅ / ⚠️ / ❌

### 0.2 Discovery Checklist (Find New Issues)

Use this to discover issues NOT covered in the v0.1.8 fixes:

| Category | Question | Where To Check | Status |
|----------|----------|----------------|--------|
| **Handoff gaps** | Is there any handoff point without explicit "who owns next"? | All skill files → search for `TaskCreate`, `SendMessage` | [ ] |
| **Termination criteria** | Are there any loops/rounds without explicit max or exit condition? | All skill files → search for "round", "loop", "retry" | [ ] |
| **User decisions** | Are there ambiguous states where lead should ask user but doesn't? | cc-teams-lead → search for "if.*equal", "if.*tie", "if.*fails" | [ ] |
| **Memory loss** | Can any teammate output be lost before Memory Update? | Session handoff payload, Memory Notes collection | [ ] |
| **Zombie resources** | Can any team/task/teammate persist after workflow completion? | TeamDelete, shutdown flow, orphan sweep | [ ] |
| **Priority conflicts** | Are all conflict resolution priorities explicit? | Challenge round, debate verdict, remediation priority | [ ] |
| **Cross-reference integrity** | Do all cross-references to other skills work? | `cc-teams:*` references → verify skill exists | [ ] |
| **Contract validation** | Can any contract field be missing without triggering remediation? | Router Contract validation section | [ ] |
| **Agent capability leaks** | Can any read-only agent accidentally write? | Agent files → check `mode: READ-ONLY` enforcement | [ ] |
| **Escalation dead-ends** | Does every escalation ladder have a final user decision? | Escalation sections in cc-teams-lead | [ ] |

**New issue template:**
```
ISSUE: [Brief description]
LOCATION: [File:line]
IMPACT: [What can go wrong]
PROPOSED FIX: [How to fix]
```

---

## 1. Test Setup (Before Any Scenario)

- [ ] Agent Teams enabled in Claude Code:
  - `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`
- [ ] CC-Teams plugin loaded from this repo.
- [ ] Start from repository root:
  - `/Users/rom.iluz/Dev/cc10x_v5/cc-teams`
- [ ] No stale active team in current session (or explicitly cleaned up).
- [ ] Test in a real coding task, not synthetic prompt-only checks.

---

## 2. Global Expected Behavior (Applies To Every Request)

### Entry and routing
- [ ] CC-Teams lead is the orchestration entrypoint.
- [ ] Intent routing priority is deterministic:
  - ERROR -> DEBUG
  - PLAN -> PLAN
  - REVIEW -> REVIEW
  - otherwise -> BUILD
- [ ] Error signals always win conflicts (for example, "fix build" routes to DEBUG).

### Agent Teams lifecycle
- [ ] Lead performs Agent Teams preflight before team execution.
- [ ] Lead executes explicit team creation gate (team created + teammates reachable) before task assignment.
- [ ] Lead enters delegate mode after team creation and stays orchestration-only.
- [ ] Lead assigns or coordinates tasks; lead does not do feature implementation work.
- [ ] Teammates are spawned phase-scoped (on demand), not all at workflow kickoff.
- [ ] Team naming is project-scoped: `cc-teams-{project_key}-{workflow}-{timestamp}`.
- [ ] Preflight stale-team cleanup is project-scoped; foreign-project teams are logged but not auto-cleaned.
- [ ] Lead emits a structured handoff payload before pause/interruptible boundaries (not a vague narrative update).
- [ ] Team is cleaned up at end: shutdown requests then delete team resources.
- [ ] Shutdown uses retry/wait logic; workflow does not finalize until `TeamDelete()` succeeds.

### Operational state and escalation
- [ ] Lead uses normalized runtime states: `working`, `idle-blocked`, `idle-unresponsive`, `stalled`, `done`.
- [ ] Lead never reports `working` without fresh current-turn evidence.
- [ ] Lead applies severity escalation model for lag/unresponsive paths: `LOW`, `MEDIUM`, `HIGH`, `CRITICAL`.
- [ ] Each severity level maps to deterministic action (wait, status request, reassign, user decision).

### Task orchestration
- [ ] Workflow creates explicit `CC-TEAMS ...` task hierarchy.
- [ ] Workflow task hierarchy is created in the team-scoped task list (post-`TeamCreate`), not in a stale pre-team context.
- [ ] Every workflow task description is identity-stamped:
  - `Workflow Instance: ...`
  - `Workflow Kind: ...`
  - `Project Root: ...`
- [ ] Dependencies are DAG-safe (`addBlockedBy` forward-only).
- [ ] Parallel phases run in parallel only when protocol requires it.
- [ ] Startup orphan sweep runs before routing/resume:
  - stale scoped `in_progress` tasks are re-queued (`pending`) or deleted deterministically
  - only one active workflow instance remains per project
  - foreign-project tasks do not block current run
- [ ] Resume uses deterministic checklist (TaskList truth + team continuity + blocker revalidation), not stale assumptions.
- [ ] Workflow is not considered complete before `CC-TEAMS Memory Update` completes.
- [ ] Workflow is not considered complete before `TEAM_SHUTDOWN` succeeds.
- [ ] BUILD depth selection is deterministic (`QUICK` vs `FULL`) and defaults to `FULL` unless all quick-safety conditions pass.
- [ ] QUICK mode never bypasses Router Contract validation, verifier evidence, or memory update.
- [ ] QUICK mode auto-escalates to FULL chain on any blocking/remediation signal.
- [ ] Only outputs from runnable/in-progress tasks can drive gate changes; pre-runnable teammate findings are advisory until task is runnable.

### Router Contract enforcement
- [ ] Every teammate output ends with `### Router Contract (MACHINE-READABLE)` YAML.
- [ ] Lead validates contract before marking task complete.
- [ ] Contract includes `CONTRACT_VERSION`, `CLAIMED_ARTIFACTS`, and `EVIDENCE_COMMANDS` fields.
- [ ] If contract missing or malformed, lead creates remediation evidence path (non-silent failure).
- [ ] Unauthorized artifact claims trigger `CC-TEAMS REM-EVIDENCE` (no silent proceed).
- [ ] Narrative artifact claims must match `CLAIMED_ARTIFACTS`; mismatches trigger `CC-TEAMS REM-EVIDENCE`.

### Memory behavior
- [ ] Teammates read memory at start.
- [ ] Default memory owner is lead (`MEMORY_OWNER: lead`).
- [ ] Teammates emit Memory Notes; lead persists memory in final memory task.
- [ ] No unsafe parallel memory write races.

### Hooks policy
- [ ] Core CC-Teams orchestration works with hooks disabled.
- [ ] Hook gates are optional opt-in only (never hard dependency).

---

## 3. Gate Sequence Expected (Lead)

Expected gate flow:

1. `AGENT_TEAMS_READY`
2. `MEMORY_LOADED`
3. `TASKS_CHECKED`
4. `INTENT_CLARIFIED`
5. `RESEARCH_EXECUTED` (conditional)
6. `RESEARCH_PERSISTED` (conditional)
7. `REQUIREMENTS_CLARIFIED` (BUILD)
8. `TEAM_CREATED`
9. `TASKS_CREATED`
10. `CONTRACTS_VALIDATED`
11. `ALL_TASKS_COMPLETED`
12. `MEMORY_UPDATED`
13. `TEAM_SHUTDOWN`

Manual check:
- [ ] Gate order is respected with no skipped critical gate.

---

## 4. Workflow-Specific Expected Behavior

## PLAN Workflow

Expected runtime behavior:
- [ ] Planner runs in plan mode (`mode: "plan"`).
- [ ] Planner drafts plan, calls `ExitPlanMode`, waits for lead approval.
- [ ] Lead approves/rejects with explicit criteria (tests, paths, risks).
- [ ] Plan file saved to `docs/plans/YYYY-MM-DD-<feature>-plan.md` only after approval.
- [ ] Planner emits Memory Notes; lead persists references in memory task.

Expected artifacts:
- [ ] `CC-TEAMS PLAN: ...` task exists.
- [ ] `CC-TEAMS planner: ...` task exists.
- [ ] `CC-TEAMS Memory Update: Index plan in memory` exists and completes.

Never acceptable:
- [ ] Planner writes plan file before approval.
- [ ] Planner silently completes without Router Contract.

## BUILD Workflow

Expected runtime behavior:
- [ ] Plan-first gate triggers when no active plan context.
- [ ] Depth is selected before task creation:
  - `QUICK` only for bounded low-risk build scope
  - `FULL` for all high-risk/cross-layer/ambiguous scope
- [ ] Team kickoff spawns only builder + live-reviewer; downstream roles spawn when their tasks become runnable.
- [ ] Builder and live-reviewer coordinate in real time using direct teammate messaging.
- [ ] Builder owns all writes; other teammates are read-only.
- [ ] FULL post-build sequence runs: hunter -> 3 reviewers (parallel) -> challenge -> verifier -> memory update.
- [ ] QUICK post-build sequence runs: builder/live-reviewer -> verifier -> memory update.
- [ ] No shortcut path from hunter/remediation directly to verifier.
- [ ] Verifier reports evidence with commands and exit codes.

Expected artifacts:
- [ ] `CC-TEAMS BUILD: ...` parent task.
- [ ] Builder, live-reviewer, hunter, 3 reviewer tasks, challenge, verifier, memory update.
- [ ] Router Contracts for each teammate.

Never acceptable:
- [ ] Non-builder teammate edits source files.
- [ ] Verifier runs before challenge completion.
- [ ] Memory update omitted.
- [ ] QUICK mode used for high-risk or cross-layer changes.
- [ ] QUICK mode closes workflow after blocking findings without escalating to FULL.

## REVIEW Workflow

Expected runtime behavior:
- [ ] Security, performance, and quality reviewers run independently in parallel.
- [ ] Lead initiates challenge round with cross-review messaging.
- [ ] Security-critical conflicts are resolved conservatively.
- [ ] Unified verdict drives remediation or completion.

Expected artifacts:
- [ ] 3 reviewer tasks + challenge + memory update.
- [ ] Reviewer outputs include evidence and Router Contracts.

Never acceptable:
- [ ] Single-reviewer shortcut for significant review scope.
- [ ] Challenge phase skipped.

## DEBUG Workflow

Expected runtime behavior:
- [ ] Lead generates multiple falsifiable hypotheses.
- [ ] Investigator count is dynamic (2-5), not hardcoded.
- [ ] Investigators run in parallel, then debate phase cross-examines hypotheses.
- [ ] Winning hypothesis passed to builder for TDD fix.
- [ ] Post-fix full triad review + challenge + verifier + memory update.

Expected artifacts:
- [ ] `CC-TEAMS DEBUG: ...` parent task.
- [ ] N investigator tasks (N=2..5), debate, builder fix, 3 reviewers, challenge, verifier, memory update.

Never acceptable:
- [ ] "Quick fix" before root cause phase.
- [ ] Nested team creation inside debug workflow.

---

## 5. Remediation and Failure Handling (Expected)

### Blocking findings
- [ ] If `BLOCKING=true` or `REQUIRES_REMEDIATION=true`, lead creates `CC-TEAMS REM-FIX: ...`.
- [ ] Downstream tasks are blocked until remediation path resolves.

### Remediation re-review loop
- [ ] After REM-FIX completion, lead creates re-review tasks (security/performance/quality).
- [ ] Challenge round and re-hunt run before verifier is unblocked.
- [ ] Remediation task naming uses `CC-TEAMS REM-FIX:` (legacy `CC-TEAMS REMEDIATION:` accepted only for backward compatibility).

### Circuit breaker
- [ ] If REM-FIX count reaches 3+, lead triggers explicit user choice:
  - Research best practices
  - Fix locally
  - Skip
  - Abort

### Missing contract path
- [ ] Missing Router Contract triggers evidence remediation, not silent proceed.

### Task status lag / idle handling
- [ ] Lead nudges teammates if task state lags or teammate idles unexpectedly.
- [ ] Lead follows deterministic escalation ladder (nudge -> status request -> reassign).
- [ ] Lead does not prematurely close workflow while tasks remain incomplete.
- [ ] Lead does not claim "working" without fresh evidence from current turn.
- [ ] Lead labels idle state explicitly (`idle-blocked` vs `idle-unresponsive`), not vague idle spam.
- [ ] Repeated unresponsive path escalates to `stalled`/`CRITICAL` with explicit user decision before unsafe continuation.
- [ ] Premature findings from non-runnable teammates do not trigger remediation by default.

---

## 6. Agent-Team Capability Utilization (Must Be Visible)

- [ ] Direct teammate messaging is used where protocol requires collaboration:
  - builder <-> live-reviewer
  - reviewer <-> reviewer (challenge round)
  - investigator <-> investigator (debate)
- [ ] Parallel reviewer execution is used in review arenas.
- [ ] Parallel investigator execution is used in bug court.
- [ ] Lead remains coordinator and synthesizer, not code implementer.
- [ ] Read-only review agents remain read-only by capability (no write/edit/shell-write path).

---

## 7. Interruption / Resume Expected Behavior

If session is interrupted mid-workflow:
- [ ] Lead loads latest handoff payload (if present) from memory before making resume decisions.
- [ ] Handoff payload contains required fields:
  - `workflow_instance`, `workflow_kind`, `project_root`, `team_name`
  - `gate`, `task_snapshot`, `contracts`, `remediation`
  - `next_owner`, `resume_entrypoint`, `stale_assumptions`
- [ ] Lead detects in-progress tasks and missing teammates.
- [ ] Existing task state is preserved (no blind reset).
- [ ] Scoped orphan tasks are normalized before resume (`in_progress` without active teammate -> `pending`).
- [ ] Team is recreated if needed and only missing teammates are respawned.
- [ ] Blockers are revalidated before continuing:
  - verifier still blocked by challenge/remediation path when required
  - memory update still blocked by verifier
- [ ] Execution resumes from task DAG state using explicit `resume_entrypoint`.
- [ ] If handoff payload conflicts with TaskList state, TaskList wins and conflict is logged.
- [ ] Only one active workflow instance is resumed for current project.

Never acceptable:
- [ ] Restart from scratch without checking existing task DAG.
- [ ] Orphaned in-progress tasks ignored.
- [ ] Resume continuation based only on old teammate claims without current-task verification.
- [ ] Finalizing workflow while stale team resources still exist.

---

## 8. Scenario Matrix (Run in Real Claude Code)

Use one real task per scenario. Mark each check `V` or `X`.

## S01 - PLAN (ambiguous request)
- Prompt example: "Plan a robust auth module for this repo."
- Expected:
  - [ ] Clarification asked before plan finalization.
  - [ ] Plan approval flow executed.
  - [ ] Plan saved after approval only.

## S02 - PLAN with external research trigger
- Prompt example: "Plan Stripe + webhook architecture with best practices."
- Expected:
  - [ ] Research executed first.
  - [ ] Research persisted to `docs/research/...`.
  - [ ] Planner incorporates findings into plan.

## S03 - BUILD without existing plan
- Prompt example: "Implement feature X."
- Expected:
  - [ ] Plan-first gate asks user choice.
  - [ ] If build proceeds directly, requirements clarified explicitly.

## S04 - BUILD pair loop
- Expected:
  - [ ] Builder sends review requests to live-reviewer.
  - [ ] Live-reviewer responds LGTM/STOP with concrete reasons.
  - [ ] Builder blocks on STOP issues before continuing.

## S05 - BUILD post-implementation quality gate
- Expected:
  - [ ] Hunter runs before triad reviewers.
  - [ ] Triad reviewers run in parallel.
  - [ ] Challenge round occurs before verifier.

## S16 - BUILD quick-path bounded change
- Prompt example: "Small isolated refactor in one module, no API/schema/security changes."
- Expected:
  - [ ] Depth selector chooses QUICK.
  - [ ] Workflow still enforces Router Contracts + verifier evidence + memory update.
  - [ ] Team shutdown still required before completion.

## S17 - BUILD quick-path forced escalation
- Prompt example: "Quick change request that reveals blocking issue during verifier/remediation."
- Expected:
  - [ ] QUICK starts if eligible.
  - [ ] Blocking/remediation signal forces escalation to FULL.
  - [ ] FULL chain (hunter + triad + challenge + verifier) executes before completion.

## S18 - Premature finding from non-runnable teammate
- Prompt example: "BUILD run where verifier/reviewer sends findings before their task is runnable."
- Expected:
  - [ ] Lead classifies message as advisory pre-check (not gate-driving evidence).
  - [ ] Lead does not open `REM-FIX` / `REM-EVIDENCE` from this signal alone.
  - [ ] Lead acts on findings only when the corresponding task becomes runnable/in-progress.

## S19 - Cross-project stale team isolation
- Prompt example: "Session has stale teams from another repo and current repo starts a new workflow."
- Expected:
  - [ ] Lead creates current team with project-scoped team name.
  - [ ] Lead cleans only stale teams for current `project_key`.
  - [ ] Foreign-project stale teams do not block current workflow.

## S06 - BUILD verifier evidence
- Expected:
  - [ ] Verifier cites command + exit code evidence.
  - [ ] No "should pass" claims.

## S07 - REVIEW triad consensus
- Prompt example: "Review this auth/checkout change."
- Expected:
  - [ ] Security/performance/quality reviewers all execute.
  - [ ] Conflict resolution handled in challenge.

## S08 - DEBUG with 3+ hypotheses
- Prompt example: "Bug: app exits after one message."
- Expected:
  - [ ] Multiple hypotheses assigned to investigators.
  - [ ] Evidence-based debate run.
  - [ ] Winning root cause selected before fix.

## S09 - DEBUG remediation cycle
- Expected:
  - [ ] Fix is followed by full triad review.
  - [ ] Re-review loop runs when blocking findings appear.

## S10 - Missing Router Contract simulation
- Expected:
  - [ ] Lead detects non-compliance and routes evidence remediation.
  - [ ] Workflow does not silently proceed.

## S11 - Blocking finding simulation
- Expected:
  - [ ] `CC-TEAMS REM-FIX` task created.
  - [ ] Downstream tasks blocked until fix path completes.

## S12 - Circuit breaker simulation (3+ remediations)
- Expected:
  - [ ] Lead asks explicit user decision; does not loop forever.

## S13 - Session interruption
- Expected:
  - [ ] Interruption occurs during active execution (not only during shutdown).
  - [ ] Lead emits handoff payload before/at interruption boundary.
  - [ ] Resume checks existing tasks and applies orphan sweep.
  - [ ] Missing teammates are respawned for remaining runnable tasks only.
  - [ ] Resume continues from explicit `resume_entrypoint` without DAG reset.

## S14 - Team shutdown
- Expected:
  - [ ] Shutdown requests sent to teammates.
  - [ ] Team delete after approvals.
  - [ ] Workflow not finalized if team deletion fails.

## S15 - Handoff payload fidelity
- Expected:
  - [ ] Payload is persisted and references current workflow instance + gate.
  - [ ] Payload task snapshot matches TaskList at resume time (or conflict is explicitly recorded).
  - [ ] `stale_assumptions` is explicit (`[]` or listed assumptions), never omitted.

---

## 9. Hard Fail Conditions (Do Not Ship If Any True)

- [ ] Lead implements code directly in workflow.
- [ ] Team workflows complete without Memory Update task completion.
- [ ] Team workflows complete without TEAM_SHUTDOWN success.
- [ ] Remediation-required contracts are ignored.
- [ ] Non-builder teammate writes source files.
- [ ] Reviewer/investigator messaging phases do not function.
- [ ] Debug path fixes symptoms without root cause phase.
- [ ] Plan mode approval flow is bypassed.
- [ ] Workflow requires hooks to function.

---

## 10. Final Manual Verdict Template

Use this at the end of your live run:

```markdown
# CC-Teams Live Validation Verdict

Date:
Branch/Commit:
Tester:

Scenarios passed: [X/Y]
Hard fail conditions present: [Yes/No]

## What worked well (V)
- ...

## What degraded / failed (X)
- ...

## Ship decision
- [ ] Ready to merge
- [ ] Needs targeted fixes before merge

## Required follow-ups
1. ...
2. ...
```

---

## 11. Harmony Report (Completeness Gate)

Run this after the scenario matrix and before final production decision.

### A. Rule Consistency
- [ ] No contradictory gate ordering between runtime and runbook.
- [ ] State vocabulary is consistent (`working`, `idle-blocked`, `idle-unresponsive`, `stalled`, `done`).
- [ ] Remediation route is fully resolvable (blocking -> `REM-FIX` -> re-review/re-hunt -> verifier).

### B. Authority Clarity
- [ ] Runtime behavior authority is lead skill.
- [ ] Validation authority is runbook.
- [ ] Regression authority is lint.
- [ ] Governance authority is decision log.

### C. Completeness
- [ ] No skipped critical gate in live run.
- [ ] No unauthorized artifact claim passed silently.
- [ ] No orphan/inconsistent workflow instance left unresolved.
- [ ] Team lifecycle closed (`shutdown_request` + `TeamDelete`) before final completion.

### Required Pass Criteria
1. `npm run check:cc-teams` passes.
2. Harmony Report sections A/B/C have no `X`.
3. No hard-fail condition is present.
4. Decision log contains explicit release verdict entry.

If any criterion fails:
1. Mark release as `NOT READY`.
2. Open targeted remediation tasks.
3. Re-run Harmony Report after fixes.

---

## 12. Retrospective Verdict Template

Use this after running the Retrospective Validation (Section 0):

```markdown
# CC-Teams Retrospective Validation Verdict

**Version:** 0.1.8
**Date:** [YYYY-MM-DD]
**Validated By:** [Name/AI]

## Section 0.1: Orchestration Fixes (11 total)

| # | Fix | Status | Evidence |
|---|-----|--------|----------|
| 1.1 | REM-FIX assignee | ✅/⚠️/❌ | [line ref or note] |
| 1.2 | TeamDelete recovery | ✅/⚠️/❌ | [line ref or note] |
| 1.3 | Reviewer conflict priority | ✅/⚠️/❌ | [line ref or note] |
| 1.4 | Contract-diff checkpoint | ✅/⚠️/❌ | [line ref or note] |
| 1.5 | Shutdown rejection | ✅/⚠️/❌ | [line ref or note] |
| 2.1 | Challenge termination | ✅/⚠️/❌ | [line ref or note] |
| 2.2 | Debate termination | ✅/⚠️/❌ | [line ref or note] |
| 2.3 | Live-reviewer timeout | ✅/⚠️/❌ | [line ref or note] |
| 2.4 | Memory Notes preservation | ✅/⚠️/❌ | [line ref or note] |
| 2.5 | Orphan task handling | ✅/⚠️/❌ | [line ref or note] |
| 2.6 | Bug Court verdict | ✅/⚠️/❌ | [line ref or note] |

**Fixes Verified:** [X/11]

## Section 0.2: New Issues Discovered

| # | Issue | Location | Impact | Severity |
|---|-------|----------|--------|----------|
| N.1 | [Description] | [File:line] | [What can go wrong] | HIGH/MED/LOW |
| N.2 | ... | ... | ... | ... |

**New Issues Found:** [N]

## Verdict

- [ ] All 11 fixes verified ✅
- [ ] No new HIGH/CRITICAL issues discovered
- [ ] Cross-references intact
- [ ] Static checks pass (`npm run check:cc-teams`)

**Overall Status:**
- [ ] ✅ VALIDATED - Ready for production
- [ ] ⚠️ PARTIAL - Needs targeted fixes (list below)
- [ ] ❌ FAILED - Major rework required

**Required Actions:**
1. [Action if any]
2. [Action if any]
```
