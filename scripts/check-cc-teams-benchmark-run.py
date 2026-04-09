#!/usr/bin/env python3
from __future__ import annotations

import json
import sys
from pathlib import Path


ALLOWED_STATUSES = {"PASS", "FAIL", "PARTIAL", "NOT_RUN"}


def fail(message: str) -> None:
    print(f"[benchmark-run] {message}", file=sys.stderr)
    sys.exit(1)


def load_json(path: Path):
    try:
        return json.loads(path.read_text())
    except json.JSONDecodeError as exc:
        fail(f"invalid JSON in {path}: {exc}")


def main() -> None:
    if len(sys.argv) != 2:
        fail("usage: python3 scripts/check-cc-teams-benchmark-run.py <run-dir>")

    run_dir = Path(sys.argv[1]).resolve()
    if not run_dir.is_dir():
        fail(f"run directory does not exist: {run_dir}")

    manifest_path = run_dir / "cases-manifest.json"
    case_results_path = run_dir / "case-results.jsonl"
    summary_input_path = run_dir / "summary-input.json"

    for path in (manifest_path, case_results_path, summary_input_path):
        if not path.is_file():
            fail(f"missing required run file: {path}")

    manifest = load_json(manifest_path)
    if not isinstance(manifest, list) or not manifest:
        fail("cases-manifest.json must be a non-empty JSON array")

    manifest_case_ids = [entry.get("case_id") for entry in manifest]
    if any(not case_id for case_id in manifest_case_ids):
        fail("every manifest case must define case_id")
    if len(set(manifest_case_ids)) != len(manifest_case_ids):
        fail("cases-manifest.json contains duplicate case_id values")

    case_results = []
    for raw_line in case_results_path.read_text().splitlines():
        if not raw_line.strip():
            continue
        try:
            case_results.append(json.loads(raw_line))
        except json.JSONDecodeError as exc:
            fail(f"invalid JSON line in case-results.jsonl: {exc}")

    if len(case_results) != len(manifest):
        fail(
            "case-results.jsonl count does not match cases-manifest.json "
            f"({len(case_results)} != {len(manifest)})"
        )

    result_case_ids = [entry.get("case_id") for entry in case_results]
    if result_case_ids != manifest_case_ids:
        fail(
            "case-results.jsonl case_id order/content drifted from cases-manifest.json"
        )

    for entry in case_results:
        status = entry.get("status")
        if status not in ALLOWED_STATUSES:
            fail(f"{entry.get('case_id')} has invalid status: {status}")

    summary_input = load_json(summary_input_path)
    if not isinstance(summary_input, dict):
        fail("summary-input.json must be a JSON object")
    if "kpi_inputs" not in summary_input or not isinstance(
        summary_input["kpi_inputs"], dict
    ):
        fail("summary-input.json must contain a kpi_inputs object")

    print(
        "[benchmark-run] OK: run scaffold has aligned manifest, case results, and summary input"
    )


if __name__ == "__main__":
    main()
