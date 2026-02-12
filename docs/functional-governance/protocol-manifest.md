# CC100x Protocol Manifest (Functional Canon)

Status: canonical
Last validated: 2026-02-11

## Source of Truth

- `plugins/cc100x/skills`
- `plugins/cc100x/agents`

No other location defines runtime behavior.

## Orchestration Entry and Routing

- Single entry orchestrator is `cc100x-lead`.
- Routing priority is strict: ERROR > PLAN > REVIEW > BUILD.
- ERROR always wins ambiguity.

Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:4`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:25`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:34`

## Workflow Canon (SDLC as One System)

- BUILD: Pair Build (builder + live-reviewer) -> hunter -> triad review + challenge -> verifier.
- DEBUG: Bug Court (2-5 investigators) -> debate -> builder fix -> triad review + challenge -> verifier.
- REVIEW: triad review + challenge round.
- PLAN: single planner in plan approval mode.
- Challenge completion: all reviewers acknowledged, at least one response from each, conflicts resolved or escalated.
- Debate completion (DEBUG): all investigators responded, no new evidence, max 3 rounds.
- Verdict decision: clear winner requires reproducible test + survived challenges; ties/contested go to user.

Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:40`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:41`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:42`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:43`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:328`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:1315`
Source: `plugins/cc100x/skills/bug-court/SKILL.md:135`
Source: `plugins/cc100x/skills/bug-court/SKILL.md:153`

## Agent Teams Preflight Canon

Before execution/resume:

- Agent Teams must be enabled.
- Only one active team is allowed per session.
- Team naming is deterministic.
- Lead must switch to delegate mode after team creation.
- `TEAM_CREATED` is an operational gate: `TeamCreate(...)` + teammate reachability via direct `SendMessage(...)` before any assignment.
- Teammates are activated by phase (lazy spawn), not pre-spawned all at kickoff.
- Default memory owner is lead (`MEMORY_OWNER: lead`).

Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:47`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:57`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:61`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:67`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:73`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:76`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:88`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:80`

## Task DAG and Completion Canon

- Workflows are task-graph enforced via `TaskCreate`/`TaskUpdate`.
- Workflow task hierarchy is created in the team-scoped task list after team creation.
- BUILD topology is guarded: required tasks/blockers are validated pre-execution and pre-verifier.
- No direct shortcut from hunter/remediation to verifier.
- Memory Update task is mandatory in BUILD/DEBUG/REVIEW/PLAN.
- Workflow completion requires all tasks complete, including Memory Update and successful TEAM_SHUTDOWN.
- Legacy tasks (missing workflow stamp) are NOT resumed; fresh stamped tasks are created instead.

Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:202`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:273`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:222`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:243`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:825`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:849`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:310`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:396`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:443`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:470`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:905`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:1026`

## Router Contract and Remediation Canon

- Lead validates every teammate via Router Contract before task completion.
- Router Contracts use schema versioning (`CONTRACT_VERSION`) and include artifact/evidence fields (`CLAIMED_ARTIFACTS`, `EVIDENCE_COMMANDS`).
- Blocking/remediation fields create remediation pathing.
- Remediation naming is canonicalized to `CC100X REM-FIX:` (legacy `CC100X REMEDIATION:` is compatibility-only).
- REM-FIX task assignment: default to `builder`; if builder's own output needs fixing, lead asks user for self-correct vs manual intervention.
- Circuit breaker applies before repeated REM-FIX loops.
- Remediation re-enters re-review + re-hunt before verifier.
- Contract-diff checkpoint runs before verifier: compares FILES_MODIFIED, EVIDENCE_COMMANDS, CLAIMED_ARTIFACTS, and SPEC_COMPLIANCE between upstream and downstream claims. Mismatch blocks verifier.

Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:671`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:688`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:1048`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:1329`
Source: `plugins/cc100x/skills/router-contract/SKILL.md:93`
Source: `plugins/cc100x/skills/router-contract/SKILL.md:95`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:702`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:747`
Source: `plugins/cc100x/skills/router-contract/SKILL.md:20`

## Role and Write Ownership Canon

- Builder is the only source-writer in BUILD implementation flow.
- Investigator is read-only during hypothesis phase.
- Reviewers/hunter/verifier/live-reviewer are read-only.
- Planner writes plan files; memory persistence is lead-owned by default.
- Read-only review agents are capability-constrained and must not generate ad-hoc report artifacts.

Source: `plugins/cc100x/agents/builder.md:15`
Source: `plugins/cc100x/agents/investigator.md:15`
Source: `plugins/cc100x/agents/security-reviewer.md:15`
Source: `plugins/cc100x/agents/performance-reviewer.md:15`
Source: `plugins/cc100x/agents/quality-reviewer.md:15`
Source: `plugins/cc100x/agents/hunter.md:15`
Source: `plugins/cc100x/agents/verifier.md:15`
Source: `plugins/cc100x/agents/live-reviewer.md:15`
Source: `plugins/cc100x/agents/planner.md:15`

## Artifact Governance Canon

- Teammate outputs are message-first (Router Contract + findings), not root report file generation.
- Durable artifact paths are scoped (`docs/plans/`, `docs/research/`, `docs/reviews/` when explicitly requested).
- Unauthorized artifact claims route to `CC100X REM-EVIDENCE` and block downstream tasks.

## Memory Ownership Canon

- Lead owns memory persistence by default in team workflows.
- Teammates emit Memory Notes; lead persists in workflow-final memory task.
- Teammate memory edits are explicit exception only (`MEMORY_OWNER: teammate`).
- Session handoff payload includes `memory_notes_collected` field to preserve notes across compaction boundaries.

Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:607`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:1053`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:313`
Source: `plugins/cc100x/skills/session-memory/SKILL.md:19`
Source: `plugins/cc100x/skills/session-memory/SKILL.md:152`
Source: `plugins/cc100x/skills/session-memory/SKILL.md:154`

## Agent-Team Collaboration Canon

- Reviewer/investigator debate phases require direct teammate messaging.
- Required messaging agents have `SendMessage` tool access.
- Parallel phases are followed by lead-level result collection and synthesis.

Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:841`
Source: `plugins/cc100x/agents/security-reviewer.md:7`
Source: `plugins/cc100x/agents/performance-reviewer.md:7`
Source: `plugins/cc100x/agents/quality-reviewer.md:7`
Source: `plugins/cc100x/agents/investigator.md:7`
Source: `plugins/cc100x/agents/live-reviewer.md:7`
Source: `plugins/cc100x/agents/builder.md:7`

## Constraints and Operations Canon

- No session resumption of teammates.
- No nested teams.
- One team per session.
- Lead is fixed for team lifetime.
- Permission inheritance occurs at spawn.
- Broadcast is restricted (targeted messaging preferred).
- Team shutdown must end with `TeamDelete()`.
- Shutdown rejection is explicit: read reason, check tasks, retry or escalate (Force vs Investigate).
- If `TeamDelete()` fails, retry up to 3 times; after 3 failures, user chooses Proceed (manual cleanup) or Abort (keep workflow open).
- Idle/task status lag follows deterministic escalation (nudge -> status request -> reassignment).
- Lead updates are state-change-driven (no repetitive idle heartbeat narration).

Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:935`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:936`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:942`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:943`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:944`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:945`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:1032`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:1038`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:1124`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:1020`

## Hooks and Self-Claim Policy Canon

- Hooks are optional and disabled-by-default for core runtime correctness.
- Self-claim is explicit opt-in and not default in role-specialized BUILD/DEBUG flows.

Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:956`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:989`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:1010`

## Release Gates Canon

Mandatory gates include:

- `AGENT_TEAMS_READY`
- `MEMORY_LOADED`
- `TASKS_CHECKED`
- `TEAM_CREATED`
- `TASKS_CREATED`
- `CONTRACTS_VALIDATED`
- `ALL_TASKS_COMPLETED`
- `MEMORY_UPDATED`
- `TEAM_SHUTDOWN`

Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:1014`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:1016`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:1028`
