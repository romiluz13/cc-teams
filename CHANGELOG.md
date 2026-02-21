# Changelog

## [0.1.18] - 2026-02-22

### Added

**Specialist Reviewer Agents (conditional)**
- `accessibility-reviewer`: WCAG 2.1 AA audit agent — 10-point checklist (keyboard nav, ARIA, color contrast, semantic HTML, focus management, touch targets, screen reader). Spawned when UI files detected in FILES_MODIFIED. A11y wins on CRITICAL (regulatory compliance).
- `api-contract-reviewer`: API breaking-change detector — 9-point checklist (removed endpoints, schema diffs, type incompatibility, auth/status code changes). Spawned when API route files detected. API contract wins on CRITICAL (client-facing impact).

**Cross-Layer BUILD Workflow**
- `frontend-builder` agent: TDD builder owning frontend scope (components/pages/hooks/styles), with isolation: worktree and frontend-patterns skill hints. Implements against verified API contract.
- `backend-builder` agent: TDD builder owning backend scope (api/services/models/db), with isolation: worktree and architecture-patterns skill hints. Publishes API_CONTRACT_SPEC in Memory Notes.
- `cross-layer-build` skill: Full protocol for parallel frontend+backend implementation — contract-first relay (backend defines API, lead validates, frontend implements), async live-review (both builders complete before review), file conflict gate.
- Async live-reviewer mode in cross-layer: reviews ALL changes from BOTH builders post-completion (eliminates per-module blocking that would serialize parallel builders)
- accessibility-reviewer and api-contract-reviewer ALWAYS spawn in cross-layer BUILD (both frontend and API are guaranteed)

**Pre-Spawn Optimization**
- Downstream agents now pre-spawned with blocked tasks when their predecessor STARTS (not finishes)
- hunter pre-spawned when builder task starts → executes immediately when builder finishes
- review triad + conditional reviewers pre-spawned when hunter starts → execute immediately
- verifier pre-spawned when review tasks start → executes immediately when challenge completes
- Eliminates 1-2 turn spawn latency between phases with zero quality trade-off (blocked agents are idle: no output, no token cost)

**Persistent Agent Memory**
- `investigator`: `memory: project` — accumulates codebase-specific bug patterns and root cause knowledge across sessions (additive to .claude/cc-teams/ workflow memory)
- `security-reviewer`: `memory: user` — accumulates vulnerability patterns across ALL codebases reviewed (cross-project security intelligence)

**Planner Worktree Isolation**
- `planner`: `isolation: worktree` — plan file writes are now branch-isolated (WorktreeCreate hook syncs .claude/cc-teams/ memory to new worktree)

**Cross-Layer Detection in BUILD**
- Lead auto-detects cross-layer when requirements mention both frontend (UI/components) and backend (API/services)
- Routes to BUILD-CROSSLAYER task template and cross-layer-build skill automatically

## [0.1.17] - 2026-02-22

### Fixed
- **Planner plan-mode escalation** — removed invalid `SendMessage(recipient: "lead")` (not a valid
  Agent Teams name); planner now outputs BLOCKED as plain text and goes idle (idle notification
  carries it to lead automatically per Agent Teams spec)
- **Planner probe race condition** — `.probe` file now uses PID-unique temp name `$$` to prevent
  false plan-mode detection when two planners run in the same repo simultaneously
- **Memory Update blocked forever** — added MEMORY UPDATE ESCAPE HATCH to escalation ladder:
  when verifier is declared CRITICAL/stalled, lead manually unblocks Memory Update and persists
  partial learnings rather than silently losing the entire workflow's learnings
- **Hunter no SendMessage** — added `SendMessage` to hunter tools (lint-compatible); hunter can
  now proactively signal BLOCKED to lead mid-task
- **Verifier no SendMessage** — added `SendMessage` to verifier tools; same fix as hunter
- **Orphan sweep silent deletion** — replaced auto-delete of sibling workflow trees with
  `AskUserQuestion` (mark as pending/archived, not deleted); only delete on explicit user confirmation
- **All-investigators-BLOCKED deadlock** — added All-Investigators-BLOCKED Exit Path to Bug Court
  Phase 3: AskUserQuestion with three options (new hypotheses / user-provided fix / abort spike)
- **TEAM_SHUTDOWN retry loop unbound** — capped at one rejection attempt per teammate;
  non-task rejections ask user immediately instead of retrying forever
- **Pre-compaction "30+ tool calls" unenforced** — replaced with reference to PreCompact hook
  (CC-TEAMS COMPACT_CHECKPOINT marker in progress.md is the actual trigger, not a call count)
- **Synthesized contract BLOCKING undefined** — added conservative merge rules table to
  router-contract/SKILL.md: BLOCKING=true if ANY contract is blocking; CONFIDENCE=min of all
- **Debate round limit unenforced** — added explicit round counter + broadcast close signal
  at round 3 in Bug Court Phase 3 lead actions
- **Confidence weighting undefined** — replaced "weighted by severity" with "minimum of 3 scores
  (weakest-link principle)" in Review Arena unified contract
- **npm audit silent fail on missing jq** — added `command -v jq` check before piping in verifier;
  falls back to text grep when jq unavailable
- **Investigator premature challenge messages** — added "WAIT FOR LEAD SIGNAL" gate before
  Challenging section in investigator.md; challengers must wait for lead's debate-open message
- **Builder Router Handoff inconsistency** — added PHASE_GATE_RESULT and PHASE_GATE_CMD to
  Router Handoff (Stable Extraction) section to match the YAML contract block
- **Reviewer unlimited challenge messages** — added one-response discipline to all 3 reviewer
  agents: one AGREE/DISAGREE/ESCALATE response per challenge round, no unilateral extensions
- **Teammate-idle hook stale version** — updated CONTRACT_VERSION 2.3 → 2.4 in error message
- **Handoff payload missing teammate_roster** — added teammate_roster field (spawned,
  pending_spawn, completed) to canonical handoff payload template for reliable session resume

## [0.1.16] - 2026-02-22

### Added
- **Per-Agent Spawn Context Requirements** (cc-teams-lead/SKILL.md)
  - Each agent type now has a canonical list of REQUIRED fields the lead must include at spawn
  - builder: TECH_STACK, TEST_CMD, BUILD_CMD, SCOPE, REQUIREMENTS
  - investigator: ASSIGNED_HYPOTHESIS, CONFIDENCE, NEXT_TEST, ERROR_CONTEXT, REPRODUCTION, GIT_CONTEXT, ALL_HYPOTHESES
  - reviewer triad: SCOPE, FOCUS, BLOCKING_ONLY, AUTH_METHOD, SENSITIVE_FILES
  - verifier: TEST_CMD, BUILD_CMD, HUNTER_FINDINGS, REVIEWER_FINDINGS, PLAN_EXIT_CRITERIA, PHASE_GATE_CMD
  - planner: RESEARCH_SUMMARY, EXISTING_PATTERNS, PRIOR_DECISIONS, REQUIREMENTS
- **Dependency Security audit** (security-reviewer.md, verifier.md)
  - security-reviewer: read-only lock file + package.json scan (no Bash required), DEPENDENCY_AUDIT contract field
  - verifier: `npm audit --json` added to verification commands, DEPENDENCY_AUDIT + DEPENDENCY_AUDIT_DETAIL in contract
  - DEPENDENCY_AUDIT=FAIL (high/critical vulns found) → BLOCKING=true in verifier contract
- **Phase Gate Commands** (planner.md, planning-patterns/SKILL.md, builder.md, cc-teams-lead/SKILL.md)
  - Planner Plan Format adds `**Gate Command:**` field per phase (exit criteria become executable)
  - planning-patterns phase TaskCreate description now includes Gate Command field
  - Builder Verify step runs gate_command if plan specifies one; captures PHASE_GATE_RESULT
  - Lead contract validation blocks on PHASE_GATE_RESULT=FAIL or DEPENDENCY_AUDIT=FAIL
- **Router Contract v2.4** — new fields: PHASE_GATE_RESULT, PHASE_GATE_CMD (builder);
  DEPENDENCY_AUDIT, DEPENDENCY_AUDIT_DETAIL (verifier + security-reviewer)

## [0.1.15] - 2026-02-22

### Added
- **Hook Infrastructure** (`plugins/cc-teams/hooks/`, `plugins/cc-teams/settings.json`)
  - `TeammateIdle` hook: enforces Router Contract YAML presence before any agent goes idle
  - `TaskCompleted` hook: validates `CC-TEAMS Memory Update` task has real memory files
  - `WorktreeCreate` hook: syncs `.claude/cc-teams/` memory to new builder worktree
  - `PreCompact` hook: writes compact checkpoint marker to `progress.md`
  - `settings.json`: plugin-level hook registration (auto-activates on Claude Code v2.1.49+)
- **Worktree isolation for builder** (`isolation: worktree` in agent frontmatter)
  - Builder now runs in an isolated git worktree during BUILD workflows
  - Eliminates file conflict risk for long-running or parallel build sessions
- **`activeForm` convention** documented in task templates (present-continuous spinner label)

### Fixed
- Keyboard shortcut corrected: `Shift+Down` only (Shift+Up removed in Claude Code v2.1.47)
- Added `Ctrl+F` (kill all background agents, two-press confirm) to display controls table

### Notes
- Core orchestration unchanged — all hooks exit 0 on unknown input (no-break guarantee)
- Lead spawn prompt memory summary remains the primary memory source for builder in worktrees;
  `WorktreeCreate` hook syncs files as an additional fidelity layer

## [0.1.14] - 2026-02-12

### Fixed

- **Verifier Hanging / Systemic Response Awareness Gap** (ALL agents + lead + skills)
  - Root cause #1: Lead execution loop said "Wait for teammates" without connecting to escalation ladder
  - Root cause #2: Most agents had "Task Completion" but not "Task Response (MANDATORY)" with deadline awareness
  - Evidence: User session showed verifier (Task #9) started but lead passively waited with "Awaiting verifier evidence..."

  **Comprehensive fix across 10 files:**

  | File | Fix Applied |
  |------|-------------|
  | `verifier.md` | Added "Task Response (MANDATORY)" section |
  | `hunter.md` | Added "Task Response (MANDATORY)" section |
  | `builder.md` | Added "Task Response (MANDATORY)" section |
  | `investigator.md` | Added "Task Response (MANDATORY)" section |
  | `live-reviewer.md` | Added "Task Response (MANDATORY)" section |
  | `planner.md` | Added "Task Response (MANDATORY)" section |
  | `security-reviewer.md` | Added "Task Response (MANDATORY)" section (existing Challenge Round Response kept) |
  | `performance-reviewer.md` | Added "Task Response (MANDATORY)" section (existing Challenge Round Response kept) |
  | `quality-reviewer.md` | Added "Task Response (MANDATORY)" section (existing Challenge Round Response kept) |
  | `cc-teams-lead/SKILL.md` | Fixed execution loop step 4: explicit escalation when waiting |
  | `review-arena/SKILL.md` | Fixed Phase 1 Lead actions: explicit escalation |
  | `bug-court/SKILL.md` | Added Lead actions to Phase 2: explicit escalation |

### Task Response (MANDATORY) Pattern

All agents now include:
```markdown
## Task Response (MANDATORY)

1. **You MUST complete and respond** - Non-response triggers lead escalation
2. **Deadline awareness:** Lead monitors at T+2 (nudge), T+5 (deadline), T+8 (replacement)
3. **If blocked:** Reply immediately with BLOCKED: {reason}
4. **Upon completion:** Output Router Contract
5. **Non-response consequence:** At T+8, lead spawns replacement and reassigns
```

### Notes

- This fix ensures NO agent can silently hang the workflow
- Every parallel phase (review-arena, bug-court) now has explicit escalation in Lead actions
- Invariant #7 changed from "Wait for teammates" to "Monitor teammates with escalation"

## [0.1.13] - 2026-02-12

### Fixed

- **Challenge Round Response Not Mandatory** (security-reviewer, performance-reviewer, quality-reviewer)
  - Root cause: "Challenging Other Reviewers" section used PASSIVE language ("When you receive...")
  - Reviewers didn't know they MUST respond to challenge requests
  - Evidence: User session showed 2/3 reviewers went idle during challenge round
  - Fix: Added "Challenge Round Response (MANDATORY)" section to all 3 reviewer agents with:
    - "You MUST respond" requirement
    - T+5 deadline awareness (T+8 = synthesis without you)
    - Valid response types (AGREE, DISAGREE, ESCALATE)
    - Consequence warning for non-response

### Notes

- Comprehensive audit of all 17 files (9 agents + 8 skills) confirmed this as the ONLY critical flaw
- All other protocols (Router Contract, Memory, TDD, Escalation) are working correctly

## [0.1.12] - 2026-02-11

### Fixed

- **Planner Deadlock** (planner.md, cc-teams-lead/SKILL.md)
  - Root cause: Planner was spawned with `mode: "plan"` which is READ-ONLY
  - Planner couldn't save plan files or update memory
  - Fix: Removed `mode: "plan"` from planner spawning, added explicit Plan Mode Rule

## [0.1.11] - 2026-02-11

### Fixed

- **Test Process Discipline** (builder.md, verifier.md, cc-teams-lead/SKILL.md, test-driven-development/SKILL.md)
  - Root cause: Vitest watch mode left 61 hanging processes, froze user's computer
  - Fix: Added Test Process Discipline sections requiring `CI=true` or `--run` flag
  - Added Test Process Cleanup Gate (#13) to cc-teams-lead before Team Shutdown
  - Updated TDD skill examples with proper flags

## [0.1.10] - 2026-02-10

### Fixed

- **REM-EVIDENCE Timeout** (cc-teams-lead/SKILL.md)
  - Root cause: Builder didn't respond to REM-EVIDENCE request for Router Contract
  - Workflow hung indefinitely waiting for response
  - Fix: Added REM-EVIDENCE Timeout Rule connecting to Task Status Lag escalation ladder
  - Added Lead Synthesis Fallback for non-responsive teammates

## [0.1.9] - 2026-02-09

### Added

- **Babysitter Repo Pattern Integration** (multiple files)
  - Integrated 5 high-value patterns from a5c-ai/babysitter repo:
    - "Smallest correct change set" constraint
    - "Root cause + prevention" for investigators
    - Prioritized output formats
    - Evidence-first reasoning
    - Explicit confidence scoring

## [0.1.0] - 2026-02-01

### Added

- Initial CC-Teams release
- Agent Teams-based orchestration for Claude Code
- 9 specialized agents: builder, planner, verifier, hunter, investigator, live-reviewer, security-reviewer, performance-reviewer, quality-reviewer
- 8 skills: cc-teams-lead, review-arena, bug-court, pair-build, router-contract, session-memory, test-driven-development, verification
- Router Contract YAML format for machine-readable agent handoffs
- Challenge Round protocol for reviewer consensus
- Task Status Lag escalation ladder
- Memory persistence with lead ownership
