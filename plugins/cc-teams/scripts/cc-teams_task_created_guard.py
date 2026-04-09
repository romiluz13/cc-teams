#!/usr/bin/env python3
"""Guard CC-Teams task creation with identity-stamp invariants."""

from __future__ import annotations

import sys

from cc_teams_hooklib import (
    append_forensic_event,
    load_input,
    log_event,
    now_iso,
    parse_task_metadata,
    workflow_event_for,
)


REQUIRED_STAMP_KEYS = (
    "Workflow Instance",
    "Workflow Kind",
    "Project Root",
    "wf",
    "kind",
    "origin",
    "phase",
    "plan",
    "scope",
    "reason",
)


def block(
    task_id: str | None,
    wf: str | None,
    phase: str | None,
    subject: str,
    reason: str,
    details: str,
) -> int:
    workflow_event_for(
        wf,
        {
            "ts": now_iso(),
            "wf": wf,
            "event": "task_creation_blocked",
            "workflow_kind": "unknown",
            "phase_cursor": phase or "unknown",
            "pending_gate": "task_created_guard",
            "source": "hook",
            "summary": f"task_creation_blocked:{reason}",
            "task_subject": subject,
            "task_id": task_id,
        },
    )
    log_event(
        "plugin_task_created_guard",
        {
            "wf": wf,
            "phase": phase or "none",
            "task_id": task_id,
            "agent": "hook",
            "event": "task_creation_blocked",
            "decision": "block",
            "reason": reason,
            "task_subject": subject,
        },
    )
    append_forensic_event(
        "task-created-blocks",
        {
            "wf": wf,
            "phase": phase or "none",
            "task_id": task_id,
            "task_subject": subject,
            "reason": reason,
        },
    )
    print(details, end="", file=sys.stderr)
    return 2


def main() -> int:
    data = load_input()
    subject = data.get("task_subject", "") or ""
    description = data.get("task_description") or ""
    task_id = data.get("task_id")
    team_name = data.get("team_name")

    if not subject.startswith("CC-TEAMS "):
        return 0

    metadata = parse_task_metadata(description)
    wf = metadata.get("wf") or metadata.get("Workflow Instance") or team_name
    phase = metadata.get("phase")
    missing = [key for key in REQUIRED_STAMP_KEYS if key not in metadata]

    if missing:
        return block(
            task_id,
            wf,
            phase,
            subject,
            "missing_task_metadata",
            "[CC-Teams] Task creation blocked: task description is missing required identity-stamp lines: "
            + ", ".join(missing)
            + "\n",
        )

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
