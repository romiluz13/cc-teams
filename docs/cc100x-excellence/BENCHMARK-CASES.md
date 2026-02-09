# CC100x Benchmark Cases

## Purpose
Define the pre-production benchmark corpus used to compare CC100x against CC10x and validate quality gates from `KPI-SCORECARD.md`.

## Corpus Design Principles
1. Cover the entire SDLC: PLAN, BUILD, REVIEW, DEBUG.
2. Include realistic ambiguity and failure modes.
3. Include seeded defects for objective review/debug scoring.
4. Include orchestration stress scenarios (parallelism, interruption, remediation loops).
5. Keep fixtures deterministic and replayable.

## Case Metadata Schema
Each case must include:
1. `case_id`
2. `workflow`
3. `category`
4. `risk_class` (`low|medium|high|critical`)
5. `coupling` (`low|medium|high`)
6. `seeded_defects` (count, optional)
7. `expected_topology`
8. `pass_criteria`
9. `primary_kpis`

Recommended YAML record:

```yaml
case_id: B-03
workflow: BUILD
category: shared-state-concurrency
risk_class: high
coupling: high
seeded_defects: 0
expected_topology: "builder + live-reviewer -> hunter -> review-arena -> verifier"
pass_criteria:
  - "No data race regression in test suite"
  - "Verifier passes all concurrency scenarios"
primary_kpis: [K1, K5, K6, K8]
```

## Benchmark Matrix (v1)

| Case ID | Workflow | Scenario | Risk | Coupling | Expected Topology | Primary KPIs |
|---|---|---|---|---|---|---|
| P-01 | PLAN | Ambiguous feature with conflicting requirements | High | Medium | planner with plan approval | K1, K8 |
| P-02 | PLAN | Cross-layer auth redesign | Critical | High | planner with architecture constraints | K1, K8 |
| P-03 | PLAN | Migration plan with rollback strategy | High | Medium | planner + risk-heavy plan | K1, K8 |
| P-04 | PLAN | Legacy module decomposition plan | Medium | High | planner decomposition roadmap | K1, K8 |
| P-05 | PLAN | External SDK integration planning | Medium | Medium | planner + external research context | K1, K8 |
| P-06 | PLAN | Incident follow-up hardening roadmap | High | Medium | planner with phased remediation | K1, K8 |
| B-01 | BUILD | Low-coupling feature implementation | Medium | Low | pair-build standard chain | K1, K5, K8 |
| B-02 | BUILD | Cross-layer feature (UI+API+tests) | High | High | pair-build full chain | K1, K5, K6, K8 |
| B-03 | BUILD | Shared-state concurrency feature | Critical | High | pair-build + strict verifier focus | K1, K5, K6, K8 |
| B-04 | BUILD | File-overlap stress (parallel safety) | High | High | deterministic profile expected | K6, K8, K10 |
| B-05 | BUILD | Security-sensitive auth flow | Critical | Medium | pair-build + strong review arena | K1, K2, K3, K5 |
| B-06 | BUILD | Performance-sensitive endpoint | High | Medium | pair-build + perf scrutiny | K1, K2, K5 |
| R-01 | REVIEW | Seeded OWASP defects | Critical | Medium | review-arena triad + challenge | K2, K3, K8 |
| R-02 | REVIEW | Seeded performance regressions | High | Medium | review-arena triad + challenge | K2, K3 |
| R-03 | REVIEW | Maintainability/code smell cluster | Medium | Low | review-arena quality-heavy | K2 |
| R-04 | REVIEW | False-positive trap corpus | Medium | Low | review-arena precision stress | K2, K10 |
| R-05 | REVIEW | Pre-existing vs new issue separation | High | Medium | review-arena causality check | K2, K8 |
| R-06 | REVIEW | Cross-review conflict scenario | High | Medium | review challenge resolution | K2, K8, K10 |
| D-01 | DEBUG | Deterministic crash with stack trace | Medium | Low | bug-court with 2-3 hypotheses | K4, K5, K8 |
| D-02 | DEBUG | Intermittent race condition | Critical | High | bug-court with 4-5 hypotheses | K4, K5, K6 |
| D-03 | DEBUG | External API behavior regression | High | Medium | bug-court + research-aware path | K4, K5 |
| D-04 | DEBUG | Ambiguous multi-root-cause symptoms | Critical | High | bug-court full debate rigor | K4, K5, K10 |
| D-05 | DEBUG | Session interruption recovery mid-flow | High | Medium | recovery protocol + resumed team | K6, K7, K8 |
| D-06 | DEBUG | Multi-remediation loop stress | High | High | bug-court + remediation re-review | K5, K6, K8 |

Total cases: `24`

## Pass Criteria by Workflow

## PLAN
1. Plan is actionable and phase-structured.
2. Risks and validation commands are explicit.
3. Memory references and artifacts are correctly linked.

## BUILD
1. TDD evidence exists (RED then GREEN).
2. Post-build gates pass (hunter + review arena + verifier).
3. No orchestration integrity violations.

## REVIEW
1. High-confidence findings are mostly true positives.
2. Seeded defects are detected at target rates.
3. Challenge round resolves conflicts explicitly.

## DEBUG
1. Winning hypothesis maps to actual root cause.
2. First fix is verified and stable where expected.
3. Recovery behavior is correct after interruption scenarios.

## Execution Protocol
1. Run full corpus with `deterministic` profile first.
2. Run full corpus with `adaptive` profile.
3. Run full corpus with `turbo-quality` profile.
4. Compare each profile against CC10x baseline `B0`.
5. Record all runs in decision log before any release decision.

## Fixture and Artifact Conventions
1. Fixtures: `artifacts/eval/fixtures/<case_id>/`
2. Run outputs: `artifacts/eval/<timestamp>/<profile>/`
3. Case results: one JSON line per case in `case-results.jsonl`
4. Scorecard computed from case results only (no manual edits)

## Benchmark Readiness Checklist
1. Every case has deterministic fixture.
2. Every case has explicit expected outcomes.
3. Seeded defects are documented with ground truth.
4. Case runner can execute all 24 cases without manual intervention.
5. Failure in one case does not stop corpus execution.
