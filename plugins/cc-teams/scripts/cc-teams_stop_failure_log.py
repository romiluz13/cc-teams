#!/usr/bin/env python3
"""Log stop failure events to hook log and workflow events when possible."""

from typing import Any

from cc_teams_hooklib import (
    append_forensic_event,
    latest_workflow_payload,
    load_input,
    log_event,
    now_iso,
    persist_forensic_snapshot,
    workflow_event,
)


def main() -> int:
    data = load_input()
    error_type = data.get("error", "unknown")
    error_details = (data.get("error_details", "") or "")[:200]
    payload = latest_workflow_payload()
    wf = None
    phase = None
    pending_gate = None
    workflow_kind = None
    memory_sync: dict[str, Any] = {}
    resume_entrypoint = None
    if payload:
        wf = payload.get("workflow_instance") or payload.get("team_name")
        phase = payload.get("phase_cursor") or "unknown"
        pending_gate = payload.get("pending_gate") or "none"
        workflow_kind = payload.get("workflow_kind") or "unknown"
        memory_sync = payload.get("memory_sync") or {}
        resume_entrypoint = payload.get("resume_entrypoint")
        workflow_event(
            {
                "ts": now_iso(),
                "wf": wf,
                "event": "stop_failure",
                "workflow_kind": workflow_kind,
                "phase_cursor": phase,
                "pending_gate": pending_gate,
                "source": "hook",
                "summary": f"stop_failure:{error_type}",
                "details": error_details or None,
                "error_type": error_type,
                "memory_sync_persisted": bool(
                    memory_sync.get("blocking_exit_persisted")
                ),
                "resume_entrypoint": resume_entrypoint or "unknown",
            }
        )

    forensic = {
        "ts": now_iso(),
        "wf": wf,
        "phase": phase,
        "workflow_kind": workflow_kind,
        "pending_gate": pending_gate,
        "error_type": error_type,
        "details": error_details or None,
        "resume_entrypoint": resume_entrypoint or "unknown",
    }
    persist_forensic_snapshot("last-stop-failure", forensic)
    append_forensic_event("stop-failures", forensic)

    log_event(
        "plugin_stop_failure",
        {
            "wf": wf,
            "phase": phase,
            "task_id": None,
            "agent": "hook",
            "event": "stop_failure",
            "decision": "logged",
            "reason": error_type,
            "pending_gate": pending_gate,
            "workflow_kind": workflow_kind,
            "resume_entrypoint": resume_entrypoint,
        },
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
