#!/usr/bin/env python3
"""Audit log for instruction file loads."""

from cc_teams_hooklib import latest_workflow_payload, load_input, log_event


def main() -> int:
    data = load_input()
    payload = latest_workflow_payload()
    wf = None
    phase = None
    if payload:
        wf = payload.get("workflow_instance") or payload.get("team_name")
        phase = payload.get("phase_cursor") or "none"
    log_event(
        "plugin_instructions_loaded",
        {
            "wf": wf,
            "phase": phase,
            "task_id": None,
            "agent": "hook",
            "event": "instructions_loaded",
            "decision": "logged",
            "reason": data.get("load_reason", "unknown"),
            "file_path": data.get("file_path", "unknown"),
            "memory_type": data.get("memory_type", "unknown"),
            "source": data.get("source", "hook"),
        },
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
