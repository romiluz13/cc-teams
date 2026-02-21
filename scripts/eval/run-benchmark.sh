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

if [[ -d "$out_dir" && "$force" -ne 1 ]]; then
  echo "Run directory already exists: $out_dir" >&2
  echo "Use --force to overwrite." >&2
  exit 1
fi

rm -rf "$out_dir"
mkdir -p "$out_dir"

cat > "$out_dir/cases-manifest.json" <<'JSON'
[
  {"case_id":"P-01","workflow":"PLAN","risk_class":"high","coupling":"medium"},
  {"case_id":"P-02","workflow":"PLAN","risk_class":"critical","coupling":"high"},
  {"case_id":"P-03","workflow":"PLAN","risk_class":"high","coupling":"medium"},
  {"case_id":"P-04","workflow":"PLAN","risk_class":"medium","coupling":"high"},
  {"case_id":"P-05","workflow":"PLAN","risk_class":"medium","coupling":"medium"},
  {"case_id":"P-06","workflow":"PLAN","risk_class":"high","coupling":"medium"},

  {"case_id":"B-01","workflow":"BUILD","risk_class":"medium","coupling":"low"},
  {"case_id":"B-02","workflow":"BUILD","risk_class":"high","coupling":"high"},
  {"case_id":"B-03","workflow":"BUILD","risk_class":"critical","coupling":"high"},
  {"case_id":"B-04","workflow":"BUILD","risk_class":"high","coupling":"high"},
  {"case_id":"B-05","workflow":"BUILD","risk_class":"critical","coupling":"medium"},
  {"case_id":"B-06","workflow":"BUILD","risk_class":"high","coupling":"medium"},

  {"case_id":"R-01","workflow":"REVIEW","risk_class":"critical","coupling":"medium"},
  {"case_id":"R-02","workflow":"REVIEW","risk_class":"high","coupling":"medium"},
  {"case_id":"R-03","workflow":"REVIEW","risk_class":"medium","coupling":"low"},
  {"case_id":"R-04","workflow":"REVIEW","risk_class":"medium","coupling":"low"},
  {"case_id":"R-05","workflow":"REVIEW","risk_class":"high","coupling":"medium"},
  {"case_id":"R-06","workflow":"REVIEW","risk_class":"high","coupling":"medium"},

  {"case_id":"D-01","workflow":"DEBUG","risk_class":"medium","coupling":"low"},
  {"case_id":"D-02","workflow":"DEBUG","risk_class":"critical","coupling":"high"},
  {"case_id":"D-03","workflow":"DEBUG","risk_class":"high","coupling":"medium"},
  {"case_id":"D-04","workflow":"DEBUG","risk_class":"critical","coupling":"high"},
  {"case_id":"D-05","workflow":"DEBUG","risk_class":"high","coupling":"medium"},
  {"case_id":"D-06","workflow":"DEBUG","risk_class":"high","coupling":"high"}
]
JSON

jq -cr '
  .[] | {
    case_id,
    workflow,
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
- Use `cases-manifest.json` as the source case list.
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
