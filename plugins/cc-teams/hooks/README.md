# CC-Teams Hooks

This directory contains the optional CC-Teams plugin runtime hooks.

The operational stance is intentionally:
- audit-first
- fail-safe
- disabled-by-default safe

These hooks should improve observability and compaction continuity without becoming a hard dependency for core CC-Teams orchestration.

## Hook Coverage

Current CC-Teams runtime hooks:
- `TeammateIdle` — enforce Router Contract presence before idle
- `TaskCreated` — guard task identity stamps before creation
- `TaskCompleted` — guard task identity stamps and Memory Update completion invariants
- `WorktreeCreate` — sync `.claude/cc-teams/` memory into isolated worktrees
- `PreCompact` — write checkpoint marker before compaction
- `SessionStart` — inject compact workflow resume context
- `PostCompact` — log compaction event against latest workflow
- `Stop` — persist compact workflow stop snapshot
- `StopFailure` — log API/stop failure events
- `InstructionsLoaded` — log instruction-file loads for auditability

## Principles

- Hooks are optional. Core CC-Teams orchestration must still work if they are disabled.
- Hooks should never block the workflow on unknown or malformed input unless the specific hook is intentionally gating a local invariant.
- Audit hooks prefer append-only logs and compact snapshots over mutating workflow truth.
- Workflow artifact snapshot remains the durable runtime truth; hook logs are supporting telemetry.
- Blocking guard hooks should leave deterministic forensic breadcrumbs, not only stderr output.

## Files

- Runtime configuration snippet to merge into Claude Code settings: `plugins/cc-teams/settings.json`
- Hook mode config: `plugins/cc-teams/config/hook-mode.json`
- Shared helpers: `plugins/cc-teams/scripts/cc_teams_hooklib.py`
- TaskCreated guard: `plugins/cc-teams/scripts/cc-teams_task_created_guard.py`
- TaskCompleted guard: `plugins/cc-teams/scripts/cc-teams_task_completed_guard.py`

Hook commands resolve from `CLAUDE_PROJECT_DIR` so they remain stable even when the hook fires from a nested current working directory.

## Local Audit Surfaces

Hooks may write to:
- `.claude/cc-teams/hook-events.log`
- `.claude/cc-teams/precompact-state.json`
- `.claude/cc-teams/forensics/*.json`
- `.claude/cc-teams/forensics/*.jsonl`
- latest workflow `.events.jsonl` when a workflow can be identified safely
