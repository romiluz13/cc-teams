#!/usr/bin/env python3
"""Persist a compact workflow snapshot on session stop."""

import json

from cc_teams_hooklib import (
    append_forensic_event,
    latest_workflow_payload,
    load_input,
    log_event,
    now_iso,
    persist_forensic_snapshot,
    state_root,
)


def main() -> int:
    data = load_input()
    if data.get("stop_hook_active"):
        return 0

    payload = latest_workflow_payload()
    if not payload:
        return 0

    snapshot = {
        "ts": now_iso(),
        "workflow_instance": payload.get("workflow_instance")
        or payload.get("team_name"),
        "workflow_kind": payload.get("workflow_kind"),
        "phase_cursor": payload.get("phase_cursor"),
        "phase_status": payload.get("phase_status") or {},
        "pending_gate": payload.get("pending_gate"),
        "research_quality": payload.get("research_quality") or {},
        "memory_sync": payload.get("memory_sync") or {},
        "latency_telemetry": payload.get("latency_telemetry") or {},
        "source": "stop",
    }
    try:
        (state_root() / "precompact-state.json").write_text(
            json.dumps(snapshot, ensure_ascii=True),
            encoding="utf-8",
        )
    except Exception:
        pass

    persist_forensic_snapshot("last-stop", snapshot)
    append_forensic_event("stop-history", snapshot)

    log_event(
        "plugin_stop_persist",
        {
            "wf": snapshot.get("workflow_instance"),
            "phase": snapshot.get("phase_cursor") or "none",
            "task_id": None,
            "agent": "hook",
            "event": "stop_state_saved",
            "decision": "saved",
            "reason": "session_stop",
        },
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
