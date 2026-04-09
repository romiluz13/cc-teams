#!/usr/bin/env python3
"""Shared helpers for optional CC-Teams runtime hooks."""

from __future__ import annotations

import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


def repo_root() -> Path:
    project_dir = os.environ.get("CLAUDE_PROJECT_DIR")
    if project_dir:
        return Path(project_dir)
    return Path.cwd()


def state_root() -> Path:
    root = repo_root() / ".claude" / "cc-teams"
    root.mkdir(parents=True, exist_ok=True)
    return root


def workflows_dir() -> Path:
    root = state_root() / "workflows"
    root.mkdir(parents=True, exist_ok=True)
    return root


def forensics_dir() -> Path:
    root = state_root() / "forensics"
    root.mkdir(parents=True, exist_ok=True)
    return root


def now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def load_input() -> dict[str, Any]:
    raw = sys.stdin.read().strip()
    if not raw:
        return {}
    try:
        parsed = json.loads(raw)
    except Exception:
        return {}
    return parsed if isinstance(parsed, dict) else {}


def load_mode() -> dict[str, Any]:
    path = repo_root() / "plugins" / "cc-teams" / "config" / "hook-mode.json"
    if not path.exists():
        return {}
    try:
        parsed = json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return {}
    return parsed if isinstance(parsed, dict) else {}


def latest_workflow_path() -> Path | None:
    candidates = sorted(
        (
            path
            for path in workflows_dir().glob("*.json")
            if not path.name.endswith(".events.jsonl")
        ),
        key=lambda path: path.stat().st_mtime,
        reverse=True,
    )
    return candidates[0] if candidates else None


def latest_workflow_payload() -> dict[str, Any] | None:
    path = latest_workflow_path()
    if path is None:
        return None
    try:
        parsed = json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return None
    return parsed if isinstance(parsed, dict) else None


def workflow_payload_for(wf: str | None) -> dict[str, Any] | None:
    if not wf:
        return None
    path = workflows_dir() / f"{wf}.json"
    if not path.exists():
        return None
    try:
        parsed = json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return None
    return parsed if isinstance(parsed, dict) else None


def parse_task_metadata(description: str) -> dict[str, str]:
    metadata: dict[str, str] = {}
    for raw_line in description.splitlines():
        line = raw_line.strip()
        if not line or ":" not in line:
            continue
        key, value = line.split(":", 1)
        metadata[key.strip()] = value.strip()
    return metadata


def append_jsonl(path: Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(payload, ensure_ascii=True) + "\n")


def write_json(path: Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, ensure_ascii=True), encoding="utf-8")


def log_event(source: str, payload: dict[str, Any]) -> None:
    event = {"ts": now_iso(), "source": source, **payload}
    try:
        append_jsonl(state_root() / "hook-events.log", event)
    except Exception:
        pass


def workflow_event(payload: dict[str, Any]) -> None:
    latest = latest_workflow_payload()
    if not latest:
        return
    wf = latest.get("workflow_instance") or latest.get("team_name")
    if not wf:
        return
    workflow_event_for(wf, payload)


def workflow_event_for(wf: str | None, payload: dict[str, Any]) -> None:
    if not wf:
        return
    try:
        append_jsonl(workflows_dir() / f"{wf}.events.jsonl", payload)
    except Exception:
        pass


def persist_forensic_snapshot(name: str, payload: dict[str, Any]) -> None:
    try:
        write_json(forensics_dir() / f"{name}.json", payload)
    except Exception:
        pass


def append_forensic_event(name: str, payload: dict[str, Any]) -> None:
    try:
        append_jsonl(forensics_dir() / f"{name}.jsonl", payload)
    except Exception:
        pass


def emit_context(message: str) -> None:
    sys.stdout.write(message.rstrip() + os.linesep)
