---
name: cc100x-lead
description: |
  THE ONLY ENTRY POINT FOR CC100X. Orchestrates Agent Teams for development workflows.
  Multi-perspective adversarial reviews, competing hypothesis debugging, and real-time pair building.

  Use this skill when: building, implementing, debugging, fixing, reviewing, planning, refactoring, testing, or ANY coding request.

  Triggers: build, implement, create, make, write, add, develop, code, feature, component, app, application, review, audit, check, analyze, debug, fix, error, bug, broken, troubleshoot, plan, design, architect, roadmap, strategy, memory, session, context, save, load, test, tdd, frontend, ui, backend, api, pattern, refactor, optimize, improve, enhance, update, modify, change, help, assist, work, start, begin, continue, research, cc100x.

  CRITICAL: Execute workflow immediately. Never just describe capabilities.
  REQUIRES: Agent Teams enabled (CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1)
---

# CC100x Lead

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
| **REVIEW** | `cc100x:review-arena` | 3 reviewers (security, performance, quality) |
| **DEBUG** | `cc100x:bug-court` | 2-5 investigators → builder fix → Review Arena (3 reviewers + challenge) → verifier |
| **BUILD** | `cc100x:pair-build` | Builder + Live Reviewer → Hunter → Review Arena (3 reviewers + challenge) → Verifier |
| **PLAN** | Plan Approval Mode | Single planner (mode: "plan", lead approves) |

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
   - Use `cc100x-{workflow}-{YYYYMMDD-HHMMSS}`.
   - Persist the active team name in memory (`activeContext.md ## Recent Changes`) during workflow-final Memory Update.

4. **Delegate mode required**
   - After team creation, enter delegate mode immediately (`Shift+Tab`) before assigning any task.
   - Never assign teammate work before `TEAM_CREATED` gate is satisfied.

5. **Memory owner declared**
   - In teammate prompts, set `MEMORY_OWNER: lead`.
   - Teammates emit Memory Notes; lead persists memory in the final Memory Update task.

## Gate #9 Operational Team Creation (MANDATORY)

`TEAM_CREATED` is not a narrative statement. It requires operational evidence.

1. Generate deterministic `team_name = cc100x-{workflow}-{YYYYMMDD-HHMMSS}`.
2. Create the team with the lead as coordinator (`TeamCreate(...)`).
3. Spawn only phase-required teammates for the selected workflow (lazy activation, not full pre-spawn).
4. Verify team health before task assignment:
   - required teammate names exist
   - each teammate can receive a direct message (`SendMessage(type="message", ...)`)
5. Enter delegate mode (`Shift+Tab`).
6. Only then assign any teammate task from TaskList.

If any step fails:
- Do NOT continue workflow execution.
- Fix team creation/teammate spawn first or stop and report a blocking orchestration error.

## Phase-Scoped Teammate Activation (MANDATORY)

To reduce idle confusion, token waste, and premature findings, teammates are spawned by phase:

- **BUILD**
  - Team create: `builder`, `live-reviewer`
  - When hunter task becomes runnable: spawn `hunter`
  - When review tasks become runnable: spawn `security-reviewer`, `performance-reviewer`, `quality-reviewer`
  - When verifier task becomes runnable: spawn `verifier`
- **DEBUG**
  - Team create: only required `investigator-*`
  - After winning hypothesis / fix task runnable: spawn `builder`
  - After fix-review tasks runnable: spawn 3 reviewers
  - When verifier task becomes runnable: spawn `verifier`
- **REVIEW**
  - Team create: spawn 3 reviewers (phase-1 workers)
- **PLAN**
  - Team create: spawn `planner`

Non-negotiable rules:
1. Do NOT spawn downstream teammates early "just in case".
2. Do NOT treat idle from not-yet-needed teammates as a stall.
3. Spawn teammate only when at least one task for that role is runnable.

---

## Memory Protocol (PERMISSION-FREE)

**LOAD FIRST (Before routing):**

**Step 1 - Create directory (MUST complete before Step 2):**
```
Bash(command="mkdir -p .claude/cc100x")
```

**Step 2 - Load memory files (AFTER Step 1 completes):**
```
Read(file_path=".claude/cc100x/activeContext.md")
Read(file_path=".claude/cc100x/patterns.md")
Read(file_path=".claude/cc100x/progress.md")
```

**IMPORTANT:** Do NOT run Step 1 and Step 2 in parallel. Wait for mkdir to complete before reading files.

If any memory file is missing:
- Create it with `Write(...)` using the templates from `cc100x:session-memory` (include the contract comment + required headings).
- Then `Read(...)` it before continuing.

**TEMPLATE VALIDATION GATE (Auto-Heal):**

After loading memory files, ensure ALL required sections exist.

### activeContext.md - Required Sections
`## Current Focus`, `## Recent Changes`, `## Next Steps`, `## Decisions`,
`## Learnings`, `## References`, `## Blockers`, `## Last Updated`

### progress.md - Required Sections
`## Current Workflow`, `## Tasks`, `## Completed`, `## Verification`, `## Last Updated`

### patterns.md - Required Sections
`## Common Gotchas` (minimum)

**Auto-heal pattern:**
```
# If any section missing in activeContext.md, insert before ## Last Updated:
# Example: "## References" is missing
Edit(file_path=".claude/cc100x/activeContext.md",
     old_string="## Last Updated",
     new_string="## References\n- Plan: N/A\n- Design: N/A\n- Research: N/A\n\n## Last Updated")

# Example: progress.md missing "## Verification"
Edit(file_path=".claude/cc100x/progress.md",
     old_string="## Last Updated",
     new_string="## Verification\n- [None yet]\n\n## Last Updated")

# VERIFY after each heal
Read(file_path=".claude/cc100x/activeContext.md")
```

This is idempotent: runs once per project (subsequent sessions find sections present).
**Why:** Old projects may lack these sections, causing Edit failures.

**UPDATE (Checkpoint + Final):**
- Avoid memory edits during parallel phases (multiple teammates running).
- Do a **workflow-final** memory update/check after the team completes.
- Use Edit tool on memory files (permission-free), then Read-back verify.

Memory update rules (do not improvise):
1. Use `Edit(...)` (not `Write`) to update existing `.claude/cc100x/*.md`.
2. Immediately `Read(...)` the edited file and confirm the expected text exists.
3. If the update did not apply, STOP and retry with a correct, exact `old_string` anchor (do not proceed with stale memory).

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
   - `subject` starts with `CC100X `
   - description includes `Project Root: {cwd}` OR legacy task has no root stamp but clearly belongs to current run
3. For scoped tasks with `status="in_progress"`:
   - if owning teammate is missing/not running/not reachable: `TaskUpdate({ taskId, status: "pending" })`
   - if task belongs to a non-active workflow instance: `TaskUpdate({ taskId, status: "deleted" })`
4. If multiple workflow parent tasks are active in this project, keep only one canonical instance:
   - prefer the one matching current team name in memory
   - otherwise prefer the newest task id
   - mark other pending/in-progress sibling workflow trees as `deleted`
5. Re-run `TaskList()` and continue only when:
   - no scoped orphan `in_progress` tasks remain without an active reachable teammate
   - exactly one active workflow instance exists for this project

Only ask user if the workflow instance is truly ambiguous after this sweep (rare tie case).

**If active CC100x workflow task exists (subject starts with `CC100X `):**
- Resume from task state (use `TaskGet({ taskId })` for the task you plan to resume)
- Skip workflow selection - continue execution from where it stopped
- Check `blockedBy` to determine which teammate to run next

**Safety rule (avoid cross-project collisions):**
- If you find tasks that do NOT clearly belong to this project/workflow identity, do not resume them.
- Foreign-project tasks are ignored, not resumed.
- Never let foreign tasks block current workflow progress.

**Legacy compatibility:** Older CC100x versions may have created tasks with subjects starting `BUILD:` / `DEBUG:` / `REVIEW:` / `PLAN:` (without the `CC100X` prefix).
- If such tasks exist, ask the user whether to resume the legacy tasks or start a fresh CC100X-namespaced workflow.

Task lists can be shared across sessions via `CLAUDE_CODE_TASK_LIST_ID`. Treat TaskLists as potentially long-lived; always scope before resuming.

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

```
Workflow Instance: {team_name}
Workflow Kind: {BUILD|DEBUG|REVIEW|PLAN}
Project Root: {cwd}
```

Rules:
1. Apply this stamp to EVERY CC100X task (parent + children + remediation tasks).
2. Use this stamp for orphan sweep and cross-project isolation.
3. Do not resume or mutate tasks with a different `Project Root`.
4. If stamp is missing (legacy task), treat cautiously and prefer fresh stamped tasks for new runs.

---

## Session Handoff Payload (MANDATORY)

When a workflow may be resumed later (compaction boundary, interruption risk, user pause, or CRITICAL stall), emit and persist a handoff payload.

Canonical payload shape:

```yaml
workflow_instance: "cc100x-build-20260210-150000"
workflow_kind: "BUILD"
project_root: "/absolute/path"
team_name: "cc100x-build-20260210-150000"
gate: "CONTRACTS_VALIDATED"
timestamp_utc: "2026-02-10T23:05:00Z"
task_snapshot:
  in_progress: ["#9 CC100X builder: ..."]
  pending_runnable: ["#11 CC100X hunter: ..."]
  blocked: ["#12 CC100X security-reviewer: ... blocked by #11"]
contracts:
  last_validated: ["builder: PASS", "live-reviewer: PASS"]
  unresolved_blocking: []
remediation:
  open_rem_fix_ids: []
next_owner: "hunter"
resume_entrypoint: "Run TaskList, verify #11 runnable, then assign hunter"
stale_assumptions: []
```

Rules:
1. Persist latest payload in `.claude/cc100x/progress.md` under `## Verification`.
2. Never infer missing facts; use `unknown` when evidence is unavailable.
3. `stale_assumptions` is required. Use an explicit empty list (`[]`) when none.
4. Handoff payload is lead-owned and must be based on current TaskList + validated contracts.

Emit payload at minimum when:
1. escalation reaches `CRITICAL` (`stalled`);
2. user asks to pause/continue later;
3. long-running workflow crosses pre-compaction checkpoint (every 30+ tool calls);
4. session is about to end while workflow tasks remain incomplete.

## Session Interruption Recovery (Agent Teams)

**Problem:** `/resume` does NOT restore teammates. If session interrupted mid-workflow, teammates are gone.

## Resume Checklist (MANDATORY)

On resume or startup with active CC100X tasks, execute in order:

1. Load memory files and read latest handoff payload from `.claude/cc100x/progress.md` (if present).
2. Run `TaskList()` and apply Orphan Task Recovery sweep before any assignment.
3. Rebuild truth from task state, not memory narrative:
   - identify in-progress, runnable, blocked tasks;
   - identify latest validated contracts and open remediation tasks.
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
   - next deterministic step.
8. Continue from `resume_entrypoint` only after steps 1-7 succeed.

Recovery rules:
1. Preserve existing task state (do not reset workflow by default).
2. Do not mark tasks completed based only on teammate claims from a prior session.
3. If handoff payload conflicts with current TaskList, TaskList wins and conflict is logged in Memory Notes.

**Prevention:** For long-running workflows (Bug Court multi-round, Pair Build multi-module), trigger pre-compaction memory checkpoint every 30+ tool calls.

---

## Task-Based Orchestration

**Create workflow task hierarchy only AFTER TeamCreate for that workflow.**
**Stamp every task description with Workflow Identity metadata (see section above).**

**Task sizing guidance:** Aim for 5-6 tasks per teammate, each a self-contained deliverable.

### Tasks System Capabilities

**Persistence:** Tasks are stored in the filesystem at `~/.claude/tasks/{team-name}/`. They survive context compaction and session restarts.

**DAG Dependencies:** Use `addBlockedBy` and `addBlocks` to create dependency graphs. Blocked tasks cannot start until their dependencies complete. This enforces phase ordering (e.g., review must finish before challenge round starts).

**Cross-Session Sharing:** Task lists can be shared across sessions via `CLAUDE_CODE_TASK_LIST_ID` environment variable. If resuming a workflow across sessions:
1. Check if `CLAUDE_CODE_TASK_LIST_ID` is set
2. If set → `TaskList()` returns tasks from that shared list
3. Scope tasks by CC100X prefix before resuming (avoid cross-project collisions)
4. Resume from task state rather than re-creating the hierarchy

**Task Cleanup:** When tasks are abandoned or obsolete, use `TaskUpdate({ taskId, status: "deleted" })` to clean them up. Run cleanup:
- After workflow completion (delete parent wrapper tasks if desired)
- When aborting a workflow (delete all pending tasks for that workflow)
- At session start if stale tasks are found (tasks from interrupted workflows)

### TeamCreate Task-List Context Rule (MANDATORY)

Agent Teams task lists are team-scoped (`~/.claude/tasks/{team-name}/`).
Creating a team can move execution to a team-scoped task context.

Operational rules:
1. Create the team first (`TeamCreate(...)`), then create CC100X workflow tasks.
2. Immediately after team creation, run `TaskList()` and verify current task context is the team workflow context.
3. If pre-team tasks were created and are not visible after team creation, DO NOT continue with partial state:
   - recreate the full CC100X workflow hierarchy in the team-scoped list
   - continue only with the recreated team-scoped tasks
4. Never assign teammate work from an unscoped/non-team task list.

This avoids lost/phantom tasks during team initialization.

### BUILD Workflow Tasks
```
# 0. Check if following a plan (from activeContext.md)
# Look in "## References" section for "- Plan:" entry (not "N/A"):
#   → Extract plan_file path (e.g., `docs/plans/2024-01-27-auth-plan.md`)
#   → Include in task description for context preservation

# 1. Parent workflow task
TaskCreate({
  subject: "CC100X BUILD: {feature_summary}",
  description: "User request: {request}\n\nWorkflow: BUILD (Pair Build)\nTeam: Builder + Live Reviewer → Hunter → Review Arena (security, performance, quality) → Verifier\n\nPlan: {plan_file or 'N/A'}",
  activeForm: "Building {feature}"
})
# Returns workflow_task_id

# 2. Builder task
TaskCreate({
  subject: "CC100X builder: Implement {feature}",
  description: "Build the feature using TDD (RED→GREEN→REFACTOR).\n\nPlan: {plan_file or 'N/A'}\nRequirements: {requirements}\n\nYou OWN all file writes. No other teammate edits files.\nAfter each module, message 'live-reviewer' with: 'Review {file_path}'.\nWait for reviewer feedback before continuing.",
  activeForm: "Building components"
})
# Returns builder_task_id

# 3. Live Reviewer task (starts alongside builder - NOT blocked)
TaskCreate({
  subject: "CC100X live-reviewer: Real-time review",
  description: "READ-ONLY. Wait for messages from builder requesting review.\nFor each: read file, check security/correctness/patterns, reply LGTM or STOP.",
  activeForm: "Reviewing in real-time"
})
# Returns live_reviewer_task_id

# 4. Hunter task (blocked by builder)
TaskCreate({
  subject: "CC100X hunter: Silent failure audit",
  description: "Scan implementation for: empty catches, log-only handlers, generic errors, swallowed exceptions.\nOutput Router Contract with findings.",
  activeForm: "Hunting failures"
})
# Returns hunter_task_id
TaskUpdate({ taskId: hunter_task_id, addBlockedBy: [builder_task_id] })

# 5. Security reviewer task (blocked by hunter)
TaskCreate({
  subject: "CC100X security-reviewer: Security review of build output",
  description: "Review implementation for auth, injection, secrets, OWASP concerns, XSS/CSRF.\nUse full review standards (not live-review quick checks).\nOutput Router Contract.",
  activeForm: "Security review"
})
# Returns sec_task_id
TaskUpdate({ taskId: sec_task_id, addBlockedBy: [hunter_task_id] })

# 6. Performance reviewer task (blocked by hunter)
TaskCreate({
  subject: "CC100X performance-reviewer: Performance review of build output",
  description: "Review implementation for N+1 queries, loops, memory leaks, caching, bundle and API efficiency.\nUse full review standards.\nOutput Router Contract.",
  activeForm: "Performance review"
})
# Returns perf_task_id
TaskUpdate({ taskId: perf_task_id, addBlockedBy: [hunter_task_id] })

# 7. Quality reviewer task (blocked by hunter)
TaskCreate({
  subject: "CC100X quality-reviewer: Quality review of build output",
  description: "Review implementation for correctness, patterns, complexity, error handling, tests, maintainability.\nUse full review standards.\nOutput Router Contract.",
  activeForm: "Quality review"
})
# Returns qual_task_id
TaskUpdate({ taskId: qual_task_id, addBlockedBy: [hunter_task_id] })

# 8. Build Review Arena challenge round (blocked by all 3 reviewers)
TaskCreate({
  subject: "CC100X BUILD Review Arena: Challenge round",
  description: "Share each reviewer's findings with the others.\nChallenge and resolve conflicts (security wins on CRITICAL).\nMerge final review verdict for downstream verifier.",
  activeForm: "Running build challenge round"
})
# Returns build_challenge_task_id
TaskUpdate({ taskId: build_challenge_task_id, addBlockedBy: [sec_task_id, perf_task_id, qual_task_id] })

# 9. Verifier task (blocked by build challenge)
TaskCreate({
  subject: "CC100X verifier: E2E verification",
  description: "Run tests, verify E2E functionality.\nEvery scenario needs PASS/FAIL with exit code evidence.\nConsider ALL findings from hunter + security/performance/quality reviewers.\nOutput Router Contract.",
  activeForm: "Verifying integration"
})
# Returns verifier_task_id
TaskUpdate({ taskId: verifier_task_id, addBlockedBy: [build_challenge_task_id] })

# 10. Memory Update task (blocked by verifier - TASK-ENFORCED)
TaskCreate({
  subject: "CC100X Memory Update: Persist build learnings",
  description: "REQUIRED: Collect Memory Notes from ALL teammate outputs and persist to memory files.\n\n**Instructions:**\n1. Find all '### Memory Notes' sections from completed teammates\n2. Persist learnings to .claude/cc100x/activeContext.md ## Learnings\n3. Persist patterns to .claude/cc100x/patterns.md ## Common Gotchas\n4. Persist verification to .claude/cc100x/progress.md ## Verification\n\n**Pattern:**\nRead(file_path=\".claude/cc100x/activeContext.md\")\nEdit(old_string=\"## Learnings\", new_string=\"## Learnings\\n- [from agent]: {insight}\")\nRead(file_path=\".claude/cc100x/activeContext.md\")  # Verify\n\nRepeat for patterns.md and progress.md.",
  activeForm: "Persisting workflow learnings"
})
# Returns memory_task_id
TaskUpdate({ taskId: memory_task_id, addBlockedBy: [verifier_task_id] })
```

### DEBUG Workflow Tasks
```
TaskCreate({
  subject: "CC100X DEBUG: {error_summary}",
  description: "User request: {request}\n\nWorkflow: DEBUG (Bug Court)\nTeam: Investigators → Debate → Fix → Review Arena (security, performance, quality) → Verifier",
  activeForm: "Debugging {error}"
})

# One task per hypothesis (dynamic investigator count: 2-5)
investigator_task_ids = []
for each hypothesis h_i in {hypotheses}:
  TaskCreate({
    subject: "CC100X investigator-{i}: Test hypothesis - {h_i}",
    description: "Champion hypothesis: '{h_i}'\nGather evidence FOR this hypothesis. Try to PROVE it's the root cause.\nAlso gather evidence that could DISPROVE other hypotheses.\nError context: {error_details}\nMemory patterns: {common_gotchas}\n\nYou are READ-ONLY. Do NOT edit source code.\nOutput Router Contract at end.",
    activeForm: "Investigating hypothesis {i}"
  })
  # Returns inv_i_task_id
  investigator_task_ids.append(inv_i_task_id)

TaskCreate({
  subject: "CC100X Bug Court: Debate round",
  description: "Share evidence between investigators. Each tries to disprove others.\nDetermine winning hypothesis based on strongest evidence + least counter-evidence.",
  activeForm: "Running debate round"
})
# Returns debate_task_id
TaskUpdate({ taskId: debate_task_id, addBlockedBy: investigator_task_ids })

TaskCreate({
  subject: "CC100X builder: Implement fix for winning hypothesis",
  description: "Implement the fix using TDD:\n1. Write regression test FIRST (must fail before fix)\n2. Implement minimal fix\n3. Verify regression test passes\n4. Run full test suite",
  activeForm: "Implementing fix"
})
# Returns fix_task_id
TaskUpdate({ taskId: fix_task_id, addBlockedBy: [debate_task_id] })

# Full-spectrum post-fix review (blocked by fix)
TaskCreate({
  subject: "CC100X security-reviewer: Security review of the fix",
  description: "Review fix for auth/injection/secrets/OWASP risks and security regressions.\nOutput Router Contract.",
  activeForm: "Security review"
})
# Returns fix_sec_task_id
TaskUpdate({ taskId: fix_sec_task_id, addBlockedBy: [fix_task_id] })

TaskCreate({
  subject: "CC100X performance-reviewer: Performance review of the fix",
  description: "Review fix for latency, N+1, loops, memory, and throughput regressions.\nOutput Router Contract.",
  activeForm: "Performance review"
})
# Returns fix_perf_task_id
TaskUpdate({ taskId: fix_perf_task_id, addBlockedBy: [fix_task_id] })

TaskCreate({
  subject: "CC100X quality-reviewer: Quality review of the fix",
  description: "Review fix for correctness, patterns, complexity, and maintainability.\nOutput Router Contract.",
  activeForm: "Quality review"
})
# Returns fix_qual_task_id
TaskUpdate({ taskId: fix_qual_task_id, addBlockedBy: [fix_task_id] })

TaskCreate({
  subject: "CC100X DEBUG Review Arena: Challenge round",
  description: "Share security/performance/quality findings.\nChallenge and resolve conflicts before verification (security wins on CRITICAL).",
  activeForm: "Running debug challenge round"
})
# Returns debug_challenge_task_id
TaskUpdate({ taskId: debug_challenge_task_id, addBlockedBy: [fix_sec_task_id, fix_perf_task_id, fix_qual_task_id] })

TaskCreate({
  subject: "CC100X verifier: Verify fix E2E",
  description: "Verify fix works E2E. Run all tests. Verify original symptom resolved.\nConsider ALL findings from security/performance/quality reviewers.",
  activeForm: "Verifying fix"
})
# Returns verifier_task_id
TaskUpdate({ taskId: verifier_task_id, addBlockedBy: [debug_challenge_task_id] })

# Memory Update task (blocked by verifier - TASK-ENFORCED)
TaskCreate({
  subject: "CC100X Memory Update: Persist debug learnings",
  description: "REQUIRED: Collect Memory Notes from ALL teammate outputs.\n\nFocus on:\n- Root cause for patterns.md ## Common Gotchas\n- Debug attempt history for activeContext.md\n- Verification evidence for progress.md\n\n**Use Read-Edit-Read pattern for each file.**",
  activeForm: "Persisting debug learnings"
})
# Returns memory_task_id
TaskUpdate({ taskId: memory_task_id, addBlockedBy: [verifier_task_id] })
```

### REVIEW Workflow Tasks
```
TaskCreate({
  subject: "CC100X REVIEW: {target_summary}",
  description: "User request: {request}\n\nWorkflow: REVIEW (Review Arena)\nTeam: 3 reviewers (security, performance, quality) → challenge round",
  activeForm: "Reviewing {target}"
})

TaskCreate({
  subject: "CC100X security-reviewer: Security review of {target}",
  description: "Review for: auth, injection, secrets, OWASP top 10, XSS, CSRF.\nOutput Router Contract.",
  activeForm: "Security review"
})
# Returns sec_task_id

TaskCreate({
  subject: "CC100X performance-reviewer: Performance review of {target}",
  description: "Review for: N+1 queries, memory leaks, bundle size, loops, caching.\nOutput Router Contract.",
  activeForm: "Performance review"
})
# Returns perf_task_id

TaskCreate({
  subject: "CC100X quality-reviewer: Quality review of {target}",
  description: "Review for: patterns, naming, complexity, error handling, test coverage.\nOutput Router Contract.",
  activeForm: "Quality review"
})
# Returns qual_task_id

TaskCreate({
  subject: "CC100X Review Arena: Challenge round",
  description: "Share each reviewer's findings with the other two.\nReviewers challenge and debate via peer messaging.\nResolve conflicts (security wins on CRITICAL).",
  activeForm: "Running challenge round"
})
# Returns challenge_task_id
TaskUpdate({ taskId: challenge_task_id, addBlockedBy: [sec_task_id, perf_task_id, qual_task_id] })

# Memory Update task (blocked by challenge - TASK-ENFORCED)
TaskCreate({
  subject: "CC100X Memory Update: Persist review learnings",
  description: "REQUIRED: Collect Memory Notes from ALL reviewer outputs.\n\nFocus on:\n- Patterns for patterns.md\n- Review verdict for progress.md\n\n**Use Read-Edit-Read pattern for each file.**",
  activeForm: "Persisting review learnings"
})
# Returns memory_task_id
TaskUpdate({ taskId: memory_task_id, addBlockedBy: [challenge_task_id] })
```

### PLAN Workflow Tasks
```
TaskCreate({
  subject: "CC100X PLAN: {feature_summary}",
  description: "User request: {request}\n\nWorkflow: PLAN\nAgent: Single planner (Plan Approval Mode)",
  activeForm: "Planning {feature}"
})

TaskCreate({
  subject: "CC100X planner: Create plan for {feature}",
  description: "Create comprehensive implementation plan.\n\nResearch: {research_file or 'None'}\nRequirements: {requirements}",
  activeForm: "Creating plan"
})
# Returns planner_task_id
# NOTE: Spawn planner with mode: "plan" for Plan Approval Mode
# Lead reviews plan_approval_request, approves/rejects via plan_approval_response

# Memory Update task (blocked by planner - TASK-ENFORCED)
TaskCreate({
  subject: "CC100X Memory Update: Index plan in memory",
  description: "REQUIRED: Update memory files with plan reference.\n\nFocus on:\n- Add plan file to activeContext.md ## References\n- Update progress.md with plan status\n\n**Use Read-Edit-Read pattern for each file.**",
  activeForm: "Indexing plan in memory"
})
# Returns memory_task_id
TaskUpdate({ taskId: memory_task_id, addBlockedBy: [planner_task_id] })
```

---

## Workflow Execution

### BUILD
1. Load memory → Check if already done in progress.md
2. **Plan-First Gate** (STATE-BASED, not phrase-based):
   - Skip ONLY if: (plan in `## References` ≠ "N/A") AND (active `CC100X` task exists)
   - Otherwise → AskUserQuestion: "Plan first (Recommended) / Build directly"
3. **Clarify requirements** (DO NOT SKIP) → Use AskUserQuestion
4. **Create Agent Team (MANDATORY gate)**:
   - `TeamCreate(...)` with deterministic team name
   - spawn `builder` + `live-reviewer` only
   - defer `hunter` / triad reviewers / `verifier` until their tasks are runnable
   - verify teammate reachability via direct message
   - enter delegate mode (`Shift+Tab`)
   - run `TaskList()` to confirm team-scoped task context
   - if any of these fail: STOP (do not run task-only fallback)
5. **Create task hierarchy in the team-scoped task list** (see Task-Based Orchestration above)
6. **Start execution** (see Team Execution Loop below)
7. Update memory, then execute TEAM_SHUTDOWN gate before final completion

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
2. **Spawn planner with Plan Approval Mode:**
   - Use `mode: "plan"` when spawning the planner teammate
   - Planner works in read-only mode (explores codebase, designs approach)
   - When planner calls ExitPlanMode, lead receives plan_approval_request
   - Lead reviews plan → approves via `plan_approval_response` or rejects with feedback
   - **Approval criteria:** Plan includes TDD steps, file paths, validation commands, and risk assessment
   - **Rejection reasons:** Missing test steps, vague file references, no risk assessment
   - If rejected → planner revises plan, resubmits
   - If approved → planner exits plan mode, saves plan file + updates memory
3. **If external research detected (external tech OR explicit request):**
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
      Edit(file_path=".claude/cc100x/activeContext.md", ...)  # Add to References section
  → PHASE 3: Invoke planner with: "Research findings: {results}\nResearch saved to: docs/research/..."
```
Research is a PREREQUISITE, not a hint. Planner cannot skip it.
**Research without persistence is LOST after context compaction.**

4. **Create Agent Team (MANDATORY gate)**:
   - `TeamCreate(...)` with deterministic team name
   - spawn planner teammate
   - verify teammate reachability via direct message
   - enter delegate mode (`Shift+Tab`)
   - run `TaskList()` to confirm team-scoped task context
   - if team gate fails: STOP
5. **Create task hierarchy in the team-scoped task list** (see Task-Based Orchestration above)
6. **Invoke planner with Plan Approval Mode** (pass research results + file path if step 3 was executed)
7. **Review plan** → Approve or reject via plan_approval_response
8. Update memory → Reference saved plan, then execute TEAM_SHUTDOWN gate

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

## SKILL_HINTS (INVOKE via Skill() - not optional)
{detected skills from table below}
**If skills listed:** Call `Skill(skill="{skill-name}")` immediately after memory load.

---
IMPORTANT:
- `MEMORY_OWNER: lead` (default). Teammates do NOT edit `.claude/cc100x/*` unless prompt explicitly overrides with `MEMORY_OWNER: teammate`.
- Every teammate MUST include a clearly labeled `### Memory Notes (For Workflow-Final Persistence)` section with:
  - **Learnings:** [insights for activeContext.md]
  - **Patterns:** [gotchas for patterns.md]
  - **Verification:** [results for progress.md]
- Every teammate status reply MUST include one of:
  - `WORKING` (actively progressing)
  - `BLOCKED: {reason}` (cannot proceed)
  - `DONE` (work finished, Router Contract included)
- Lead persists these notes in the task-enforced `CC100X Memory Update` step.

Execute the task and include 'Task {TASK_ID}: COMPLETED' in your output when done.
```

**TASK ID is REQUIRED in prompt.** Lead updates task status after teammate returns.

## Skill Loading Hierarchy (DEFINITIVE)

**Two mechanisms exist:**

### 1. Agent Definition `skills:` (PRELOAD - Automatic)
```yaml
# In agent .md frontmatter:
skills: cc100x:session-memory, cc100x:verification
```
- Loaded AUTOMATICALLY when agent starts
- Full skill content injected into agent context
- Agent does NOT need to call `Skill()` for these
- **This is the PRIMARY mechanism for all CC100x internal skills**

**Agent Teams difference:** Unlike CC10x subagents, Agent Teams teammates CAN see CLAUDE.md + project skills. This means project-level skills from `plugins/cc100x/skills/` are already available to teammates. SKILL_HINTS is still needed for:
- Conditional skills (e.g., `github-research` only when research triggers fire)
- User-global skills from `~/.claude/CLAUDE.md` Complementary Skills table

### 2. Lead's SKILL_HINTS (Conditional - On Demand)
- Lead passes SKILL_HINTS for skills not loaded via agent frontmatter
- **Source 1:** Lead detection table — `github-research` when research triggers fire
- **Source 2:** CLAUDE.md Complementary Skills table — domain skills matching task signals
- Agent calls `Skill(skill="{name}")` for each skill in SKILL_HINTS after memory load
- If a skill fails to load (not installed), agent notes it in Memory Notes and continues

**Skill triggers for teammates (DETECT AND PASS AS SKILL_HINTS):**

| Detected Pattern | Skill | Agents |
|------------------|-------|--------|
| **BUILD workflow** (any build/implement/create) | `cc100x:test-driven-development`, `cc100x:code-generation`, `cc100x:architecture-patterns`, `cc100x:frontend-patterns` | builder |
| **REVIEW workflow** (any review/audit/check) | `cc100x:code-review-patterns`, `cc100x:architecture-patterns`, `cc100x:frontend-patterns` | security-reviewer, performance-reviewer, quality-reviewer |
| **BUILD live loop** (real-time Pair Build feedback) | `cc100x:code-review-patterns`, `cc100x:architecture-patterns`, `cc100x:frontend-patterns` | live-reviewer |
| **BUILD post-hunt comprehensive review** | `cc100x:code-review-patterns`, `cc100x:architecture-patterns`, `cc100x:frontend-patterns` | security-reviewer, performance-reviewer, quality-reviewer |
| **DEBUG post-fix comprehensive review** | `cc100x:code-review-patterns`, `cc100x:architecture-patterns`, `cc100x:frontend-patterns` | security-reviewer, performance-reviewer, quality-reviewer |
| **DEBUG workflow** (any debug/fix/error) | `cc100x:debugging-patterns`, `cc100x:architecture-patterns`, `cc100x:frontend-patterns` | investigator |
| **PLAN workflow** (any plan/design/architect) | `cc100x:planning-patterns`, `cc100x:brainstorming`, `cc100x:architecture-patterns`, `cc100x:frontend-patterns` | planner |
| **BUILD/DEBUG post-build** (hunter phase) | `cc100x:code-review-patterns`, `cc100x:architecture-patterns`, `cc100x:frontend-patterns` | hunter |
| **BUILD/DEBUG post-verification** (verifier phase) | `cc100x:debugging-patterns`, `cc100x:architecture-patterns`, `cc100x:frontend-patterns` | verifier |
| External: new tech, unfamiliar library, complex integration | `cc100x:github-research` | planner, investigator |
| Debug exhausted: 3+ local attempts failed, external service error | `cc100x:github-research` | investigator |
| User explicitly requests: "research", "github", "octocode", "best practices" | `cc100x:github-research` | planner, investigator |

**Detection runs BEFORE agent invocation. Pass detected skills in SKILL_HINTS.**

**Workflow-based skills are ALWAYS passed for the matching workflow/stage.** They are not conditional — every BUILD gets TDD+code-gen, every REVIEW and post-fix/post-hunt comprehensive review gate gets code-review-patterns, etc. This mirrors CC10x's guaranteed quality coverage while preserving Agent Teams structure.

**Note:** `cc100x:router-contract`, `cc100x:verification`, and `cc100x:session-memory` are NOT in this table because they load via agent frontmatter (unconditional). Every agent gets router-contract + verification; builder/planner also load session-memory for memory read discipline and Memory Notes structure. These do NOT need SKILL_HINTS.

**Also check CLAUDE.md Complementary Skills table and include matching skills in SKILL_HINTS.**

---

## Artifact Governance (MANDATORY)

CC100x workflows are message-first. Teammates should not create ad-hoc report files.

Approved durable artifact paths:
- `docs/plans/` (planner output)
- `docs/research/` (lead research persistence)
- `docs/reviews/` (only when user explicitly requests a saved review file)

Forbidden by default:
- Root-level teammate reports like `CHALLENGE_ROUND_*.md`, `SECURITY_REVIEW*.md`, `ROUTER_CONTRACT*.json`
- Any unrequested `*.md`, `*.json`, `*.txt` report artifact outside approved paths

Enforcement rules:
1. If teammate output claims "created/saved/wrote file" for an unauthorized path:
   - create `CC100X REM-EVIDENCE: unauthorized artifact claim`
   - block downstream tasks
   - request corrected output with inline findings + Router Contract only
2. Lead may allow exceptions only with explicit user instruction (record decision in memory).

---

## Post-Team Validation (Router Contract)

After each teammate completes (or team finishes), validate using Router Contracts:

### Step 1: Check for Router Contract
```
Look for "### Router Contract (MACHINE-READABLE)" section in teammate output.
If found → Use contract-based validation below.
If NOT found → Teammate output is non-compliant. Create REM-EVIDENCE task:
  TaskCreate({
    subject: "CC100X REM-EVIDENCE: {teammate} missing Router Contract",
    description: "Teammate output lacks Router Contract section. Re-run teammate or manually verify output quality.",
    activeForm: "Collecting teammate contract"
  })
  Block downstream tasks and STOP.
```

### Step 1.5: Validate Artifact Claims
```
Scan teammate output for file-creation claims ("created", "saved", "wrote", "exported").
If a claimed artifact path exists:
  - ensure path is in approved durable paths or explicitly user-approved
If claim is unauthorized OR path is missing:
  TaskCreate({
    subject: "CC100X REM-EVIDENCE: unauthorized artifact claim",
    description: "Teammate claimed artifact outside approved paths or missing file evidence.",
    activeForm: "Validating artifact claims"
  })
  Block downstream tasks and STOP.
```

### Step 2: Parse and Validate Contract
```
Parse the YAML block inside Router Contract section.

CONTRACT FIELDS:
- STATUS: Teammate's self-reported status (PASS/FAIL/APPROVE/etc)
- BLOCKING: true/false - whether workflow should stop
- REQUIRES_REMEDIATION: true/false - whether REM-FIX task needed
- REMEDIATION_REASON: Exact text for remediation task description
- CRITICAL_ISSUES: Count of blocking issues (if applicable)
- MEMORY_NOTES: Structured notes for workflow-final persistence

VALIDATION RULES:

**Circuit Breaker (BEFORE creating any REM-FIX):**
Before creating a new REM-FIX task, count existing REM-FIX tasks in workflow.
If count ≥ 3 → AskUserQuestion:
- **Research best practices (Recommended)** → Execute external research, persist, retry
- **Fix locally** → Create another REM-FIX task
- **Skip** → Proceed despite errors (not recommended)
- **Abort** → Stop workflow, manual fix

1. If contract.BLOCKING == true OR contract.REQUIRES_REMEDIATION == true:
   → Remediation task naming is STRICT:
     - use subject prefix `CC100X REM-FIX:`
     - do NOT use alternate names in new runs
   → TaskCreate({
       subject: "CC100X REM-FIX: {teammate_name}",
       description: contract.REMEDIATION_REASON,
       activeForm: "Fixing {teammate_name} issues"
     })
   → Task-enforced gate:
     - Find downstream workflow tasks via TaskList() (subjects prefixed with `CC100X `)
     - For every downstream task not completed:
       TaskUpdate({ taskId: downstream_task_id, addBlockedBy: [remediation_task_id] })
   → STOP. Do not invoke next teammate until remediation completes.
   → User can bypass (record decision in memory).

2. If contract.CRITICAL_ISSUES > 0 AND parallel phase (multiple reviewers):
   → Conflict check: If one reviewer APPROVE AND another has CRITICAL_ISSUES > 0:
     AskUserQuestion: "Reviewer approved, but {other} found {N} critical issues. Investigate or Skip?"
     - If "Investigate" → Create REM-FIX for critical issues
     - If "Skip" → Proceed (record decision in memory)
   → If no conflict and CRITICAL_ISSUES > 0: treat as blocking (rule 1)

3. Collect contract.MEMORY_NOTES for workflow-final persistence

4. If none of above triggered → Proceed to next task
```

### Step 3: Output Validation Evidence
```
### Agent Validation: {teammate_name}
- Router Contract: Found
- STATUS: {contract.STATUS}
- BLOCKING: {contract.BLOCKING}
- CRITICAL_ISSUES: {contract.CRITICAL_ISSUES}
- Proceeding: [Yes/No + reason]
```

---

## Remediation Re-Review Loop

```
WHEN any remediation task COMPLETES
(`CC100X REM-FIX:` OR legacy `CC100X REMEDIATION:`):
  │
  ├─→ 1. TaskCreate({ subject: "CC100X security-reviewer: Re-review after remediation" })
  │      → Returns re_sec_id
  │
  ├─→ 2. TaskCreate({ subject: "CC100X performance-reviewer: Re-review after remediation" })
  │      → Returns re_perf_id
  │
  ├─→ 3. TaskCreate({ subject: "CC100X quality-reviewer: Re-review after remediation" })
  │      → Returns re_qual_id
  │
  ├─→ 4. TaskCreate({ subject: "CC100X Remediation Review Arena: Challenge round" })
  │      → Returns re_challenge_id
  │      TaskUpdate({ taskId: re_challenge_id, addBlockedBy: [re_sec_id, re_perf_id, re_qual_id] })
  │
  ├─→ 5. TaskCreate({ subject: "CC100X hunter: Re-hunt after remediation" })
  │      → Returns re_hunter_id
  │
  ├─→ 6. Find verifier task:
  │      TaskList() → Find task where subject contains "verifier"
  │      → verifier_task_id
  │
  ├─→ 7. Block verifier on re-reviews:
  │      TaskUpdate({ taskId: verifier_task_id, addBlockedBy: [re_challenge_id, re_hunter_id] })
  │
  └─→ 8. Resume execution (re-reviews run before verifier)
```

**Why:** Code changes must be re-reviewed before shipping (orchestration integrity).

---

## Workflow Structural Integrity Guard (MANDATORY)

Run this guard before starting execution and again before starting verifier tasks.

### BUILD required task subjects
- `CC100X builder:`
- `CC100X live-reviewer:`
- `CC100X hunter:`
- `CC100X security-reviewer:`
- `CC100X performance-reviewer:`
- `CC100X quality-reviewer:`
- `CC100X BUILD Review Arena: Challenge round`
- `CC100X verifier:`
- `CC100X Memory Update:`

### Required BUILD blockers
- hunter blocked by builder
- each reviewer blocked by hunter
- challenge blocked by all 3 reviewers
- verifier blocked by challenge
- memory update blocked by verifier

If any required task or blocker is missing:
- create/fix the missing task dependency BEFORE execution continues
- never shortcut directly from hunter/remediation to verifier

### Remediation integrity
- Canonical remediation task prefix is `CC100X REM-FIX:`.
- Legacy prefix `CC100X REMEDIATION:` may appear in older runs; treat it as remediation too.
- Any remediation completion must trigger re-review triad + remediation challenge + re-hunt, then re-block verifier.

---

## Team Execution Loop

**NEVER stop after one teammate.** The workflow is NOT complete until ALL tasks are completed.

### Execution Loop

```
-1. Preflight gate:
   - Confirm Agent Teams is enabled and current session has no stale active team.
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
     - **Lead-owned tasks** (`... Challenge round`, `CC100X Memory Update`) run in lead context
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
   - If none ready AND uncompleted tasks exist → Wait for teammates
   - If ALL workflow tasks completed → run TEAM_SHUTDOWN gate (do not mark workflow done yet)

5. Repeat until:
   - All tasks have status="completed" (INCLUDING the Memory Update task)
   - TEAM_SHUTDOWN gate succeeded (`shutdown_request` sent/approved + `TeamDelete()` completed)
   - OR critical error detected (create error task, halt)

**CRITICAL:** Workflow completion requires BOTH:
1. `CC100X Memory Update` task completed
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

When parallel teammates complete (e.g., 3 reviewers in Review Arena), their outputs must be collected and cross-referenced.

### Pattern: Collect and Pass Findings

```
# After all parallel teammates complete:
1. TaskList()  # Verify all show "completed"

2. Collect outputs from teammate messages:
   REVIEWER_1_FINDINGS = {security-reviewer's Critical Issues + Verdict}
   REVIEWER_2_FINDINGS = {performance-reviewer's Critical Issues + Verdict}
   REVIEWER_3_FINDINGS = {quality-reviewer's Critical Issues + Verdict}

3. For Challenge Round: Share each reviewer's findings with the others via peer messaging:
   SendMessage(type="message", recipient="security-reviewer",
     content="Here are findings from other reviewers: {REVIEWER_2_FINDINGS + REVIEWER_3_FINDINGS}. Challenge or agree?")
   # Repeat for other reviewers

4. For downstream teammates (e.g., verifier after hunt + review challenge):
   Include ALL findings in teammate prompt:
   "## Previous Findings\n### Hunter\n{HUNTER_FINDINGS}\n### Reviewer\n{REVIEWER_FINDINGS}"

5. Before invoking verifier, run a contract-diff checkpoint:
   - Compare upstream contract claims vs downstream usage assumptions
   - If mismatch exists, create `CC100X REM-FIX:` task and block verifier
   - Only invoke verifier when contract diff is clean
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

Memory persistence is enforced via the "CC100X Memory Update" task in the task hierarchy.

**When you see this task become available:**
1. Review teammate outputs for `### Memory Notes` sections
2. Follow the task description to persist learnings
3. Use Read-Edit-Read pattern for each memory file
4. Mark task completed

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
   TaskList() → Find existing tasks with subject starting "CC100X TODO:"
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
5. **Teammates CAN see CLAUDE.md + project skills.** Unlike CC10x subagents, Agent Teams teammates load CLAUDE.md and project-level skills automatically.
6. **No synchronization primitives.** Pair Build's builder-reviewer sync uses message-based polling, not blocking waits.
7. **Delegate mode is MANDATORY.** Lead must enter delegate mode (Shift+Tab) after team creation to prevent accidentally implementing code.
8. **Token cost awareness.** Agent Teams uses significantly more tokens than single-agent workflows. Each teammate has its own context window. Minimize unnecessary parallel spawns — only parallelize when the protocol requires it (e.g., 3 reviewers in Review Arena, multiple investigators in Bug Court).
9. **One team at a time per session.** Clean up current team before starting a new one in the same session.
10. **Lead is fixed for team lifetime.** The creator session remains the lead; do not assume leadership transfer to teammates.
11. **Permission inheritance at spawn.** Teammates start with lead permission mode; per-teammate permission tuning can only happen after spawn.
12. **Broadcast sparingly.** Prefer targeted `message` over `broadcast`; broadcast token cost scales with team size.

## Agent Teams Display & Controls

| Action | Shortcut | When to Use |
|--------|----------|-------------|
| Enter delegate mode | **Shift+Tab** | After team creation (MANDATORY) |
| Select teammate to view | **Shift+Up/Down** | Monitor teammate progress |
| Toggle task list | **Ctrl+T** | Check task status during workflow |
| Interrupt teammate | **Escape** | Stop a teammate that's stuck or off-track |

## Optional Hook-Driven Quality Gates (Disabled By Default)

CC100x core orchestration MUST work without hooks.

If a project explicitly opts in, Agent Teams hooks can add extra enforcement:
- `TeammateIdle`: if a teammate goes idle without Router Contract or while task still needs evidence, return exit code `2` with corrective feedback.
- `TaskCompleted`: block task completion (exit code `2`) when contract fields are missing, malformed, or blocking remediation is unresolved.

Minimal optional policy:
1. Reject completion if Router Contract section is missing.
2. Reject completion if `BLOCKING=true` and no REM-FIX task exists.
3. Reject completion if `SPEC_COMPLIANCE=FAIL` without explicit user skip decision logged.

Default stance: keep hooks off unless user explicitly enables and validates them.

## Model Selection Guidance

Quality-first default (CC100x pre-production hardening): use `inherit` for every teammate.

| Teammate | Quality-First (Default) | Balanced Override (Optional) |
|----------|--------------------------|-------------------------------|
| builder | `inherit` | `inherit` |
| investigator | `inherit` | `inherit` |
| planner | `inherit` | `inherit` |
| security-reviewer | `inherit` | `inherit` |
| performance-reviewer | `inherit` | `sonnet` |
| quality-reviewer | `inherit` | `sonnet` |
| live-reviewer | `inherit` | `sonnet` |
| hunter | `inherit` | `sonnet` |
| verifier | `inherit` | `sonnet` |

**Override rule:** If any teammate misses issues, immediately re-run that stage with `inherit`.

## Self-Claim Mode (Explicit Opt-In Only)

Default is **disabled** to preserve deterministic role routing.

Only enable self-claim when:
- Task descriptions are fully role-agnostic
- Role-specific sequencing is not required
- User explicitly asks for autonomous claiming

When enabled, teammates can self-claim unblocked tasks:

```
After completing a task:
1. Teammate calls TaskList()
2. Finds task with status="pending", no owner, empty blockedBy
3. Claims via TaskUpdate({ taskId, owner: "{my-name}", status: "in_progress" })
4. Notifies lead: "Claimed task: {subject}"
```

Task claiming is lock-safe in Agent Teams (file-lock protected), so simultaneous claim attempts resolve without duplicate ownership.

**When not to enable:** BUILD/DEBUG phases with specialized roles (builder, investigators, reviewers, verifier). These should stay lead-assigned.

---

## Gates (Must Pass)

1. **AGENT_TEAMS_READY** - Agent Teams enabled; no stale active team in session
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
13. **TEAM_SHUTDOWN** - Send shutdown_request to all teammates, wait for approvals, TeamDelete()

---

## Team Shutdown (Gate #13)

After workflow completes AND memory is updated:
1. Send `shutdown_request` to each teammate via `SendMessage(type="shutdown_request", recipient="{name}")`
2. Wait for shutdown approvals from all teammates
3. If teammate rejects shutdown → check unfinished work, resolve, retry
4. Retry shutdown loop up to 3 attempts with short backoff (for slow tool completion)
5. After approvals → `TeamDelete()` to clean up team resources
6. If `TeamDelete()` fails, retry up to 3 times and keep workflow open
7. Report final results to user only after cleanup succeeds

**Do not finalize early:** Never report workflow as complete while teammates are still active or team resources still exist.

**Team Naming Convention:** `cc100x-{workflow}-{YYYYMMDD-HHMMSS}`
Example: `cc100x-build-20260206-143022`, `cc100x-debug-20260206-150000`

---

## Key Rules

1. **Lead NEVER implements code** - delegate mode always
2. **Every teammate outputs a Router Contract** - YAML at end of output
3. **Every workflow reads memory first** - `.claude/cc100x/`
4. **Teammates own file sets** - no two teammates edit the same file
5. **READ-ONLY agents** include Memory Notes for lead to persist
6. **Lead owns memory persistence by default**; teammates provide Memory Notes unless explicitly assigned `MEMORY_OWNER: teammate`
7. **Wait for teammates** - never implement while teammates are working
8. **All skill references** use `cc100x:` prefix
9. **No nested teams** - reuse existing team for sub-workflows
10. **Memory anchor integrity** - never rename section headers used as Edit anchors
