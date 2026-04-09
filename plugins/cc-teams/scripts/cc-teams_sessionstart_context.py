#!/usr/bin/env python3
"""Emit compact workflow resume context on session start or resume."""

from cc_teams_hooklib import (
    emit_context,
    latest_workflow_payload,
    load_input,
    log_event,
)


def main() -> int:
    data = load_input()
    source = data.get("source", "startup")
    payload = latest_workflow_payload()
    if not payload:
        return 0

    boundary_history = (payload.get("boundary_history") or {}).get("latest") or {}
    phase_summary = (payload.get("phase_transition_summaries") or {}).get(
        "latest_verified"
    ) or {}
    research_quality = (payload.get("research_quality") or {}).get("overall") or "none"
    memory_sync = payload.get("memory_sync") or {}
    wf = payload.get("workflow_instance") or payload.get("team_name")
    message = (
        "CC-Teams workflow context "
        f"({source}): wf={wf or 'unknown'} "
        f"type={payload.get('workflow_kind') or 'unknown'} "
        f"phase_cursor={payload.get('phase_cursor') or 'none'} "
        f"pending_gate={payload.get('pending_gate') or 'none'} "
        f"research_quality={research_quality} "
        f"memory_sync={'persisted' if memory_sync.get('blocking_exit_persisted') else 'open'} "
        f"convergence={((payload.get('quality') or {}).get('convergence_state')) or 'unknown'} "
        f"active_closed={len(boundary_history.get('active_closed_boundaries') or [])} "
        f"accepted_risk={len(boundary_history.get('accepted_risk_boundaries') or [])} "
        f"retired={len(boundary_history.get('retired_boundaries') or [])} "
        f"last_verified_phase={phase_summary.get('phase_id') or 'none'}."
    )
    log_event(
        "plugin_sessionstart_context",
        {
            "wf": wf,
            "phase": payload.get("phase_cursor") or "none",
            "task_id": None,
            "agent": "hook",
            "event": "session_context",
            "decision": "inject",
            "reason": source,
        },
    )
    emit_context(message)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
