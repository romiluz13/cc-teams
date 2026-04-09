---
name: router-contract
description: |
  Defines the YAML Router Contract format that ALL CC-Teams teammates must output.
  Used by the lead to validate teammate work and make orchestration decisions.
---

# Router Contract (CC-Teams)

## Purpose

The Router Contract is a machine-readable YAML block output by every teammate at the end of their work. The lead uses it to:
- Validate teammate output quality
- Decide whether to proceed or block
- Collect memory notes for persistence
- Resolve conflicts between teammates

---

## Contract Format (REQUIRED)

Every teammate MUST include this section at the end of their output:

````markdown
### Router Contract (MACHINE-READABLE)
```yaml
CONTRACT_VERSION: "2.5"
STATUS: [value from agent-specific list below]
CONFIDENCE: [0-100]
CRITICAL_ISSUES: [count]
HIGH_ISSUES: [count]
BLOCKING: [true|false]
REQUIRES_REMEDIATION: [true|false]
REMEDIATION_REASON: [null or description of what needs fixing]
SPEC_COMPLIANCE: [PASS|FAIL|N/A]
TRACEABILITY_IMPACT: [none|risk_detected|conflict_detected]   # reviewers + hunter + live-reviewer
REQUIREMENTS_AT_RISK: [list or empty]                         # reviewers + hunter + live-reviewer
ACCEPTANCE_CRITERIA_AT_RISK: [list or empty]                  # reviewers + hunter + live-reviewer
DECISION_DEPENDENCIES_AT_RISK: [list or empty]                # reviewers + hunter + live-reviewer
# v2.5 additions (agent-specific — include only for relevant roles):
PHASE_ID: "[phase id or ad-hoc-scope]"         # builder family
PHASE_STATUS: [completed|partial|blocked]      # builder family
PHASE_EXIT_READY: [true|false]                 # builder family
CHECKPOINT_TYPE: [none|human_verify|decision|human_action]  # builder family
PROOF_STATUS: [passed|gaps_found|human_needed] # builder family + verifier
INPUTS: [list or empty]                        # builder family
EXPECTED_ARTIFACTS: [list or empty]            # builder family
REQUIREMENT_IDS_IN_SCOPE: [list or empty]      # builder family
ACCEPTANCE_CRITERIA_IN_SCOPE: [list or empty]  # builder family
APPROVED_DECISION_DEPENDENCIES: [list or empty] # builder family
REQUIREMENTS_SATISFIED: [list or empty]        # builder family
ACCEPTANCE_CRITERIA_SATISFIED: [list or empty] # builder family
DECISION_DEPENDENCIES_SATISFIED: [list or empty] # builder family
TDD_RED_EXIT: [1|null]                         # builder family
TDD_GREEN_EXIT: [0|null]                      # builder family
PHASE_GATE_RESULT: [PASS|FAIL|N/A]            # builder family
PHASE_GATE_CMD: ["gate command or N/A"]       # builder family
SCENARIOS:                                    # builder family
  - name: "[scenario name]"
    given: "[state]"
    when: "[action]"
    then: "[result]"
    command: "[exact command]"
    expected: "[expected result]"
    actual: "[actual result]"
    exit_code: [code]
    status: [PASS|FAIL|BLOCKED]
ASSUMPTIONS: [list or empty]                  # builder family
DECISIONS: [list or empty]                    # builder family
BLOCKED_ITEMS: [list or empty]                # builder family
SKIPPED_ITEMS: [list or empty]                # builder family
SCOPE_INCREASES: [list or empty]              # builder family
PLAN_MODE: [direct|execution_plan|decision_rfc]    # planner only
VERIFICATION_RIGOR: [standard|critical_path]       # planner only
OPEN_DECISIONS: [list or empty]                    # planner only
RECOMMENDED_DEFAULTS: [list or empty]              # planner only
CONTRADICTIONS_FOUND: [count]                      # planner only
REQUIREMENT_PHASE_COVERAGE: [complete|gaps_found]  # planner only
ACCEPTANCE_PROOF_COVERAGE: [complete|gaps_found]   # planner only
FINDING_BUCKETS:                                   # plan-gap-reviewer only
  repo_mismatches: [count]
  missing_surfaces: [count]
  execution_order_issues: [count]
  hidden_assumptions: [count]
  under_scoped_integrations: [count]
  open_decisions_presented_as_settled: [count]
  requirement_conflicts: [count]
  traceability_gaps: [count]
REPLAN_NEEDED: [true|false]                        # plan-gap-reviewer only
REPLAN_REASON: [reason or "None"]                  # plan-gap-reviewer only
DEPENDENCY_AUDIT: [PASS|WARN|FAIL|SKIPPED]  # verifier + security-reviewer
DEPENDENCY_AUDIT_DETAIL: ["detail or N/A"]  # verifier only
SCENARIOS_FAILED: [count]                       # verifier only
PROOF_RECONCILIATION:                           # verifier only
  truths: [verified|missing|human_needed]
  artifacts: [verified|missing|human_needed]
  wiring: [verified|missing|human_needed]
SCENARIO_EVIDENCE:                              # verifier only
  - name: "[scenario]"
    command: "[command]"
    expected: "[expected]"
    actual: "[actual]"
    exit: [code]
    result: [PASS|FAIL|BLOCKED]
TRACEABILITY_STATUS: [verified|gaps_found|human_needed]  # verifier only
REQUIREMENTS_VERIFIED: [list or empty]                   # verifier only
ACCEPTANCE_CRITERIA_VERIFIED: [list or empty]            # verifier only
DECISION_DEPENDENCIES_CHECKED: [list or empty]           # verifier only
TRACEABILITY_GAPS: [list or empty]                       # verifier only
STATE_DELTA:
  what_changed: [list or empty]
  remains_open: [list or empty]
  should_stay_closed: [list or empty]
  next_trigger: "[next required action or None]"
TIMESTAMP: [ISO 8601 timestamp]
AGENT_ID: [teammate name, e.g., "investigator-1"]
FILES_MODIFIED: [list of files changed, or empty]
CLAIMED_ARTIFACTS: [durable files claimed as created/updated by this teammate, or empty]
EVIDENCE_COMMANDS: ["command => exit <code>", "..."]
DEVIATIONS_FROM_PLAN: [null or description of what changed from plan]
MEMORY_NOTES:
  learnings: ["insight 1", "insight 2"]
  patterns: ["pattern or gotcha discovered"]
  verification: ["evidence of what was verified"]
```
````

---

## STATUS Values by Agent

| Agent | Valid STATUS Values | Description |
|-------|-------------------|-------------|
| **builder** | `PASS`, `FAIL` | PASS = phase completed, exit-ready, proof passed, RED exit=1, GREEN exit=0, and at least one passing scenario |
| **frontend-builder** | `PASS`, `FAIL` | Same as builder; FILES_MODIFIED must be frontend-scope only |
| **backend-builder** | `PASS`, `FAIL` | Same as builder; FILES_MODIFIED must be backend-scope only; API_CONTRACT_SPEC required in MEMORY_NOTES |
| **security-reviewer** | `APPROVE`, `CHANGES_REQUESTED` | APPROVE requires CRITICAL_ISSUES=0 and CONFIDENCE>=80 |
| **performance-reviewer** | `APPROVE`, `CHANGES_REQUESTED` | APPROVE requires CRITICAL_ISSUES=0 and CONFIDENCE>=80 |
| **quality-reviewer** | `APPROVE`, `CHANGES_REQUESTED` | APPROVE requires CRITICAL_ISSUES=0 and CONFIDENCE>=80 |
| **accessibility-reviewer** | `APPROVE`, `CHANGES_REQUESTED` | APPROVE requires CRITICAL_ISSUES=0 and CONFIDENCE>=80 (WCAG AA violations) |
| **api-contract-reviewer** | `APPROVE`, `CHANGES_REQUESTED` | APPROVE requires CRITICAL_ISSUES=0 and CONFIDENCE>=80 (breaking changes) |
| **live-reviewer** | `APPROVE`, `CHANGES_REQUESTED` | APPROVE requires no STOP-level issues raised |
| **hunter** | `CLEAN`, `ISSUES_FOUND` | CLEAN requires CRITICAL_ISSUES=0 |
| **verifier** | `PASS`, `FAIL` | PASS requires all scenarios passed |
| **investigator** | `EVIDENCE_FOUND`, `INVESTIGATING`, `BLOCKED` | EVIDENCE_FOUND requires reproduction evidence |
| **planner** | `PLAN_CREATED`, `NEEDS_CLARIFICATION` | PLAN_CREATED requires plan file saved, plan mode + verification rigor set, and CONFIDENCE>=50 |
| **plan-gap-reviewer** | `PASS`, `FINDINGS` | PASS requires zero blocking findings, no replan needed, and evidence-backed positive assertions |

---

## Field Definitions

### CONTRACT_VERSION
Contract schema version emitted by teammate. Current target is `2.5`.
- `2.5`: Added universal `STATE_DELTA` so every teammate reports what changed, what remains open, what must stay closed, and the next trigger
- `2.4`: Added builder-family phase-proof fields, PHASE_GATE_RESULT/PHASE_GATE_CMD, and verifier/security dependency + proof fields
- `2.3`: Stable baseline (all existing fields)

### STATUS
Agent's self-reported completion status. See table above for valid values per agent.

### CONFIDENCE
0-100 score indicating how confident the agent is in their output.
- Reviewers: >=80 to report findings
- Builder: based on assumption certainty
- Investigator: based on evidence strength
- Planner: >=50 required for `PLAN_CREATED`

### CRITICAL_ISSUES
Count of blocking issues found. Only reviewers and hunter use this.
- CRITICAL_ISSUES > 0 typically means BLOCKING=true

### HIGH_ISSUES
Count of high-severity issues. Non-blocking but should be addressed.

### BLOCKING
Whether the workflow should stop before proceeding to next agent.
- `true`: Lead must create remediation task before continuing
- `false`: Proceed to next agent/phase

### REQUIRES_REMEDIATION
Whether a fix task needs to be created.
- `true`: Create a `CC-TEAMS REM-FIX:` task with REMEDIATION_REASON as description
- `false`: No fix needed

**Naming contract (strict):**
- New remediation tasks MUST use prefix `CC-TEAMS REM-FIX:`.
- Legacy prefix `CC-TEAMS REMEDIATION:` may be treated as remediation during migration, but do not emit it in new runs.

### REMEDIATION_REASON
Exact text for the remediation task description. Null if no remediation needed.

### SPEC_COMPLIANCE
Whether the implementation meets the original requirements/spec.
- `PASS`: All requirements verified
- `FAIL`: One or more requirements not met
- `N/A`: Not applicable (e.g., hunter, investigator)

### TRACEABILITY_IMPACT / REQUIREMENTS_AT_RISK / ACCEPTANCE_CRITERIA_AT_RISK / DECISION_DEPENDENCIES_AT_RISK
Reviewer-, hunter-, and live-reviewer traceability risk fields.
- `TRACEABILITY_IMPACT`:
  - `none`: no concrete requirement or acceptance-risk found in the reviewed scope
  - `risk_detected`: findings put one or more requirements / acceptance criteria / decisions at risk
  - `conflict_detected`: another reviewer or upstream contract makes an incompatible claim that must be resolved in challenge
- `REQUIREMENTS_AT_RISK`: requirements or agreement items threatened by the finding set
- `ACCEPTANCE_CRITERIA_AT_RISK`: acceptance criteria likely to fail or regress if findings remain
- `DECISION_DEPENDENCIES_AT_RISK`: approved decisions undermined by the current implementation or proposed fix direction

### TIMESTAMP
ISO 8601 timestamp of when the contract was generated. Helps lead track ordering.

### AGENT_ID
The teammate's name (e.g., "investigator-1", "security-reviewer"). Critical for Bug Court where multiple agents share the same role.

### FILES_MODIFIED
List of files changed by WRITE agents (builder, planner). Empty for READ-ONLY agents (including investigator). Used by lead to detect file conflicts.

### CLAIMED_ARTIFACTS
Durable output files the teammate explicitly claims to have created/updated.
- MUST be empty (`[]`) for read-only teammates.
- MUST only include approved durable paths (`docs/plans/`, `docs/research/`, `docs/reviews/` when explicitly requested).
- If teammate output claims created/saved files but this field is missing or mismatched, lead treats as evidence non-compliance.

### EVIDENCE_COMMANDS
List of verification/diagnostic commands with exit codes proving claims in this contract.
- Example: `["npm test -- tests/auth.test.ts => exit 0", "npm run build => exit 0"]`
- Use `[]` only when no command evidence is applicable to the role.

### PHASE_ID / PHASE_STATUS / PHASE_EXIT_READY / CHECKPOINT_TYPE
Builder-family execution envelope fields.
- `PHASE_ID`: current plan phase identifier or `ad-hoc-scope`
- `PHASE_STATUS`: `completed`, `partial`, or `blocked`
- `PHASE_EXIT_READY`: whether exit criteria are actually satisfied
- `CHECKPOINT_TYPE`: `none`, `human_verify`, `decision`, or `human_action`

### INPUTS / EXPECTED_ARTIFACTS
Builder-family planning trace fields describing required inputs and the durable or runtime outputs expected from the scope.

### REQUIREMENT_IDS_IN_SCOPE / ACCEPTANCE_CRITERIA_IN_SCOPE / APPROVED_DECISION_DEPENDENCIES / REQUIREMENTS_SATISFIED / ACCEPTANCE_CRITERIA_SATISFIED / DECISION_DEPENDENCIES_SATISFIED
Builder-family traceability fields.
- `REQUIREMENT_IDS_IN_SCOPE`: requirement identifiers or exact requirement statements the current phase is responsible for
- `ACCEPTANCE_CRITERIA_IN_SCOPE`: acceptance criteria the current phase is expected to move toward closure
- `APPROVED_DECISION_DEPENDENCIES`: already approved decisions the builder relied on while implementing this phase
- `REQUIREMENTS_SATISFIED`: in-scope requirements the builder believes were satisfied by this phase
- `ACCEPTANCE_CRITERIA_SATISFIED`: in-scope acceptance criteria the builder believes are satisfied by this phase
- `DECISION_DEPENDENCIES_SATISFIED`: decision dependencies that remained valid under the implementation produced

### TDD_RED_EXIT / TDD_GREEN_EXIT
Builder-family TDD proof fields.
- `TDD_RED_EXIT` must be `1` for `STATUS: PASS`
- `TDD_GREEN_EXIT` must be `0` for `STATUS: PASS`
- Missing either value invalidates builder-family success

### PROOF_STATUS
Proof status for builders and verifier.
- `passed`: Scenario counts, expected/actual values, command evidence, and truths/artifacts/wiring all reconcile.
- `gaps_found`: Some proof is missing, contradictory, inferred, or incomplete.
- `human_needed`: Verification requires a human/environment decision the verifier cannot complete safely.

### SCENARIOS
Builder-family scenario evidence array.
- At least one scenario must be present for builder-family `STATUS: PASS`.
- Every passing scenario must include `name`, `given`, `when`, `then`, `command`, `expected`, `actual`, `exit_code`, and `status`.
- Missing expected/actual values invalidate `STATUS: PASS`.

### ASSUMPTIONS / DECISIONS / BLOCKED_ITEMS / SKIPPED_ITEMS / SCOPE_INCREASES
Builder-family execution truth fields.
- `ASSUMPTIONS`: correctness-sensitive assumptions
- `DECISIONS`: meaningful implementation choices
- `BLOCKED_ITEMS`: required work not completed
- `SKIPPED_ITEMS`: intentionally deferred work
- `SCOPE_INCREASES`: newly discovered work outside the approved scope

### PLAN_MODE / VERIFICATION_RIGOR / OPEN_DECISIONS / RECOMMENDED_DEFAULTS / CONTRADICTIONS_FOUND / REQUIREMENT_PHASE_COVERAGE / ACCEPTANCE_PROOF_COVERAGE
Planner contract fields.
- `PLAN_MODE`: `direct`, `execution_plan`, or `decision_rfc`
- `VERIFICATION_RIGOR`: `standard` or `critical_path`
- `OPEN_DECISIONS`: material unresolved choices that still need approval or confirmation
- `RECOMMENDED_DEFAULTS`: safe defaults proposed but not silently approved
- `CONTRADICTIONS_FOUND`: count of requirement/constraint/non-goal/decision conflicts still present in the saved plan
- `REQUIREMENT_PHASE_COVERAGE`: whether every requirement maps to at least one execution phase
- `ACCEPTANCE_PROOF_COVERAGE`: whether every acceptance criterion maps to a concrete check or verifier proof path

### FINDING_BUCKETS / REPLAN_NEEDED / REPLAN_REASON
Plan-gap-reviewer contract fields.
- `FINDING_BUCKETS`: exact counts for each allowed planning-review bucket
- `REPLAN_NEEDED`: whether the planner must revise the current saved plan
- `REPLAN_REASON`: top reason driving the revision request, or `None`

### PROOF_RECONCILIATION
Verifier-only object proving goal achievement at three layers:
- `truths`: observable user or business outcomes
- `artifacts`: files, endpoints, tests, records, or durable outputs
- `wiring`: integration connections such as component -> API -> database

All three must be `verified` for `STATUS: PASS`.

### SCENARIO_EVIDENCE
Verifier-only structured scenario evidence.
- Every scenario row must include `name`, `command`, `expected`, `actual`, `exit`, and `result`.
- `SCENARIOS_PASSED` must equal the number of entries with `exit: 0` and `result: PASS`.
- `SCENARIOS_TOTAL = SCENARIOS_PASSED + SCENARIOS_FAILED`.
- Missing expected/actual values invalidate `STATUS: PASS`.

### TRACEABILITY_STATUS / REQUIREMENTS_VERIFIED / ACCEPTANCE_CRITERIA_VERIFIED / DECISION_DEPENDENCIES_CHECKED / TRACEABILITY_GAPS
Verifier-only traceability closure fields.
- `TRACEABILITY_STATUS`:
  - `verified`: every required requirement, acceptance criterion, and decision dependency for the active phase is tied to fresh evidence
  - `gaps_found`: at least one required traceability edge is missing or contradicted
  - `human_needed`: a required traceability edge depends on a human-only environment or approval
- `REQUIREMENTS_VERIFIED`: requirement or agreement items proven by the current verifier run
- `ACCEPTANCE_CRITERIA_VERIFIED`: exact acceptance criteria closed by the verifier run
- `DECISION_DEPENDENCIES_CHECKED`: approved decisions that were materially relied on and explicitly checked
- `TRACEABILITY_GAPS`: any requirement, acceptance criterion, or approved decision still lacking proof, including any builder-claimed satisfied item that verifier could not close
- `REOPENED_PROOF_STATUS`:
  - `none`: no reopened-proof retirement question was active in this verifier run
  - `reproof_closed`: reopened proof was closed again by fresh verification evidence
  - `superseded_by_decision`: reopened proof was intentionally retired because an approved decision replaced the old proof boundary
  - `still_open`: reopened proof remains unresolved
- `REOPENED_PROOF_RETIREMENTS`: durable retirement records for reopened proof boundaries, each with the original boundary, prior phase, closure mode, and proof or decision reference

Fail closed:
- If `TRACEABILITY_STATUS != verified`, verifier cannot return `STATUS: PASS`
- If reopened proof exists and verifier returns `STATUS: PASS`, `REOPENED_PROOF_STATUS` must be `reproof_closed` or `superseded_by_decision`
- If builder claimed an item as satisfied but verifier cannot prove it, record it in `TRACEABILITY_GAPS`

### STATE_DELTA
Universal compact state-transition summary emitted by every teammate.
- `what_changed`: durable facts the teammate believes changed in the workflow state
- `remains_open`: unresolved scope, proof, risk, or planning gaps that still matter after this task
- `should_stay_closed`: facts, proofs, or boundaries that later phases should preserve rather than reopen casually
- `next_trigger`: the next deterministic action, gate, or condition implied by this teammate's result

Rules:
- This field is required for every role.
- Use concise, concrete bullets; do not restate the whole narrative output.
- If nothing remains open, emit `[]` for `remains_open`.
- If no prior closed boundary is relevant, emit `[]` for `should_stay_closed`.
- `next_trigger` must not be vague; name the next gate, teammate, revision, or remediation step.
- If a later teammate reports an item in `remains_open` that overlaps a previously verified boundary from `should_stay_closed`, treat it as a reopened-proof regression, not a generic open item.

### DEVIATIONS_FROM_PLAN
Description of any changes made that differ from the original plan. Null if implementation matches plan exactly. Critical for maintaining plan-implementation alignment.

### MEMORY_NOTES
Structured notes for the lead to persist to memory files at workflow end.
- **learnings**: Insights for `activeContext.md ## Learnings`
- **patterns**: Conventions or gotchas for `patterns.md ## Common Gotchas`
- **verification**: Evidence for `progress.md ## Verification`

---

## Severity Classification

All findings should be classified using this 4-level system:

| Severity | Definition | Blocks Ship? |
|----------|------------|-------------|
| **CRITICAL** | Security vulnerability, data loss, crash, blocks functionality | YES — Must fix |
| **MAJOR** | Affects functionality, significant quality issue | Should fix before merge |
| **MINOR** | Style issues, small improvements | Can merge, fix later |
| **NIT** | Purely stylistic preferences | Optional |

---

## Contract Rules (Per Agent)

### Builder
```yaml
STATUS: PASS | FAIL
# CONTRACT RULE: STATUS=PASS requires PHASE_STATUS=completed, PHASE_EXIT_READY=true, PROOF_STATUS=passed, TDD_RED_EXIT=1, TDD_GREEN_EXIT=0, BLOCKED_ITEMS=[], and at least one passing scenario in SCENARIOS
PHASE_ID: "[phase id]"
PHASE_STATUS: completed | partial | blocked
PHASE_EXIT_READY: true | false
CHECKPOINT_TYPE: none | human_verify | decision | human_action
PROOF_STATUS: passed | gaps_found | human_needed
INPUTS: ["input 1", "input 2"] | []
EXPECTED_ARTIFACTS: ["artifact 1", "artifact 2"] | []
REQUIREMENT_IDS_IN_SCOPE: ["REQ-1", "REQ-2"] | []
ACCEPTANCE_CRITERIA_IN_SCOPE: ["AC-1", "AC-2"] | []
APPROVED_DECISION_DEPENDENCIES: ["Use zod for validation"] | []
REQUIREMENTS_SATISFIED: ["REQ-1"] | []
ACCEPTANCE_CRITERIA_SATISFIED: ["AC-1"] | []
DECISION_DEPENDENCIES_SATISFIED: ["Use zod for validation"] | []
TDD_RED_EXIT: [1 if red phase ran, null if missing]
TDD_GREEN_EXIT: [0 if green phase ran, null if missing]
SCENARIOS:
  - name: "[scenario name]"
    given: "[state]"
    when: "[action]"
    then: "[result]"
    command: "[exact command]"
    expected: "[expected result]"
    actual: "[actual result]"
    exit_code: 0
    status: PASS
ASSUMPTIONS: ["assumption 1", "assumption 2"]
DECISIONS: ["decision 1", "decision 2"]
BLOCKED_ITEMS: ["step not completed"] | []
SKIPPED_ITEMS: ["step intentionally deferred"] | []
SCOPE_INCREASES: ["new scope discovered"] | []
STATE_DELTA:
  what_changed: ["Validation middleware now rejects malformed tokens"]
  remains_open: [] | ["Audit logging stays deferred to next phase"]
  should_stay_closed: [] | ["Previously verified session timeout behavior"]
  next_trigger: "Run verifier on current phase"
FILES_MODIFIED: ["src/auth/middleware.ts", "src/auth/middleware.test.ts"]
CLAIMED_ARTIFACTS: []
EVIDENCE_COMMANDS: ["npm test path/to/test.test.ts => exit 1", "npm test path/to/test.test.ts => exit 0"]
DEVIATIONS_FROM_PLAN: [null or "Added extra validation per live-reviewer feedback"]
```

### Reviewers (Security, Performance, Quality)
```yaml
STATUS: APPROVE | CHANGES_REQUESTED
# CONTRACT RULE: STATUS=APPROVE requires CRITICAL_ISSUES=0 and CONFIDENCE>=80
SPEC_COMPLIANCE: PASS | FAIL
TRACEABILITY_IMPACT: none | risk_detected | conflict_detected
REQUIREMENTS_AT_RISK: [] | ["REQ-1"]
ACCEPTANCE_CRITERIA_AT_RISK: [] | ["AC-1"]
DECISION_DEPENDENCIES_AT_RISK: [] | ["Use server-side validation"]
STATE_DELTA:
  what_changed: ["Security review identified missing server-side validation"]
  remains_open: [] | ["Validation gap must be remediated before verifier"]
  should_stay_closed: [] | ["Existing auth-token expiry proof"]
  next_trigger: "Challenge round or remediation task"
CRITICAL_ISSUES: [count]
HIGH_ISSUES: [count]
CLAIMED_ARTIFACTS: []
EVIDENCE_COMMANDS: ["npm test => exit 0"]
```

### Accessibility Reviewer (conditional — spawned when UI files detected)
```yaml
STATUS: APPROVE | CHANGES_REQUESTED
# CONTRACT RULE: STATUS=APPROVE requires CRITICAL_ISSUES=0 and CONFIDENCE>=80
# CRITICAL = WCAG 2.1 AA violation that blocks accessibility (keyboard trap, missing alt, no label)
SPEC_COMPLIANCE: PASS | FAIL
CRITICAL_ISSUES: [count of WCAG AA violations]
HIGH_ISSUES: [count of WCAG issues that degrade UX]
TRACEABILITY_IMPACT: none | risk_detected | conflict_detected
REQUIREMENTS_AT_RISK: [] | ["REQ-1"]
ACCEPTANCE_CRITERIA_AT_RISK: [] | ["AC-1"]
DECISION_DEPENDENCIES_AT_RISK: [] | ["Keep keyboard-only navigation compliant"]
DEPENDENCY_AUDIT: SKIPPED
STATE_DELTA:
  what_changed: ["Accessibility review confirmed keyboard trap risk"]
  remains_open: [] | ["A11y finding needs remediation"]
  should_stay_closed: [] | ["Previously verified focus-visible behavior"]
  next_trigger: "Challenge round or remediation task"
CLAIMED_ARTIFACTS: []
EVIDENCE_COMMANDS: ["<grep pattern> => exit <code>"]
```

### API Contract Reviewer (conditional — spawned when API route files detected)
```yaml
STATUS: APPROVE | CHANGES_REQUESTED
# CONTRACT RULE: STATUS=APPROVE requires CRITICAL_ISSUES=0 and CONFIDENCE>=80
# CRITICAL = breaking change (removed endpoint, removed required field, incompatible type change)
SPEC_COMPLIANCE: PASS | FAIL
CRITICAL_ISSUES: [count of breaking changes]
HIGH_ISSUES: [count of high-severity contract issues]
TRACEABILITY_IMPACT: none | risk_detected | conflict_detected
REQUIREMENTS_AT_RISK: [] | ["REQ-1"]
ACCEPTANCE_CRITERIA_AT_RISK: [] | ["AC-1"]
DECISION_DEPENDENCIES_AT_RISK: [] | ["Preserve backward-compatible response shape"]
DEPENDENCY_AUDIT: SKIPPED
STATE_DELTA:
  what_changed: ["API compatibility review detected breaking response change"]
  remains_open: [] | ["Client-facing contract mismatch remains unresolved"]
  should_stay_closed: [] | ["Previously verified stable endpoint contract"]
  next_trigger: "Challenge round or remediation task"
CLAIMED_ARTIFACTS: []
EVIDENCE_COMMANDS: ["<grep pattern> => exit <code>"]
```

### Frontend Builder / Backend Builder (Cross-Layer BUILD)
Same contract rules as `Builder`:
```yaml
STATUS: PASS | FAIL
# CONTRACT RULE: STATUS=PASS requires PHASE_STATUS=completed, PHASE_EXIT_READY=true, PROOF_STATUS=passed, TDD_RED_EXIT=1, TDD_GREEN_EXIT=0, BLOCKED_ITEMS=[], and at least one passing scenario in SCENARIOS
PHASE_ID: "[phase id]"
PHASE_STATUS: completed | partial | blocked
PHASE_EXIT_READY: true | false
CHECKPOINT_TYPE: none | human_verify | decision | human_action
PROOF_STATUS: passed | gaps_found | human_needed
INPUTS: ["input 1", "input 2"] | []
EXPECTED_ARTIFACTS: ["artifact 1", "artifact 2"] | []
REQUIREMENT_IDS_IN_SCOPE: ["REQ-1", "REQ-2"] | []
ACCEPTANCE_CRITERIA_IN_SCOPE: ["AC-1", "AC-2"] | []
APPROVED_DECISION_DEPENDENCIES: ["Use zod for validation"] | []
REQUIREMENTS_SATISFIED: ["REQ-1"] | []
ACCEPTANCE_CRITERIA_SATISFIED: ["AC-1"] | []
DECISION_DEPENDENCIES_SATISFIED: ["Use zod for validation"] | []
TDD_RED_EXIT: [1 if red phase ran, null if missing]
TDD_GREEN_EXIT: [0 if green phase ran, null if missing]
SCENARIOS:
  - name: "[scenario name]"
    given: "[state]"
    when: "[action]"
    then: "[result]"
    command: "[exact command]"
    expected: "[expected result]"
    actual: "[actual result]"
    exit_code: 0
    status: PASS
ASSUMPTIONS: ["assumption 1", "assumption 2"]
DECISIONS: ["decision 1", "decision 2"]
BLOCKED_ITEMS: ["step not completed"] | []
SKIPPED_ITEMS: ["step intentionally deferred"] | []
SCOPE_INCREASES: ["new scope discovered"] | []
PHASE_GATE_RESULT: PASS | FAIL | N/A
PHASE_GATE_CMD: "[gate command from plan or N/A]"
STATE_DELTA:
  what_changed: ["Backend contract and implementation updated for current phase"]
  remains_open: [] | ["Frontend integration deferred to sibling phase"]
  should_stay_closed: [] | ["Previously verified auth boundary behavior"]
  next_trigger: "Run downstream review/verifier path"
FILES_MODIFIED: [list — must not overlap with sibling builder's FILES_MODIFIED]
CLAIMED_ARTIFACTS: []
EVIDENCE_COMMANDS: ["<red command> => exit 1", "<green command> => exit 0"]
DEVIATIONS_FROM_PLAN: [null or deviation description]
```
**Cross-layer additional**: backend-builder MUST include `API_CONTRACT_SPEC` in MEMORY_NOTES.

### Hunter
```yaml
STATUS: CLEAN | ISSUES_FOUND
# CONTRACT RULE: STATUS=CLEAN requires CRITICAL_ISSUES=0
CRITICAL_ISSUES: [count]
HIGH_ISSUES: [count]
TRACEABILITY_IMPACT: none | risk_detected | conflict_detected
REQUIREMENTS_AT_RISK: [] | ["REQ-1"]
ACCEPTANCE_CRITERIA_AT_RISK: [] | ["AC-1"]
DECISION_DEPENDENCIES_AT_RISK: [] | ["Retry policy remains user-visible"]
STATE_DELTA:
  what_changed: ["Silent-failure scan confirmed or refuted hidden-path issues"]
  remains_open: [] | ["Hidden failure path still needs remediation"]
  should_stay_closed: [] | ["Previously verified happy-path behavior"]
  next_trigger: "Challenge round or verifier if clean"
CLAIMED_ARTIFACTS: []
EVIDENCE_COMMANDS: ["grep -rE ... => exit 0"]
```

### Verifier
```yaml
STATUS: PASS | FAIL
# CONTRACT RULE: STATUS=PASS requires BLOCKERS=0, SCENARIOS_PASSED=SCENARIOS_TOTAL, SCENARIOS_FAILED=0, PROOF_STATUS=passed, truths/artifacts/wiring all verified, and TRACEABILITY_STATUS=verified
PROOF_STATUS: passed | gaps_found | human_needed
SCENARIOS_TOTAL: [count]
SCENARIOS_PASSED: [count]
SCENARIOS_FAILED: [count]
BLOCKERS: [count]
SPEC_COMPLIANCE: PASS | FAIL
PROOF_RECONCILIATION:
  truths: verified | missing | human_needed
  artifacts: verified | missing | human_needed
  wiring: verified | missing | human_needed
SCENARIO_EVIDENCE:
  - name: "[scenario]"
    command: "[command]"
    expected: "[expected]"
    actual: "[actual]"
    exit: [code]
    result: PASS | FAIL | BLOCKED
TRACEABILITY_STATUS: verified | gaps_found | human_needed
REQUIREMENTS_VERIFIED: ["AC-1: user can submit form"] | []
ACCEPTANCE_CRITERIA_VERIFIED: ["Invalid token payloads are rejected"] | []
DECISION_DEPENDENCIES_CHECKED: ["Approved decision: use server-side validation"] | []
TRACEABILITY_GAPS: [] | ["AC-2 audit log evidence missing"]
REOPENED_PROOF_STATUS: none | reproof_closed | superseded_by_decision | still_open
REOPENED_PROOF_RETIREMENTS:
  - boundary: "[previously closed proof boundary]"
    closure_mode: reproof_closed | superseded_by_decision
    closure_ref: "[fresh proof command/output or approved decision ref]"
    prior_phase_id: "[phase id]"
STATE_DELTA:
  what_changed: ["Fresh proof closed active-phase acceptance criteria"]
  remains_open: [] | ["Traceability gap still blocks phase completion"]
  should_stay_closed: [] | ["Prior verified malformed-token rejection proof"]
  next_trigger: "Advance to next phase" | "Create remediation task"
CLAIMED_ARTIFACTS: []
EVIDENCE_COMMANDS: ["npm test => exit 0", "npm run build => exit 0"]
```

### Investigator
```yaml
STATUS: EVIDENCE_FOUND | INVESTIGATING | BLOCKED
# CONTRACT RULE: STATUS=EVIDENCE_FOUND requires ROOT_CAUSE not null AND evidence cited
AGENT_ID: "investigator-1"
ROOT_CAUSE: "[one-line summary]"
EVIDENCE: "[reproduction command/output summary]"
VARIANTS_COVERED: [count]
CLAIMED_ARTIFACTS: []
EVIDENCE_COMMANDS: ["python repro.py => exit 1"]
STATE_DELTA:
  what_changed: ["Hypothesis H1 now has reproduction evidence"]
  remains_open: [] | ["Root cause still needs confirmation"]
  should_stay_closed: [] | ["Already disproven hypotheses should stay closed"]
  next_trigger: "Debate with peer investigators or continue targeted test"
```

### Planner
```yaml
STATUS: PLAN_CREATED | NEEDS_CLARIFICATION
# CONTRACT RULE: STATUS=PLAN_CREATED requires PLAN_FILE is valid path, PLAN_MODE + VERIFICATION_RIGOR are set, and CONFIDENCE>=50
PLAN_FILE: "[path]"
PHASES: [count]
PLAN_MODE: direct | execution_plan | decision_rfc
VERIFICATION_RIGOR: standard | critical_path
OPEN_DECISIONS: [] | ["decision 1"]
RECOMMENDED_DEFAULTS: [] | ["default 1"]
RISKS_IDENTIFIED: [count]
CONTRADICTIONS_FOUND: [count]
REQUIREMENT_PHASE_COVERAGE: complete | gaps_found
ACCEPTANCE_PROOF_COVERAGE: complete | gaps_found
CONFIDENCE: [0-100]
STATE_DELTA:
  what_changed: ["Saved plan now maps requirements to executable phases"]
  remains_open: [] | ["One open decision still needs user approval"]
  should_stay_closed: [] | ["Already approved auth-library choice"]
  next_trigger: "Fresh plan-gap review"
CLAIMED_ARTIFACTS: ["docs/plans/YYYY-MM-DD-feature-plan.md"]
EVIDENCE_COMMANDS: []
```

### Plan Gap Reviewer
```yaml
STATUS: PASS | FINDINGS
# CONTRACT RULE: STATUS=PASS requires CRITICAL_ISSUES=0, REPLAN_NEEDED=false, and at least one positive assertion with evidence
CRITICAL_ISSUES: [count of blocking findings]
HIGH_ISSUES: [count of advisory findings]
BLOCKING: [true if CRITICAL_ISSUES > 0]
REQUIRES_REMEDIATION: [true if STATUS=FINDINGS]
REMEDIATION_REASON: [null or "Planner must revise plan: {summary}"]
SPEC_COMPLIANCE: PASS | FAIL
FINDING_BUCKETS:
  repo_mismatches: [count]
  missing_surfaces: [count]
  execution_order_issues: [count]
  hidden_assumptions: [count]
  under_scoped_integrations: [count]
  open_decisions_presented_as_settled: [count]
  requirement_conflicts: [count]
  traceability_gaps: [count]
REPLAN_NEEDED: true | false
REPLAN_REASON: "[reason or None]"
STATE_DELTA:
  what_changed: ["Fresh review found traceability gaps in phase coverage"]
  remains_open: [] | ["Planner revision required before execution"]
  should_stay_closed: [] | ["Requirements already grounded in repo reality"]
  next_trigger: "Planner revises saved plan"
CLAIMED_ARTIFACTS: []
EVIDENCE_COMMANDS: ["<grep/read command> => exit <code>"]
```

---

## Lead Validation Logic

### Step 1: Check Contract Exists
```
Look for "### Router Contract (MACHINE-READABLE)" in agent output.
If NOT found → non-compliant output. Create REM-EVIDENCE task. Block downstream. Request re-output.
```

### Step 2: Validate Contract Fields
```
Parse YAML block.

Circuit Breaker (BEFORE creating any REM-FIX):
- Count existing REM-FIX tasks in workflow
- If count >= 3 → AskUserQuestion:
  - Research best practices (Recommended)
  - Fix locally
  - Skip (not recommended)
  - Abort (see Abort Behavior below)

Rules:
1. If contract.AGENT_ID == "plan-gap-reviewer" AND contract.STATUS == "FINDINGS":
   → Do NOT create CC-TEAMS REM-FIX
   → Route findings back to planner revision in the PLAN workflow
   → Re-run the fresh reviewer only after planner revises the same saved plan
   → AskUserQuestion only if blocking findings persist after the allowed revision pass
   → STOP

2. If contract.BLOCKING == true OR contract.REQUIRES_REMEDIATION == true:
   → Create CC-TEAMS REM-FIX task with contract.REMEDIATION_REASON as description
   → Block downstream tasks
   → STOP

3. If contract.CRITICAL_ISSUES > 0 AND parallel phase (multiple reviewers):
   → Check for conflicts between reviewers
   → If security says CRITICAL but others disagree → security wins
   → AskUserQuestion if genuine conflict

4. Validate artifact/evidence integrity:
   → If CLAIMED_ARTIFACTS contains unauthorized paths or missing files, create REM-EVIDENCE and STOP
   → If teammate narrative claims artifacts but CLAIMED_ARTIFACTS is empty/missing, create REM-EVIDENCE and STOP
   → If role requires command proof and EVIDENCE_COMMANDS is empty/missing, create REM-EVIDENCE and STOP
   → If STATE_DELTA is missing, or any of `what_changed` / `remains_open` / `should_stay_closed` / `next_trigger` is missing, create REM-EVIDENCE and STOP
   → If STATE_DELTA.remains_open overlaps STATE_DELTA.should_stay_closed, create REM-EVIDENCE and STOP
   → If current STATE_DELTA.remains_open overlaps a previously verified phase boundary from workflow `phase_transition_summaries.latest_verified`, create `CC-TEAMS REM-FIX: reopened-proof regression` and STOP
   → If planner STATUS=PLAN_CREATED but PLAN_MODE or VERIFICATION_RIGOR is missing, create REM-EVIDENCE and STOP
   → If planner STATUS=PLAN_CREATED but CONTRADICTIONS_FOUND != 0, create REM-EVIDENCE and STOP
   → If planner STATUS=PLAN_CREATED but REQUIREMENT_PHASE_COVERAGE != complete or ACCEPTANCE_PROOF_COVERAGE != complete, create REM-EVIDENCE and STOP
   → If planner STATUS=PLAN_CREATED but PLAN_FILE is not present in CLAIMED_ARTIFACTS, create REM-EVIDENCE and STOP
   → If plan-gap-reviewer STATUS=PASS but CRITICAL_ISSUES != 0 or REPLAN_NEEDED != false, create REM-EVIDENCE and STOP
   → If plan-gap-reviewer STATUS=FINDINGS but FINDING_BUCKETS is missing, create REM-EVIDENCE and STOP
   → If plan-gap-reviewer STATUS=PASS but any FINDING_BUCKETS value is non-zero, create REM-EVIDENCE and STOP
   → If builder STATUS=PASS but PHASE_STATUS != completed, create REM-EVIDENCE and STOP
   → If builder STATUS=PASS but PHASE_EXIT_READY != true, create REM-EVIDENCE and STOP
   → If builder STATUS=PASS but PROOF_STATUS != passed, create REM-EVIDENCE and STOP
   → If builder STATUS=PASS but TDD_RED_EXIT != 1 or TDD_GREEN_EXIT != 0, create REM-EVIDENCE and STOP
   → If builder STATUS=PASS but REQUIREMENTS_SATISFIED is not a subset of REQUIREMENT_IDS_IN_SCOPE, create REM-EVIDENCE and STOP
   → If builder STATUS=PASS but ACCEPTANCE_CRITERIA_SATISFIED is not a subset of ACCEPTANCE_CRITERIA_IN_SCOPE, create REM-EVIDENCE and STOP
   → If builder STATUS=PASS but DECISION_DEPENDENCIES_SATISFIED is not a subset of APPROVED_DECISION_DEPENDENCIES, create REM-EVIDENCE and STOP
   → If builder STATUS=PASS but SCENARIOS is empty or contains no passing scenario with non-empty name/command/expected/actual/exit_code, create REM-EVIDENCE and STOP
   → If verifier STATUS=PASS but PROOF_STATUS != passed, create REM-EVIDENCE and STOP
   → If verifier STATUS=PASS but truths/artifacts/wiring are not all verified, create REM-EVIDENCE and STOP
   → If verifier STATUS=PASS but TRACEABILITY_STATUS != verified, create REM-EVIDENCE and STOP
   → If verifier scenario totals do not reconcile with SCENARIO_EVIDENCE, create REM-EVIDENCE and STOP

5. Collect contract.STATE_DELTA and contract.MEMORY_NOTES for persistence

6. If none triggered → Proceed to next phase
```

### Step 3: Output Validation Evidence
```markdown
### Agent Validation: {agent_name}
- Router Contract: Found
- STATUS: {value}
- BLOCKING: {value}
- CRITICAL_ISSUES: {value}
- SPEC_COMPLIANCE: {value}
- FILES_MODIFIED: {list}
- Proceeding: [Yes/No + reason]
```

---

## Malformed Contract Handling

| Issue | Action |
|-------|--------|
| YAML parse error | Ask teammate to re-output contract (max 2 retries) |
| Missing required field | Ask teammate to re-output with all fields (max 2 retries) |
| Invalid STATUS value | Ask teammate to use valid value from table (max 2 retries) |
| 3 consecutive failures | Mark as non-compliant, create REM-EVIDENCE task, block downstream |

**Fallback:** If teammate cannot produce valid contract after 3 attempts, lead manually assesses output quality and creates appropriate task (REM-FIX or proceed).

---

## Synthesized Contract Merge Rules (Conservative Defaults)

When the lead synthesizes a unified contract from multiple reviewer contracts (Review Arena challenge round):

| Field | Merge Rule |
|-------|-----------|
| `BLOCKING` | `true` if ANY individual contract has `BLOCKING=true` |
| `CRITICAL_ISSUES` | Sum of all (deduplicate by file:line — same finding counts once) |
| `HIGH_ISSUES` | Sum of all (deduplicated) |
| `CONFIDENCE` | Minimum of all individual scores (weakest-link principle) |
| `STATUS` | `CHANGES_REQUESTED` if ANY reviewer has `CHANGES_REQUESTED` |
| `REQUIRES_REMEDIATION` | `true` if ANY contract has it `true` |
| `REMEDIATION_REASON` | Concatenate all non-null REMEDIATION_REASONs (semicolon-separated) |
| `TRACEABILITY_IMPACT` | `conflict_detected` if reviewers disagree on traceability risk, else `risk_detected` if ANY reviewer/hunter flags risk, else `none` |
| `REQUIREMENTS_AT_RISK` | Union of all deduplicated requirement ids/statements |
| `ACCEPTANCE_CRITERIA_AT_RISK` | Union of all deduplicated acceptance criteria |
| `DECISION_DEPENDENCIES_AT_RISK` | Union of all deduplicated decision dependencies |
| `STATE_DELTA.what_changed` | Union of all deduplicated delta items |
| `STATE_DELTA.remains_open` | Union of all deduplicated open boundaries |
| `STATE_DELTA.should_stay_closed` | Union of all deduplicated preserved-closure items |
| reopened proof | Any merged open boundary that collides with a prior `should_stay_closed` item becomes reopened-proof regression |

**Why conservative defaults:** A missed CRITICAL is worse than a false positive. When in doubt, block.

---

## Abort Behavior (Circuit Breaker)

When user selects "Abort" in the circuit breaker:

1. **Revert:** If builder made changes, `git stash` or `git checkout` affected files
2. **Cleanup:** Send shutdown_request to all teammates, TeamDelete()
3. **Persist:** Update memory with:
   - `activeContext.md ## Learnings`: "Workflow aborted after 3+ REM-FIX cycles. Reason: {user_reason}"
   - `progress.md ## Tasks`: Mark all remaining tasks as deleted
4. **Report:** Present abort summary to user with list of unresolved issues

---

## Remediation Loop

When a REM-FIX task is created (code changes needed):

1. Fix is implemented (by builder)
2. Re-review is triggered (full Review Arena — security + performance + quality + challenge)
3. Re-hunt is triggered (hunter scans fix for new silent failures)
4. Only after review challenge + re-hunt pass → proceed to verifier
5. **Non-negotiable.** Code changes without full re-review break orchestration integrity.
