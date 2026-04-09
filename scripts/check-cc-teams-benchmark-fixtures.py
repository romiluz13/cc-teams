#!/usr/bin/env python3
from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any, cast


REPO = Path(__file__).resolve().parent.parent
CASES_PATH = REPO / "scripts" / "eval" / "benchmark-cases.json"
FIXTURES_PATH = REPO / "artifacts" / "eval" / "fixtures" / "index.json"

REQUIRED_FIXTURE_FIELDS = {
    "case_id",
    "fixture_id",
    "workflow",
    "category",
    "deterministic_seed",
    "interruption_profile",
    "ground_truth_mode",
    "fixture_notes",
}

ALLOWED_INTERRUPTION_PROFILES = {
    "none",
    "resume-safe",
    "mid-remediation",
    "mid-execution",
    "mid-debate",
}


def fail(message: str) -> None:
    print(f"[benchmark-fixtures] {message}", file=sys.stderr)
    sys.exit(1)


def load_json(path: Path) -> Any:
    if not path.is_file():
        fail(f"missing file: {path}")
    try:
        return json.loads(path.read_text())
    except json.JSONDecodeError as exc:
        fail(f"invalid JSON in {path}: {exc}")


def main() -> None:
    cases = load_json(CASES_PATH)
    fixtures = load_json(FIXTURES_PATH)

    if not isinstance(cases, list) or not isinstance(fixtures, list):
        fail("benchmark cases and fixtures must both be arrays")

    cases_list = cast(list[dict[str, Any]], cases)
    fixtures_list = cast(list[dict[str, Any]], fixtures)

    case_map: dict[str, dict[str, Any]] = {
        str(entry["case_id"]): entry for entry in cases_list
    }
    fixture_map: dict[str, dict[str, Any]] = {}

    for entry in fixtures_list:
        if not isinstance(entry, dict):
            fail("fixture entries must be objects")
        missing = REQUIRED_FIXTURE_FIELDS - entry.keys()
        if missing:
            fail(f"fixture entry missing required fields {sorted(missing)}: {entry}")
        case_id = entry["case_id"]
        if case_id in fixture_map:
            fail(f"duplicate fixture entry for {case_id}")
        fixture_map[case_id] = entry

        if entry["interruption_profile"] not in ALLOWED_INTERRUPTION_PROFILES:
            fail(
                f"{case_id} has unsupported interruption_profile: {entry['interruption_profile']}"
            )
        if not entry["deterministic_seed"].startswith("cc-teams-"):
            fail(
                f"{case_id} has invalid deterministic_seed: {entry['deterministic_seed']}"
            )

    case_ids = [str(entry["case_id"]) for entry in cases_list]
    fixture_ids = [str(entry["case_id"]) for entry in fixtures_list]
    if case_ids != fixture_ids:
        fail(
            "fixture index case order/content drifted from canonical benchmark cases.\n"
            f"expected: {case_ids}\n"
            f"actual:   {fixture_ids}"
        )

    for case_id, case_entry in case_map.items():
        fixture = fixture_map.get(case_id)
        if fixture is None:
            fail(f"missing fixture for {case_id}")
        fixture_entry = cast(dict[str, Any], fixture)
        if fixture_entry["workflow"] != case_entry["workflow"]:
            fail(f"{case_id} fixture workflow drifted from canonical case")
        if fixture_entry["category"] != case_entry["category"]:
            fail(f"{case_id} fixture category drifted from canonical case")

    print("[benchmark-fixtures] OK: deterministic fixture index covers all 26 cases")


if __name__ == "__main__":
    main()
