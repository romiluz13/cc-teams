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
- PLAN: planner writes the saved plan, then clean-room plan-gap-reviewer challenges it before memory indexing.

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
- `TEAM_CREATED` is an operational gate (not narrative): team exists, required teammates are spawned, direct messaging is reachable, kickoff is sent, and the first teammate status reply is received.
- Downstream agents are not pre-spawned for blocked tasks; the lead spawns teammates only when their task is runnable.
- Conditional agents (accessibility-reviewer, api-contract-reviewer) are spawned based on FILES_MODIFIED signals from builder Router Contract — not spawned at kickoff.
- Teammate prompts declare default memory owner as lead.
- Missing required workflow/stage `SKILL_HINTS` is a spawn-contract failure, not a soft omission.

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
- If challenge synthesis ends in `accepted_risk`, Memory Update must persist the accepted-risk boundary into decision/progress memory with a revalidation trigger; accepted risk is not treated as resolved.
- Workflow-final Memory Update must journal workflow kind, active phase outcome, convergence state, traceability status, strongest evidence, and intentionally open boundaries so Markdown memory mirrors artifact truth.
- Plan-backed phase transitions also persist `phase_transition_summaries` so the next phase consumes a durable summary of closed proof and intentionally open boundaries.
- Research-informed workflows persist `research_quality` so resume can distinguish complete, partial, and degraded research input quality.
- Blocking exits persist `memory_sync` so stop/resume does not guess whether handoff and workflow-final memory persistence completed safely.
- Workflow artifacts may also carry compact `latency_telemetry` when timing truth is available.
- `pending_gate` uses explicit operational states such as `scope_decision`, `checkpoint_decision`, and `memory_sync`.
- Legacy tasks (missing workflow stamp) are NOT resumed; fresh stamped tasks are created instead.

Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:202`
Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:273`
Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:222`
Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:243`
Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:310`
Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:396`

## 5) Router Contract Is Non-Negotiable

Every teammate must emit machine-readable Router Contract YAML (CONTRACT_VERSION: "2.5"). Lead validates contract before completion and routes remediation for blocking outcomes.

Current schema version 2.5 adds:
- `STATE_DELTA` — every teammate reports `what_changed`, `remains_open`, `should_stay_closed`, and `next_trigger`
- lead uses these deltas to synthesize phase-transition summaries and detect regressions against previously closed proof

Version 2.4 adds:
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
- `plan-gap-reviewer` — READ-ONLY fresh plan challenger with anti-anchoring input rules.
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
Source: `plugins/cc-teams/agents/plan-gap-reviewer.md:15`
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

## 8.1) Phase-Aware Execution Canon

- Saved plans are not passive references: BUILD hydration normalizes executable phases into workflow artifact state before builder runs.
- `phase_cursor` identifies the only approved BUILD phase that may run next when a workflow is plan-backed.
- `active_phase_contract` carries objective, inputs, surfaces, required checks, checkpoint type, autonomy, and exit criteria into builder/verifier prompts.
- If a prior phase has already been verified, the next phase receives the latest `phase_transition_summaries` entry as continuity context.
- Workflow artifact also carries `intent`, `approved_decisions`, and `traceability` so the current phase remains tied to requirements and acceptance criteria.
- Contradictory, empty, or unverifiable acceptance criteria block BUILD before a builder is assigned.
- Acceptance criteria must also map to at least one phase/check/proof path and may not conflict with non-goals or unresolved/approved decisions.
- Planner cannot finalize with contradiction or coverage-gap flags still open.
- Resume reconstructs the active phase from task state plus workflow artifact, not from stale narrative memory alone.
- DEBUG uses a workflow-scoped reset marker so attempt counting survives interruption without mixing older workflows.
- Instruction precedence is explicit: user request > project-local instructions / saved plan / approved decisions > CC-Teams lead protocol > domain skills and heuristics.

Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:259`
Source: `plugins/cc-teams/skills/session-memory/SKILL.md:74`

## 8.2) Convergence Canon

- Remediation loops are workflow-state transitions, not only task choreography.
- Workflow artifact persists `remediation_history`, `loop_counts`, and `quality.convergence_state`.
- `.events.jsonl` provides append-only replay of planner completion, contract validation, and remediation traceability deltas that explain how the artifact reached its current state.
- Snapshot writes happen before matching replay events, so replay explains the latest state rather than competing with it.
- Planner completion, builder completion, verifier completion, and remediation transitions use canonical phase-delta shapes.
- Review Arena conflict resolution is persisted in `challenge_decisions` and replayed through `challenge_decided`.
- `challenge_decisions.current_phase.resolution_state` distinguishes `clear`, `accepted_risk`, `open_disagreement`, and `reopened_prior_proof`.
- `challenge_decisions.accepted_risks` uses structured records: `risk`, `scope_boundary`, `accepted_by`, `reason`, `revalidation_trigger`.
- `challenge_decisions.reopened_proof_regressions` records reopened boundaries with prior phase, current source, and required re-proof.
- Verifier records reopened-proof retirement as `reproof_closed` or `superseded_by_decision`; silent disappearance of a regression is not valid protocol.
- `boundary_history.latest` distinguishes active closed boundaries, intentionally open boundaries, accepted-risk boundaries, and retired boundaries for safe phase inheritance.
- Replay should expose boundary-history deltas whenever verifier retirement changes what later phases inherit.
- `boundary_history.timeline_tail` keeps a compact recent history of closure/reopen/supersession transitions for resume and audit.
- Blocking findings force `needs_iteration`; verifier pass on the active phase is required before `phase_cursor` may advance.
- If a later teammate reopens something a prior verified phase marked as closed, the lead classifies it as a reopened-proof regression and routes explicit remediation.
- Reopened-proof regressions are persisted in a dedicated artifact lane (`regressions.reopened_proof`), not only inside generic remediation prose.
- Reopened-proof regressions retire only through explicit verifier retirement records: fresh re-proof or supersession by approved decision.
- Later phases inherit proof from `boundary_history.latest`, not from raw historical wording alone.
- A verified phase must produce a compact transition summary that distinguishes `phase_verified`, `pending_next_phase`, and `converged_final`.
- Builder proof cannot claim satisfied requirements, acceptance criteria, or decision dependencies outside the active phase contract scope.
- Verifier must explicitly reconcile builder-satisfied claims; unresolved mismatches force remediation.
- Verifier intake must respect `challenge_decisions.verifier_intake_state`; unresolved conflicts cannot be treated as acceptable risk.
- `accepted_risk` intake means verifier verifies inside the approved boundary; it does not mean the underlying issue is fixed.
- Verifier pass is not enough unless requirement traceability is closed for that phase with fresh evidence.
- If another incomplete phase exists, the workflow returns to `pending`; if not, convergence may become `converged`.

Source: `plugins/cc-teams/skills/cc-teams-lead/SKILL.md:390`
Source: `plugins/cc-teams/skills/session-memory/SKILL.md:74`

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

- Hooks are opt-in by merging the repo-owned snippet in `plugins/cc-teams/settings.json` into Claude Code settings; core orchestration runs correctly without them.
- Baseline hooks include `TeammateIdle`, `TaskCreated`, `TaskCompleted`, `WorktreeCreate`, and `PreCompact`.
- Optional audit-first hooks may also be enabled for `SessionStart`, `PostCompact`, `Stop`, `StopFailure`, and `InstructionsLoaded`.
- Runtime hook mode is configured in `plugins/cc-teams/config/hook-mode.json`.
- Hook commands resolve from `CLAUDE_PROJECT_DIR` so runtime scripts stay stable across nested working directories.
- `TaskCreated` now validates task identity-stamp metadata before a CC-Teams task enters the task list.
- `TaskCompleted` now validates task identity-stamp metadata and Memory Update runtime invariants, not only file existence.
- PreCompact hook writes `CC-TEAMS COMPACT_CHECKPOINT` marker to progress.md; lead emits handoff payload on next turn when marker detected (replaces "30+ tool calls" heuristic).
- Audit hook scripts may write compact telemetry under `.claude/cc-teams/`, including `.claude/cc-teams/hook-events.log` and `.claude/cc-teams/precompact-state.json`.
- Expanded hook runtime is covered by a dedicated repo lint: `scripts/lint-cc-teams-hook-runtime.sh`.
- Self-claim is explicit opt-in and disabled by default for role-specialized flows.
- Teammates can use project/user MCP and project skills visible in the Claude Code session, but CC-Teams does not rely on subagent-definition `skills:` or `mcpServers:` frontmatter being applied automatically when that definition runs as a teammate.

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
