#!/usr/bin/env python3
"""Log compaction events for the latest workflow when available."""

from cc_teams_hooklib import (
    latest_workflow_payload,
    load_input,
    load_mode,
    log_event,
    now_iso,
    workflow_event,
)


def main() -> int:
    data = load_input()
    payload = latest_workflow_payload()
    if not payload:
        return 0

    trigger = data.get("trigger", "auto")
    summary = (data.get("compact_summary", "") or "")[:200]
    wf = payload.get("workflow_instance") or payload.get("team_name")
    resume_entrypoint = payload.get("resume_entrypoint") or "unknown"
    workflow_event(
        {
            "ts": now_iso(),
            "wf": wf,
            "event": "compact_occurred",
            "workflow_kind": payload.get("workflow_kind") or "unknown",
            "phase_cursor": payload.get("phase_cursor") or "none",
            "pending_gate": payload.get("pending_gate") or "none",
            "source": "hook",
            "summary": f"postcompact:{trigger}",
            "details": summary or None,
            "resume_entrypoint": resume_entrypoint,
        }
    )
    log_event(
        "plugin_postcompact_context",
        {
            "wf": wf,
            "phase": payload.get("phase_cursor") or "none",
            "task_id": None,
            "agent": "hook",
            "event": "compact_occurred",
            "decision": "logged",
            "reason": load_mode().get("postcompactAudit", "audit"),
            "resume_entrypoint": resume_entrypoint,
        },
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
