#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  bash scripts/eval/run-benchmark.sh [options]

Options:
  --candidate <name>          Candidate label (default: cc-teams)
  --profile <name>            Execution profile (default: deterministic)
  --baseline-id <id>          Baseline label for comparison metadata (default: B0)
  --run-id <id>               Run id (default: UTC timestamp YYYYMMDDTHHMMSSZ)
  --force                     Overwrite existing run directory if present
  -h, --help                  Show this help

Output:
  artifacts/eval/<run-id>/<profile>/
    - cases-manifest.json
    - case-results.jsonl
    - summary-input.json
    - README.md
USAGE
}

candidate="cc-teams"
profile="deterministic"
baseline_id="B0"
run_id="$(date -u +%Y%m%dT%H%M%SZ)"
force=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --candidate)
      candidate="$2"
      shift 2
      ;;
    --profile)
      profile="$2"
      shift 2
      ;;
    --baseline-id)
      baseline_id="$2"
      shift 2
      ;;
    --run-id)
      run_id="$2"
      shift 2
      ;;
    --force)
      force=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

repo="$(cd "$(dirname "$0")/../.." && pwd)"
out_dir="$repo/artifacts/eval/$run_id/$profile"
manifest_src="$repo/scripts/eval/benchmark-cases.json"
fixture_index_src="$repo/artifacts/eval/fixtures/index.json"

if [[ -d "$out_dir" && "$force" -ne 1 ]]; then
  echo "Run directory already exists: $out_dir" >&2
  echo "Use --force to overwrite." >&2
  exit 1
fi

if [[ ! -f "$manifest_src" ]]; then
  echo "Missing canonical benchmark manifest: $manifest_src" >&2
  exit 1
fi

if [[ ! -f "$fixture_index_src" ]]; then
  echo "Missing canonical fixture index: $fixture_index_src" >&2
  exit 1
fi

rm -rf "$out_dir"
mkdir -p "$out_dir"

jq -n \
  --slurpfile cases "$manifest_src" \
  --slurpfile fixtures "$fixture_index_src" '
    $cases[0] as $case_list |
    $fixtures[0] as $fixture_list |
    [
      $case_list[] as $case |
      ($fixture_list[] | select(.case_id == $case.case_id)) as $fixture |
      ($case + {
        fixture_id: $fixture.fixture_id,
        deterministic_seed: $fixture.deterministic_seed,
        interruption_profile: $fixture.interruption_profile,
        ground_truth_mode: $fixture.ground_truth_mode,
        fixture_notes: $fixture.fixture_notes
      })
    ]
  ' > "$out_dir/cases-manifest.json"

cp "$fixture_index_src" "$out_dir/fixtures-index.json"

jq -cr '
  .[] | {
    case_id,
    workflow,
    category,
    risk_class,
    coupling,
    seeded_defects,
    expected_topology,
    pass_criteria,
    primary_kpis,
    status: "NOT_RUN",
    result_notes: "",
    metrics: {
      implemented_required: 0,
      total_required: 0,
      true_positive_high_conf: 0,
      total_high_conf: 0,
      seeded_critical_found: 0,
      seeded_critical_total: 0,
      correct_root_cause_cases: 0,
      debug_cases: 0,
      first_cycle_pass_cases: 0,
      remediation_cases: 0,
      successful_orchestration_runs: 0,
      total_runs: 0,
      successful_recoveries: 0,
      interruption_tests: 0,
      tasks_with_complete_evidence: 0,
      completed_tasks: 0,
      override_runs: 0,
      memory_recall_score: null
    }
  }
' "$out_dir/cases-manifest.json" > "$out_dir/case-results.jsonl"

cat > "$out_dir/summary-input.json" <<JSON
{
  "run_id": "$run_id",
  "candidate": "$candidate",
  "profile": "$profile",
  "baseline_id": "$baseline_id",
  "kpi_inputs": {
    "implemented_required": 0,
    "total_required": 0,
    "true_positive_high_conf": 0,
    "total_high_conf": 0,
    "seeded_critical_found": 0,
    "seeded_critical_total": 0,
    "correct_root_cause_cases": 0,
    "debug_cases": 0,
    "first_cycle_pass_cases": 0,
    "remediation_cases": 0,
    "successful_orchestration_runs": 0,
    "total_runs": 0,
    "successful_recoveries": 0,
    "interruption_tests": 0,
    "tasks_with_complete_evidence": 0,
    "completed_tasks": 0,
    "memory_recall_scores": [],
    "override_runs": 0
  },
  "notes": "Fill this after executing benchmark cases."
}
JSON

cat > "$out_dir/README.md" <<'MD'
# Benchmark Run Scaffold

## 1) Execute Cases
- `cases-manifest.json` is copied from the canonical corpus at `scripts/eval/benchmark-cases.json`.
- `fixtures-index.json` is copied from the canonical deterministic fixture corpus at `artifacts/eval/fixtures/index.json`.
- Record each case status in `case-results.jsonl` (`PASS|FAIL|PARTIAL|NOT_RUN`).

## 2) Aggregate KPI Inputs
- Fill totals in `summary-input.json` under `kpi_inputs`.
- Use real run evidence only (retrospectives, verifier output, task logs).

## 3) Score
```bash
bash scripts/eval/score-benchmark.sh --run-dir artifacts/eval/<run-id>/<profile>
```

## Generated Outputs (after scoring)
- `summary.json`
- `scorecard.json`

MD

echo "Benchmark scaffold created: $out_dir"
echo "Next step: fill summary-input.json and run score-benchmark.sh"
