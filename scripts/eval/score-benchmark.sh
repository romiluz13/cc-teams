#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  bash scripts/eval/score-benchmark.sh [options]

Options:
  --run-dir <path>            Run profile directory (artifacts/eval/<run-id>/<profile>)
  --run-id <id>               Run id under artifacts/eval/
  --profile <name>            Profile name (default: deterministic)
  --baseline-scorecard <path> Optional baseline scorecard.json for relative targets
  -h, --help                  Show this help

If no --run-dir and no --run-id are provided, the latest run/profile directory is used.
USAGE
}

repo="$(cd "$(dirname "$0")/../.." && pwd)"
profile="deterministic"
run_dir=""
run_id=""
baseline_scorecard=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --run-dir)
      run_dir="$2"
      shift 2
      ;;
    --run-id)
      run_id="$2"
      shift 2
      ;;
    --profile)
      profile="$2"
      shift 2
      ;;
    --baseline-scorecard)
      baseline_scorecard="$2"
      shift 2
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

if [[ -n "$run_dir" && -n "$run_id" ]]; then
  echo "Use either --run-dir or --run-id, not both." >&2
  exit 1
fi

if [[ -n "$run_id" ]]; then
  run_dir="$repo/artifacts/eval/$run_id/$profile"
elif [[ -z "$run_dir" ]]; then
  latest="$(find "$repo/artifacts/eval" -mindepth 2 -maxdepth 2 -type d 2>/dev/null | sort | tail -1 || true)"
  if [[ -z "$latest" ]]; then
    echo "No benchmark runs found under artifacts/eval/" >&2
    exit 1
  fi
  run_dir="$latest"
fi

if [[ ! -d "$run_dir" ]]; then
  echo "Run directory does not exist: $run_dir" >&2
  exit 1
fi

summary_input="$run_dir/summary-input.json"
cases_manifest="$run_dir/cases-manifest.json"
case_results="$run_dir/case-results.jsonl"
summary_out="$run_dir/summary.json"
scorecard_out="$run_dir/scorecard.json"

if [[ ! -f "$summary_input" ]]; then
  echo "Missing summary input: $summary_input" >&2
  exit 1
fi

if [[ ! -f "$case_results" ]]; then
  echo "Missing case results file: $case_results" >&2
  exit 1
fi

if [[ ! -f "$cases_manifest" ]]; then
  echo "Missing cases manifest: $cases_manifest" >&2
  exit 1
fi

python3 "$repo/scripts/check-cc-teams-benchmark-run.py" "$run_dir" >/dev/null

status_json="$(jq -s '{
  total_cases: length,
  pass_cases: (map(select(.status == "PASS")) | length),
  fail_cases: (map(select(.status == "FAIL")) | length),
  partial_cases: (map(select(.status == "PARTIAL")) | length),
  not_run_cases: (map(select(.status == "NOT_RUN")) | length)
}' "$case_results")"

baseline_json='{}'
baseline_available=false
if [[ -n "$baseline_scorecard" ]]; then
  if [[ ! -f "$baseline_scorecard" ]]; then
    echo "Baseline scorecard path not found: $baseline_scorecard" >&2
    exit 1
  fi
  baseline_json="$(cat "$baseline_scorecard")"
  baseline_available=true
fi

jq -n \
  --arg run_dir "$run_dir" \
  --arg generated_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --argjson manifest "$(cat "$cases_manifest")" \
  --argjson inputs "$(cat "$summary_input")" \
  --argjson statuses "$status_json" \
  --argjson baseline "$baseline_json" \
  --argjson baseline_available "$baseline_available" \
'
  def safe_rate($n; $d): if ($d == 0) then null else ($n / $d) end;
  def avg($arr): if ($arr | length) == 0 then null else (($arr | add) / ($arr | length)) end;
  def at_least($v; $min): ($v != null and $v >= $min);
  def equal_to($v; $target): ($v != null and $v == $target);
  def at_most($v; $max): ($v != null and $v <= $max);
  def clamp01($v):
    if $v == null then 0
    elif $v < 0 then 0
    elif $v > 1 then 1
    else $v end;

  $inputs as $in |
  ($in.kpi_inputs // {}) as $k |

  {
    K1: safe_rate(($k.implemented_required // 0); ($k.total_required // 0)),
    K2: safe_rate(($k.true_positive_high_conf // 0); ($k.total_high_conf // 0)),
    K3: safe_rate(($k.seeded_critical_found // 0); ($k.seeded_critical_total // 0)),
    K4: safe_rate(($k.correct_root_cause_cases // 0); ($k.debug_cases // 0)),
    K5: safe_rate(($k.first_cycle_pass_cases // 0); ($k.remediation_cases // 0)),
    K6: safe_rate(($k.successful_orchestration_runs // 0); ($k.total_runs // 0)),
    K7: safe_rate(($k.successful_recoveries // 0); ($k.interruption_tests // 0)),
    K8: safe_rate(($k.tasks_with_complete_evidence // 0); ($k.completed_tasks // 0)),
    K9: avg(($k.memory_recall_scores // [])),
    K10: safe_rate(($k.override_runs // 0); ($k.total_runs // 0))
  } as $kpis |

  {
    K1: at_least($kpis.K1; 0.98),
    K2: at_least($kpis.K2; 0.93),
    K3: at_least($kpis.K3; 0.90),
    K4: at_least($kpis.K4; 0.85),
    K5: at_least($kpis.K5; 0.80),
    K6: equal_to($kpis.K6; 1),
    K7: at_least($kpis.K7; 0.98),
    K8: equal_to($kpis.K8; 1)
  } as $hard_abs |

  {
    K9: at_least($kpis.K9; 4.2),
    K10: at_most($kpis.K10; 0.12)
  } as $soft_gate |

  {
    K1: 0.16,
    K2: 0.14,
    K3: 0.10,
    K4: 0.14,
    K5: 0.12,
    K6: 0.14,
    K7: 0.10,
    K8: 0.10
  } as $weights |

  (
    (clamp01($kpis.K1) * $weights.K1) +
    (clamp01($kpis.K2) * $weights.K2) +
    (clamp01($kpis.K3) * $weights.K3) +
    (clamp01($kpis.K4) * $weights.K4) +
    (clamp01($kpis.K5) * $weights.K5) +
    (clamp01($kpis.K6) * $weights.K6) +
    (clamp01($kpis.K7) * $weights.K7) +
    (clamp01($kpis.K8) * $weights.K8)
  ) as $cqi |

  (if $baseline_available and ($baseline.kpis != null) then {
      K1: (if ($kpis.K1 != null and $baseline.kpis.K1 != null) then $kpis.K1 - $baseline.kpis.K1 else null end),
      K2: (if ($kpis.K2 != null and $baseline.kpis.K2 != null) then $kpis.K2 - $baseline.kpis.K2 else null end),
      K3: (if ($kpis.K3 != null and $baseline.kpis.K3 != null) then $kpis.K3 - $baseline.kpis.K3 else null end),
      K4: (if ($kpis.K4 != null and $baseline.kpis.K4 != null) then $kpis.K4 - $baseline.kpis.K4 else null end),
      K5: (if ($kpis.K5 != null and $baseline.kpis.K5 != null) then $kpis.K5 - $baseline.kpis.K5 else null end),
      K6: (if ($kpis.K6 != null and $baseline.kpis.K6 != null) then $kpis.K6 - $baseline.kpis.K6 else null end),
      K7: (if ($kpis.K7 != null and $baseline.kpis.K7 != null) then $kpis.K7 - $baseline.kpis.K7 else null end),
      K8: (if ($kpis.K8 != null and $baseline.kpis.K8 != null) then $kpis.K8 - $baseline.kpis.K8 else null end),
      K10: (if ($kpis.K10 != null and $baseline.kpis.K10 != null) then $kpis.K10 - $baseline.kpis.K10 else null end)
    }
   else null end) as $delta |

  (if $delta == null then null else {
      K1: ($delta.K1 != null and $delta.K1 >= 0.02),
      K2: ($delta.K2 != null and $delta.K2 >= 0.03),
      K3: ($delta.K3 != null and $delta.K3 >= 0.05),
      K4: ($delta.K4 != null and $delta.K4 >= 0.05),
      K5: ($delta.K5 != null and $delta.K5 >= 0.05),
      K6: ($delta.K6 != null and $delta.K6 >= 0),
      K8: ($delta.K8 != null and $delta.K8 >= 0),
      K10: ($delta.K10 != null and $delta.K10 <= -0.05)
    }
   end) as $relative_target_pass |

  {
    run_id: ($in.run_id // "unknown"),
    candidate: ($in.candidate // "unknown"),
    profile: ($in.profile // "unknown"),
    baseline_id: ($in.baseline_id // null),
    generated_at: $generated_at,
    run_dir: $run_dir,
    corpus: {
      total_cases: ($manifest | length),
      workflows: ($manifest | group_by(.workflow) | map({workflow: .[0].workflow, count: length}))
    },
    case_status: $statuses,
    inputs: $k,
    kpis: $kpis,
    hard_gate_absolute: {
      checks: $hard_abs,
      pass: ($hard_abs | to_entries | all(.value == true))
    },
    soft_gate: {
      checks: $soft_gate,
      pass: ($soft_gate | to_entries | all(.value == true))
    },
    baseline_comparison: {
      available: $baseline_available,
      deltas: $delta,
      relative_target_pass: $relative_target_pass,
      pass: (if $relative_target_pass == null then null else ($relative_target_pass | to_entries | all(.value == true)) end)
    },
    cqi: $cqi,
    hard_gate_pass: (
      ($hard_abs | to_entries | all(.value == true)) and
      (
        if $relative_target_pass == null then true
        else ($relative_target_pass | to_entries | all(.value == true))
        end
      )
    )
  }
' > "$scorecard_out"

jq '{
  run_id,
  candidate,
  profile,
  generated_at,
  case_status,
  hard_gate_pass,
  hard_gate_absolute,
  soft_gate,
  baseline_comparison,
  cqi
}' "$scorecard_out" > "$summary_out"

echo "Scored benchmark run: $run_dir"
echo "- $summary_out"
echo "- $scorecard_out"
