# CC100x Bible (Functional-Derived)

Status: canonical-functional
Audience: maintainers, auditors, improvement workflows
Rule: every normative statement must cite a functional source

## Scope

CC100x runtime truth is defined only by:

- `plugins/cc100x/skills`
- `plugins/cc100x/agents`

Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:4`

## 1) Entry and Deterministic Routing

CC100x has one orchestration entrypoint (`cc100x-lead`) with strict routing:

- ERROR routes to DEBUG and has highest priority.
- PLAN, REVIEW, and BUILD follow in that order.
- Ambiguity resolution is explicit: ERROR wins.

Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:25`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:29`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:30`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:31`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:32`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:34`

## 2) SDLC as One Connected System

The lifecycle is integrated and task-enforced:

- BUILD: Pair Build -> Hunter -> triad review + challenge -> Verifier.
- DEBUG: 2-5 investigators -> debate -> builder fix -> triad review + challenge -> Verifier.
- REVIEW: triad review + challenge round.
- PLAN: planner in plan approval mode with lead handshake.

**Phase completion criteria are explicit:**
- Challenge round: all reviewers acknowledged peer findings, at least one response from each, conflicts resolved or escalated.
- Debate (DEBUG): all investigators responded, no new evidence, max 3 rounds.
- Verdict: clear winner requires reproducible test + survived challenges + explains primary symptom; ties/contested go to user.

Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:40`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:41`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:42`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:43`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:328`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:1315`
Source: `plugins/cc100x/skills/bug-court/SKILL.md:135`
Source: `plugins/cc100x/skills/bug-court/SKILL.md:153`

## 3) Agent Teams Preflight Is Mandatory

Before team execution or resume:

- Agent Teams must be enabled.
- Session must not keep stale active team state.
- Team naming is deterministic.
- Lead enters delegate mode before assignment.
- `TEAM_CREATED` is an operational gate (not narrative): team exists, required teammates are spawned, direct messaging is reachable.
- Teammates are spawned by phase (lazy activation), not all at workflow kickoff.
- Teammate prompts declare default memory owner as lead.

Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:47`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:57`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:61`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:67`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:73`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:76`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:88`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:786`

## 4) Task Graph and Memory-Update Closure

Workflow execution is DAG-first and closure-gated:

- Workflow tasks are explicitly created and dependency-gated.
- Workflow task hierarchy is created in the team-scoped task list after `TeamCreate`.
- BUILD structural integrity is enforced (required tasks and blockers).
- Verifier cannot bypass challenge (no hunter/remediation direct unlock).
- Every workflow includes a `CC100X Memory Update` task.
- Workflow cannot complete until Memory Update and TEAM_SHUTDOWN both succeed.
- Legacy tasks (missing workflow stamp) are NOT resumed; fresh stamped tasks are created instead.

Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:202`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:273`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:222`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:243`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:825`
Source: `plugins/cc100x/skills/pair-build/SKILL.md:190`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:310`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:396`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:443`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:470`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:905`

## 5) Router Contract Is Non-Negotiable

Every teammate must emit machine-readable Router Contract YAML. Lead validates contract before completion and routes remediation for blocking outcomes.

Before verifier invocation, lead runs a contract-diff checkpoint comparing FILES_MODIFIED, EVIDENCE_COMMANDS, CLAIMED_ARTIFACTS, and SPEC_COMPLIANCE between upstream and downstream claims. Mismatch creates `CC100X REM-FIX: Contract-diff` and blocks verifier.

Source: `plugins/cc100x/skills/router-contract/SKILL.md:20`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:671`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:688`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:710`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:1329`

## 6) Remediation and Re-Review Loop Integrity

Blocking findings trigger remediation tasks, and remediation must pass re-review + re-hunt before verifier is allowed to close.

Canonical remediation naming is `CC100X REM-FIX:`; legacy `CC100X REMEDIATION:` is accepted only for backward compatibility.

REM-FIX task assignment is explicit:
- Default: assign to `builder` (builder owns all file edits)
- Exception: if REM-FIX is for builder's own output, lead asks user for self-correct vs manual intervention

Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:710`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:747`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:1048`
Source: `plugins/cc100x/skills/router-contract/SKILL.md:93`
Source: `plugins/cc100x/skills/router-contract/SKILL.md:95`

## 7) Role Ownership and File Safety

Write/read boundaries are explicit:

- Builder owns implementation writes.
- Planner writes plan files; memory persistence remains lead-owned by default.
- Investigator is read-only in hypothesis stage.
- Reviewers/hunter/verifier/live-reviewer are read-only.
- Read-only review agents are capability-constrained (no `Write`/`Edit`; no ad-hoc artifact generation path).

Source: `plugins/cc100x/agents/builder.md:15`
Source: `plugins/cc100x/agents/planner.md:15`
Source: `plugins/cc100x/agents/investigator.md:15`
Source: `plugins/cc100x/agents/security-reviewer.md:15`
Source: `plugins/cc100x/agents/performance-reviewer.md:15`
Source: `plugins/cc100x/agents/quality-reviewer.md:15`
Source: `plugins/cc100x/agents/hunter.md:15`
Source: `plugins/cc100x/agents/verifier.md:15`
Source: `plugins/cc100x/agents/live-reviewer.md:15`

## 7.1) Artifact Governance Canon

- Teammates should return findings in messages + Router Contracts, not root-level report files.
- Approved durable artifacts are path-scoped (`docs/plans/`, `docs/research/`, and `docs/reviews/` only when explicitly requested).
- Unauthorized artifact claims must route to `CC100X REM-EVIDENCE`.

## 8) Memory Ownership Canon (Lead by Default)

Memory persistence is owner-scoped:

- Lead owns memory persistence in team workflows by default.
- Teammates emit Memory Notes for workflow-final persistence.
- Teammate direct memory edits require explicit override (`MEMORY_OWNER: teammate`).
- Session handoff payload includes `memory_notes_collected` to preserve notes across compaction boundaries.

Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:607`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:1053`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:313`
Source: `plugins/cc100x/skills/session-memory/SKILL.md:19`
Source: `plugins/cc100x/skills/session-memory/SKILL.md:152`
Source: `plugins/cc100x/skills/session-memory/SKILL.md:154`
Source: `plugins/cc100x/skills/session-memory/SKILL.md:538`

## 9) Agent Teams Constraint Canon

Operational constraints are explicit:

- No teammate session restoration via `/resume`.
- No nested teams.
- One active team per session.
- Lead identity is fixed for team lifetime.
- Teammate permissions inherit from lead at spawn.
- Broadcast is limited in favor of targeted messaging.
- Shutdown requires approval flow and team deletion.
- Shutdown rejection handling is explicit: read reason, check tasks, retry or escalate to user (Force vs Investigate).
- Failed `TeamDelete()` is retried up to 3 times; after 3 failures, user chooses Proceed (manual cleanup) or Abort (keep workflow open).
- Idle/task-lag handling is deterministic (nudge -> status request -> reassignment ladder).
- Lead communication is state-change-driven (avoid repeated idle narration without new action).

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

## 10) Hooks and Self-Claim Policy

- Hooks are optional and disabled-by-default for core correctness.
- Self-claim is explicit opt-in and disabled by default for role-specialized flows.

Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:956`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:989`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:1010`

## 11) Release Gates

A workflow is complete only when mandatory gates pass, including:

- `AGENT_TEAMS_READY`
- `CONTRACTS_VALIDATED`
- `ALL_TASKS_COMPLETED`
- `MEMORY_UPDATED`
- `TEAM_SHUTDOWN`

Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:1014`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:1016`
Source: `plugins/cc100x/skills/cc100x-lead/SKILL.md:1028`

## 12) Documentation Governance Rule

If any non-functional doc conflicts with runtime files, functional files win.
