#!/usr/bin/env python3
"""Guard CC-Teams task completion with identity-stamp and memory invariants."""

from __future__ import annotations

import sys
from pathlib import Path

from cc_teams_hooklib import (
    append_forensic_event,
    load_input,
    log_event,
    now_iso,
    parse_task_metadata,
    state_root,
    workflow_event_for,
    workflow_payload_for,
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
            "event": "task_completion_blocked",
            "workflow_kind": "unknown",
            "phase_cursor": phase or "unknown",
            "pending_gate": "task_completed_guard",
            "source": "hook",
            "summary": f"task_completion_blocked:{reason}",
            "task_subject": subject,
            "task_id": task_id,
        },
    )
    log_event(
        "plugin_task_completed_guard",
        {
            "wf": wf,
            "phase": phase or "none",
            "task_id": task_id,
            "agent": "hook",
            "event": "task_completion_blocked",
            "decision": "block",
            "reason": reason,
            "task_subject": subject,
        },
    )
    append_forensic_event(
        "task-completed-blocks",
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
    subject = data.get("task_subject", "")
    description = data.get("task_description") or ""
    task_id = data.get("task_id")

    if not subject.startswith("CC-TEAMS "):
        return 0

    metadata = parse_task_metadata(description)
    missing = [key for key in REQUIRED_STAMP_KEYS if key not in metadata]
    wf = metadata.get("wf") or metadata.get("Workflow Instance")
    phase = metadata.get("phase")

    if missing:
        return block(
            task_id,
            wf,
            phase,
            subject,
            "missing_task_metadata",
            "[CC-Teams] Task completion blocked: task description is missing required identity-stamp lines: "
            + ", ".join(missing)
            + "\n",
        )

    if metadata.get("Project Root") and metadata["Project Root"] != str(Path.cwd()):
        return block(
            task_id,
            wf,
            phase,
            subject,
            "project_root_mismatch",
            "[CC-Teams] Task completion blocked: task Project Root does not match current repository root.\n",
        )

    if "CC-TEAMS Memory Update" not in subject:
        return 0

    memory_dir = state_root()
    required_files = (
        memory_dir / "activeContext.md",
        memory_dir / "progress.md",
    )
    missing_files = [
        str(path.relative_to(Path.cwd()))
        for path in required_files
        if not path.exists()
    ]
    if missing_files:
        return block(
            task_id,
            wf,
            phase,
            subject,
            "memory_files_missing",
            "[CC-Teams] Memory Update blocked: required memory files are missing: "
            + ", ".join(missing_files)
            + "\n",
        )

    artifact = workflow_payload_for(wf)
    if artifact is None:
        return block(
            task_id,
            wf,
            phase,
            subject,
            "workflow_artifact_missing",
            "[CC-Teams] Memory Update blocked: workflow artifact is missing for this workflow instance.\n",
        )

    artifact_wf = artifact.get("workflow_instance") or artifact.get("team_name")
    if artifact_wf and artifact_wf != wf:
        return block(
            task_id,
            wf,
            phase,
            subject,
            "workflow_artifact_mismatch",
            "[CC-Teams] Memory Update blocked: workflow artifact does not match the task workflow instance.\n",
        )

    if artifact.get("memory_notes_collected") in (None, ""):
        return block(
            task_id,
            wf,
            phase,
            subject,
            "memory_notes_missing",
            "[CC-Teams] Memory Update blocked: workflow artifact is missing `memory_notes_collected`.\n",
        )

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
