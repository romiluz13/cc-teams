# CC-Teams Bible (Functional-Derived)

Status: canonical-functional
Audience: maintainers, auditors, improvement workflows
Rule: every normative statement must cite a functional source

## Scope

CC-Teams runtime truth is defined only by:

- `plugins/cc-teams/skills`
- `plugins/cc-teams/agents`

Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:4`

## 1) Entry and Deterministic Routing

CC-Teams has one orchestration entrypoint (`cc-teams-lead`) with strict routing:

- ERROR routes to DEBUG and has highest priority.
- PLAN, REVIEW, and BUILD follow in that order.
- Ambiguity resolution is explicit: ERROR wins.

Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:25`
Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:29`
Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:30`
Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:31`
Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:32`
Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:34`

## 2) SDLC as One Connected System

The lifecycle is integrated, task-enforced, and covers five workflow variants:

- BUILD: Pair Build -> Hunter -> triad + conditional reviewers (3–5) + challenge -> Verifier.
- BUILD-CROSSLAYER: backend-builder (contract pub) -> frontend-builder (contract-gated) -> async live-reviewer -> Hunter -> triad + a11y + api-contract reviewers + challenge -> Verifier.
- DEBUG: 2-5 investigators -> debate (max 3 rounds) -> builder fix -> triad + conditional reviewers + challenge -> Verifier.
- REVIEW: triad + conditional reviewers + challenge round.
- PLAN: planner writes plan files directly (NO plan mode — plan mode is code-review-only; planner writes documentation).

**Phase completion criteria are explicit:**
- Challenge round: ALL ACTIVE reviewers (3–5) acknowledged peer findings, at least one response from each, conflicts resolved or escalated.
- Debate (DEBUG): all investigators responded, no new evidence, max 3 rounds enforced by lead round counter.
- Verdict: clear winner requires reproducible test + survived challenges + explains primary symptom; ties/contested go to user.
- Cross-layer: file conflict gate validates FILES_MODIFIED across builders before live-review phase.

Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:40`
Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:41`
Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:42`
Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:43`
Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:44`
Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:328`
Source: `plugins/cc-teams/skills/bug-court/SKILL.md:135`
Source: `plugins/cc-teams/skills/bug-court/SKILL.md:153`
Source: `plugins/cc-teams/skills/cross-layer-build/SKILL.md:50`

## 3) Agent Teams Preflight Is Mandatory

Before team execution or resume:

- Agent Teams must be enabled.
- Session must not keep stale active team state.
- Team naming is deterministic.
- Lead enters delegate mode before assignment.
- `TEAM_CREATED` is an operational gate (not narrative): team exists, required teammates are spawned, direct messaging is reachable.
- Downstream agents are PRE-SPAWNED with blocked tasks when their predecessor STARTS (not finishes) — eliminates phase-transition spawn latency.
- Conditional agents (accessibility-reviewer, api-contract-reviewer) are spawned based on FILES_MODIFIED signals from builder Router Contract — not pre-spawned at kickoff.
- Teammate prompts declare default memory owner as lead.

Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:47`
Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:57`
Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:61`
Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:67`
Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:73`
Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:76`
Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:88`

## 4) Task Graph and Memory-Update Closure

Workflow execution is DAG-first and closure-gated:

- Workflow tasks are explicitly created and dependency-gated.
- Workflow task hierarchy is created in the team-scoped task list after `TeamCreate`.
- BUILD structural integrity is enforced (required tasks and blockers); BUILD-CROSSLAYER has its own required task list.
- Verifier cannot bypass challenge (no hunter/remediation direct unlock).
- Every workflow (BUILD/BUILD-CROSSLAYER/DEBUG/REVIEW/PLAN) includes a `CC-TEAMS Memory Update` task.
- Workflow cannot complete until Memory Update and TEAM_SHUTDOWN both succeed.
- Memory Update escape hatch: if verifier stalls at CRITICAL, Memory Update is manually unblocked and persists partial learnings.
- Legacy tasks (missing workflow stamp) are NOT resumed; fresh stamped tasks are created instead.

Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:202`
Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:273`
Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:222`
Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:243`
Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:310`
Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:396`

## 5) Router Contract Is Non-Negotiable

Every teammate must emit machine-readable Router Contract YAML (CONTRACT_VERSION: "2.4"). Lead validates contract before completion and routes remediation for blocking outcomes.

Current schema version 2.4 adds:
- `PHASE_GATE_RESULT` / `PHASE_GATE_CMD` — builder, frontend-builder, backend-builder
- `DEPENDENCY_AUDIT` / `DEPENDENCY_AUDIT_DETAIL` — verifier, security-reviewer
- `DEPENDENCY_AUDIT: SKIPPED` — accessibility-reviewer, api-contract-reviewer

Before verifier invocation, lead runs a contract-diff checkpoint comparing FILES_MODIFIED, EVIDENCE_COMMANDS, CLAIMED_ARTIFACTS, and SPEC_COMPLIANCE between upstream and downstream claims. Mismatch creates `CC-TEAMS REM-FIX: Contract-diff` and blocks verifier.

Synthesized contract merge (Review Arena challenge round): BLOCKING=true if ANY active reviewer contract is blocking; CONFIDENCE=minimum of all reviewer scores.

Source: `plugins/cc-teams/skills/router-contract/SKILL.md:20`
Source: `plugins/cc-teams/skills/router-contract/SKILL.md:58`
Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:671`
Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:688`

## 6) Remediation and Re-Review Loop Integrity

Blocking findings trigger remediation tasks, and remediation must pass re-review + re-hunt before verifier is allowed to close.

Canonical remediation naming is `CC-TEAMS REM-FIX:`; legacy `CC-TEAMS REMEDIATION:` is accepted only for backward compatibility.

REM-FIX task assignment is explicit:
- Default: assign to `builder` (or appropriate builder in cross-layer: frontend-builder or backend-builder)
- Exception: if REM-FIX is for builder's own output, lead asks user for self-correct vs manual intervention

Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:710`
Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:747`
Source: `plugins/cc-teams/skills/router-contract/SKILL.md:93`
Source: `plugins/cc-teams/skills/router-contract/SKILL.md:95`

## 7) Role Ownership and File Safety

Write/read boundaries are explicit and capability-enforced:

**Write agents (source code):**
- `builder` — owns all source writes in standard BUILD.
- `frontend-builder` — owns frontend scope only (components/pages/hooks/styles) in BUILD-CROSSLAYER.
- `backend-builder` — owns backend scope only (api/services/models/db) in BUILD-CROSSLAYER; publishes API_CONTRACT_SPEC in Memory Notes.
- In BUILD-CROSSLAYER, FILES_MODIFIED must not overlap across builders. Lead enforces via file conflict gate.

**Write agents (documentation only):**
- `planner` — writes plan files to `docs/plans/` only.

**Read-only agents:**
- `investigator` — READ-ONLY in hypothesis stage.
- `security-reviewer`, `performance-reviewer`, `quality-reviewer` — READ-ONLY triad reviewers.
- `accessibility-reviewer` — READ-ONLY WCAG 2.1 AA specialist (conditional).
- `api-contract-reviewer` — READ-ONLY API breaking-change validator (conditional).
- `hunter`, `verifier`, `live-reviewer` — READ-ONLY.
- All read-only agents are capability-constrained (no `Write`/`Edit`; no ad-hoc artifact generation path).

Source: `plugins/cc-teams/agents/builder.md:15`
Source: `plugins/cc-teams/agents/frontend-builder.md:15`
Source: `plugins/cc-teams/agents/backend-builder.md:15`
Source: `plugins/cc-teams/agents/planner.md:15`
Source: `plugins/cc-teams/agents/investigator.md:15`
Source: `plugins/cc-teams/agents/security-reviewer.md:15`
Source: `plugins/cc-teams/agents/performance-reviewer.md:15`
Source: `plugins/cc-teams/agents/quality-reviewer.md:15`
Source: `plugins/cc-teams/agents/accessibility-reviewer.md:15`
Source: `plugins/cc-teams/agents/api-contract-reviewer.md:15`
Source: `plugins/cc-teams/agents/hunter.md:15`
Source: `plugins/cc-teams/agents/verifier.md:15`
Source: `plugins/cc-teams/agents/live-reviewer.md:15`

## 7.1) Artifact Governance Canon

- Teammates return findings in messages + Router Contracts, not root-level report files.
- Approved durable artifacts are path-scoped (`docs/plans/`, `docs/research/`, and `docs/reviews/` only when explicitly requested).
- Unauthorized artifact claims must route to `CC-TEAMS REM-EVIDENCE`.

## 7.2) Conditional Agent Spawning Canon

accessibility-reviewer and api-contract-reviewer are CONDITIONAL agents — their spawning is signal-gated:

- Spawning signal: builder Router Contract `FILES_MODIFIED` field is inspected after hunter completes.
- `accessibility-reviewer` spawns if FILES_MODIFIED contains `.tsx|.jsx|.html|.css|.vue` files.
- `api-contract-reviewer` spawns if FILES_MODIFIED contains files in `routes/|api/|endpoints/|handlers/|controllers/` paths.
- In BUILD-CROSSLAYER: BOTH are ALWAYS spawned (UI and API presence is guaranteed).
- Conflict resolution priority: a11y wins on CRITICAL (WCAG regulatory impact); api-contract wins on CRITICAL (client-breaking changes).

Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:104`
Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:105`
Source: `plugins/cc-teams/skills/review-arena/SKILL.md:16`
Source: `plugins/cc-teams/skills/cross-layer-build/SKILL.md:168`

## 7.3) Cross-Layer BUILD Canon

BUILD-CROSSLAYER is a parallel workflow variant for features spanning both frontend and backend:

- Backend-builder implements first and MUST publish `API_CONTRACT_SPEC` in Memory Notes (endpoints, request/response shapes, auth requirements).
- Lead validates the contract and relays it to frontend-builder spawn prompt before frontend implementation begins.
- Frontend-builder implements against the verified contract only.
- Live-reviewer operates in ASYNC mode: reviews ALL changes from BOTH builders after both complete.
- Both builders use `isolation: worktree` (own git worktrees); no file conflicts possible across worktrees.
- File conflict gate (mandatory): lead validates FILES_MODIFIED across both contracts before proceeding to live-review phase.

Source: `plugins/cc-teams/skills/cross-layer-build/SKILL.md:50`
Source: `plugins/cc-teams/skills/cross-layer-build/SKILL.md:87`
Source: `plugins/cc-teams/agents/backend-builder.md:8`
Source: `plugins/cc-teams/agents/frontend-builder.md:8`

## 8) Memory Ownership Canon (Lead by Default)

Memory persistence is owner-scoped:

- Lead owns workflow memory persistence in team workflows by default.
- Teammates emit Memory Notes for workflow-final persistence.
- Teammate direct memory edits require explicit override (`MEMORY_OWNER: teammate`).
- Session handoff payload includes `memory_notes_collected` and `teammate_roster` to preserve context across compaction boundaries.

**Agent-level persistent memory (additive to workflow memory, NOT workflow state):**
- `investigator`: `memory: project` — accumulates codebase-specific bug patterns across sessions. Does not replace `.claude/cc-teams/` workflow memory; it supplements with agent-level codebase intelligence.
- `security-reviewer`: `memory: user` — accumulates vulnerability patterns across ALL codebases. Cross-project security intelligence.

**Isolation:**
- `builder`, `frontend-builder`, `backend-builder`, `planner` all have `isolation: worktree` — each runs in its own git worktree. WorktreeCreate hook syncs `.claude/cc-teams/` memory to new worktree.

Source: `plugins/cc-teams/agents/investigator.md:4`
Source: `plugins/cc-teams/agents/security-reviewer.md:4`
Source: `plugins/cc-teams/agents/planner.md:7`
Source: `plugins/cc-teams/agents/builder.md:7`
Source: `plugins/cc-teams/agents/frontend-builder.md:7`
Source: `plugins/cc-teams/agents/backend-builder.md:7`
Source: `plugins/cc-teams/skills/session-memory/SKILL.md:19`
Source: `plugins/cc-teams/skills/session-memory/SKILL.md:152`
Source: `plugins/cc-teams/skills/session-memory/SKILL.md:154`

## 9) Agent Teams Constraint Canon

Operational constraints are explicit:

- No teammate session restoration via `/resume`.
- No nested teams.
- One active team per session.
- Lead identity is fixed for team lifetime.
- Teammate permissions inherit from lead at spawn.
- Broadcast is limited in favor of targeted messaging.
- Shutdown requires approval flow and team deletion; max 1 retry for task-related rejections; non-task rejection → AskUserQuestion immediately.
- Idle/task-lag handling is deterministic (nudge -> status request -> reassignment ladder, T+2/T+5/T+8/T+10).
- Lead communication is state-change-driven (avoid repeated idle narration without new action).
- Plan mode is NEVER used for the planner agent — plan mode is code-review-only; planner writes documentation files directly.

Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:935`
Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:936`
Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:942`
Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:943`
Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:944`
Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:945`

## 10) Hooks and Self-Claim Policy

- Hooks are opt-in via `plugins/cc-teams/settings.json`; core orchestration runs correctly without them.
- Four hooks implemented: `TeammateIdle` (Router Contract enforcement before idle), `TaskCompleted` (Memory Update file gate), `WorktreeCreate` (memory sync for builder/frontend-builder/backend-builder/planner worktrees), `PreCompact` (checkpoint marker).
- PreCompact hook writes `CC-TEAMS COMPACT_CHECKPOINT` marker to progress.md; lead emits handoff payload on next turn when marker detected (replaces "30+ tool calls" heuristic).
- Self-claim is explicit opt-in and disabled by default for role-specialized flows.

Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:956`
Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:989`
Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:1010`

## 11) Release Gates

A workflow is complete only when mandatory gates pass:

- `AGENT_TEAMS_READY`
- `MEMORY_LOADED`
- `TASKS_CHECKED`
- `INTENT_CLARIFIED`
- `TEAM_CREATED`
- `TASKS_CREATED`
- `CONTRACTS_VALIDATED`
- `ALL_TASKS_COMPLETED` (including Memory Update)
- `MEMORY_UPDATED`
- `TEAM_SHUTDOWN`

Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:1014`
Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:1016`
Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:1028`

## 12) Documentation Governance Rule

If any non-functional doc conflicts with runtime files, functional files win.
