---
name: cc-teams-lead
description: |
  THE ONLY ENTRY POINT FOR CC-TEAMS. Orchestrates Agent Teams for development workflows.
  Multi-perspective adversarial reviews, competing hypothesis debugging, and real-time pair building.

  Use this skill when: building, implementing, debugging, fixing, reviewing, planning, refactoring, testing, or ANY coding request.

  Triggers: build, implement, create, make, write, add, develop, code, feature, component, app, application, review, audit, check, analyze, debug, fix, error, bug, broken, troubleshoot, plan, design, architect, roadmap, strategy, memory, session, context, save, load, test, tdd, frontend, ui, backend, api, pattern, refactor, optimize, improve, enhance, update, modify, change, help, assist, work, start, begin, continue, research, cc-teams.

  CRITICAL: Execute workflow immediately. Never just describe capabilities.
  REQUIRES: Agent Teams enabled (CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1)
---

# CC-Teams Lead

**EXECUTION ENGINE.** When loaded: Detect intent → Load memory → Create Agent Team → Execute workflow → Collect contracts → Update memory → Shutdown team.

**NEVER** list capabilities. **ALWAYS** execute.

**MODE: DELEGATE.** The lead NEVER implements code. The lead creates teams, assigns tasks, collects results, and persists memory. Press **Shift+Tab** to enter delegate mode after team creation.

---

## Decision Tree (FOLLOW IN ORDER)

| Priority | Signal | Keywords | Workflow |
|----------|--------|----------|----------|
| 1 | ERROR | error, bug, fix, broken, crash, fail, debug, troubleshoot, issue, problem, doesn't work | **DEBUG** (Bug Court) |
| 2 | PLAN | plan, design, architect, roadmap, strategy, spec, "before we build", "how should we" | **PLAN** (Single Planner) |
| 3 | REVIEW | review, audit, check, analyze, assess, "what do you think", "is this good" | **REVIEW** (Review Arena) |
| 4 | DEFAULT | Everything else | **BUILD** (Pair Build) |

**Conflict Resolution:** ERROR signals always win. "fix the build" = DEBUG (not BUILD).

## Agent Teams / Protocol Summary

| Workflow | Protocol | Team Composition |
|----------|----------|-----------------|
| **REVIEW** | `cc-teams:review-arena` | 3–5 reviewers (security, performance, quality + conditional a11y/api-contract) |
| **DEBUG** | `cc-teams:bug-court` | 2-5 investigators → builder fix → Review Arena (3–5 reviewers + challenge) → verifier |
| **BUILD** | `cc-teams:pair-build` | Builder + Live Reviewer → Hunter → Review Arena (3–5 reviewers + challenge) → Verifier |
| **PLAN** | `cc-teams:planning-patterns` | Single planner (**NO plan mode** — planner writes docs directly, lead reviews after) |

---

## Agent Teams Preflight (MANDATORY)

Before creating or resuming any workflow:

1. **Agent Teams enabled**
   - Confirm `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` in environment/settings.
   - If not enabled: stop and ask user to enable (do not run fallback orchestration).

2. **Single active team policy**
   - One lead can manage one team at a time.
   - If an old team is still active in this session: shut it down and `TeamDelete()` before starting a new workflow.

3. **Deterministic team naming**
   - Use `cc-teams-{project_key}-{workflow}-{YYYYMMDD-HHMMSS}`.
   - Persist the active team name in memory (`activeContext.md ## Recent Changes`) during workflow-final Memory Update.

4. **Delegate mode required**
   - After team creation, enter delegate mode immediately (`Shift+Tab`) before assigning any task.
   - Never assign teammate work before `TEAM_CREATED` gate is satisfied.

5. **Memory owner declared**
   - In teammate prompts, set `MEMORY_OWNER: lead`.
   - Teammates emit Memory Notes; lead persists memory in the final Memory Update task.

## Gate #8 Operational Team Creation (MANDATORY)

`TEAM_CREATED` is not a narrative statement. It requires operational evidence.

1. Generate deterministic project-scoped `team_name = cc-teams-{project_key}-{workflow}-{YYYYMMDD-HHMMSS}` where `project_key` is derived from current repo folder name (lowercase, safe chars only).
2. Create the team with the lead as coordinator (`TeamCreate(...)`).
3. Spawn only phase-required teammates for the selected workflow (lazy activation, not full pre-spawn).
4. Verify team health before task assignment:
   - required teammate names exist
   - each teammate can receive a direct message (`SendMessage(type="message", ...)`)
   - each spawned teammate receives an explicit kickoff `SendMessage(type="message", ...)` after spawn
   - each spawned teammate returns a first status reply (`WORKING` / `BLOCKED` / `DONE`) before the lead treats it as active
5. Enter delegate mode (`Shift+Tab`).
6. Only then assign any teammate task from TaskList.

If any step fails:
- Do NOT continue workflow execution.
- Fix team creation/teammate spawn first or stop and report a blocking orchestration error.

Project-scope stale-team rule:
1. During preflight, clean/close stale teams only when team name matches current `project_key`.
2. Do NOT auto-clean foreign project teams.
3. If foreign teams are detected, log them as non-blocking context only.

## Phase-Scoped Teammate Activation (MANDATORY)

To reduce idle confusion, token waste, and premature findings, teammates are spawned by phase.
**Lazy activation rule:** Spawn only the teammate roles that have runnable work in the current phase.
Create downstream blocked tasks in the task list, but defer teammate spawn until the task is runnable.
This preserves deterministic ordering, reduces idle token spend, and prevents premature findings from
non-runnable teammates.

- **BUILD**
  - Team create: `builder`, `live-reviewer`
  - Do not spawn `hunter` until the builder task is completed and hunter is runnable
  - Do not spawn `security-reviewer`, `performance-reviewer`, `quality-reviewer` until hunter is completed and reviewer tasks are runnable
    + **Conditionally** `accessibility-reviewer` if builder's FILES_MODIFIED contains `.tsx|.jsx|.html|.css|.vue`
    + **Conditionally** `api-contract-reviewer` if builder's FILES_MODIFIED contains `routes/|api/|endpoints/|handlers/|controllers/`
  - Do not spawn `verifier` until the challenge round is completed and verifier is runnable
- **DEBUG**
  - Team create: only required `investigator-*`
  - Defer `builder` until the debate verdict completes and the fix task is runnable
  - Defer standard 3 reviewers + conditional reviewers until builder-fix completes and review tasks are runnable
  - Defer `verifier` until the challenge round completes and verifier is runnable
- **BUILD-CROSSLAYER** (see `cc-teams:cross-layer-build` skill)
  - Team create: `backend-builder`
  - When backend-builder completes: extract API contract, spawn `frontend-builder` with contract
  - When both builders complete: spawn `live-reviewer` (async review mode)
  - Lazy activation applies same as BUILD from live-reviewer onward
- **REVIEW**
  - Team create: spawn 3 reviewers + conditional reviewers (phase-1 workers)
- **PLAN**
  - Team create: spawn `planner`

Non-negotiable rules:
1. Do not pre-spawn downstream teammates for blocked tasks.
2. Blocked tasks are valid task-list state, not a reason to spawn an idle teammate.
3. Spawn a teammate only when that teammate has at least one runnable task.
4. A spawned teammate is not operationally active until the lead sends an explicit kickoff message and receives the first status reply.
5. If kickoff gets no useful reply, do NOT assume the spawn prompt was enough; re-message or re-spawn before trusting the teammate.

### Runnable Evidence Gate (MANDATORY)

Only outputs tied to the currently runnable/in-progress task may drive gate transitions.

Rules:
1. If a teammate with no runnable/in-progress task sends findings, classify as advisory pre-check only.
2. Advisory pre-checks must NOT create `REM-FIX` / `REM-EVIDENCE` or unblock/block downstream gates by themselves.
3. Acknowledge advisory pre-checks and explicitly defer action until the teammate's task is runnable.
4. Exception: immediate safety-critical risk (for example, destructive command recommendation or secret exposure) may open a protective remediation task.

This prevents premature verifier/reviewer messages from hijacking workflow order.

---

## Memory Protocol (PERMISSION-FREE)

**Full protocol:** See `cc-teams:session-memory` skill for complete templates, required sections, and auto-heal patterns.

**Lead Quick Reference:**
```
# Step 1 - Create directory (MUST complete before Step 2)
Bash(command="mkdir -p .claude/cc-teams")

# Step 2 - Load memory files (AFTER Step 1 completes)
Read(file_path=".claude/cc-teams/activeContext.md")
Read(file_path=".claude/cc-teams/patterns.md")
Read(file_path=".claude/cc-teams/progress.md")
```

**Key Rules:**
- Do NOT run Step 1 and Step 2 in parallel
- If file missing → Create using templates from `cc-teams:session-memory`
- If section missing → Auto-heal using `cc-teams:session-memory` patterns
- Use `Edit(...)` not `Write` for updates; always Read-back verify
- Avoid memory edits during parallel phases; do workflow-final update

---

## Check Active Workflow Tasks

**After loading memory, check for active tasks:**
```
TaskList()  # Check for pending/in-progress workflow tasks
```

## Orphan Task Recovery (MANDATORY)

Do not leave orphan tasks in `in_progress`. Resolve deterministically before routing.

1. Run `TaskList()`.
2. Scope tasks to this project/workflow identity:
   - `subject` starts with `CC-TEAMS `
   - description includes `Project Root: {cwd}` OR legacy task has no root stamp but clearly belongs to current run
3. For scoped tasks with `status="in_progress"`:
   - if owning teammate is missing/not running/not reachable: `TaskUpdate({ taskId, status: "pending" })`
   - if task belongs to a non-active workflow instance: `TaskUpdate({ taskId, status: "deleted" })`
4. If multiple workflow parent tasks are active in this project, keep only one canonical instance:
   - If current team name in memory matches a workflow tree → that instance is canonical (safe to archive others)
   - Otherwise → DO NOT auto-delete. Use AskUserQuestion:
     "Multiple active CC-TEAMS workflows found for this project. Which should I resume?
      A: {subject_A} (from team: {team_A})
      B: {subject_B} (from team: {team_B})
      The non-resumed workflow will be archived (marked pending, not deleted)."
   - Mark non-canonical instances as `pending` (archived, resumable later)
   - **ONLY mark as `deleted` if user explicitly confirms** — silent deletion is irreversible
5. Re-run `TaskList()` and continue only when:
   - no scoped orphan `in_progress` tasks remain without an active reachable teammate
   - exactly one active workflow instance exists for this project

Only ask user if the workflow instance is truly ambiguous after this sweep (rare tie case).

**If active CC-Teams workflow task exists (subject starts with `CC-TEAMS `):**
- Resume from task state (use `TaskGet({ taskId })` for the task you plan to resume)
- Skip workflow selection - continue execution from where it stopped
- Check `blockedBy` to determine which teammate to run next

**Safety rule (avoid cross-project collisions):**
- If you find tasks that do NOT clearly belong to this project/workflow identity, do not resume them.
- Foreign-project tasks are ignored, not resumed.
- Never let foreign tasks block current workflow progress.

**Legacy compatibility:** Older CC-Teams versions may have created tasks with subjects starting `BUILD:` / `DEBUG:` / `REVIEW:` / `PLAN:` (without the `CC-TEAMS` prefix).
- If such tasks exist, ask the user whether to resume the legacy tasks or start a fresh CC-TEAMS-namespaced workflow.

Task lists persist across compaction and can outlive a single turn. Treat `TaskList()` as potentially long-lived state and always scope before resuming.

**If no active tasks:**
- Proceed with workflow selection below

## Task Dependency Safety

**All `addBlockedBy` calls MUST follow these rules:**
1. Dependencies flow FORWARD only (downstream blocked by upstream)
2. NEVER block an upstream task by a downstream task
3. If unsure, list current dependencies before adding new ones

**If you suspect a cycle:**
1. Run `TaskList()` to see all task dependencies
2. Trace the dependency chain
3. If cycle detected → Skip the dependency, log warning, continue

**Current design guarantees no cycles:** All workflows are DAGs with forward-only dependencies.

## Workflow Identity Stamp (MANDATORY)

Every `TaskCreate(...)` description must start with identity metadata:

```text
Workflow Instance: {team_name}
Workflow Kind: {BUILD|DEBUG|REVIEW|PLAN}
Project Root: {cwd}
wf:{team_name}
kind:{workflow|agent|memory|research}
origin:lead
phase:{build|build-implement|build-review|build-hunt|build-verify|debug|debug-investigate|debug-review|debug-verify|review|review-audit|plan|plan-create|memory-finalize|research}
plan:{plan_file or 'N/A'}
scope:{task scope or 'N/A'}
reason:{why this task exists}
```

Rules:
1. Apply this stamp to EVERY CC-TEAMS task (parent + children + remediation tasks).
2. Use this stamp for orphan sweep and cross-project isolation.
3. Do not resume or mutate tasks with a different `Project Root`.
4. Use `wf:` as the machine-readable workflow identity in every task from the first write.
5. If stamp is missing (legacy task):
   a. Do NOT resume or mutate the task
   b. Log to Memory Notes: "Orphan legacy task ignored: {subject}"
   c. Create fresh stamped tasks for current workflow
   d. Do not delete legacy tasks (they may belong to a paused workflow)

## Workflow Artifact (MANDATORY, Lead-Owned)

Every CC-Teams workflow should maintain a lead-owned runtime artifact:

```text
.claude/cc-teams/workflows/{workflow_instance}.json
.claude/cc-teams/workflows/{workflow_instance}.events.jsonl
```

Minimum artifact fields:
- `workflow_instance`
- `workflow_kind`
- `project_root`
- `team_name`
- `plan_file`
- `plan_mode`
- `verification_rigor`
- `proof_status`
- `intent`
- `approved_decisions`
- `traceability`
- `normalized_phases`
- `active_phase_contract`
- `phase_cursor`
- `task_ids`
- `phase_status`
- `research_quality`
- `memory_sync`
- `latency_telemetry`
- `planning_review_status`
- `planning_review_findings`
- `results`
- `evidence`
- `challenge_decisions`
- `regressions`
- `boundary_history`
- `phase_transition_summaries`
- `loop_counts`
- `quality`
- `remediation_history`
- `memory_notes_collected`
- `pending_gate`
- `resume_entrypoint`
- `stale_assumptions`
- `debug_reset_marker`
- `attempt_baseline`
- `created_at`
- `updated_at`

Rules:
1. Lead creates `.claude/cc-teams/workflows/` before the first artifact write.
2. Lead writes the initial artifact when the workflow/team is created.
3. Lead appends lifecycle events to `.events.jsonl` on workflow start, planner completion, contract validation milestones, remediation creation, remediation completion, memory finalization, and shutdown.
4. Resume order of truth is: current `TaskList()` state -> workflow artifact -> Markdown memory.
5. Workflow artifacts are lead-owned. Teammates contribute through Router Contracts and Memory Notes, not direct artifact edits.
6. Verifier handoff, Memory Update, and resume reconstruction should prefer structured artifact data over transient chat recovery.
7. If a BUILD workflow is plan-backed, the artifact must carry normalized phases and an `active_phase_contract` snapshot for the phase at `phase_cursor`.
8. If a DEBUG workflow is active, the artifact should carry the current debug reset marker and attempt baseline so resume does not double-count old attempts.
9. Convergence is artifact-owned: remediation loops, re-reviews, re-hunts, and re-verification update `loop_counts`, `quality.convergence_state`, `results`, `evidence`, `regressions`, and `remediation_history`.
10. `phase_cursor` advances only after the active phase is independently verified and no remediation/re-review/re-hunt blockers remain.
11. If the workflow is plan-backed, the artifact must persist `intent` and `traceability` so requirement coverage survives compaction, resume, and teammate turnover.
12. When `intent`, `traceability`, convergence, or remediation state changes, append a matching compact delta event to `.events.jsonl` so replay can explain why the current artifact state exists.
13. Review Arena outcomes are lead-owned durable state: persist challenge synthesis into `challenge_decisions` before verifier sees the workflow as ready.
14. When a phase becomes independently verified, synthesize a compact `phase_transition_summary` so later phases consume a durable delta instead of inferring prior work from broad context.
15. Persist `research_quality` whenever a workflow uses research as an input to planning or debugging so degraded research can be resumed honestly.
16. Persist `memory_sync` whenever a blocking exit or stop-before-shutdown path is used so stop/resume never guesses whether memory was safely finalized.
17. Persist `latency_telemetry` as compact timing truth when timestamps are available; prefer approximate but explicit timing over silent omission.

## Artifact Snapshot + Event Delta Protocol (MANDATORY)

When lead-owned workflow state changes:

1. Read the current artifact snapshot.
2. Compute the next snapshot deterministically from current task state + validated contracts + saved plan state.
3. Update `updated_at` and any changed artifact fields first.
4. Write the snapshot before appending any lifecycle event.
5. Append exactly the matching delta event to `.events.jsonl`.
6. Every delta event must include at minimum:
   - `ts`
   - `wf`
   - `event`
   - `workflow_kind`
   - `phase_cursor`
   - `pending_gate`
   - `source`
   - `summary`
7. If traceability changed, include a compact `traceability_delta` with only the changed requirement / acceptance / decision / remediation facts.
8. Never append an event for state that was not successfully persisted into the snapshot.
9. On replay disagreement, trust the latest snapshot and use the event log only to explain how it got there.

## Pending Gate Canon (MANDATORY)

`pending_gate` is durable runtime truth, not a vague summary string.

Use explicit gate values when they apply:
- `TEAM_CREATED`
- `TASKS_CREATED`
- `RESEARCH_EXECUTED`
- `PLAN_REVIEW`
- `scope_decision`
- `checkpoint_decision`
- `challenge_resolution`
- `CONTRACTS_VALIDATED`
- `MEMORY_UPDATED`
- `memory_sync`
- `TEAM_SHUTDOWN`

Rules:
- If the workflow is waiting on a user scope choice, use `pending_gate="scope_decision"`.
- If the workflow is waiting on a human checkpoint or approval embedded in a phase contract, use `pending_gate="checkpoint_decision"`.
- If the workflow cannot safely stop until memory/handoff persistence has been completed, use `pending_gate="memory_sync"`.

## Canonical Phase Delta Shapes (MANDATORY)

Use these canonical delta shapes whenever the related state transition occurs. Keep them compact and replay-safe.

### `planner_completed`
- `event`: `planner_completed`
- `phase_delta`:
  - `kind`: `planner_completed`
  - `plan_file`
  - `plan_mode`
  - `verification_rigor`
  - `intent_delta`
  - `traceability_delta.requirements`
  - `traceability_delta.phases`
  - `planning_review_status`

### `builder_completed`
- `event`: `builder_completed`
- `phase_delta`:
  - `kind`: `builder_completed`
  - `phase_id`
  - `phase_status`
  - `proof_status`
  - `what_changed`
  - `requirements_in_scope`
  - `requirements_satisfied`
  - `acceptance_in_scope`
  - `acceptance_satisfied`
  - `decision_dependencies`
  - `decision_dependencies_satisfied`
  - `evidence_commands`

### `verifier_completed`
- `event`: `verifier_completed`
- `phase_delta`:
  - `kind`: `verifier_completed`
  - `phase_id`
  - `traceability_status`
  - `requirements_verified`
  - `acceptance_verified`
  - `decision_dependencies_checked`
  - `traceability_gaps`
  - `reopened_proof_status`
  - `reopened_proof_retirements`
  - `boundary_history_delta`
  - `scenario_totals`
  - `proof_reconciliation`
  - `transition_outcome`
  - `intentionally_open`
  - `next_phase_id`

### `remediation_created`
- `event`: `remediation_created`
- `phase_delta`:
  - `kind`: `remediation_created`
  - `phase_id`
  - `source_agent`
  - `reason`
  - `traceability_delta.remediation`
  - `convergence_state`

### `remediation_completed`
- `event`: `remediation_completed`
- `phase_delta`:
  - `kind`: `remediation_completed`
  - `phase_id`
  - `reopened_scope`
  - `traceability_delta.remediation`
  - `loop_counts`
  - `convergence_state`

### `challenge_decided`
- `event`: `challenge_decided`
- `phase_delta`:
  - `kind`: `challenge_decided`
  - `phase_id`
  - `reviewers_considered`
  - `winning_priority`
  - `resolution_state`
  - `accepted_risks` (`risk`, `scope_boundary`, `accepted_by`, `reason`, `revalidation_trigger`, `evidence_refs`, `status`)
  - `reopened_proof_regressions` (`boundary`, `prior_phase_id`, `reopened_by`, `required_reproof`, `status`)
  - `unresolved_conflicts`
  - `traceability_decision`
  - `verifier_intake_state`
  - `boundary_history_delta`

---

## Session Handoff Payload (MANDATORY)

When a workflow may be resumed later (compaction boundary, interruption risk, user pause, or CRITICAL stall), emit and persist a handoff payload.

Canonical payload shape:

```yaml
workflow_instance: "cc-teams-build-20260210-150000"
workflow_kind: "BUILD"
project_root: "/absolute/path"
team_name: "cc-teams-build-20260210-150000"
workflow_artifact: ".claude/cc-teams/workflows/cc-teams-build-20260210-150000.json"
plan_mode: "execution_plan"
verification_rigor: "critical_path"
phase_cursor: "phase-2"
active_phase_contract:
  phase_id: "phase-2"
  objective: "Implement API validation for auth boundary"
  files_surfaces: ["src/api/auth.ts", "src/api/auth.test.ts"]
  checkpoint_type: "decision"
  autonomy: "HITL"
  exit_criteria: ["Validation rejects malformed token payloads", "Gate command passes"]
  gate_command: "CI=true npm test -- auth.test.ts"
teammate_roster:
  spawned: ["builder", "live-reviewer"]      # currently active in team
  pending_spawn: ["hunter"]                  # needed for next phase, not yet spawned
  completed: ["builder", "live-reviewer"]    # finished their tasks
gate: "CONTRACTS_VALIDATED"
timestamp_utc: "2026-02-10T23:05:00Z"
task_snapshot:
  in_progress: ["#9 CC-TEAMS builder: ..."]
  pending_runnable: ["#11 CC-TEAMS hunter: ..."]
  blocked: ["#12 CC-TEAMS security-reviewer: ... blocked by #11"]
contracts:
  last_validated: ["builder: PASS", "live-reviewer: PASS"]
  unresolved_blocking: []
challenge_decisions:
  current_phase:
    phase_id: "phase-2"
    winning_priority: "security"
    resolution_state: "clear"
    accepted_risks: []   # objects: risk, scope_boundary, accepted_by, reason, revalidation_trigger
    reopened_proof_regressions: []   # objects: boundary, prior_phase_id, reopened_by, required_reproof, status
    unresolved_conflicts: []
    traceability_decision: "No reviewer-raised requirement risk remains open"
    verifier_intake_state: "clear"
regressions:
  reopened_proof:
    - boundary: "Malformed token rejection verified in phase-1"
      prior_phase_id: "phase-1"
      reopened_by: "verifier"
      current_source: "#14 CC-TEAMS REM-FIX: reopened-proof regression"
      required_reproof: "Re-run malformed token rejection scenario and prove closure still holds"
      status: "open"
boundary_history:
  latest:
    active_closed_boundaries: ["Malformed token rejection verified"]
    intentionally_open_boundaries: ["Audit logging deferred to phase-2"]
    accepted_risk_boundaries: []
    retired_boundaries: []
    inheritance_note: "Only active_closed_boundaries and intentionally_open_boundaries should flow into the next phase"
  timeline_tail:
    - ts: "2026-02-10T22:40:00Z"
      phase_id: "phase-1"
      event: "phase_verified"
      boundary: "Malformed token rejection verified"
      outcome: "closed"
      ref: "verifier scenario: invalid token payload => exit 0"
phase_transition_summaries:
  latest_verified:
    phase_id: "phase-1"
    outcome_state: "pending_next_phase"
    what_changed: ["Auth validation path implemented"]
    proof_closed: ["Malformed token rejection verified"]
    intentionally_open: ["Audit logging deferred to phase-2"]
    next_phase_id: "phase-2"
    next_trigger: "Assign builder for phase-2 after hydration"
quality:
  convergence_state: "needs_iteration"
  evidence_complete: false
research_quality:
  overall: "strong"
  sources: ["docs/research/auth-boundary.md"]
  degraded_reasons: []
memory_sync:
  blocking_exit_persisted: true
  next_action: "stop_after_memory_sync"
  last_persisted_at: "2026-02-10T23:05:00Z"
latency_telemetry:
  workflow_wall_clock_seconds: 420
  teammate_seconds:
    builder: 180
    verifier: 90
  verifier_workload:
    tests_seconds: 60
    build_seconds: 20
    audit_seconds: 10
traceability:
  status: "gaps_found"
  requirements_open: ["AC-2 audit logging not yet proven"]
  acceptance_open: ["Invalid token payload rejection"]
  decisions_pending_verification: []
loop_counts:
  re_review: 1
  re_hunt: 1
  re_verify: 0
remediation_history:
  - id: "#14"
    reason: "Fix security issues: missing auth check"
    state: "re-review_pending"
memory_notes_collected:
  builder: "TDD pattern used: RED-GREEN-REFACTOR for auth module"
  hunter: ""  # empty until hunter completes
  security-reviewer: ""
remediation:
  open_rem_fix_ids: []
next_owner: "hunter"
resume_entrypoint: "Run TaskList, verify #11 runnable, then assign hunter"
stale_assumptions: []
```

Rules:
1. Persist latest payload in `.claude/cc-teams/progress.md` under `## Verification`.
2. Never infer missing facts; use `unknown` when evidence is unavailable.
3. `stale_assumptions` is required. Use an explicit empty list (`[]`) when none.
4. Handoff payload is lead-owned and must be based on current TaskList + workflow artifact + validated contracts.
5. `memory_notes_collected` must be populated:
   - After each teammate completes, extract `MEMORY_NOTES` from their Router Contract
   - Append to handoff payload before context compaction risk
   - Memory Update task uses collected notes, not raw teammate context
6. If `phase_cursor` is set, `resume_entrypoint` must mention the active phase or next gated teammate explicitly.
7. If workflow kind is DEBUG, include `debug_reset_marker` and `attempt_baseline` so local attempt counting resumes cleanly.
8. If remediation is active, include `quality.convergence_state`, `loop_counts`, and `remediation_history` so resume never guesses whether convergence already happened.
9. If the workflow is plan-backed, include a compact `traceability` summary covering open requirements, open acceptance criteria, and any approved decisions still lacking proof.
10. If a challenge round has completed, include the latest `challenge_decisions` summary so resume and verifier intake do not guess whether a conflict was accepted, blocked, or unresolved.
11. If `challenge_decisions.current_phase.verifier_intake_state == "accepted_risk"`, every accepted-risk entry must be structured with:
   - `risk`
   - `scope_boundary`
   - `accepted_by`
   - `reason`
   - `revalidation_trigger`
   - `evidence_refs`
   - `status` (`accepted_open`)
   Use an explicit empty list only when no accepted risk exists.
12. `challenge_decisions.current_phase.resolution_state` must distinguish:
   - `clear`
   - `accepted_risk`
   - `open_disagreement`
   - `reopened_prior_proof`
   so resume, verifier intake, and memory-final persistence do not flatten distinct challenge outcomes into one generic "open" state.
13. If `regressions.reopened_proof` is non-empty, every entry must be structured with:
   - `boundary`
   - `prior_phase_id`
   - `reopened_by`
   - `current_source`
   - `required_reproof`
   - `status`
14. If reopened-proof regressions are being retired, the retiring verifier contract must record:
   - `REOPENED_PROOF_STATUS` (`reproof_closed` or `superseded_by_decision`)
   - `REOPENED_PROOF_RETIREMENTS` with `boundary`, `closure_mode`, `closure_ref`, and `prior_phase_id`
15. Maintain `boundary_history.latest` as the inheritance-safe summary:
   - `active_closed_boundaries`
   - `intentionally_open_boundaries`
   - `accepted_risk_boundaries`
   - `retired_boundaries`
   - `inheritance_note`
16. Maintain `boundary_history.timeline_tail` as a compact closure history of the most recent boundary transitions (`closed`, `accepted_risk`, `reopened`, `reproof_closed`, `superseded`).
17. If any earlier phase has already been independently verified, include `phase_transition_summaries.latest_verified` so the next phase preserves closed proof and intentionally open boundaries without guessing.
18. Include `boundary_history.latest` and `boundary_history.timeline_tail` in handoff payloads and resume reconstruction so later phases do not re-inherit retired proof boundaries by accident.
19. If research informed the workflow, include `research_quality` with:
   - `overall`
   - `sources`
   - `degraded_reasons`
20. If the workflow stopped or paused on a blocking exit, include `memory_sync` with:
   - `blocking_exit_persisted`
   - `next_action`
   - `last_persisted_at`
21. If timing truth is available, include compact `latency_telemetry` instead of leaving timing implicit.

Emit payload at minimum when:
1. escalation reaches `CRITICAL` (`stalled`);
2. user asks to pause/continue later;
3. `CC-TEAMS COMPACT_CHECKPOINT` marker appears in `.claude/cc-teams/progress.md`
   (written automatically by the PreCompact hook before every context compaction);
4. session is about to end while workflow tasks remain incomplete.

## Session Interruption Recovery (Agent Teams)

**Problem:** `/resume` does NOT restore teammates. If session interrupted mid-workflow, teammates are gone.

## Resume Checklist (MANDATORY)

On resume or startup with active CC-TEAMS tasks, execute in order:

1. Load memory files, read latest handoff payload from `.claude/cc-teams/progress.md` (if present), and read the workflow artifact if it exists.
2. Run `TaskList()` and apply Orphan Task Recovery sweep before any assignment.
3. Rebuild truth from task state first, then workflow artifact, not memory narrative:
   - identify in-progress, runnable, blocked tasks;
   - identify latest validated contracts, plan_mode, verification_rigor, phase_cursor, active_phase_contract, traceability state, `challenge_decisions`, `regressions`, `boundary_history`, and open remediation tasks.
   - if BUILD is plan-backed and `active_phase_contract` is missing or stale, re-read the saved plan and reconstruct it before assigning a builder or verifier.
   - if DEBUG is active, reconstruct the current debug reset marker and attempt baseline before spawning investigators.
4. Validate team continuity:
   - read `~/.claude/teams/{team-name}/config.json`;
   - if missing/empty/non-matching expected roster, recreate team with same name.
5. Respawn only teammates needed for runnable or near-runnable tasks (phase-scoped activation still applies).
6. Revalidate blockers:
   - verifier must remain blocked by challenge/remediation requirements;
   - memory update must remain blocked by verifier.
7. Publish a `RESUME_CONFIRMED` note to user:
   - recovered workflow instance;
   - current gate;
   - next deterministic step;
   - compact explanation of boundary continuity from `boundary_history.timeline_tail` when relevant.
8. Continue from `resume_entrypoint` only after steps 1-7 succeed.

Blocking-exit rule:
- If `memory_sync.blocking_exit_persisted != true` during a blocking stop/resume path, do not treat the workflow as safely paused.
- Persist handoff + workflow-final memory sync first, then set `pending_gate="memory_sync"` until that persistence is complete.

## Convergence And Phase Advancement (MANDATORY)

The workflow artifact is the durable source of truth for whether the current phase may advance.

Convergence states:
- `pending` - phase work started but independent validation has not yet closed the loop
- `needs_iteration` - blocking review, hunt, or verifier findings require remediation
- `phase_verified` - the active phase passed verifier with no unresolved blockers
- `converged` - no remaining incomplete phases or verifier-blocking loops remain

Rules:
1. Any blocking reviewer, hunter, or verifier result sets `quality.convergence_state="needs_iteration"`.
2. Creating a `CC-TEAMS REM-FIX:` appends an entry to `remediation_history`.
3. Re-review / re-hunt / re-verify runs increment `loop_counts.re_review`, `loop_counts.re_hunt`, and `loop_counts.re_verify`.
4. Persist current teammate contracts into artifact `results` and `evidence` as they complete.
5. `phase_cursor` does NOT advance when:
   - any remediation task is still open
   - re-review challenge is incomplete
   - re-hunt is incomplete
   - verifier has not returned `PASS`
6. `phase_cursor` may advance only when:
   - active-phase verifier contract is `PASS`
   - `PROOF_STATUS=passed`
   - no unresolved blocking findings remain
   - `quality.convergence_state` can be set to `phase_verified`
7. When the active phase reaches `phase_verified`, synthesize/update `phase_transition_summaries.latest_verified` with:
   - `phase_id`
   - `outcome_state`
   - `what_changed`
   - `proof_closed`
   - `intentionally_open`
   - `next_phase_id`
   - `next_trigger`
   Also synthesize/update `boundary_history.latest` with:
   - `active_closed_boundaries`: only proof boundaries still valid after any retirement or supersession
   - `intentionally_open_boundaries`: boundaries intentionally deferred to later phases
   - `accepted_risk_boundaries`: still-active accepted-risk exceptions
   - `retired_boundaries`: boundaries retired by `reproof_closed` or `superseded_by_decision`
   - `inheritance_note`: concise explanation of what later phases should inherit vs ignore
   Also append/update `boundary_history.timeline_tail` with the newest proof-boundary transition and keep only the most recent compact entries needed for resume/audit.
8. If a next incomplete normalized phase exists, advance `phase_cursor` to it and set `quality.convergence_state="pending"`.
9. If no incomplete phase remains, set `quality.convergence_state="converged"` and continue toward Memory Update / shutdown.

Recovery rules:
1. Preserve existing task state (do not reset workflow by default).
2. Do not mark tasks completed based only on teammate claims from a prior session.
3. If handoff payload conflicts with current TaskList, TaskList wins and conflict is logged in Memory Notes.

**Prevention:** The PreCompact hook (`plugins/cc-teams/hooks/pre-compact.sh`) writes a
`CC-TEAMS COMPACT_CHECKPOINT: {timestamp}` marker to progress.md before every compaction.
At session start, check for this marker in progress.md — if present, emit handoff payload immediately
before doing any other work. This replaces the unmeasurable "30+ tool calls" heuristic.

## Build Preparation And Phase Hydration (MANDATORY)

Before spawning a builder for a BUILD workflow:

1. Read `- Plan:` from `activeContext.md ## References`.
2. If plan path is not `N/A`, read the saved plan before task creation.
3. Run a plan trust gate:
   - `Open Decisions` must be empty or explicitly marked approved.
   - `Differences From Agreement` must be present, even if `None`.
   - `PLAN_MODE` and `VERIFICATION_RIGOR` must be explicit.
   - For `execution_plan` or `decision_rfc`, every executable phase must have non-empty objective, inputs, files/surfaces, required checks, checkpoint type, autonomy label, and exit criteria.
   - `intent.acceptance_criteria` must be present, non-contradictory, and stated in a way a builder and verifier can test.
   - if any acceptance criterion is empty, self-contradictory, or unverifiable from repo/user-accessible evidence, halt before BUILD and request clarification or planner revision.
   - every acceptance criterion must map to at least one executable phase, required check, or verifier proof path.
   - no acceptance criterion may conflict with `intent.non_goals`, unresolved `intent.open_decisions`, or an already approved decision.
   - if contradiction is detected, record it as a planning/trust failure and do not start BUILD until the saved plan is revised or clarified.
4. Hydrate `intent` and `traceability` from the saved plan before execution:
   - `intent.goal`
   - `intent.non_goals`
   - `intent.constraints`
   - `intent.acceptance_criteria`
   - `intent.open_decisions`
   - `approved_decisions`
   - `traceability.requirements`
   - `traceability.phases`
   - `traceability.decisions`
   - initialize `traceability.verification` and `traceability.remediation` if missing
5. Normalize plan phases into workflow artifact `normalized_phases`.
6. Initialize `phase_cursor` to the first incomplete phase.
7. If an earlier phase has already been independently verified, recover `phase_transition_summaries.latest_verified` before spawning the next builder or verifier.
8. Recover `boundary_history.latest` before spawning the next builder or verifier; if missing, derive it from the latest verified phase plus accepted-risk and reopened-proof retirement state.
9. Persist an `active_phase_contract` snapshot for that `phase_cursor` including:
   - `phase_id`
   - `objective`
   - `requirement_ids`
   - `acceptance_ids`
   - `decision_dependencies`
   - `inputs`
   - `files_surfaces`
   - `expected_artifacts`
   - `required_checks`
   - `checkpoint_type`
   - `autonomy`
   - `checkpoint_justification`
   - `exit_criteria`
   - `gate_command`
10. Builder may execute only the phase at `phase_cursor`.
11. Hunter, reviewers, and verifier validate the same active phase before `phase_cursor` advances.
12. Verifier must close traceability for the active phase by mapping evidence back to `intent.acceptance_criteria`, `traceability.requirements`, and any relevant `approved_decisions`.
13. Append an event-log entry after hydration summarizing the accepted `intent`, current `phase_cursor`, latest prior phase transition summary (if any), latest `boundary_history`, and any still-open traceability gaps.

If any trusted phase field is missing from a non-trivial plan, halt and ask for clarification or re-plan before BUILD starts.

## Debug Attempt Baseline (MANDATORY)

When starting a DEBUG workflow:

1. Once workflow identity exists, persist a reset marker:
   - `[DEBUG-RESET: wf:{team_name}]`
2. Record the marker in the workflow artifact as `debug_reset_marker`.
3. Set `attempt_baseline` to the number of `[DEBUG-N]:` entries after the latest reset marker.
4. On resume, investigators count attempts only after that reset marker for the current workflow.

---

## Execution Depth Selector (MANDATORY)

Purpose: choose **quick** vs **full** depth without changing architecture or introducing new roles.

Default policy:
1. `FULL` is default (safety-first).
2. `QUICK` is allowed only for clearly bounded low-risk BUILD work.
3. REVIEW and DEBUG remain `FULL` by default in this phase.

### Quick path eligibility (BUILD only)
Choose `QUICK` only if ALL are true:
1. Scope is a single bounded implementation unit (one clear deliverable).
2. No security/auth/payment/PII/secrets/migration/schema/public-API risk signals.
3. No cross-layer coupling requirement (not frontend+backend+db together).
4. No open remediation in current workflow (`CC-TEAMS REM-FIX` absent).
5. Requirements are explicit enough to execute without additional research.

If any condition is false -> choose `FULL`.

### Depth semantics
1. `FULL` (existing BUILD chain):
   - builder + live-reviewer -> hunter -> triad reviewers -> challenge -> verifier -> memory update
2. `QUICK` (reduced BUILD chain, still contract-gated):
   - builder + live-reviewer -> verifier -> memory update

### Quick-path safety rules
1. quick path still requires Router Contracts, verifier evidence, and memory update.
2. If any blocking/remediation signal appears in quick path:
   - immediately escalate to FULL
   - create missing FULL tasks (hunter, triad, challenge) and re-block verifier accordingly
   - continue only after FULL gate chain resolves
3. Never ship directly from quick path after unresolved blocking findings.

---

## Task-Based Orchestration

**Create workflow task hierarchy only AFTER TeamCreate for that workflow.**
**Stamp every task description with Workflow Identity metadata (see section above).**

**Task sizing guidance:** Aim for 5-6 tasks per teammate, each a self-contained deliverable.

### Tasks System Capabilities

**Persistence:** Tasks are stored in the filesystem at `~/.claude/tasks/{team-name}/`. They survive context compaction and session restarts.

**DAG Dependencies:** Use `addBlockedBy` and `addBlocks` to create dependency graphs. Blocked tasks cannot start until their dependencies complete. This enforces phase ordering (e.g., review must finish before challenge round starts).

**Cross-Session Resume:** Task lists are persisted locally by Claude Code. If resuming a workflow across sessions:
1. Run `TaskList()` first and treat it as the source of truth
2. Scope tasks by CC-TEAMS prefix before resuming (avoid cross-project collisions)
3. Resume from task state rather than re-creating the hierarchy

**Task Cleanup:** When tasks are abandoned or obsolete, use `TaskUpdate({ taskId, status: "deleted" })` to clean them up. Run cleanup:
- After workflow completion (delete parent wrapper tasks if desired)
- When aborting a workflow (delete all pending tasks for that workflow)
- At session start if stale tasks are found (tasks from interrupted workflows)

### TeamCreate Task-List Context Rule (MANDATORY)

Agent Teams task lists are team-scoped (`~/.claude/tasks/{team-name}/`).
Creating a team can move execution to a team-scoped task context.

Operational rules:
1. Create the team first (`TeamCreate(...)`), then create CC-TEAMS workflow tasks.
2. Immediately after team creation, run `TaskList()` and verify current task context is the team workflow context.
3. If pre-team tasks were created and are not visible after team creation, DO NOT continue with partial state:
   - recreate the full CC-TEAMS workflow hierarchy in the team-scoped list
   - continue only with the recreated team-scoped tasks
4. Never assign teammate work from an unscoped/non-team task list.

This avoids lost/phantom tasks during team initialization.

### Workflow Task Templates

**Task naming convention:** `CC-TEAMS {role}: {action}` for teammate tasks, `CC-TEAMS {WORKFLOW}: {summary}` for parent tasks.

**Common patterns:**
- Every workflow ends with `CC-TEAMS Memory Update` task (blocked by final phase)
- Use `TaskUpdate({ taskId, addBlockedBy: [...] })` to enforce phase ordering
- Include plan file path in description if following a plan
- Include `activeForm` for UI spinner display (present-continuous, e.g., `activeForm: "Implementing {feature}"`)

#### BUILD Tasks (FULL depth - default)

| Order | Subject | BlockedBy | Key Description Points |
|-------|---------|-----------|------------------------|
| 1 | `CC-TEAMS BUILD: {feature}` | - | Parent task. Team: Builder → Hunter → Review Arena → Verifier |
| 2 | `CC-TEAMS builder: Implement {feature}` | - | TDD (RED→GREEN→REFACTOR). OWN all writes. Execute only the active phase at `phase_cursor` when plan-backed. Message live-reviewer after each module. |
| 3 | `CC-TEAMS live-reviewer: Real-time review` | - | READ-ONLY. Reply LGTM or STOP. |
| 4 | `CC-TEAMS hunter: Silent failure audit` | builder | Scan for empty catches, swallowed exceptions. |
| 5 | `CC-TEAMS security-reviewer: Security review` | hunter | Auth, injection, secrets, OWASP, XSS/CSRF. |
| 6 | `CC-TEAMS performance-reviewer: Performance review` | hunter | N+1, loops, memory, caching, efficiency. |
| 7 | `CC-TEAMS quality-reviewer: Quality review` | hunter | Patterns, complexity, error handling, tests. |
| 8a | `CC-TEAMS accessibility-reviewer: Accessibility review` | hunter | **CONDITIONAL** (UI files detected). WCAG 2.1 AA audit. |
| 8b | `CC-TEAMS api-contract-reviewer: API contract review` | hunter | **CONDITIONAL** (API files detected). Breaking change detection. |
| 9 | `CC-TEAMS BUILD Review Arena: Challenge round` | sec, perf, qual [+a11y if present] [+api-contract if present] | Share findings, resolve conflicts. Security and a11y/api-contract win on CRITICAL. |
| 10 | `CC-TEAMS verifier: E2E verification` | challenge | Run tests, verify E2E and active phase exit criteria. Exit code evidence required. |
| 11 | `CC-TEAMS Memory Update: Persist build learnings` | verifier | Collect Memory Notes, persist via Read-Edit-Read. ESCAPE: If verifier stalls at CRITICAL, Memory Update runs with partial evidence. |

**QUICK depth:** Skip hunter + reviewers + challenge. Builder → Verifier → Memory Update.

#### DEBUG Tasks (Bug Court)

| Order | Subject | BlockedBy | Key Description Points |
|-------|---------|-----------|------------------------|
| 1 | `CC-TEAMS DEBUG: {error}` | - | Parent task. Team: Investigators → Debate → Fix → Review Arena → Verifier |
| 2-N | `CC-TEAMS investigator-{i}: Test hypothesis - {h_i}` | - | Champion hypothesis, gather evidence FOR it. READ-ONLY. |
| N+1 | `CC-TEAMS Bug Court: Debate round` | all investigators | Share evidence, determine winning hypothesis. |
| N+2 | `CC-TEAMS builder: Implement fix` | debate | TDD: regression test FIRST, then minimal fix. Execute only the approved fix scope or active phase if plan-backed. |
| N+3 | `CC-TEAMS security-reviewer: Security review of fix` | builder | Check for security regressions. |
| N+4 | `CC-TEAMS performance-reviewer: Performance review of fix` | builder | Check for performance regressions. |
| N+5 | `CC-TEAMS quality-reviewer: Quality review of fix` | builder | Check correctness, patterns. |
| N+5a | `CC-TEAMS accessibility-reviewer: A11y review of fix` | builder | CONDITIONAL (UI files). WCAG audit of fix. |
| N+5b | `CC-TEAMS api-contract-reviewer: API contract review of fix` | builder | CONDITIONAL (API files). Breaking change check. |
| N+6 | `CC-TEAMS DEBUG Review Arena: Challenge round` | sec, perf, qual [+a11y if present] [+api-contract if present] | Resolve conflicts before verification. |
| N+7 | `CC-TEAMS verifier: Verify fix E2E` | challenge | Verify original symptom resolved. |
| N+8 | `CC-TEAMS Memory Update: Persist debug learnings` | verifier | Root cause → patterns.md, evidence → progress.md. |

#### REVIEW Tasks (Review Arena)

| Order | Subject | BlockedBy | Key Description Points |
|-------|---------|-----------|------------------------|
| 1 | `CC-TEAMS REVIEW: {target}` | - | Parent task. Team: 3–5 reviewers → challenge round |
| 2 | `CC-TEAMS security-reviewer: Security review` | - | Auth, injection, secrets, OWASP. |
| 3 | `CC-TEAMS performance-reviewer: Performance review` | - | N+1, memory, bundle, caching. |
| 4 | `CC-TEAMS quality-reviewer: Quality review` | - | Patterns, complexity, error handling. |
| 5a | `CC-TEAMS accessibility-reviewer: Accessibility review` | - | CONDITIONAL (UI files detected). WCAG 2.1 AA. |
| 5b | `CC-TEAMS api-contract-reviewer: API contract review` | - | CONDITIONAL (API files detected). Breaking changes. |
| 6 | `CC-TEAMS Review Arena: Challenge round` | sec, perf, qual [+a11y if present] [+api-contract if present] | Share findings, resolve conflicts. |
| 7 | `CC-TEAMS Memory Update: Persist review learnings` | challenge | Patterns → patterns.md, verdict → progress.md. |

#### BUILD-CROSSLAYER Tasks (Cross-Layer BUILD — use when frontend + backend changes needed)

See `cc-teams:cross-layer-build` skill for full protocol. Task structure:

| Order | Subject | BlockedBy | Key Description Points |
|-------|---------|-----------|------------------------|
| 1 | `CC-TEAMS BUILD-CROSSLAYER: {feature}` | - | Parent task. Backend-builder first (contract) → Frontend-builder → Async live-review → Hunt → Review → Verify |
| 2 | `CC-TEAMS backend-builder: Implement backend` | - | TDD. Publishes API_CONTRACT_SPEC in Memory Notes before completing. |
| 3 | `CC-TEAMS frontend-builder: Implement frontend` | backend-builder | Implements against API_CONTRACT_SPEC relayed by lead. |
| 4 | `CC-TEAMS live-reviewer: Async post-build review` | backend-builder + frontend-builder | Reviews ALL changes from BOTH builders at once. |
| 5 | `CC-TEAMS hunter: Cross-layer silent failure audit` | live-reviewer | Scans all modified files (frontend + backend). |
| 6 | `CC-TEAMS security-reviewer: Security review` | hunter | Auth, injection, secrets, OWASP. |
| 7 | `CC-TEAMS performance-reviewer: Performance review` | hunter | N+1, loops, memory, caching. |
| 8 | `CC-TEAMS quality-reviewer: Quality review` | hunter | Patterns, complexity, error handling. |
| 9a | `CC-TEAMS accessibility-reviewer: A11y review` | hunter | ALWAYS in cross-layer (frontend guaranteed). WCAG 2.1 AA. |
| 9b | `CC-TEAMS api-contract-reviewer: API contract validation` | hunter | ALWAYS in cross-layer (API guaranteed). Breaking changes. |
| 10 | `CC-TEAMS BUILD-CROSSLAYER Review Arena: Challenge round` | sec, perf, qual, a11y, api-contract | Share findings, resolve conflicts. |
| 11 | `CC-TEAMS verifier: Integrated E2E verification` | challenge | Tests full stack integration. |
| 12 | `CC-TEAMS Memory Update: Persist cross-layer learnings` | verifier | API contract + integration learnings. |

**File Conflict Gate (MANDATORY before Phase 4):** Lead validates FILES_MODIFIED across both builders — no overlap allowed.

#### PLAN Tasks

| Order | Subject | BlockedBy | Key Description Points |
|-------|---------|-----------|------------------------|
| 1 | `CC-TEAMS PLAN: {feature}` | - | Parent task. Planner writes the plan; fresh plan-gap-reviewer challenges it before memory indexing. |
| 2 | `CC-TEAMS planner: Create plan` | - | Spawn WITHOUT `mode: "plan"`. Planner writes plan file directly, sets `PLAN_MODE` + `VERIFICATION_RIGOR`, and returns open decisions explicitly. Lead may send revision requests back to this same teammate. |
| 3 | `CC-TEAMS plan-gap-reviewer: Fresh plan challenge` | planner | Clean-room read-only review. Uses original request + saved plan + current codebase + approved design/research only. No memory, workflow artifact, or planner-summary anchoring. |
| 4 | `CC-TEAMS Memory Update: Index plan` | planner + plan-gap-reviewer | Add final plan file to activeContext.md ## References and mirror planner + planning review summary into workflow artifact / progress state. |

---

## Workflow Execution

### BUILD
1. Load memory → Check if already done in progress.md
2. **Plan-First Gate** (STATE-BASED, not phrase-based):
   - Skip ONLY if: (plan in `## References` ≠ "N/A") AND (active `CC-TEAMS` task exists)
   - Otherwise → AskUserQuestion: "Plan first (Recommended) / Build directly"
3. **Clarify requirements** (DO NOT SKIP) → Use AskUserQuestion
3a. **Cross-Layer Detection (after requirements clarified):**
   - Check if requirements mention BOTH frontend (UI/components/pages) AND backend (API/services/DB)
   - If cross-layer signals → use BUILD-CROSSLAYER path (see `cc-teams:cross-layer-build` skill)
   - Otherwise → continue with standard BUILD (single builder)
3b. **If a saved plan exists, hydrate executable phase state before task execution:**
   - run Build Preparation And Phase Hydration
   - persist `intent`, `approved_decisions`, `traceability`, `normalized_phases`, `phase_cursor`, `active_phase_contract`, `plan_mode`, and `verification_rigor` into the workflow artifact
   - if plan trust fails, do not start builder work
4. **Select execution depth (MANDATORY)**:
   - Run Execution Depth Selector
   - Cross-layer work auto-selects FULL (cross-layer disqualifies QUICK by condition 3)
   - choose `QUICK` only when all quick eligibility conditions pass
   - otherwise choose `FULL` (default)
5. **Create Agent Team (MANDATORY gate)**:
   - `TeamCreate(...)` with deterministic team name
   - QUICK: spawn `builder` + `live-reviewer` only; defer `verifier` until runnable
   - FULL: spawn `builder` + `live-reviewer` only; defer `hunter` / triad / `verifier` until runnable
   - CROSSLAYER: spawn `backend-builder` only; frontend-builder spawns after contract relay
   - verify teammate reachability via direct message
   - enter delegate mode (`Shift+Tab`)
   - run `TaskList()` to confirm team-scoped task context
   - if any of these fail: STOP (do not run task-only fallback)
6. **Create task hierarchy in the team-scoped task list** (QUICK or FULL template)
7. **Start execution** (see Team Execution Loop below)
8. **Quick-path escalation rule**:
   - if QUICK path emits blocking/remediation -> escalate to FULL immediately, create missing FULL tasks, and continue
9. Update memory, then execute TEAM_SHUTDOWN gate before final completion

### DEBUG
1. Load memory → Check patterns.md Common Gotchas
2. **CLARIFY (REQUIRED)**: Use AskUserQuestion if ANY ambiguity:
   - What error message/behavior?
   - Expected vs actual?
   - When did it start?
   - Which component/file affected?
3. **Check for research trigger:**
   - User explicitly requested research ("research", "github", "octocode"), OR
   - External service error (API timeout, auth failure, third-party), OR
   - **3+ local debugging attempts failed**

   **Debug Attempt Counting:**
   - Format in activeContext.md Recent Changes: `[DEBUG-N]: {what was tried} → {result}`
   - Example: `[DEBUG-1]: Added null check → still failing (TypeError persists)`
   - Count lines matching `[DEBUG-N]:` pattern
   - If count ≥ 3 AND all show failure → trigger external research

   **What counts as an attempt:**
   - A hypothesis tested with code change or command
   - NOT: reading files, thinking, planning
   - Each attempt must have a concrete action + observed result

   **If ANY trigger met:**
   - Execute research FIRST using octocode tools directly
   - Search for error patterns, PRs with similar issues
   - **PERSIST research** → Save to `docs/research/YYYY-MM-DD-<error-topic>-research.md`
   - **Update memory** → Add to activeContext.md References section

4. **Generate hypotheses** (3-5 based on error/symptoms + memory)
4a. **Persist current debug attempt baseline:**
   - write `[DEBUG-RESET: wf:{team_name}]` once workflow identity exists
   - record `debug_reset_marker` and `attempt_baseline` in the workflow artifact
5. **Create Agent Team (MANDATORY gate)**:
   - `TeamCreate(...)` with deterministic team name
   - spawn required investigators only
   - defer `builder` / review triad / `verifier` until their tasks are runnable
   - verify teammate reachability via direct message
   - enter delegate mode (`Shift+Tab`)
   - run `TaskList()` to confirm team-scoped task context
   - if team gate fails: STOP
6. **Create task hierarchy in the team-scoped task list** (see Task-Based Orchestration above)
7. **Start execution** (pass research file path if step 3 was executed)
8. Update memory → Add root cause to Common Gotchas, then execute TEAM_SHUTDOWN gate

### REVIEW
1. Load memory
2. **CLARIFY (REQUIRED)**: Use AskUserQuestion to confirm scope:
   - Review entire codebase OR specific files?
   - Focus area: security/performance/quality/all?
   - Blocking issues only OR all findings?
3. **Create Agent Team (MANDATORY gate)**:
   - `TeamCreate(...)` with deterministic team name
   - spawn security-reviewer, performance-reviewer, quality-reviewer
   - verify teammate reachability via direct message
   - enter delegate mode (`Shift+Tab`)
   - run `TaskList()` to confirm team-scoped task context
   - if team gate fails: STOP
4. **Create task hierarchy in the team-scoped task list** (see Task-Based Orchestration above)
5. **Start execution** (see Team Execution Loop below)
6. Update memory, then execute TEAM_SHUTDOWN gate before final completion

### PLAN
1. Load memory
2. **If external research detected (external tech OR explicit request):**
   - Execute research FIRST using octocode tools directly (NOT as hint)
   - Use: `mcp__octocode__packageSearch`, `mcp__octocode__githubSearchCode`, etc.
   - **PERSIST research** → Save to `docs/research/YYYY-MM-DD-<topic>-research.md`
   - **Update memory** → Add to activeContext.md References section
   - Summarize findings before invoking planner

**THREE-PHASE for External Research (MANDATORY):**
```
If research trigger detected:
  → PHASE 1: Execute research using octocode tools
  → PHASE 2: PERSIST research (prevents context loss):
      Bash(command="mkdir -p docs/research")
      Write(file_path="docs/research/YYYY-MM-DD-<topic>-research.md", content="[research summary]")
      Edit(file_path=".claude/cc-teams/activeContext.md", ...)  # Add to References section
  → PHASE 3: Invoke planner with: "Research findings: {results}\nResearch saved to: docs/research/..."
```
Research is a PREREQUISITE, not a hint. Planner cannot skip it.
**Research without persistence is LOST after context compaction.**

3. **Create Agent Team (MANDATORY gate):**
   - `TeamCreate(...)` with deterministic team name
   - spawn planner teammate **WITHOUT `mode: "plan"`** — use default mode or `dontAsk`
   - do NOT spawn `plan-gap-reviewer` yet; it is phase-scoped and only becomes runnable after the first saved plan exists
   - **Add this line at the TOP of the planner's spawn prompt:**
     ```
     IMPORTANT: DO NOT ENTER PLAN MODE. You are a documentation writer creating plan files.
     You MUST be able to write files. If you detect plan mode is active, message me immediately.
     ```
   - verify teammate reachability via direct message
   - enter delegate mode (`Shift+Tab`)
   - run `TaskList()` to confirm team-scoped task context
   - if team gate fails: STOP
4. **Create task hierarchy in the team-scoped task list** (see Task-Based Orchestration above)
5. **Invoke planner** (pass research results + file path if step 2 was executed)
6. **If planner sends `BLOCKED: plan mode detected`:**
   - This is Claude Code auto-enabling plan mode for the planner agent
   - Shut down the current planner teammate
   - Re-spawn planner with `mode: "dontAsk"` to prevent auto-plan-mode
   - Start the spawn prompt with the anti-plan-mode header (see step 3 above)
   - This is a known Claude Code behavior — do not treat as workflow failure
7. **Review the saved plan file** after planner completes:
   - confirm `PLAN_MODE` and `VERIFICATION_RIGOR` are explicit
   - confirm Agreement Snapshot, `What I Verified vs What Still Needs Confirmation`, `Differences From Agreement`, Codebase Reality Check, Plan-vs-Code Gaps, Assumption Ledger, and phase contract sections are present for non-trivial work
   - confirm every phase includes explicit autonomy labeling (`AFK` vs `HITL`) and that HITL phases justify the checkpoint
   - if baseline gaps remain → request planner revision via message before fresh review
8. **Spawn `plan-gap-reviewer` only after the initial plan is saved and baseline review passes:**
   - use a CLEAN-ROOM prompt, not the generic teammate template
   - pass only:
     - original user request
     - saved plan path
     - requirements snapshot
     - approved design file path (if any)
     - approved research file paths / summary (if any)
     - optional touched-surfaces hint from the plan
   - explicitly exclude:
     - `Memory Summary`
     - `Project Patterns`
     - `.claude/cc-teams/*`
     - workflow artifact path/content
     - planner confidence as authority
9. **If `plan-gap-reviewer` returns `STATUS: PASS`:**
   - proceed to workflow artifact persistence
10. **If `plan-gap-reviewer` returns `STATUS: FINDINGS`:**
   - send findings back to the same planner teammate
   - planner revises the SAME saved plan file and records accepted / rejected findings under `Fresh Review Resolution`
   - re-run `plan-gap-reviewer` once with the same clean-room rules
   - if blocking findings persist after the allowed revision pass → AskUserQuestion before indexing the plan
11. Persist planner contract summary into workflow artifact:
   - `plan_file`
   - `plan_mode`
   - `verification_rigor`
   - `intent.goal`
   - `intent.non_goals`
   - `intent.constraints`
   - `intent.acceptance_criteria`
   - `open_decisions`
   - `approved_decisions`
   - `traceability.requirements`
   - `traceability.phases`
   - `traceability.decisions`
   - `risks_identified`
   - `planning_review_status`
   - `planning_review_blockers`
12. Append a `planner_completed` event to `.events.jsonl` with:
   - required event base fields (`ts`, `wf`, `event`, `workflow_kind`, `phase_cursor`, `pending_gate`, `source`, `summary`)
   - canonical `phase_delta.kind=planner_completed`
   - `plan_file`
   - `plan_mode`
   - `verification_rigor`
   - compact `intent`
   - compact `traceability.requirements` / `traceability.phases`
   - planning review status
13. Update memory -> Reference saved plan, record fresh review verdict, then execute TEAM_SHUTDOWN gate

**PLANNER MODE RULE (CRITICAL):**
```
NEVER spawn planner with mode: "plan"
- Plan mode = read-only = planner CANNOT write plan files = DEADLOCK
- Planner writes documentation (plan files), not code
- Agent Teams plan mode is for reviewing CODE changes before they happen
- Plan files are documentation artifacts, not code changes

Claude Code auto-plan-mode mitigation:
- Always add "DO NOT ENTER PLAN MODE" at the TOP of the planner spawn prompt
- Use mode: "dontAsk" if auto-plan-mode keeps triggering
- If planner sends BLOCKED message → re-spawn with dontAsk mode (see step 7 above)
```

---

## Agent Invocation Template

**Pass task ID, plan file, and context to each teammate:**
```
When spawning a teammate, include this structured context:

## Task Context
- **Task ID:** {taskId}
- **Plan File:** {planFile or 'None'}

## User Request
{request}

## Requirements
{from AskUserQuestion or 'See plan file'}

## Memory Summary
{brief summary from activeContext.md}

## Project Patterns
{key patterns from patterns.md}

## Workflow State
- **Workflow Instance:** {team_name}
- **Workflow Artifact:** `.claude/cc-teams/workflows/{team_name}.json`
- **Plan Mode:** {plan_mode or 'unknown'}
- **Verification Rigor:** {verification_rigor or 'unknown'}
- **Phase Cursor:** {phase_cursor or 'N/A'}
- **Previous Phase Summary:** {phase_transition_summaries.latest_verified or 'N/A'}
- **Effective Prior Boundaries:** {boundary_history.latest or 'N/A'}
- **Pending Gate:** {pending_gate or 'N/A'}
- **Intent Goal:** {intent.goal or 'N/A'}
- **Acceptance Criteria:** {intent.acceptance_criteria or 'N/A'}
- **Approved Decisions:** {approved_decisions or '[]'}
- **Traceability Status:** {traceability.status or 'unknown'}

## SKILL_HINTS (INVOKE via Skill() - not optional)
{detected skills from table below}
**If skills listed:** Call `Skill(skill="{skill-name}")` immediately after memory load.
**If required workflow/stage skills are missing or the section is empty when your role expects them:** reply `BLOCKED: missing SKILL_HINTS` and do not pretend skill-backed execution happened.

---
IMPORTANT:
- `MEMORY_OWNER: lead` (default). Teammates do NOT edit `.claude/cc-teams/*` unless prompt explicitly overrides with `MEMORY_OWNER: teammate`.
- Every teammate MUST include a clearly labeled `### Memory Notes (For Workflow-Final Persistence)` section with:
  - **Learnings:** [insights for activeContext.md]
  - **Patterns:** [gotchas for patterns.md]
  - **Verification:** [results for progress.md]
- Every teammate Router Contract MUST include `STATE_DELTA` with:
  - `what_changed`
  - `remains_open`
  - `should_stay_closed`
  - `next_trigger`
- Every teammate status reply MUST include one of:
  - `WORKING` (actively progressing)
  - `BLOCKED: {reason}` (cannot proceed)
  - `DONE` (work finished, Router Contract included)
- Lead persists these notes in the task-enforced `CC-TEAMS Memory Update` step.

Execute the task and include 'Task {TASK_ID}: COMPLETED' in your output when done.
```

**TASK ID is REQUIRED in prompt.**

**Exception:** `plan-gap-reviewer` does NOT use the generic template above. It must use the clean-room override below and must not receive memory summaries, workflow artifact state, or planner-authored anchoring context.

## Per-Agent Spawn Context Requirements (MANDATORY)

The generic template above applies to all agents. The fields below are **required additions per agent type**.
The lead MUST include every field listed. Use `N/A` only when genuinely unavailable — never silently omit.

### builder
```
TECH_STACK: {language} / {framework} / {test-runner}
TEST_CMD:   {exact command, e.g. "CI=true npm test" or "npx vitest run"}
BUILD_CMD:  {exact command, e.g. "npm run build" or "N/A if no build step"}
SCOPE:      {files/modules this implementation touches}
REQUIREMENTS: {all AskUserQuestion responses from requirements clarification}
WORKFLOW_ARTIFACT: .claude/cc-teams/workflows/{team_name}.json
PHASE_CURSOR: {phase_cursor or 'ad-hoc-scope'}
ACTIVE_PHASE_ID: {phase id or 'ad-hoc-scope'}
ACTIVE_PHASE_OBJECTIVE: {objective or task scope}
ACTIVE_PHASE_REQUIREMENT_IDS: {requirement ids or 'N/A'}
ACTIVE_PHASE_ACCEPTANCE_IDS: {acceptance ids or 'N/A'}
ACTIVE_PHASE_DECISION_DEPENDENCIES: {decision dependencies or 'N/A'}
ACTIVE_PHASE_INPUTS: {inputs or 'N/A'}
ACTIVE_PHASE_SURFACES: {files/surfaces or task scope}
ACTIVE_PHASE_EXPECTED_ARTIFACTS: {expected artifacts or 'N/A'}
ACTIVE_PHASE_REQUIRED_CHECKS: {required checks or TEST_CMD/BUILD_CMD}
ACTIVE_PHASE_CHECKPOINT_TYPE: {none|human_verify|decision|human_action}
ACTIVE_PHASE_AUTONOMY: {AFK|HITL|N/A}
ACTIVE_PHASE_CHECKPOINT_JUSTIFICATION: {reason or 'N/A'}
ACTIVE_PHASE_EXIT_CRITERIA: {exit criteria or 'N/A'}
ACTIVE_PHASE_GATE_CMD: {gate command or 'N/A'}
PRIOR_PHASE_SUMMARY: {phase_transition_summaries.latest_verified or 'N/A'}
EFFECTIVE_PRIOR_BOUNDARIES: {boundary_history.latest or 'N/A'}
INTENT_GOAL: {intent.goal or task scope}
INTENT_CONSTRAINTS: {intent.constraints or 'N/A'}
INTENT_ACCEPTANCE_CRITERIA: {intent.acceptance_criteria or 'N/A'}
APPROVED_DECISIONS: {approved_decisions or '[]'}
TRACEABILITY_TARGETS: {traceability.requirements / traceability.phases entries for ACTIVE_PHASE_ID or 'N/A'}
```

### investigator-{N}
```
ASSIGNED_HYPOTHESIS: H{N}: {title}
CONFIDENCE:  {score}/100 — {rationale}
NEXT_TEST:   {smallest discriminating command to prove/disprove}
ERROR_CONTEXT: {full error message / stack trace / observed symptom}
REPRODUCTION:  {exact steps or command to reproduce}
GIT_CONTEXT:   {output of: git log --oneline -5 -- <affected-files>}
ALL_HYPOTHESES: {list of all HN titles so investigator can challenge others}
WORKFLOW_ARTIFACT: .claude/cc-teams/workflows/{team_name}.json
DEBUG_RESET_MARKER: [DEBUG-RESET: wf:{team_name}]
ATTEMPT_BASELINE: {count of [DEBUG-N] entries after latest reset marker}
```

### security-reviewer / performance-reviewer / quality-reviewer
```
SCOPE:          {specific files list OR "full codebase" — from user's AskUserQuestion response}
FOCUS:          {security|performance|quality|all — from user's AskUserQuestion response}
BLOCKING_ONLY:  {yes|no — from user's AskUserQuestion response}
AUTH_METHOD:    {JWT|session|OAuth|API-key|N/A — from activeContext.md or grep of codebase}
SENSITIVE_FILES: {files containing auth/secrets/payments — from patterns.md or initial grep}
```
_(`AUTH_METHOD` and `SENSITIVE_FILES` are required for security-reviewer only. All 5 fields apply across all active reviewers — the standard triad plus any conditional reviewers spawned.)_

### verifier
```
TEST_CMD:          {exact test command}
BUILD_CMD:         {exact build command or N/A}
HUNTER_FINDINGS:   {STATUS + CRITICAL_ISSUES count from hunter Router Contract}
REVIEWER_FINDINGS: {STATUS + CRITICAL_ISSUES from each active reviewer Router Contract (3–5)}
PLAN_EXIT_CRITERIA: {prose exit criteria from plan phase, or N/A}
PHASE_GATE_CMD:    {gate_command from plan phase, or N/A}
WORKFLOW_ARTIFACT: .claude/cc-teams/workflows/{team_name}.json
PHASE_CURSOR: {phase_cursor or 'N/A'}
ACTIVE_PHASE_ID: {phase id or 'N/A'}
ACTIVE_PHASE_OBJECTIVE: {objective or 'N/A'}
ACTIVE_PHASE_REQUIREMENT_IDS: {requirement ids or 'N/A'}
ACTIVE_PHASE_ACCEPTANCE_IDS: {acceptance ids or 'N/A'}
ACTIVE_PHASE_DECISION_DEPENDENCIES: {decision dependencies or 'N/A'}
ACTIVE_PHASE_REQUIRED_CHECKS: {required checks or 'N/A'}
ACTIVE_PHASE_CHECKPOINT_TYPE: {none|human_verify|decision|human_action|N/A}
ACTIVE_PHASE_AUTONOMY: {AFK|HITL|N/A}
INTENT_ACCEPTANCE_CRITERIA: {intent.acceptance_criteria or 'N/A'}
APPROVED_DECISIONS: {approved_decisions or '[]'}
TRACEABILITY_TARGETS: {traceability.requirements / traceability.phases / traceability.decisions relevant to ACTIVE_PHASE_ID or 'N/A'}
CHALLENGE_DECISION_RECORD: {resolution_state / accepted_risks / reopened_proof_regressions / unresolved_conflicts / traceability_decision / verifier_intake_state or 'N/A'}
PRIOR_PHASE_SUMMARY: {phase_transition_summaries.latest_verified or 'N/A'}
EFFECTIVE_PRIOR_BOUNDARIES: {boundary_history.latest or 'N/A'}
```

### planner
```
RESEARCH_SUMMARY:  {if research was executed — key findings + path to research file, else N/A}
EXISTING_PATTERNS: {top 3 relevant entries from patterns.md for this feature}
PRIOR_DECISIONS:   {decisions from activeContext.md ## Decisions relevant to this feature}
REQUIREMENTS:      {all AskUserQuestion responses}
DESIGN_FILE:       {approved design file path or N/A}
PLANNING_REVIEW_FINDINGS: {fresh review findings when revising a plan, else N/A}
WORKFLOW_ARTIFACT: .claude/cc-teams/workflows/{team_name}.json
LATEST_PHASE_TRANSITION_SUMMARY: {phase_transition_summaries.latest_verified or 'N/A'}
EFFECTIVE_PRIOR_BOUNDARIES: {boundary_history.latest or 'N/A'}
``` Lead updates task status after teammate returns.

### plan-gap-reviewer (CLEAN-ROOM OVERRIDE — do NOT use generic template)
```
ORIGINAL_USER_REQUEST: {verbatim user request}
PLAN_FILE:            {saved plan path}
REQUIREMENTS:         {requirements snapshot or "See plan file"}
DESIGN_FILE:          {approved design file path or N/A}
RESEARCH_FILES:       {approved research paths or N/A}
TOUCHED_SURFACES_HINT:{files/modules named by plan or N/A}

FRESHNESS_RULE:
- Do NOT read `.claude/cc-teams/*`
- Do NOT use Memory Summary, Project Patterns, or Workflow Artifact
- Do NOT treat planner confidence or prior summaries as authority
- Use only request + saved plan + current codebase + explicitly approved design/research files
```

## Skill Loading Hierarchy (DEFINITIVE)

**Two mechanisms exist:**

### 1. Agent Definition `skills:` (Subagent-Only Convenience)
```yaml
# In agent .md frontmatter:
skills: cc-teams:session-memory, cc-teams:verification
```
- Useful when the definition runs as a standalone subagent.
- Do NOT rely on `skills:` frontmatter being applied when this definition is used as an Agent Teams teammate.

**Agent Teams difference:** Teammates run with normal Claude Code session context, so they can use `CLAUDE.md`, project skills, and configured project/user MCP. But teammate startup does **not** guarantee subagent-definition `skills:` or `mcpServers:` frontmatter will be applied. For CC-Teams, SKILL_HINTS + explicit `Skill()` invocation remains the authoritative teammate skill-loading path.

### 2. Lead's SKILL_HINTS (Conditional - On Demand)
- Lead passes SKILL_HINTS for teammate skills that must be invoked explicitly on the Agent Teams path
- **Source 1:** Lead detection table — `github-research` when research triggers fire
- **Source 2:** CLAUDE.md Complementary Skills table — domain skills matching task signals
- **Source 3:** Explicit user-requested complementary skills, including repo/user installed skills such as `find-skills`
- Agent calls `Skill(skill="{name}")` for each skill in SKILL_HINTS after memory load
- If a skill fails to load (not installed), agent notes it in Memory Notes and continues

**Skill triggers for teammates (DETECT AND PASS AS SKILL_HINTS):**

| Detected Pattern | Skill | Agents |
|------------------|-------|--------|
| **BUILD workflow** (any build/implement/create) | `cc-teams:test-driven-development`, `cc-teams:code-generation`, `cc-teams:architecture-patterns`, `cc-teams:frontend-patterns` | builder |
| **REVIEW workflow** (any review/audit/check) | `cc-teams:code-review-patterns`, `cc-teams:architecture-patterns`, `cc-teams:frontend-patterns` | security-reviewer, performance-reviewer, quality-reviewer |
| **BUILD live loop** (real-time Pair Build feedback) | `cc-teams:code-review-patterns`, `cc-teams:architecture-patterns`, `cc-teams:frontend-patterns` | live-reviewer |
| **BUILD post-hunt comprehensive review** | `cc-teams:code-review-patterns`, `cc-teams:architecture-patterns`, `cc-teams:frontend-patterns` | security-reviewer, performance-reviewer, quality-reviewer |
| **DEBUG post-fix comprehensive review** | `cc-teams:code-review-patterns`, `cc-teams:architecture-patterns`, `cc-teams:frontend-patterns` | security-reviewer, performance-reviewer, quality-reviewer |
| **DEBUG workflow** (any debug/fix/error) | `cc-teams:debugging-patterns`, `cc-teams:architecture-patterns`, `cc-teams:frontend-patterns` | investigator |
| **PLAN workflow** (any plan/design/architect) | `cc-teams:planning-patterns`, `cc-teams:brainstorming`, `cc-teams:architecture-patterns`, `cc-teams:frontend-patterns` | planner |
| **BUILD/DEBUG post-build** (hunter phase) | `cc-teams:code-review-patterns`, `cc-teams:architecture-patterns`, `cc-teams:frontend-patterns` | hunter |
| **BUILD/DEBUG post-verification** (verifier phase) | `cc-teams:debugging-patterns`, `cc-teams:architecture-patterns`, `cc-teams:frontend-patterns` | verifier |
| External: new tech, unfamiliar library, complex integration | `cc-teams:github-research` | planner, investigator |
| Debug exhausted: 3+ local attempts failed, external service error | `cc-teams:github-research` | investigator |
| User explicitly requests: "research", "github", "octocode", "best practices" | `cc-teams:github-research` | planner, investigator |

**Detection runs BEFORE agent invocation. Pass detected skills in SKILL_HINTS.**

**Workflow-based skills are ALWAYS passed for the matching workflow/stage.** They are not conditional — every BUILD gets TDD+code-gen, every REVIEW and post-fix/post-hunt comprehensive review gate gets code-review-patterns, etc. This mirrors CC10x's guaranteed quality coverage while preserving Agent Teams structure.

**Lead-side hard rule:** Missing required workflow/stage SKILL_HINTS is a spawn-contract failure. Do NOT silently continue with an under-equipped teammate. Rebuild the teammate prompt with the required SKILL_HINTS and re-kickoff the teammate.

**Note:** `cc-teams:router-contract`, `cc-teams:verification`, and `cc-teams:session-memory` are NOT in this table because they load via agent frontmatter (unconditional). Every agent gets router-contract + verification; builder/planner also load session-memory for memory read discipline and Memory Notes structure. These do NOT need SKILL_HINTS.

**Also check CLAUDE.md Complementary Skills table and include matching skills in SKILL_HINTS.**

## Instruction Precedence (MANDATORY)

When repo instructions, saved plan constraints, or explicit user requirements conflict with a stylistic or heuristic skill suggestion:
1. explicit user request
2. project-local instructions / saved plan / approved decisions
3. CC-Teams lead protocol
4. domain skills and heuristics

Skills fill gaps. They do not override explicit repo or workflow contracts.

---

## Artifact Governance (MANDATORY)

CC-Teams workflows are message-first. Teammates should not create ad-hoc report files.

Approved durable artifact paths:
- `docs/plans/` (planner output)
- `docs/research/` (lead research persistence)
- `docs/reviews/` (only when user explicitly requests a saved review file)

Forbidden by default:
- Root-level teammate reports like `CHALLENGE_ROUND_*.md`, `SECURITY_REVIEW*.md`, `ROUTER_CONTRACT*.json`
- Any unrequested `*.md`, `*.json`, `*.txt` report artifact outside approved paths

Enforcement rules:
1. If teammate output claims "created/saved/wrote file" for an unauthorized path:
   - create `CC-TEAMS REM-EVIDENCE: unauthorized artifact claim`
   - block downstream tasks
   - request corrected output with inline findings + Router Contract only
2. Lead may allow exceptions only with explicit user instruction (record decision in memory).

---

## Post-Team Validation (Router Contract)

**Full contract schema:** See `cc-teams:router-contract` skill for field definitions and YAML structure.

After each teammate completes, validate:

### Validation Steps
```
1. CHECK CONTRACT EXISTS
   Look for "### Router Contract (MACHINE-READABLE)" in output.
   If NOT found → Create `CC-TEAMS REM-EVIDENCE: {teammate} missing Router Contract`, block downstream, STOP.

2. VALIDATE ARTIFACT CLAIMS
   Check contract.CLAIMED_ARTIFACTS against approved paths (docs/plans/, docs/research/, docs/reviews/).
   If unauthorized/missing → Create `CC-TEAMS REM-EVIDENCE: unauthorized artifact claim`, STOP.

3. PARSE AND VALIDATE CONTRACT
   Circuit Breaker: If ≥3 REM-FIX tasks exist → AskUserQuestion (Research/Fix locally/Skip/Abort).

   If contract.AGENT_ID=="plan-gap-reviewer" AND contract.STATUS=="FINDINGS":
     → Do NOT create REM-FIX
     → Route findings back to planner revision in PLAN
     → Re-run fresh review only after planner revises the same saved plan
     → AskUserQuestion only if blocking findings persist after the allowed revision pass
     → STOP

   If contract.BLOCKING=true OR contract.REQUIRES_REMEDIATION=true:
     → Create `CC-TEAMS REM-FIX: {teammate_name}` with contract.REMEDIATION_REASON
     → Assign to builder (default) or ask user if builder's own output
     → Set workflow artifact `quality.convergence_state="needs_iteration"`
     → Append `{reason, source_agent, ts}` to `remediation_history`
     → Append matching traceability regression / gap entry to `traceability.remediation`
     → Append `remediation_created` event to `.events.jsonl` with required event base fields and canonical `phase_delta.kind=remediation_created`
     → Block all downstream tasks via TaskUpdate(..., addBlockedBy)
     → STOP until remediation completes

   If contract.CRITICAL_ISSUES > 0 in parallel phase:
     → Conflict check between reviewers → AskUserQuestion if disagreement

   If contract.AGENT_ID=="plan-gap-reviewer" AND contract.STATUS=="PASS" AND (contract.CRITICAL_ISSUES != 0 OR contract.REPLAN_NEEDED != false):
     → Create `CC-TEAMS REM-EVIDENCE: plan review contract mismatch`, STOP

   If contract.AGENT_ID=="planner" AND contract.STATUS=="PLAN_CREATED" AND (contract.CONTRADICTIONS_FOUND != 0 OR contract.REQUIREMENT_PHASE_COVERAGE != "complete" OR contract.ACCEPTANCE_PROOF_COVERAGE != "complete"):
     → Create `CC-TEAMS REM-EVIDENCE: planner contradiction or coverage mismatch`
     → Route back to planner revision before fresh review
     → STOP

   If EVIDENCE_COMMANDS missing/inconsistent for evidence-required roles:
     → Create `CC-TEAMS REM-EVIDENCE`, STOP.

   If contract.STATE_DELTA missing or any of `what_changed`, `remains_open`, `should_stay_closed`, `next_trigger` is missing:
     → Create `CC-TEAMS REM-EVIDENCE: state delta missing`
     → Block all downstream tasks via TaskUpdate
     → STOP until corrected evidence is provided

   If prior `phase_transition_summaries.latest_verified` exists AND contract.STATE_DELTA.remains_open overlaps prior `proof_closed` or `should_stay_closed` boundaries:
     → Create `CC-TEAMS REM-FIX: reopened-proof regression`
     → Set workflow artifact `quality.convergence_state="needs_iteration"`
     → Append reopened-proof details to `traceability.remediation`
     → Append/update structured entry in artifact `regressions.reopened_proof`
     → Record regression against the prior verified phase in `results` / `evidence`
     → Append `remediation_created` event to `.events.jsonl` with reopened-proof summary
     → STOP until remediation proves the prior closure still holds or intentionally supersedes it

   If teammate is builder/frontend-builder/backend-builder AND contract.STATUS == "PASS":
     - require contract.PHASE_STATUS == "completed"
     - require contract.PHASE_EXIT_READY == true
     - require contract.PROOF_STATUS == "passed"
     - require contract.TDD_RED_EXIT == 1 AND contract.TDD_GREEN_EXIT == 0
     - require at least one passing scenario in contract.SCENARIOS
     - require traceability coverage fields (`REQUIREMENT_IDS_IN_SCOPE`, `ACCEPTANCE_CRITERIA_IN_SCOPE`, `APPROVED_DECISION_DEPENDENCIES`, `REQUIREMENTS_SATISFIED`, `ACCEPTANCE_CRITERIA_SATISFIED`, `DECISION_DEPENDENCIES_SATISFIED`) to be present for plan-backed phases
     - require `REQUIREMENTS_SATISFIED ⊆ REQUIREMENT_IDS_IN_SCOPE`
     - require `ACCEPTANCE_CRITERIA_SATISFIED ⊆ ACCEPTANCE_CRITERIA_IN_SCOPE`
     - require `DECISION_DEPENDENCIES_SATISFIED ⊆ APPROVED_DECISION_DEPENDENCIES`
     If any are missing/inconsistent:
       → Create `CC-TEAMS REM-EVIDENCE: builder proof contract incomplete`
       → Block all downstream tasks via TaskUpdate
       → STOP until corrected evidence is provided

   If contract.PHASE_GATE_RESULT == "FAIL":
     → Create `CC-TEAMS REM-FIX: phase-gate failed — {contract.PHASE_GATE_CMD}`
     → Block all downstream tasks via TaskUpdate
     → STOP until builder re-runs gate command and reports PHASE_GATE_RESULT=PASS

   If contract.DEPENDENCY_AUDIT == "FAIL":
     → Treat as BLOCKING=true for the verifier phase
     → Create `CC-TEAMS REM-FIX: dependency vulnerabilities — {contract.DEPENDENCY_AUDIT_DETAIL}`
     → Block Memory Update until resolved

   If contract.AGENT_ID is verifier AND contract.STATUS=="PASS" AND contract.TRACEABILITY_STATUS != "verified":
     → Create `CC-TEAMS REM-EVIDENCE: verifier traceability proof incomplete`
     → Block all downstream tasks via TaskUpdate
     → STOP until requirement / acceptance-criteria proof is corrected

   If contract.AGENT_ID is verifier AND artifact `regressions.reopened_proof` has any `status: "open"` entries:
     - require contract.REOPENED_PROOF_STATUS in {"reproof_closed", "superseded_by_decision"}
     - require contract.REOPENED_PROOF_RETIREMENTS to cover every open reopened-proof boundary
     If missing/incomplete:
       → Create `CC-TEAMS REM-EVIDENCE: reopened-proof retirement incomplete`
       → Block all downstream tasks via TaskUpdate
       → STOP until verifier proves the regression was re-closed or explicitly superseded by approved decision

   If contract.AGENT_ID is verifier AND prior builder contract for the active phase exists:
     - require `builder.REQUIREMENTS_SATISFIED ⊆ verifier.REQUIREMENTS_VERIFIED`
     - require `builder.ACCEPTANCE_CRITERIA_SATISFIED ⊆ verifier.ACCEPTANCE_CRITERIA_VERIFIED`
     - require `builder.DECISION_DEPENDENCIES_SATISFIED ⊆ verifier.DECISION_DEPENDENCIES_CHECKED`
     If any mismatch exists:
       → Create `CC-TEAMS REM-FIX: builder-verifier traceability mismatch`
       → Set workflow artifact `quality.convergence_state="needs_iteration"`
       → Append mismatch details to `traceability.remediation`
       → Append `remediation_created` event to `.events.jsonl` with mismatch summary
       → STOP until remediation resolves the mismatch

   Collect contract.MEMORY_NOTES for workflow-final persistence.
   Persist contract summary into workflow artifact `results` / `evidence`, including `STATE_DELTA`.
   Append a `contract_validated` event to `.events.jsonl` with required event base fields, agent id, status, active phase, and any traceability delta.
   If contract.AGENT_ID is hunter/live-reviewer/security-reviewer/performance-reviewer/quality-reviewer/accessibility-reviewer/api-contract-reviewer:
     → persist traceability risk summary from `TRACEABILITY_IMPACT`, `REQUIREMENTS_AT_RISK`, `ACCEPTANCE_CRITERIA_AT_RISK`, and `DECISION_DEPENDENCIES_AT_RISK` into workflow artifact `results` / `evidence`
   If contract.AGENT_ID is builder/frontend-builder/backend-builder:
     → append companion `builder_completed` event with canonical `phase_delta.kind=builder_completed`
   If contract.AGENT_ID is verifier:
     → persist verifier traceability summary into workflow artifact `traceability.verification`
     → update open requirement / acceptance / decision proof gaps from contract.TRACEABILITY_GAPS
     → if contract.REOPENED_PROOF_STATUS in {"reproof_closed", "superseded_by_decision"}:
       - update matching artifact `regressions.reopened_proof[*].status` to `reclosed` or `superseded`
       - persist retirement details into workflow artifact `results` / `evidence`
     → synthesize/update `phase_transition_summaries.latest_verified` from:
       - `phase_id`: active phase id
       - `what_changed`: contract.STATE_DELTA.what_changed
       - `proof_closed`: contract.STATE_DELTA.should_stay_closed
       - `intentionally_open`: contract.STATE_DELTA.remains_open
       - `next_trigger`: contract.STATE_DELTA.next_trigger
       - `outcome_state`: `converged_final` if no incomplete phase remains, else `pending_next_phase`
     → append companion `verifier_completed` event with canonical `phase_delta.kind=verifier_completed`
   If contract.AGENT_ID is hunter/reviewer/verifier and contract is non-blocking:
     → update artifact `quality.evidence_complete` toward true as coverage closes
   If contract.AGENT_ID is verifier AND `challenge_decisions` for active phase shows `verifier_intake_state == "blocked_by_conflict"`:
     → Create `CC-TEAMS REM-EVIDENCE: unresolved challenge conflict reached verifier`
     → STOP until challenge decision record is resolved
   If contract.AGENT_ID is verifier AND contract.STATUS=="PASS":
     → apply Convergence And Phase Advancement rules before proceeding

4. OUTPUT VALIDATION EVIDENCE
   ### Agent Validation: {teammate_name}
   - Router Contract: Found
   - STATUS: {contract.STATUS}
- BLOCKING: {contract.BLOCKING}
- CRITICAL_ISSUES: {contract.CRITICAL_ISSUES}
- Proceeding: [Yes/No + reason]
```

### REM-EVIDENCE Timeout Rule (MANDATORY)

REM-EVIDENCE tasks follow the Task Status Lag escalation ladder:

1. **T+2 min**: Nudge teammate: "Provide Router Contract YAML per template."
2. **T+5 min**: Direct request with deadline: "Router Contract required within 2 minutes or lead will synthesize."
3. **T+8 min**: **Lead Synthesis Fallback** - If teammate provided narrative output but no YAML:
   - Extract STATUS, BLOCKING, CRITICAL_ISSUES from narrative
   - Construct minimal Router Contract with `SYNTHESIZED_BY: lead`
   - Log: "Router Contract synthesized from narrative - teammate did not provide YAML"
   - Continue workflow (do NOT hang indefinitely)
4. **T+10 min**: If no narrative exists to synthesize from:
   - Mark as CRITICAL/stalled
   - AskUserQuestion: "Teammate unresponsive. Skip validation / Reassign / Abort?"

**Never hang indefinitely waiting for Router Contract.** The escalation ladder MUST be applied.

---

## Remediation Re-Review Loop

```
WHEN any remediation task COMPLETES
(`CC-TEAMS REM-FIX:` OR legacy `CC-TEAMS REMEDIATION:`):
  │
  ├─→ 0. Update workflow artifact:
  │      - increment `loop_counts.re_review`
  │      - set `quality.convergence_state="needs_iteration"`
  │      - update matching `remediation_history` entry to `state: "re-review_started"`
  │      - append / update `traceability.remediation` with reopened requirement or acceptance-criteria gaps
  │      - append `remediation_completed` event to `.events.jsonl` with required event base fields and canonical `phase_delta.kind=remediation_completed`
  │
  ├─→ 1. TaskCreate({ subject: "CC-TEAMS security-reviewer: Re-review after remediation" })
  │      → Returns re_sec_id
  │
  ├─→ 2. TaskCreate({ subject: "CC-TEAMS performance-reviewer: Re-review after remediation" })
  │      → Returns re_perf_id
  │
  ├─→ 3. TaskCreate({ subject: "CC-TEAMS quality-reviewer: Re-review after remediation" })
  │      → Returns re_qual_id
  │
  ├─→ 4. TaskCreate({ subject: "CC-TEAMS Remediation Review Arena: Challenge round" })
  │      → Returns re_challenge_id
  │      TaskUpdate({ taskId: re_challenge_id, addBlockedBy: [re_sec_id, re_perf_id, re_qual_id] })
  │
  ├─→ 5. TaskCreate({ subject: "CC-TEAMS hunter: Re-hunt after remediation" })
  │      → Returns re_hunter_id
  │      → increment `loop_counts.re_hunt`
  │
  ├─→ 6. Find verifier task:
  │      TaskList() → Find task where subject contains "verifier"
  │      → verifier_task_id
  │
  ├─→ 7. Block verifier on re-reviews:
  │      TaskUpdate({ taskId: verifier_task_id, addBlockedBy: [re_challenge_id, re_hunter_id] })
  │      → next verifier pass increments `loop_counts.re_verify`
  │
  └─→ 8. Resume execution (re-reviews run before verifier)
```

**Why:** Code changes must be re-reviewed before shipping (orchestration integrity).

---

## Workflow Structural Integrity Guard (MANDATORY)

Run this guard before starting execution and again before starting verifier tasks.

### BUILD required task subjects
- `CC-TEAMS builder:`
- `CC-TEAMS live-reviewer:`
- `CC-TEAMS hunter:`
- `CC-TEAMS security-reviewer:`
- `CC-TEAMS performance-reviewer:`
- `CC-TEAMS quality-reviewer:`
- `CC-TEAMS accessibility-reviewer:` (if UI signals detected — conditional)
- `CC-TEAMS api-contract-reviewer:` (if API signals detected — conditional)
- `CC-TEAMS BUILD Review Arena: Challenge round`
- `CC-TEAMS verifier:`
- `CC-TEAMS Memory Update:`

### BUILD-CROSSLAYER required task subjects
- `CC-TEAMS backend-builder:`
- `CC-TEAMS frontend-builder:`
- `CC-TEAMS live-reviewer:`
- `CC-TEAMS hunter:`
- `CC-TEAMS security-reviewer:`
- `CC-TEAMS performance-reviewer:`
- `CC-TEAMS quality-reviewer:`
- `CC-TEAMS accessibility-reviewer:` (always in cross-layer)
- `CC-TEAMS api-contract-reviewer:` (always in cross-layer)
- `CC-TEAMS BUILD-CROSSLAYER Review Arena: Challenge round`
- `CC-TEAMS verifier:`
- `CC-TEAMS Memory Update:`

### Required BUILD blockers
- hunter blocked by builder
- each active reviewer blocked by hunter
- challenge blocked by all 3 reviewers (security/performance/quality) plus conditional reviewers if present
- challenge blocked by all active reviewers (3–5 depending on signals)
- verifier blocked by challenge
- memory update blocked by verifier

If any required task or blocker is missing:
- create/fix the missing task dependency BEFORE execution continues
- never shortcut directly from hunter/remediation to verifier

### Remediation integrity
- Canonical remediation task prefix is `CC-TEAMS REM-FIX:`.
- Legacy prefix `CC-TEAMS REMEDIATION:` may appear in older runs; treat it as remediation too.
- Any remediation completion must trigger re-review triad + remediation challenge + re-hunt, then re-block verifier.
- Do not mark remediation converged in chat alone; convergence state must be reflected in the workflow artifact.

---

## Team Execution Loop

**NEVER stop after one teammate.** The workflow is NOT complete until ALL tasks are completed.

### Execution Loop

```
-1. Preflight gate:
   - Confirm Agent Teams is enabled and current project scope has no stale active team.
   - If resuming: recover/recreate teammates before assigning tasks.

0. Enter delegate mode (FIRST):
   Press **Shift+Tab** after team creation.
   Lead MUST be in delegate mode before assigning ANY tasks.
   This prevents lead from accidentally implementing code.

1. Normalize then find runnable tasks:
   TaskList() → run Orphan Task Recovery sweep first.
   Then find tasks where:
   - status = "pending"
   - blockedBy is empty OR all blockedBy tasks are "completed"

2. Start teammate(s):
   - TaskUpdate({ taskId: runnable_task_id, status: "in_progress" })
   - Classify task owner:
     - **Lead-owned tasks** (`... Challenge round`, `CC-TEAMS Memory Update`) run in lead context
     - **Teammate tasks** are assigned via message with task context (see Agent Invocation Template)
   - If assigned teammate is not yet active in team:
     - spawn teammate now
     - verify reachability via direct message
     - only then assign task
   - If multiple teammate tasks are ready → assign to multiple teammates simultaneously

3. After teammate completes:
   - Lead validates output first (see Post-Team Validation)
   - If output is valid (blocking or non-blocking) → TaskUpdate({ taskId: runnable_task_id, status: "completed" })
   - If output is invalid/non-compliant → keep task incomplete, request retry or create REM-EVIDENCE
   - If output is blocking → create REM-FIX and block downstream before continuing
   - Lead calls TaskList() to find next available tasks

4. Determine next:
   - Find tasks where ALL blockedBy tasks are "completed"
   - If multiple ready → Assign ALL to teammates in parallel
   - If one ready → Assign to teammate
   - If none ready AND uncompleted tasks exist:
     → **Apply Task Status Lag escalation (see below) for each in-progress task**
     → Classify each in-progress task as `working`, `idle-blocked`, or `idle-unresponsive`
     → If `idle-unresponsive`: start T+2/T+5/T+8 escalation sequence immediately
     → **Never passively wait** - always apply escalation ladder
   - If ALL workflow tasks completed → run TEAM_SHUTDOWN gate (do not mark workflow done yet)

5. Repeat until:
   - All tasks have status="completed" (INCLUDING the Memory Update task)
   - TEAM_SHUTDOWN gate succeeded (`shutdown_request` sent/approved + `TeamDelete()` completed)
   - OR critical error detected (create error task, halt)

**CRITICAL:** Workflow completion requires BOTH:
1. `CC-TEAMS Memory Update` task completed
2. TEAM_SHUTDOWN executed successfully (`SendMessage(type="shutdown_request", ...)` + `TeamDelete()`)

If memory update completed but shutdown failed, workflow is still IN PROGRESS.
```

## Operational State Vocabulary (MANDATORY)

Use these states consistently in lead communications and routing decisions:

1. `working`
   - only when there is fresh evidence from this turn (new tool output, concrete progress, or new contract signal)
2. `idle-blocked`
   - task is blocked by unresolved dependencies (`blockedBy` not complete)
3. `idle-unresponsive`
   - task is runnable but teammate does not provide useful status/progress
4. `stalled`
   - escalation ladder exhausted (or repeated unresponsive cycles) and workflow cannot safely progress
5. `done`
   - task completed and Router Contract validated

Never report `working` without fresh evidence in the current turn.

### Task Status Lag (Agent Teams)

Teammates sometimes idle between turns or lag task updates. Use deterministic escalation.

#### Severity Escalation Model (MANDATORY)

Map lag conditions to deterministic severity:

1. **LOW**
   - Condition: `idle-blocked` with unresolved dependencies
   - Action: no escalation, continue dependency-driven wait
2. **MEDIUM**
   - Condition: runnable task reaches T+5 with no useful update (`idle-unresponsive`)
   - Action: send direct status request with deadline
3. **HIGH**
   - Condition: no useful response by T+8
   - Action: spawn replacement teammate and reassign the task
4. **CRITICAL**
   - Condition: no progress by T+10 after reassignment OR repeated HIGH on same task
   - Action: mark path as `stalled`, freeze downstream starts, and ask user for explicit decision (continue with fallback / narrow scope / abort)

Record MEDIUM/HIGH/CRITICAL decisions in workflow-final Memory Notes.

1. **T+2 minutes without status update**
   - Send nudge: "Reply with WORKING / BLOCKED / DONE + short reason."
2. **T+5 minutes**
   - Send direct status request with deadline and unblock options.
3. **T+8 minutes**
   - If still no useful response, spawn replacement teammate and reassign task.
4. **T+10 minutes**
   - If reassigned path is still not progressing, classify as CRITICAL (`stalled`), freeze downstream starts, and ask user for explicit decision.
   - Otherwise keep original task blocked/stale and continue with reassigned path.

**MEMORY UPDATE ESCAPE HATCH** — applies when `verifier` is the stalled agent:
If verifier is declared CRITICAL/stalled and user chose "continue with fallback" or "abort":
1. Collect whatever verification evidence exists from the handoff payload or last known contract
2. Manually unblock Memory Update: `TaskUpdate({ taskId: memory_update_id, addBlockedBy: [] })`
3. Run Memory Update with partial evidence — note "Verifier stalled: persisting partial learnings"
4. Record the stall in progress.md `## Verification`
_Rationale: Workflow learnings must be persisted even when verifier fails. Never let a stalled
verifier permanently block Memory Update._

Notes:
- Idle is normal when a task is blocked by dependencies; do not escalate if blockedBy is unresolved.
- Idle from non-spawned or not-yet-needed roles is expected; do not treat as failure.
- Never keep workflow in ambiguous idle state beyond escalation ladder.
- Record reassignment decisions in Memory Notes.
- Before saying "teammate is working", require fresh evidence from this turn (message/tool output).
- If no fresh signal, report "status unknown, status request sent" (not "working").

## Lead Communication Discipline (MANDATORY)

Lead updates must be state-change-driven, not heartbeat spam.

Send user updates when:
1. A phase starts or completes.
2. A blocker is detected with concrete evidence.
3. A remediation path is created/resolved.
4. Final verifier/memory/shutdown gates complete.

Avoid:
- Repeating "X is idle" messages without new action.
- Asking user to choose options while escalation ladder is still in progress.
- Long progress narration when no state changed.
- Claiming a teammate is "working" without fresh evidence from current turn.
- Using plain "idle" without context; always qualify as `idle-blocked` or `idle-unresponsive`.

---

## Results Collection (Parallel Teammates)

When parallel teammates complete (3–5 reviewers in Review Arena depending on signals), their outputs must be collected and cross-referenced.

### Pattern: Collect and Pass Findings

```
# After all active reviewers complete:
1. TaskList()  # Verify all active reviewer tasks show "completed"

2. Collect outputs from ALL active reviewer messages:
   REVIEWER_1_FINDINGS = {security-reviewer's Critical Issues + Verdict}
   REVIEWER_2_FINDINGS = {performance-reviewer's Critical Issues + Verdict}
   REVIEWER_3_FINDINGS = {quality-reviewer's Critical Issues + Verdict}
   # If spawned:
   REVIEWER_4_FINDINGS = {accessibility-reviewer's Critical Issues + Verdict}  # if UI files
   REVIEWER_5_FINDINGS = {api-contract-reviewer's Critical Issues + Verdict}   # if API files

3. For Challenge Round: Share EACH reviewer's findings with ALL others via peer messaging:
   SendMessage(type="message", recipient="security-reviewer",
     content="Here are findings from other reviewers: {all_other_reviewers_findings}. Challenge or agree?")
   # Repeat for ALL active reviewers (3–5)

   Challenge completion criteria (per review-arena/SKILL.md):
   - All ACTIVE reviewers acknowledged peer findings (no silent reviewer)
   - At least one cross-review response from each active reviewer (agreement or challenge)
   - Conflicts are resolved or explicitly escalated

   Conflict resolution priority (per review-arena/SKILL.md):
   - Security says CRITICAL, others disagree → Security wins (conservative principle)
   - A11y says CRITICAL, others disagree → A11y wins (regulatory/compliance impact)
   - API contract says CRITICAL, others disagree → API contract wins (client-breaking impact)
   - Performance vs Quality conflict → Present both to user with trade-off analysis
   - Traceability conflict (different requirements / acceptance criteria at risk) → preserve the union and mark `TRACEABILITY_IMPACT=conflict_detected` for synthesis
   - No consensus → Present all active reviewer perspectives to user, let them decide

   After challenge responses arrive, lead MUST persist a `challenge_decision_record` into workflow artifact `challenge_decisions`:
   - `phase_id`
   - `reviewers_considered`
   - `winning_priority`
   - `resolution_state`
   - `accepted_risks`
   - `reopened_proof_regressions`
   - `unresolved_conflicts`
   - `traceability_decision`
   - `verifier_intake_state`
   - `boundary_history_delta`

   Each `accepted_risks` entry is a bounded exception record:
   - `risk` - concise statement of the accepted exposure or deviation
   - `scope_boundary` - exact requirement / acceptance / surface boundary verifier must preserve
   - `accepted_by` - who approved carrying the risk
   - `reason` - why this risk is tolerated for now
   - `revalidation_trigger` - condition that forces the risk to be revisited
   - `evidence_refs` - proof, review finding, or decision references that justify the current boundary
   - `status` - `accepted_open` until a later workflow explicitly retires it

   Verifier intake states:
   - `clear` → no unresolved challenge conflict remains
   - `accepted_risk` → risk accepted explicitly and verifier should verify within that accepted boundary; this is NOT equivalent to resolved
   - `blocked_by_conflict` → unresolved conflict remains; verifier must not proceed

   Challenge resolution states:
   - `clear` → no exception or conflict remains
   - `accepted_risk` → verifier proceeds inside an explicitly bounded accepted-risk exception
   - `open_disagreement` → reviewer disagreement remains unresolved and verifier must not proceed
   - `reopened_prior_proof` → a previously closed boundary has been reopened and must be re-proven before normal convergence resumes

   Resolution-state mapping rules:
   - if `reopened_proof_regressions` is non-empty → `resolution_state="reopened_prior_proof"` and `verifier_intake_state="blocked_by_conflict"`
   - else if `accepted_risks` is non-empty and `unresolved_conflicts` is empty → `resolution_state="accepted_risk"` and `verifier_intake_state="accepted_risk"`
   - else if `unresolved_conflicts` is non-empty → `resolution_state="open_disagreement"` and `verifier_intake_state="blocked_by_conflict"`
   - else → `resolution_state="clear"` and `verifier_intake_state="clear"`

   `boundary_history_delta` should capture only what changed for later-phase inheritance:
   - boundaries newly accepted as risk
   - boundaries newly reopened
   - boundaries no longer safe to inherit without re-proof
   - inheritance note changes caused by the challenge outcome

   Each `reopened_proof_regressions` entry is a durable regression record:
   - `boundary` - exact proof boundary that was previously closed
   - `prior_phase_id` - the last phase that independently proved the boundary
   - `reopened_by` - teammate or synthesis source that surfaced the regression
   - `current_source` - remediation task, finding id, or contract reference for the reopened state
   - `required_reproof` - the concrete proof that must be re-established
   - `status` - `open` until the regression is re-proved or superseded by an approved decision
     later becomes `reclosed` or `superseded` when verifier retires it with explicit evidence or approved-decision reference

   Append a `challenge_decided` event to `.events.jsonl` with canonical `phase_delta.kind=challenge_decided` after the snapshot is updated.

4. For downstream teammates (e.g., verifier after hunt + review challenge):
   Include ALL findings in teammate prompt:
   "## Previous Findings\n### Hunter\n{HUNTER_FINDINGS}\n### Reviewer\n{REVIEWER_FINDINGS}\n### Traceability Risks\nRequirements at risk: {union}\nAcceptance criteria at risk: {union}\nDecision dependencies at risk: {union}"

5. Before invoking verifier, run a contract-diff checkpoint:
   - Compare upstream contract claims vs downstream usage assumptions
   - Comparison dimensions:
     a. FILES_MODIFIED match (builder claims vs hunter/reviewer observations)
     b. EVIDENCE_COMMANDS executed and passed (red/green exits present)
     c. CLAIMED_ARTIFACTS match claimed vs actual files (if any)
     d. SPEC_COMPLIANCE alignment (builder claims PASS, but reviewer finds gap?)
     e. TRACEABILITY alignment (reviewer/hunter risk sets vs builder/verifier satisfied/proven sets)
   - If mismatch exists:
     - Log: "Contract-diff mismatch: {dimension} - upstream={X}, downstream={Y}"
     - Create `CC-TEAMS REM-FIX: Contract-diff` task with mismatch details
     - Block verifier until mismatch resolved
   - Only invoke verifier when contract diff is clean
   - If `challenge_decision_record.verifier_intake_state == blocked_by_conflict`, do NOT invoke verifier
```

### Why Both Task System AND Results Passing

| Aspect | Tasks Handle | Lead Handles |
|--------|--------------|--------------|
| Completion status | Automatic | - |
| Dependency unblocking | Automatic | - |
| Teammate findings/output | NOT shared | Pass via messages |
| Conflict resolution | - | Include both findings |

---

## Workflow-Final Memory Persistence (Task-Enforced)

Memory persistence is enforced via the "CC-TEAMS Memory Update" task in the task hierarchy.

**When you see this task become available:**
1. Review teammate outputs for `### Memory Notes` sections
2. Follow the task description to persist learnings
3. Journal the workflow outcome canonically so Markdown memory mirrors the latest workflow artifact:
   - `activeContext.md ## Recent Changes` → workflow kind, active phase outcome, and whether the workflow closed cleanly, converged to a next phase, or ended with an intentional boundary
   - `activeContext.md ## Learnings` → concise phase or workflow insights worth carrying forward
   - `progress.md ## Completed` → workflow or phase result with compact evidence reference
   - `progress.md ## Verification` → latest artifact truth: workflow instance, phase id, convergence state, traceability status, evidence pointers, and anything intentionally left open
4. If latest `challenge_decisions.current_phase.verifier_intake_state == "accepted_risk"`, persist the accepted-risk boundary explicitly:
   - `activeContext.md ## Decisions` → decision statement with owner + rationale
   - `activeContext.md ## Recent Changes` → record that workflow closed with a bounded accepted-risk exception
   - `progress.md ## Verification` → current proof boundary, accepted exposure, and revalidation trigger
   - `patterns.md` only when the accepted-risk handling teaches a reusable guardrail
5. If traceability is still intentionally open after a successful checkpoint, state the boundary explicitly instead of implying closure:
   - open next-phase requirements
   - accepted-risk exceptions
   - approved deferred TODO scope
6. If `regressions.reopened_proof` is non-empty, persist reopened proof separately from accepted risk or normal deferred scope:
   - `activeContext.md ## Recent Changes` → note that previously closed proof was reopened and is back in active remediation
   - `progress.md ## Verification` → name the reopened boundary, prior proving phase, and required re-proof
   - avoid compressing reopened proof into a vague "still open" note
7. Do NOT rewrite accepted risk, reopened proof, or intentionally open scope as "resolved" or "completed"; they remain bounded exceptions until a later workflow closes them with proof or a superseding decision
8. Use Read-Edit-Read pattern for each memory file
9. Mark task completed

Canonical workflow-final journaling expectations:
- `activeContext.md ## Recent Changes`
  - one line that names workflow kind, active phase, and outcome
  - include whether the next state is `pending`, `phase_verified`, or `converged`
- `activeContext.md ## Decisions`
  - record any new approved decision or accepted-risk boundary created during the workflow
- `activeContext.md ## Learnings`
  - only distilled insights, not a replay transcript
- `progress.md ## Completed`
  - index the completed workflow or completed phase with the strongest evidence reference
- `progress.md ## Verification`
  - mirror workflow artifact truth in compact form:
    - `workflow_instance`
    - `phase_id` / `phase_cursor`
    - `quality.convergence_state`
    - `traceability.status`
    - `challenge_decisions.current_phase.resolution_state` when present
    - `regressions.reopened_proof` when present
    - `phase_transition_summaries.latest_verified` when present
    - evidence references or commands
    - intentionally open items with their boundary or next trigger

**Why task-enforced:**
- Tasks survive context compaction
- Tasks are visible in TaskList() - can't be forgotten
- Task description contains explicit instructions
- Workflow isn't complete until Memory Update task is done

**Why this design:**
- READ-ONLY teammates (reviewers, hunter, verifier) cannot persist memory themselves
- You (lead) collect their Memory Notes and persist at workflow-final
- This avoids parallel edit conflicts and ensures nothing is lost

---

## TODO Candidate Handling (After Workflow Completes)

After all workflow tasks complete, collect follow-up work from teammate outputs:

```
1. Parse teammate outputs for:
   - "### TODO Candidates (For Lead Task Creation)"
   - Subject/Description/Priority entries

2. Backward-compatibility check:
   TaskList() → Find existing tasks with subject starting "CC-TEAMS TODO:"
   Merge existing TODO tasks + newly proposed TODO candidates

3. If any TODOs exist:
   → List them: "Teammates identified these follow-up items:"
     - [subject] - [first line of description] - [priority]
   → Ask user: "Address now / Keep for later / Delete"

4. User chooses:
   - "Address now" → Start new BUILD/DEBUG workflow for selected items
   - "Keep" → Create missing TODO tasks via TaskCreate(...) and leave pending
   - "Delete" → Delete existing TODO tasks; discard new candidates

5. Continue to MEMORY_UPDATED gate
```

**Why TODO items are separate:** They are non-blocking discoveries made during teammate work. They do not auto-execute because they lack full dependency context. User decides priority.

---

## Agent Teams Constraints (CRITICAL)

These constraints come from the Agent Teams architecture. Violating them causes data loss or broken workflows.

1. **No file isolation.** Two teammates editing the same file = overwrites. Builder OWNS all writes. Reviewers/investigators are READ-ONLY.
2. **No session resumption.** `/resume` does NOT restore teammates. See Session Interruption Recovery above.
3. **No nested teams.** Bug Court/Pair Build post-fix or post-hunt review gates must reuse the existing team, not spawn a new team. Spawn reviewer teammates into the existing team instead.
4. **Lead's history doesn't carry over.** When creating a team, lead's conversation history is NOT available to teammates. All context must be passed via task descriptions, messages, or memory files.
5. **Teammates use normal Claude Code session context.** They can use `CLAUDE.md`, project skills, and configured project/user MCP, but do NOT assume subagent-definition `skills:` or `mcpServers:` frontmatter is applied automatically on the teammate path.
6. **No synchronization primitives.** Pair Build's builder-reviewer sync uses message-based polling, not blocking waits.
7. **Delegate mode is MANDATORY.** Lead must enter delegate mode (Shift+Tab) after team creation to prevent accidentally implementing code.
8. **Token cost awareness.** Agent Teams uses significantly more tokens than single-agent workflows. Each teammate has its own context window. Minimize unnecessary parallel spawns — only parallelize when the protocol requires it (e.g., 3 reviewers in Review Arena, multiple investigators in Bug Court).
9. **One team at a time per session.** Clean up current team before starting a new one in the same session.
10. **Lead is fixed for team lifetime.** The creator session remains the lead; do not assume leadership transfer to teammates.
11. **Permission inheritance at spawn.** Teammates start with lead permission mode; per-teammate permission tuning can only happen after spawn.
12. **Broadcast sparingly.** Prefer targeted `message` over `broadcast`; broadcast token cost scales with team size.
13. **NEVER spawn planner with `mode: "plan"`.** Plan mode = read-only = planner cannot write plan files = DEADLOCK. Claude Code may auto-enable plan mode for agents doing planning work — always add "DO NOT ENTER PLAN MODE" at the top of the planner spawn prompt and use `mode: "dontAsk"` if needed. If planner sends BLOCKED message, re-spawn with `dontAsk`. See PLAN workflow step 7.

## Agent Teams Display & Controls

| Action | Shortcut | When to Use |
|--------|----------|-------------|
| Enter delegate mode | **Shift+Tab** | After team creation (MANDATORY) |
| Select teammate to view | **Shift+Down** | Cycle through teammates (wraps to lead) |
| Toggle task list | **Ctrl+T** | Check task status during workflow |
| Kill all background agents | **Ctrl+F** (two-press confirm) | Emergency stop all teammates |
| Interrupt teammate | **Escape** | Stop a teammate that's stuck or off-track |

## Hook-Driven Quality Gates (Opt-in by merging `plugins/cc-teams/settings.json` into Claude Code settings)

CC-Teams core orchestration works without hooks. Hooks add an automated safety net layer on top.
When the hook snippet from `plugins/cc-teams/settings.json` is merged into Claude Code settings, baseline hooks activate and optional audit hooks may also run. Hook commands must resolve from `CLAUDE_PROJECT_DIR`, not from whatever nested `cwd` the hook fired under.

| Hook | Trigger | CC-Teams Effect |
|------|---------|-----------------|
| `TeammateIdle` | Teammate going idle | Enforces Router Contract YAML presence |
| `TaskCreated` | Task being created | Enforces task identity-stamp metadata before creation |
| `TaskCompleted` | Task marked complete | Enforces task identity-stamp metadata + Memory Update runtime invariants |
| `WorktreeCreate` | Builder worktree created | Syncs `.claude/cc-teams/` to new worktree |
| `PreCompact` | Context compaction imminent | Writes checkpoint marker to `progress.md` |
| `SessionStart` | Session opens/resumes | Injects compact workflow context for safe resume |
| `PostCompact` | Context compaction completed | Appends compact replay telemetry |
| `Stop` | Session stop | Persists compact stop snapshot for resume |
| `StopFailure` | Stop API failure | Logs stop-failure telemetry for audit |
| `InstructionsLoaded` | Instructions file load | Audits instruction-loading events |

Hook scripts: `plugins/cc-teams/hooks/` and `plugins/cc-teams/scripts/`
Core behavior is unchanged if hooks are not installed or the hook settings snippet is not merged into Claude Code settings.

## Model Selection Guidance

**Default:** Use `inherit` for all teammates (quality-first, production-safe).

**Optional balanced override:** `sonnet` for performance-reviewer, quality-reviewer, live-reviewer, hunter, verifier. Keep `inherit` for builder, investigator, planner, security-reviewer.

**Override rule:** If any teammate misses issues, immediately re-run that stage with `inherit`.

## Self-Claim Mode (Explicit Opt-In Only)

**Default: DISABLED** to preserve deterministic role routing.

Enable only when: task descriptions are role-agnostic, sequencing not required, user explicitly requests.

When enabled: teammates call `TaskList()`, find pending tasks with empty blockedBy, claim via `TaskUpdate({ taskId, owner: "{my-name}", status: "in_progress" })`.

**Do NOT enable for:** BUILD/DEBUG phases with specialized roles (builder, investigators, reviewers, verifier).

---

## Gates (Must Pass)

1. **AGENT_TEAMS_READY** - Agent Teams enabled; no stale active team for current `project_key`
2. **MEMORY_LOADED** - Before routing
3. **TASKS_CHECKED** - Check TaskList() for active workflow
4. **INTENT_CLARIFIED** - User intent is unambiguous (all workflows)
5. **RESEARCH_EXECUTED** - Before planner (if research trigger detected)
6. **RESEARCH_PERSISTED** - Save to docs/research/ + update activeContext.md (if research was executed)
7. **REQUIREMENTS_CLARIFIED** - Before invoking teammates (BUILD only)
8. **TEAM_CREATED** - Agent Team spawned for workflow
9. **TASKS_CREATED** - Workflow task hierarchy created in team-scoped task list
10. **CONTRACTS_VALIDATED** - Validate Router Contract before marking each teammate task completed
11. **ALL_TASKS_COMPLETED** - All tasks (including Memory Update) status="completed"
12. **MEMORY_UPDATED** - Before marking done
13. **TEST_PROCESSES_CLEANED** - Kill orphaned test processes before shutdown
14. **TEAM_SHUTDOWN** - Send shutdown_request to all teammates, wait for approvals, TeamDelete()

---

## Test Process Cleanup (Gate #13)

**Problem:** Test runners (Vitest, Jest) default to watch mode, leaving processes hanging indefinitely. 61 hanging processes = frozen computer.

Before Team Shutdown, clean up orphaned test processes:

```bash
# 1. Check for hanging test processes
HANGING=$(pgrep -f "vitest|jest|mocha" | wc -l)

# 2. If processes found, kill them
if [ "$HANGING" -gt 0 ]; then
  pkill -f "vitest" 2>/dev/null || true
  pkill -f "jest" 2>/dev/null || true
  pkill -f "mocha" 2>/dev/null || true
  echo "Cleaned $HANGING test processes"
fi

# 3. Verify cleanup
pgrep -f "vitest|jest|mocha" || echo "All test processes cleaned"
```

**Log in Memory Notes:** `Test processes cleaned: {count} killed` (or `0` if none found)

---

## Team Shutdown (Gate #14)

After workflow completes AND memory is updated AND test processes cleaned:
1. Send `shutdown_request` to each teammate via `SendMessage(type="shutdown_request", recipient="{name}")`
2. Wait for approvals.
   - **If approved:** proceed to `TeamDelete()`
   - **If rejected with task reason:** fix/re-assign the incomplete task, then retry ONCE
     - If still rejected after one fix → AskUserQuestion: "Force shutdown / Investigate?"
   - **If rejected with non-task reason** (error, bug, other): AskUserQuestion IMMEDIATELY
   - **Never retry more than once per rejection** — infinite retry loops cause workflow hang
3. After approvals → `TeamDelete()`
4. If `TeamDelete()` fails, retry up to 3 times, then AskUserQuestion: "Proceed (manual cleanup) or Abort?"
5. Report results only after cleanup succeeds OR user chose "Proceed"

**Team Naming:** `cc-teams-{project_key}-{workflow}-{YYYYMMDD-HHMMSS}`

---

## Key Rules

1. **Lead NEVER implements code** - delegate mode always
2. **Every teammate outputs a Router Contract** - YAML at end of output
3. **Every workflow reads memory first** - `.claude/cc-teams/`
4. **Teammates own file sets** - no two teammates edit the same file
5. **READ-ONLY agents** include Memory Notes for lead to persist
6. **Lead owns memory persistence by default**; teammates provide Memory Notes unless explicitly assigned `MEMORY_OWNER: teammate`
7. **Monitor teammates with escalation** - never implement while teammates are working, but apply Task Status Lag escalation (T+2/T+5/T+8) if `idle-unresponsive`
8. **All skill references** use `cc-teams:` prefix
9. **No nested teams** - reuse existing team for sub-workflows
10. **Memory anchor integrity** - never rename section headers used as Edit anchors
