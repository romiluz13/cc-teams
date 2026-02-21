# CC-Teams Protocol Manifest (Functional Canon)

Status: canonical
Last validated: 2026-02-22

## Source of Truth

- `plugins/cc-teams/skills`
- `plugins/cc-teams/agents`

No other location defines runtime behavior.

## Orchestration Entry and Routing

- Single entry orchestrator is `cc-teams-lead`.
- Routing priority is strict: ERROR > PLAN > REVIEW > BUILD.
- ERROR always wins ambiguity.

Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:4`
Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:25`
Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:34`

## Workflow Canon (SDLC as One System)

- BUILD: Pair Build (builder + live-reviewer) -> hunter -> triad + conditional reviewers + challenge -> verifier.
- BUILD-CROSSLAYER: backend-builder (contract) -> frontend-builder -> async live-reviewer -> hunter -> triad + a11y + api-contract reviewers + challenge -> verifier.
- DEBUG: Bug Court (2-5 investigators) -> debate -> builder fix -> triad + conditional reviewers + challenge -> verifier.
- REVIEW: triad + conditional reviewers + challenge round.
- PLAN: single planner (no plan mode — planner writes documentation files directly).
- Challenge completion: all ACTIVE reviewers (3–5) acknowledged, at least one response from each, conflicts resolved or escalated.
- Debate completion (DEBUG): all investigators responded, no new evidence, max 3 rounds enforced.
- Verdict decision: clear winner requires reproducible test + survived challenges; ties/contested go to user.
- Cross-layer file conflict gate (BUILD-CROSSLAYER): lead validates FILES_MODIFIED across builders — no overlap before proceeding.

Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:40`
Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:41`
Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:42`
Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:43`
Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:44`
Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:328`
Source: `plugins/cc-teams/skills/bug-court/SKILL.md:135`
Source: `plugins/cc-teams/skills/bug-court/SKILL.md:153`
Source: `plugins/cc-teams/skills/cross-layer-build/SKILL.md:50`

## Agent Teams Preflight Canon

Before execution/resume:

- Agent Teams must be enabled.
- Only one active team is allowed per session.
- Team naming is deterministic.
- Lead must switch to delegate mode after team creation.
- `TEAM_CREATED` is an operational gate: `TeamCreate(...)` + teammate reachability via direct `SendMessage(...)` before any assignment.
- Downstream agents are pre-spawned with blocked tasks when their predecessor STARTS (not finishes) to eliminate phase-transition spawn latency.
- Conditional agents (accessibility-reviewer, api-contract-reviewer) are spawned based on FILES_MODIFIED signals from the builder Router Contract — not pre-spawned at team creation.
- Default memory owner is lead (`MEMORY_OWNER: lead`).

Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:47`
Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:57`
Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:61`
Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:67`
Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:73`
Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:76`
Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:88`
Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:80`

## Task DAG and Completion Canon

- Workflows are task-graph enforced via `TaskCreate`/`TaskUpdate`.
- Workflow task hierarchy is created in the team-scoped task list after team creation.
- BUILD topology is guarded: required tasks/blockers are validated pre-execution and pre-verifier.
- BUILD-CROSSLAYER topology is guarded separately (13-task chain including both builders and 5 reviewers).
- No direct shortcut from hunter/remediation to verifier.
- Memory Update task is mandatory in BUILD/BUILD-CROSSLAYER/DEBUG/REVIEW/PLAN.
- Workflow completion requires all tasks complete, including Memory Update and successful TEAM_SHUTDOWN.
- Legacy tasks (missing workflow stamp) are NOT resumed; fresh stamped tasks are created instead.
- Memory Update escape hatch: if verifier stalls at CRITICAL, Memory Update is manually unblocked and persists partial learnings.

Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:202`
Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:273`
Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:222`
Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:243`
Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:310`
Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:396`

## Router Contract and Remediation Canon

- Lead validates every teammate via Router Contract before task completion.
- Router Contracts use schema versioning (`CONTRACT_VERSION: "2.4"`) and include artifact/evidence fields (`CLAIMED_ARTIFACTS`, `EVIDENCE_COMMANDS`).
- v2.4 adds: `PHASE_GATE_RESULT`/`PHASE_GATE_CMD` (builder/frontend-builder/backend-builder); `DEPENDENCY_AUDIT` (verifier + security-reviewer); `DEPENDENCY_AUDIT: SKIPPED` (accessibility-reviewer, api-contract-reviewer).
- Blocking/remediation fields create remediation pathing.
- Remediation naming is canonicalized to `CC-TEAMS REM-FIX:` (legacy `CC-TEAMS REMEDIATION:` is compatibility-only).
- REM-FIX task assignment: default to `builder`; if builder's own output needs fixing, lead asks user for self-correct vs manual intervention.
- Circuit breaker applies before repeated REM-FIX loops.
- Remediation re-enters re-review + re-hunt before verifier.
- Contract-diff checkpoint runs before verifier: compares FILES_MODIFIED, EVIDENCE_COMMANDS, CLAIMED_ARTIFACTS, and SPEC_COMPLIANCE between upstream and downstream claims. Mismatch blocks verifier.
- Synthesized contract merge: BLOCKING=true if ANY contract blocking; CONFIDENCE=min of all scores.

Source: `plugins/cc-teams/skills/router-contract/SKILL.md:58`
Source: `plugins/cc-teams/skills/router-contract/SKILL.md:74`
Source: `plugins/cc-teams/skills/router-contract/SKILL.md:20`

## Role and Write Ownership Canon

- Builder, frontend-builder, and backend-builder are the only source-writers in BUILD/BUILD-CROSSLAYER implementation flows.
- In BUILD-CROSSLAYER: backend-builder and frontend-builder own distinct, non-overlapping file scopes enforced by the file conflict gate.
- Investigator is read-only during hypothesis phase.
- Reviewers (security, performance, quality, accessibility, api-contract) / hunter / verifier / live-reviewer are read-only.
- Planner writes plan files only; memory persistence is lead-owned by default.
- Read-only review agents are capability-constrained and must not generate ad-hoc report artifacts.

Source: `plugins/cc-teams/agents/builder.md:15`
Source: `plugins/cc-teams/agents/frontend-builder.md:15`
Source: `plugins/cc-teams/agents/backend-builder.md:15`
Source: `plugins/cc-teams/agents/investigator.md:15`
Source: `plugins/cc-teams/agents/security-reviewer.md:15`
Source: `plugins/cc-teams/agents/performance-reviewer.md:15`
Source: `plugins/cc-teams/agents/quality-reviewer.md:15`
Source: `plugins/cc-teams/agents/accessibility-reviewer.md:15`
Source: `plugins/cc-teams/agents/api-contract-reviewer.md:15`
Source: `plugins/cc-teams/agents/hunter.md:15`
Source: `plugins/cc-teams/agents/verifier.md:15`
Source: `plugins/cc-teams/agents/live-reviewer.md:15`
Source: `plugins/cc-teams/agents/planner.md:15`

## Conditional Agent Spawning Canon

- accessibility-reviewer and api-contract-reviewer are CONDITIONAL — not always active.
- Spawning signal: builder Router Contract `FILES_MODIFIED` field is inspected after hunter completes.
- accessibility-reviewer spawns if FILES_MODIFIED contains `.tsx|.jsx|.html|.css|.vue` files.
- api-contract-reviewer spawns if FILES_MODIFIED contains files in `routes/|api/|endpoints/|handlers/|controllers/` paths.
- In BUILD-CROSSLAYER: both are ALWAYS spawned (UI and API are both guaranteed in cross-layer workflows).
- Challenge round adjusts to include all ACTIVE reviewers (3–5 depending on signals).

Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:104`
Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:105`
Source: `plugins/cc-teams/skills/cross-layer-build/SKILL.md:168`

## Artifact Governance Canon

- Teammate outputs are message-first (Router Contract + findings), not root report file generation.
- Durable artifact paths are scoped (`docs/plans/`, `docs/research/`, `docs/reviews/` when explicitly requested).
- Unauthorized artifact claims route to `CC-TEAMS REM-EVIDENCE` and block downstream tasks.

## Memory Ownership Canon

- Lead owns workflow memory persistence by default in team workflows.
- Teammates emit Memory Notes; lead persists in workflow-final memory task.
- Teammate memory edits are explicit exception only (`MEMORY_OWNER: teammate`).
- Session handoff payload includes `memory_notes_collected` and `teammate_roster` fields to preserve context across compaction boundaries.
- Agent-level persistent memory (additive to workflow memory, NOT workflow state):
  - `investigator`: `memory: project` — accumulates codebase-specific bug patterns across sessions.
  - `security-reviewer`: `memory: user` — accumulates vulnerability patterns across ALL codebases.
- Planner has `isolation: worktree` — plan file writes branch-isolated; WorktreeCreate hook syncs `.claude/cc-teams/` to new worktree.

Source: `plugins/cc-teams/agents/investigator.md:4`
Source: `plugins/cc-teams/agents/security-reviewer.md:4`
Source: `plugins/cc-teams/agents/planner.md:7`
Source: `plugins/cc-teams/skills/session-memory/SKILL.md:19`
Source: `plugins/cc-teams/skills/session-memory/SKILL.md:152`

## Agent-Team Collaboration Canon

- Reviewer/investigator debate phases require direct teammate messaging.
- Required messaging agents have `SendMessage` tool access.
- Parallel phases are followed by lead-level result collection and synthesis.
- In BUILD-CROSSLAYER, live-reviewer operates in async mode: reviews ALL changes from BOTH builders after both complete (not per-module blocking).
- API contract relay: backend-builder publishes API_CONTRACT_SPEC in Memory Notes; lead validates and relays to frontend-builder before frontend implementation begins.

Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:841`
Source: `plugins/cc-teams/agents/security-reviewer.md:7`
Source: `plugins/cc-teams/agents/performance-reviewer.md:7`
Source: `plugins/cc-teams/agents/quality-reviewer.md:7`
Source: `plugins/cc-teams/agents/accessibility-reviewer.md:7`
Source: `plugins/cc-teams/agents/api-contract-reviewer.md:7`
Source: `plugins/cc-teams/agents/investigator.md:7`
Source: `plugins/cc-teams/agents/live-reviewer.md:7`
Source: `plugins/cc-teams/agents/builder.md:7`
Source: `plugins/cc-teams/skills/cross-layer-build/SKILL.md:87`

## Constraints and Operations Canon

- No session resumption of teammates.
- No nested teams.
- One team per session.
- Lead is fixed for team lifetime.
- Permission inheritance occurs at spawn.
- Broadcast is restricted (targeted messaging preferred).
- Team shutdown must end with `TeamDelete()`.
- Shutdown rejection: max 1 retry for task-related reasons; non-task rejection → AskUserQuestion immediately.
- Idle/task status lag follows deterministic escalation (nudge -> status request -> reassignment).
- Lead updates are state-change-driven (no repetitive idle heartbeat narration).

Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:935`
Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:936`
Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:942`
Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:943`
Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:944`
Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:945`

## Hooks and Self-Claim Policy Canon

- Hooks are opt-in via `plugins/cc-teams/settings.json`; core orchestration runs correctly without them.
- Four hooks implemented: `TeammateIdle` (Router Contract enforcement), `TaskCompleted` (Memory Update gate), `WorktreeCreate` (memory sync for builder/frontend-builder/backend-builder/planner worktrees), `PreCompact` (checkpoint marker).
- PreCompact hook writes `CC-TEAMS COMPACT_CHECKPOINT` marker to progress.md; lead emits handoff payload on next turn when marker detected.
- Hook scripts live in `plugins/cc-teams/hooks/`; all exit 0 on unknown/ambiguous input.
- Self-claim is explicit opt-in and not default in role-specialized BUILD/DEBUG flows.

Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:956`
Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:989`
Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:1010`

## Release Gates Canon

Mandatory gates include:

- `AGENT_TEAMS_READY`
- `MEMORY_LOADED`
- `TASKS_CHECKED`
- `INTENT_CLARIFIED`
- `TEAM_CREATED`
- `TASKS_CREATED`
- `CONTRACTS_VALIDATED`
- `ALL_TASKS_COMPLETED`
- `MEMORY_UPDATED`
- `TEAM_SHUTDOWN`

Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:1014`
Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:1016`
Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:1028`
