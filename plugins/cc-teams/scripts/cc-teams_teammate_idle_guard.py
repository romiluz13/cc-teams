#!/usr/bin/env python3
"""Enforce Router Contract presence before teammate idle, with forensic logging."""

from __future__ import annotations

import sys

from cc_teams_hooklib import (
    append_forensic_event,
    load_input,
    log_event,
    now_iso,
    workflow_event_for,
    workflow_payload_for,
)


ENFORCED_ROLES = {
    "builder",
    "live-reviewer",
    "hunter",
    "security-reviewer",
    "performance-reviewer",
    "quality-reviewer",
    "verifier",
    "planner",
}


def block(
    teammate: str,
    team_name: str | None,
    workflow_kind: str | None,
    phase: str | None,
    reason: str,
    details: str,
) -> int:
    event = {
        "ts": now_iso(),
        "wf": team_name,
        "event": "teammate_idle_blocked",
        "workflow_kind": workflow_kind or "unknown",
        "phase_cursor": phase or "unknown",
        "pending_gate": "teammate_idle_guard",
        "source": "hook",
        "summary": f"teammate_idle_blocked:{reason}",
        "teammate": teammate,
        "reason": reason,
    }
    workflow_event_for(team_name, event)
    log_event(
        "plugin_teammate_idle_guard",
        {
            "wf": team_name,
            "phase": phase or "unknown",
            "task_id": None,
            "agent": teammate,
            "event": "teammate_idle_blocked",
            "decision": "block",
            "reason": reason,
        },
    )
    append_forensic_event(
        "teammate-idle-blocks",
        {
            **event,
            "details": details.strip(),
        },
    )
    print(details, end="", file=sys.stderr)
    return 2


def main() -> int:
    data = load_input()
    teammate = data.get("teammate_name", "") or ""
    team_name = data.get("team_name")
    last_message = data.get("last_assistant_message", "") or ""

    enforce = teammate in ENFORCED_ROLES or teammate.startswith("investigator-")
    if not enforce or not last_message:
        return 0

    payload = workflow_payload_for(team_name) or {}
    workflow_kind = payload.get("workflow_kind")
    phase = payload.get("phase_cursor")

    if len(last_message) > 524288:
        if "Router Contract (MACHINE-READABLE)" in last_message:
            return 0
        return block(
            teammate,
            team_name,
            workflow_kind,
            phase,
            "missing_router_contract_large_message",
            f"[CC-Teams] {teammate} is missing Router Contract YAML block (large message detected).\n",
        )

    if "Router Contract (MACHINE-READABLE)" not in last_message:
        return block(
            teammate,
            team_name,
            workflow_kind,
            phase,
            "missing_router_contract",
            f"[CC-Teams] {teammate} is missing Router Contract YAML block.\n"
            "Include '### Router Contract (MACHINE-READABLE)' with complete YAML before going idle.\n"
            "See cc-teams:router-contract skill for the required CONTRACT_VERSION 2.5 schema.\n",
        )

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
