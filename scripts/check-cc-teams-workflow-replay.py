#!/usr/bin/env python3
"""Validate deterministic replay fixtures for key CC-Teams workflow-state behaviors."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
FIXTURES_DIR = ROOT / "plugins" / "cc-teams" / "tests" / "fixtures"

REQUIRED_FIXTURES = (
    "workflow-identity-cc-teams.json",
    "memory-sync-blocking.json",
    "latency-telemetry.json",
    "debug-research.json",
    "build-scope-gate.json",
    "build-checkpoint-decision.json",
    "stop-failure-log.json",
    "postcompact-event.json",
    "instructions-loaded-audit.json",
    "sessionstart-context.json",
    "task-created-guard.json",
    "teammate-idle-guard.json",
)

REQUIRED_ARTIFACT_KEYS = (
    "workflow_instance",
    "workflow_kind",
    "project_root",
    "team_name",
    "plan_mode",
    "verification_rigor",
    "proof_status",
    "intent",
    "traceability",
    "phase_cursor",
    "task_ids",
    "results",
    "evidence",
    "quality",
    "remediation_history",
    "pending_gate",
    "resume_entrypoint",
    "stale_assumptions",
)


def fail(message: str) -> None:
    raise AssertionError(message)


def require(condition: bool, message: str) -> None:
    if not condition:
        fail(message)


def load_fixture(name: str) -> dict[str, Any]:
    path = FIXTURES_DIR / name
    if not path.exists():
        fail(f"missing fixture: {name}")
    return json.loads(path.read_text(encoding="utf-8"))


def validate_artifact_shape(fixture: dict[str, Any]) -> None:
    artifact = fixture["starting_artifact"]
    missing = [key for key in REQUIRED_ARTIFACT_KEYS if key not in artifact]
    require(not missing, f"{fixture['id']}: artifact missing keys {missing}")
    require(
        artifact["workflow_instance"] == artifact["team_name"],
        f"{fixture['id']}: workflow_instance and team_name must match",
    )
    require(
        isinstance(artifact.get("traceability"), dict),
        f"{fixture['id']}: traceability must be an object",
    )
    require(
        isinstance(artifact.get("quality"), dict),
        f"{fixture['id']}: quality must be an object",
    )


def validate_identity_fixture(fixture: dict[str, Any]) -> None:
    validate_artifact_shape(fixture)
    expected = fixture["expected"]
    require(
        expected["collides_with_previous_session"] is False,
        f"{fixture['id']}: workflow identity should not collide with previous sessions",
    )


def validate_memory_sync_fixture(fixture: dict[str, Any]) -> None:
    validate_artifact_shape(fixture)
    artifact = fixture["starting_artifact"]
    memory_sync = artifact.get("memory_sync") or {}
    require(
        artifact["pending_gate"] == "memory_sync",
        f"{fixture['id']}: pending_gate must be memory_sync",
    )
    require(
        memory_sync.get("blocking_exit_persisted") is True,
        f"{fixture['id']}: blocking_exit_persisted must be true",
    )
    require(
        memory_sync.get("next_action") == "stop_after_memory_sync",
        f"{fixture['id']}: next_action must be stop_after_memory_sync",
    )


def validate_latency_fixture(fixture: dict[str, Any]) -> None:
    validate_artifact_shape(fixture)
    telemetry = fixture["starting_artifact"].get("latency_telemetry") or {}
    require(
        "workflow_wall_clock_seconds" in telemetry,
        f"{fixture['id']}: missing workflow_wall_clock_seconds",
    )
    agent_wall = telemetry.get("agent_wall_clock_seconds") or {}
    for key in ("builder", "reviewer", "hunter", "verifier"):
        require(key in agent_wall, f"{fixture['id']}: missing agent timing for {key}")
    verifier = telemetry.get("verifier") or {}
    require(
        verifier.get("phase_exit_proof_runs", 0) >= 1,
        f"{fixture['id']}: missing phase_exit_proof_runs",
    )
    workload = verifier.get("workload_seconds") or {}
    for key in ("tests", "build", "scan", "reconcile", "reasoning"):
        require(key in workload, f"{fixture['id']}: missing verifier workload {key}")


def validate_research_fixture(fixture: dict[str, Any]) -> None:
    validate_artifact_shape(fixture)
    research_quality = fixture["starting_artifact"].get("research_quality") or {}
    require(
        research_quality.get("overall")
        in {"low", "medium", "high", "partial", "degraded"},
        f"{fixture['id']}: research_quality.overall must be populated",
    )
    investigator = fixture["agent_outputs"].get("investigator_contract") or {}
    require(
        investigator.get("NEEDS_EXTERNAL_RESEARCH") is True,
        f"{fixture['id']}: investigator must request external research",
    )


def validate_gate_fixture(fixture: dict[str, Any], gate: str) -> None:
    validate_artifact_shape(fixture)
    require(
        fixture["starting_artifact"]["pending_gate"] == gate,
        f"{fixture['id']}: pending_gate must be {gate}",
    )
    require(
        fixture["expected"]["pending_gate"] == gate,
        f"{fixture['id']}: expected pending_gate must be {gate}",
    )


def validate_hook_event_fixture(fixture: dict[str, Any]) -> None:
    validate_artifact_shape(fixture)
    expected = fixture["expected"]
    require("event" in expected, f"{fixture['id']}: expected event name is required")
    require(
        isinstance(expected.get("required_fields"), list)
        and expected["required_fields"],
        f"{fixture['id']}: required_fields must be a non-empty list",
    )


def validate_sessionstart_fixture(fixture: dict[str, Any]) -> None:
    validate_artifact_shape(fixture)
    expected = fixture["expected"]
    require(
        isinstance(expected.get("message_contains"), list)
        and expected["message_contains"],
        f"{fixture['id']}: message_contains must be a non-empty list",
    )
    research_quality = fixture["starting_artifact"].get("research_quality") or {}
    require(
        bool(research_quality.get("overall")),
        f"{fixture['id']}: research_quality.overall must be populated",
    )
    latest_verified = (
        fixture["starting_artifact"].get("phase_transition_summaries") or {}
    ).get("latest_verified") or {}
    require(
        bool(latest_verified.get("phase_id")),
        f"{fixture['id']}: latest verified phase must be populated",
    )


def main() -> int:
    fixtures = {name: load_fixture(name) for name in REQUIRED_FIXTURES}
    validate_identity_fixture(fixtures["workflow-identity-cc-teams.json"])
    validate_memory_sync_fixture(fixtures["memory-sync-blocking.json"])
    validate_latency_fixture(fixtures["latency-telemetry.json"])
    validate_research_fixture(fixtures["debug-research.json"])
    validate_gate_fixture(fixtures["build-scope-gate.json"], "scope_decision")
    validate_gate_fixture(
        fixtures["build-checkpoint-decision.json"], "checkpoint_decision"
    )
    validate_hook_event_fixture(fixtures["stop-failure-log.json"])
    validate_hook_event_fixture(fixtures["postcompact-event.json"])
    validate_hook_event_fixture(fixtures["instructions-loaded-audit.json"])
    validate_sessionstart_fixture(fixtures["sessionstart-context.json"])
    validate_hook_event_fixture(fixtures["task-created-guard.json"])
    validate_hook_event_fixture(fixtures["teammate-idle-guard.json"])
    print("OK: CC-Teams workflow replay fixtures are present and structurally valid.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
