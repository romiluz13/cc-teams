# CC100x Expected Behavior Runbook (Real E2E Manual Validation)

This runbook defines expected runtime behavior for CC100x in real Claude Code sessions.
Use it as the source of truth while you run full end-to-end cycles and mark `V` / `X`.

It is intentionally behavior-first (not synthetic scoring-first).

---

## 1. Test Setup (Before Any Scenario)

- [ ] Agent Teams enabled in Claude Code:
  - `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`
- [ ] CC100x plugin loaded from this repo.
- [ ] Start from repository root:
  - `/Users/rom.iluz/Dev/cc10x_v5/cc100x`
- [ ] No stale active team in current session (or explicitly cleaned up).
- [ ] Test in a real coding task, not synthetic prompt-only checks.

---

## 2. Global Expected Behavior (Applies To Every Request)

### Entry and routing
- [ ] CC100x lead is the orchestration entrypoint.
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
- [ ] Team is cleaned up at end: shutdown requests then delete team resources.

### Task orchestration
- [ ] Workflow creates explicit `CC100X ...` task hierarchy.
- [ ] Dependencies are DAG-safe (`addBlockedBy` forward-only).
- [ ] Parallel phases run in parallel only when protocol requires it.
- [ ] Workflow is not considered complete before `CC100X Memory Update` completes.
- [ ] Workflow is not considered complete before `TEAM_SHUTDOWN` succeeds.

### Router Contract enforcement
- [ ] Every teammate output ends with `### Router Contract (MACHINE-READABLE)` YAML.
- [ ] Lead validates contract before marking task complete.
- [ ] If contract missing or malformed, lead creates remediation evidence path (non-silent failure).

### Memory behavior
- [ ] Teammates read memory at start.
- [ ] Default memory owner is lead (`MEMORY_OWNER: lead`).
- [ ] Teammates emit Memory Notes; lead persists memory in final memory task.
- [ ] No unsafe parallel memory write races.

### Hooks policy
- [ ] Core CC100x orchestration works with hooks disabled.
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
8. `TASKS_CREATED`
9. `TEAM_CREATED`
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
- [ ] `CC100X PLAN: ...` task exists.
- [ ] `CC100X planner: ...` task exists.
- [ ] `CC100X Memory Update: Index plan in memory` exists and completes.

Never acceptable:
- [ ] Planner writes plan file before approval.
- [ ] Planner silently completes without Router Contract.

## BUILD Workflow

Expected runtime behavior:
- [ ] Plan-first gate triggers when no active plan context.
- [ ] Builder and live-reviewer coordinate in real time using direct teammate messaging.
- [ ] Builder owns all writes; other teammates are read-only.
- [ ] Post-build sequence runs: hunter -> 3 reviewers (parallel) -> challenge -> verifier -> memory update.
- [ ] No shortcut path from hunter/remediation directly to verifier.
- [ ] Verifier reports evidence with commands and exit codes.

Expected artifacts:
- [ ] `CC100X BUILD: ...` parent task.
- [ ] Builder, live-reviewer, hunter, 3 reviewer tasks, challenge, verifier, memory update.
- [ ] Router Contracts for each teammate.

Never acceptable:
- [ ] Non-builder teammate edits source files.
- [ ] Verifier runs before challenge completion.
- [ ] Memory update omitted.

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
- [ ] `CC100X DEBUG: ...` parent task.
- [ ] N investigator tasks (N=2..5), debate, builder fix, 3 reviewers, challenge, verifier, memory update.

Never acceptable:
- [ ] "Quick fix" before root cause phase.
- [ ] Nested team creation inside debug workflow.

---

## 5. Remediation and Failure Handling (Expected)

### Blocking findings
- [ ] If `BLOCKING=true` or `REQUIRES_REMEDIATION=true`, lead creates `CC100X REM-FIX: ...`.
- [ ] Downstream tasks are blocked until remediation path resolves.

### Remediation re-review loop
- [ ] After REM-FIX completion, lead creates re-review tasks (security/performance/quality).
- [ ] Challenge round and re-hunt run before verifier is unblocked.
- [ ] Remediation task naming uses `CC100X REM-FIX:` (legacy `CC100X REMEDIATION:` accepted only for backward compatibility).

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
- [ ] Lead does not prematurely close workflow while tasks remain incomplete.

---

## 6. Agent-Team Capability Utilization (Must Be Visible)

- [ ] Direct teammate messaging is used where protocol requires collaboration:
  - builder <-> live-reviewer
  - reviewer <-> reviewer (challenge round)
  - investigator <-> investigator (debate)
- [ ] Parallel reviewer execution is used in review arenas.
- [ ] Parallel investigator execution is used in bug court.
- [ ] Lead remains coordinator and synthesizer, not code implementer.

---

## 7. Interruption / Resume Expected Behavior

If session is interrupted mid-workflow:
- [ ] Lead detects in-progress tasks and missing teammates.
- [ ] Existing task state is preserved (no blind reset).
- [ ] Team is recreated if needed and only missing teammates are respawned.
- [ ] Execution resumes from task DAG state.

Never acceptable:
- [ ] Restart from scratch without checking existing task DAG.
- [ ] Orphaned in-progress tasks ignored.

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
  - [ ] `CC100X REM-FIX` task created.
  - [ ] Downstream tasks blocked until fix path completes.

## S12 - Circuit breaker simulation (3+ remediations)
- Expected:
  - [ ] Lead asks explicit user decision; does not loop forever.

## S13 - Session interruption
- Expected:
  - [ ] Resume checks existing tasks.
  - [ ] Missing teammates are respawned for remaining tasks.

## S14 - Team shutdown
- Expected:
  - [ ] Shutdown requests sent to teammates.
  - [ ] Team delete after approvals.
  - [ ] Workflow not finalized if team deletion fails.

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
# CC100x Live Validation Verdict

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
