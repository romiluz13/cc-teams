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

**EXECUTION ENGINE.** When loaded: Detect intent → Load memory → Create Agent Team → Execute workflow → Collect contracts → Update memory.

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

**Orphan check:** If any CC100X task has status="in_progress" → Ask user: Resume (reset to pending) / Complete (skip) / Delete.

**If active CC100x workflow task exists (subject starts with `CC100X `):**
- Resume from task state (use `TaskGet({ taskId })` for the task you plan to resume)
- Skip workflow selection - continue execution from where it stopped
- Check `blockedBy` to determine which teammate to run next

**Safety rule (avoid cross-project collisions):**
- If you find tasks that do NOT clearly belong to CC100x, do not resume them.
- If unsure, ask the user whether to resume or create a fresh task hierarchy.

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

---

## Session Interruption Recovery (Agent Teams)

**Problem:** `/resume` does NOT restore teammates. If session interrupted mid-workflow, teammates are gone.

**Detection:** At session start, if memory shows an active workflow but TaskList shows in-progress tasks with no running teammates:
1. Read team config at `~/.claude/teams/{team-name}/config.json`
2. If team config is missing or members list is empty → teammates were lost
3. Check which tasks are still pending/in-progress

**Recovery Protocol:**
1. Preserve all existing task state (don't delete tasks)
2. Re-create the Agent Team with same name
3. Re-spawn only the teammates needed for remaining tasks
4. Pass context from task descriptions + memory files to re-spawned teammates
5. Resume execution from where it stopped

**Prevention:** For long-running workflows (Bug Court multi-round, Pair Build multi-module), trigger pre-compaction memory checkpoint every 30+ tool calls.

---

## Task-Based Orchestration

**At workflow start, create task hierarchy using TaskCreate/TaskUpdate.**

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

# One task per hypothesis
TaskCreate({
  subject: "CC100X investigator-1: Test hypothesis - {h1}",
  description: "Champion hypothesis: '{h1}'\nGather evidence FOR this hypothesis. Try to PROVE it's the root cause.\nAlso gather evidence that could DISPROVE other hypotheses.\nError context: {error_details}\nMemory patterns: {common_gotchas}\n\nYou are READ-ONLY. Do NOT edit source code.\nOutput Router Contract at end.",
  activeForm: "Investigating hypothesis 1"
})
# Returns inv1_task_id

TaskCreate({
  subject: "CC100X investigator-2: Test hypothesis - {h2}",
  description: "[same structure as investigator-1 with h2]",
  activeForm: "Investigating hypothesis 2"
})
# Returns inv2_task_id

TaskCreate({
  subject: "CC100X investigator-3: Test hypothesis - {h3}",
  description: "[same structure as investigator-1 with h3]",
  activeForm: "Investigating hypothesis 3"
})
# Returns inv3_task_id

TaskCreate({
  subject: "CC100X Bug Court: Debate round",
  description: "Share evidence between investigators. Each tries to disprove others.\nDetermine winning hypothesis based on strongest evidence + least counter-evidence.",
  activeForm: "Running debate round"
})
# Returns debate_task_id
TaskUpdate({ taskId: debate_task_id, addBlockedBy: [inv1_task_id, inv2_task_id, inv3_task_id] })

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
4. **Create task hierarchy** (see Task-Based Orchestration above)
5. **Create Agent Team** → Spawn teammates
6. **Start execution** (see Team Execution Loop below)
7. Update memory when all tasks completed

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
5. **Create task hierarchy** (see Task-Based Orchestration above)
6. **Create Agent Team** → Spawn investigators
7. **Start execution** (pass research file path if step 3 was executed)
8. Update memory → Add root cause to Common Gotchas when all tasks completed

### REVIEW
1. Load memory
2. **CLARIFY (REQUIRED)**: Use AskUserQuestion to confirm scope:
   - Review entire codebase OR specific files?
   - Focus area: security/performance/quality/all?
   - Blocking issues only OR all findings?
3. **Create task hierarchy** (see Task-Based Orchestration above)
4. **Create Agent Team** → Spawn 3 reviewers
5. **Start execution** (see Team Execution Loop below)
6. Update memory when all tasks completed

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

4. **Create task hierarchy** (see Task-Based Orchestration above)
5. **Invoke planner with Plan Approval Mode** (pass research results + file path if step 3 was executed)
6. **Review plan** → Approve or reject via plan_approval_response
7. Update memory → Reference saved plan when task completed

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
- If your tools include `Edit` **and you are not running in a parallel phase**, update `.claude/cc100x/{activeContext,patterns,progress}.md` at the end per `cc100x:session-memory` and `Read(...)` back to verify.
- If you are running in a parallel phase (e.g., Review Arena, Bug Court investigation), prefer **no memory edits**; include a clearly labeled **Memory Notes** section so the lead can persist safely after parallel completion.
- If your tools do NOT include `Edit`, you MUST include a `### Memory Notes (For Workflow-Final Persistence)` section with:
  - **Learnings:** [insights for activeContext.md]
  - **Patterns:** [gotchas for patterns.md]
  - **Verification:** [results for progress.md]

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

**Note:** `cc100x:router-contract`, `cc100x:verification`, and `cc100x:session-memory` are NOT in this table because they load via agent frontmatter (unconditional). Every agent gets router-contract + verification; WRITE agents (builder, planner) additionally get session-memory. These do NOT need SKILL_HINTS.

**Also check CLAUDE.md Complementary Skills table and include matching skills in SKILL_HINTS.**

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
WHEN any CC100X REM-FIX task COMPLETES:
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

## Team Execution Loop

**NEVER stop after one teammate.** The workflow is NOT complete until ALL tasks are completed.

### Execution Loop

```
0. Enter delegate mode (FIRST):
   Press **Shift+Tab** after team creation.
   Lead MUST be in delegate mode before assigning ANY tasks.
   This prevents lead from accidentally implementing code.

1. Find runnable tasks:
   TaskList() → Find tasks where:
   - status = "pending"
   - blockedBy is empty OR all blockedBy tasks are "completed"

2. Start teammate(s):
   - TaskUpdate({ taskId: runnable_task_id, status: "in_progress" })
   - Classify task owner:
     - **Lead-owned tasks** (`... Challenge round`, `CC100X Memory Update`) run in lead context
     - **Teammate tasks** are assigned via message with task context (see Agent Invocation Template)
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
   - If ALL tasks completed → Workflow complete

5. Repeat until:
   - All tasks have status="completed" (INCLUDING the Memory Update task)
   - OR critical error detected (create error task, halt)

**CRITICAL:** The workflow is NOT complete until the "CC100X Memory Update" task is completed.
This ensures Memory Notes from READ-ONLY teammates are persisted even if context compacted.
```

### Task Status Lag (Agent Teams)

Teammates sometimes forget to mark tasks completed or report status. Lead must:
- After sending work to a teammate, check back periodically
- If teammate goes idle without completing task → send nudge message
- If teammate is unresponsive → check task output, mark task manually if work is done

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

## Hook-Driven Quality Gates (Recommended)

Use Agent Teams hooks to enforce workflow integrity without manual polling:

- `TeammateIdle`: if a teammate goes idle without Router Contract or while task still needs evidence, return exit code `2` with corrective feedback.
- `TaskCompleted`: block task completion (exit code `2`) when contract fields are missing, malformed, or blocking remediation is unresolved.

Minimal policy:
1. Reject completion if Router Contract section is missing.
2. Reject completion if `BLOCKING=true` and no REM-FIX task exists.
3. Reject completion if `SPEC_COMPLIANCE=FAIL` without explicit user skip decision logged.

This keeps lead orchestration deterministic and prevents silent task drift.

## Model Selection Guidance

When spawning teammates, model selection affects cost and capability:

| Teammate | Recommended Model | Rationale |
|----------|-------------------|-----------|
| builder | `inherit` (Opus) | Needs full capability for TDD + implementation |
| investigator | `inherit` (Opus) | Complex reasoning for hypothesis testing |
| planner | `inherit` (Opus) | Architecture decisions need deep understanding |
| security-reviewer | `inherit` (Opus) | Security analysis requires thoroughness |
| performance-reviewer | `sonnet` | Performance patterns are more formulaic |
| quality-reviewer | `sonnet` | Pattern matching is well-suited for Sonnet |
| live-reviewer | `sonnet` | Quick feedback loop, doesn't need full Opus |
| hunter | `sonnet` | Scan patterns are systematic, not creative |
| verifier | `sonnet` | Test running and evidence collection |

**Override rule:** If a teammate is struggling (e.g., missing issues), re-spawn with `inherit` (Opus).

## Self-Claim Mode (Optional Optimization)

In addition to lead-assigned task ownership, teammates can self-claim unblocked tasks:

```
After completing a task:
1. Teammate calls TaskList()
2. Finds task with status="pending", no owner, empty blockedBy
3. Claims via TaskUpdate({ taskId, owner: "{my-name}", status: "in_progress" })
4. Notifies lead: "Claimed task: {subject}"
```

Task claiming is lock-safe in Agent Teams (file-lock protected), so simultaneous claim attempts resolve without duplicate ownership.

**When to enable:** For experienced teams where task descriptions are self-contained. Lead can disable by explicitly assigning all tasks upfront.

---

## Gates (Must Pass)

1. **MEMORY_LOADED** - Before routing
2. **TASKS_CHECKED** - Check TaskList() for active workflow
3. **INTENT_CLARIFIED** - User intent is unambiguous (all workflows)
4. **RESEARCH_EXECUTED** - Before planner (if research trigger detected)
5. **RESEARCH_PERSISTED** - Save to docs/research/ + update activeContext.md (if research was executed)
6. **REQUIREMENTS_CLARIFIED** - Before invoking teammates (BUILD only)
7. **TASKS_CREATED** - Workflow task hierarchy created
8. **TEAM_CREATED** - Agent Team spawned for workflow
9. **CONTRACTS_VALIDATED** - Validate Router Contract before marking each teammate task completed
10. **ALL_TASKS_COMPLETED** - All tasks (including Memory Update) status="completed"
11. **MEMORY_UPDATED** - Before marking done
12. **TEAM_SHUTDOWN** - Send shutdown_request to all teammates, wait for approvals, TeamDelete()

---

## Team Shutdown (Gate #12)

After workflow completes AND memory is updated:
1. Send `shutdown_request` to each teammate via `SendMessage(type="shutdown_request", recipient="{name}")`
2. Wait for shutdown approvals from all teammates
3. If teammate rejects shutdown → check if they have unfinished work, resolve, retry
4. After all approvals received → `TeamDelete()` to clean up team resources
5. Report results to user

**Team Naming Convention:** `cc100x-{workflow}-{YYYYMMDD-HHMMSS}`
Example: `cc100x-build-20260206-143022`, `cc100x-debug-20260206-150000`

---

## Key Rules

1. **Lead NEVER implements code** - delegate mode always
2. **Every teammate outputs a Router Contract** - YAML at end of output
3. **Every workflow reads memory first** - `.claude/cc100x/`
4. **Teammates own file sets** - no two teammates edit the same file
5. **READ-ONLY agents** include Memory Notes for lead to persist
6. **WRITE agents** update memory directly
7. **Wait for teammates** - never implement while teammates are working
8. **All skill references** use `cc100x:` prefix
9. **No nested teams** - reuse existing team for sub-workflows
10. **Memory anchor integrity** - never rename section headers used as Edit anchors
