#!/usr/bin/env python3
from __future__ import annotations

import json
import re
import sys
from pathlib import Path


REPO = Path(__file__).resolve().parent.parent
MANIFEST = REPO / "scripts" / "eval" / "benchmark-cases.json"
DOC = REPO / "docs" / "cc-teams-excellence" / "BENCHMARK-CASES.md"

EXPECTED_CASE_IDS = [
    "P-01",
    "P-02",
    "P-03",
    "P-04",
    "P-05",
    "P-06",
    "B-01",
    "B-02",
    "B-03",
    "B-04",
    "B-05",
    "B-06",
    "B-07",
    "R-01",
    "R-02",
    "R-03",
    "R-04",
    "R-05",
    "R-06",
    "D-01",
    "D-02",
    "D-03",
    "D-04",
    "D-05",
    "D-06",
    "D-07",
]

EXPECTED_BY_WORKFLOW = {
    "PLAN": 6,
    "BUILD": 7,
    "REVIEW": 6,
    "DEBUG": 7,
}

REQUIRED_FIELDS = {
    "case_id",
    "workflow",
    "category",
    "risk_class",
    "coupling",
    "seeded_defects",
    "expected_topology",
    "pass_criteria",
    "primary_kpis",
}


def fail(message: str) -> None:
    print(f"[benchmark-corpus] {message}", file=sys.stderr)
    sys.exit(1)


def load_manifest() -> list[dict]:
    if not MANIFEST.is_file():
        fail(f"missing manifest: {MANIFEST}")
    try:
        data = json.loads(MANIFEST.read_text())
    except json.JSONDecodeError as exc:
        fail(f"invalid JSON in manifest: {exc}")
    if not isinstance(data, list):
        fail("manifest root must be a JSON array")
    return data


def extract_doc_case_ids() -> list[str]:
    if not DOC.is_file():
        fail(f"missing benchmark doc: {DOC}")
    ids: list[str] = []
    for line in DOC.read_text().splitlines():
        match = re.match(r"^\|\s*([PBRD]-\d{2})\s*\|", line)
        if match:
            ids.append(match.group(1))
    return ids


def main() -> None:
    manifest = load_manifest()
    doc_case_ids = extract_doc_case_ids()

    manifest_ids: list[str] = []
    workflow_counts = {key: 0 for key in EXPECTED_BY_WORKFLOW}

    for entry in manifest:
        if not isinstance(entry, dict):
            fail("manifest entries must be JSON objects")
        missing = REQUIRED_FIELDS - entry.keys()
        if missing:
            fail(f"case entry missing required fields {sorted(missing)}: {entry}")

        case_id = entry["case_id"]
        workflow = entry["workflow"]
        manifest_ids.append(case_id)

        if workflow not in EXPECTED_BY_WORKFLOW:
            fail(f"{case_id} has unsupported workflow: {workflow}")
        workflow_counts[workflow] += 1

        if entry["risk_class"] not in {"low", "medium", "high", "critical"}:
            fail(f"{case_id} has invalid risk_class: {entry['risk_class']}")
        if entry["coupling"] not in {"low", "medium", "high"}:
            fail(f"{case_id} has invalid coupling: {entry['coupling']}")
        if not isinstance(entry["seeded_defects"], int) or entry["seeded_defects"] < 0:
            fail(f"{case_id} has invalid seeded_defects: {entry['seeded_defects']}")
        if not isinstance(entry["pass_criteria"], list) or not entry["pass_criteria"]:
            fail(f"{case_id} must define non-empty pass_criteria")
        if not isinstance(entry["primary_kpis"], list) or not entry["primary_kpis"]:
            fail(f"{case_id} must define non-empty primary_kpis")

    if manifest_ids != EXPECTED_CASE_IDS:
        fail(
            "manifest case ids/order drifted.\n"
            f"expected: {EXPECTED_CASE_IDS}\n"
            f"actual:   {manifest_ids}"
        )

    if doc_case_ids != EXPECTED_CASE_IDS:
        fail(
            "benchmark doc case ids/order drifted.\n"
            f"expected: {EXPECTED_CASE_IDS}\n"
            f"actual:   {doc_case_ids}"
        )

    if len(manifest_ids) != 26:
        fail(f"manifest must contain 26 cases, found {len(manifest_ids)}")

    for workflow, expected_count in EXPECTED_BY_WORKFLOW.items():
        actual_count = workflow_counts[workflow]
        if actual_count != expected_count:
            fail(
                f"workflow {workflow} expected {expected_count} cases, found {actual_count}"
            )

    print("[benchmark-corpus] OK: canonical benchmark corpus has 26 aligned cases")


if __name__ == "__main__":
    main()
