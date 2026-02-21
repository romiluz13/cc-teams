# CC-Teams Excellence KPI Scorecard

## Purpose
Define measurable quality gates for production-safe CC-Teams upgrades without regressing CC10x core reliability.

This scorecard is quality-first. It intentionally excludes cost optimization.

## Measurement Principles
1. Compare CC-Teams against CC10x on the same benchmark corpus.
2. Require both absolute quality floors and relative improvement over CC10x baseline.
3. Block release if any hard gate fails.
4. Prefer reproducible measurements over subjective impressions.

## Baseline Protocol
1. Run benchmark corpus with CC10x (Baseline `B0`).
2. Run benchmark corpus with CC-Teams candidate (`C1`, `C2`, ...).
3. Use identical fixtures, seeds, and execution environment.

## KPI Definitions

| KPI ID | Metric | Definition | Formula | Absolute Floor | Relative Target vs B0 | Gate |
|---|---|---|---|---|---|---|
| K1 | Spec Compliance Rate | Required requirements correctly implemented | `implemented_required / total_required` | `>= 0.98` | `+0.02` | Hard |
| K2 | Review Precision@80+ | High-confidence review findings that are true positives | `true_positive_high_conf / total_high_conf` | `>= 0.93` | `+0.03` | Hard |
| K3 | Review Recall (Seeded Criticals) | Seeded critical defects detected by review workflow | `seeded_critical_found / seeded_critical_total` | `>= 0.90` | `+0.05` | Hard |
| K4 | Root Cause Hit Rate | Debug verdict identifies actual root cause | `correct_root_cause_cases / debug_cases` | `>= 0.85` | `+0.05` | Hard |
| K5 | First-Fix Verification Pass | Cases fixed successfully in first remediation cycle | `first_cycle_pass_cases / remediation_cases` | `>= 0.80` | `+0.05` | Hard |
| K6 | Orchestration Reliability | No deadlocks/stalled DAG execution | `successful_orchestration_runs / total_runs` | `= 1.00` | maintain | Hard |
| K7 | Interruption Recovery Success | Resume/recovery after teammate loss works correctly | `successful_recoveries / interruption_tests` | `>= 0.98` | `+0.03` | Hard |
| K8 | Evidence Completeness | Tasks completed with full required evidence in contracts | `tasks_with_complete_evidence / completed_tasks` | `= 1.00` | maintain | Hard |
| K9 | Memory Recall Utility | Quality of resumed-session memory usefulness (human-rated) | average reviewer score `1-5` | `>= 4.2` | `+0.4` | Soft |
| K10 | Human Override Rate | Runs requiring manual override due orchestration ambiguity | `override_runs / total_runs` | `<= 0.12` | `-0.05` | Soft |

## Composite Quality Index (CQI)

Use CQI for ranking candidates; release still depends on hard gates.

`CQI = Σ(weight_i * normalized_kpi_i)`

Recommended weights:

| KPI | Weight |
|---|---|
| K1 | 0.16 |
| K2 | 0.14 |
| K3 | 0.10 |
| K4 | 0.14 |
| K5 | 0.12 |
| K6 | 0.14 |
| K7 | 0.10 |
| K8 | 0.10 |

Total: `1.00`

## Release Gate Policy
1. All hard KPIs (K1-K8) must pass.
2. Hard KPI pass must be sustained for 3 consecutive full benchmark runs.
3. If any hard KPI fails, release is blocked until corrected and re-validated.
4. Soft KPIs (K9-K10) do not block release but require decision-log signoff if below target.

## Execution Profile Expectations (Current vs Roadmap)
1. Current runtime baseline is `deterministic`; all hard-gate decisions use this baseline.
2. If `adaptive` is introduced later, it must not regress any hard KPI versus deterministic.
3. If `turbo-quality` is introduced later, it must also pass all hard KPIs before adoption.

## Required Scorecard Outputs
Each benchmark run must produce:
1. `artifacts/eval/<timestamp>/<profile>/summary.json`
2. `artifacts/eval/<timestamp>/<profile>/scorecard.json`
3. `artifacts/eval/<timestamp>/<profile>/case-results.jsonl`

Minimum `scorecard.json` shape:

```json
{
  "run_id": "2026-02-09T16-45-00Z",
  "candidate": "cc-teams",
  "profile": "deterministic",
  "kpis": {
    "K1": 0.99,
    "K2": 0.94,
    "K3": 0.92,
    "K4": 0.87,
    "K5": 0.82,
    "K6": 1.0,
    "K7": 0.99,
    "K8": 1.0,
    "K9": 4.4,
    "K10": 0.08
  },
  "hard_gate_pass": true,
  "soft_gate_pass": true,
  "cqi": 0.93
}
```

## Ownership
1. Scorecard definitions: orchestration owner.
2. Data generation: evaluation harness.
3. Final gate decision: release governance decision log.
