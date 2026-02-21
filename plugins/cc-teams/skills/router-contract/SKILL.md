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
CONTRACT_VERSION: "2.4"
STATUS: [value from agent-specific list below]
CONFIDENCE: [0-100]
CRITICAL_ISSUES: [count]
HIGH_ISSUES: [count]
BLOCKING: [true|false]
REQUIRES_REMEDIATION: [true|false]
REMEDIATION_REASON: [null or description of what needs fixing]
SPEC_COMPLIANCE: [PASS|FAIL|N/A]
# v2.4 additions (agent-specific — include only for relevant roles):
PHASE_GATE_RESULT: [PASS|FAIL|N/A]          # builder only
PHASE_GATE_CMD: ["gate command or N/A"]     # builder only
DEPENDENCY_AUDIT: [PASS|WARN|FAIL|SKIPPED]  # verifier + security-reviewer
DEPENDENCY_AUDIT_DETAIL: ["detail or N/A"]  # verifier only
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
| **builder** | `PASS`, `FAIL` | PASS = TDD evidence present (RED exit=1, GREEN exit=0) |
| **security-reviewer** | `APPROVE`, `CHANGES_REQUESTED` | APPROVE requires CRITICAL_ISSUES=0 and CONFIDENCE>=80 |
| **performance-reviewer** | `APPROVE`, `CHANGES_REQUESTED` | APPROVE requires CRITICAL_ISSUES=0 and CONFIDENCE>=80 |
| **quality-reviewer** | `APPROVE`, `CHANGES_REQUESTED` | APPROVE requires CRITICAL_ISSUES=0 and CONFIDENCE>=80 |
| **live-reviewer** | `APPROVE`, `CHANGES_REQUESTED` | APPROVE requires no STOP-level issues raised |
| **hunter** | `CLEAN`, `ISSUES_FOUND` | CLEAN requires CRITICAL_ISSUES=0 |
| **verifier** | `PASS`, `FAIL` | PASS requires all scenarios passed |
| **investigator** | `EVIDENCE_FOUND`, `INVESTIGATING`, `BLOCKED` | EVIDENCE_FOUND requires reproduction evidence |
| **planner** | `PLAN_CREATED`, `NEEDS_CLARIFICATION` | PLAN_CREATED requires plan file saved + CONFIDENCE>=50 |

---

## Field Definitions

### CONTRACT_VERSION
Contract schema version emitted by teammate. Current target is `2.4`.
- `2.4`: Added PHASE_GATE_RESULT/PHASE_GATE_CMD (builder), DEPENDENCY_AUDIT/DETAIL (verifier + security-reviewer)
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
# CONTRACT RULE: STATUS=PASS requires TDD_RED_EXIT=1 AND TDD_GREEN_EXIT=0
TDD_RED_EXIT: [1 if red phase ran, null if missing]
TDD_GREEN_EXIT: [0 if green phase ran, null if missing]
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
CRITICAL_ISSUES: [count]
HIGH_ISSUES: [count]
CLAIMED_ARTIFACTS: []
EVIDENCE_COMMANDS: ["npm test => exit 0"]
```

### Hunter
```yaml
STATUS: CLEAN | ISSUES_FOUND
# CONTRACT RULE: STATUS=CLEAN requires CRITICAL_ISSUES=0
CRITICAL_ISSUES: [count]
HIGH_ISSUES: [count]
CLAIMED_ARTIFACTS: []
EVIDENCE_COMMANDS: ["grep -rE ... => exit 0"]
```

### Verifier
```yaml
STATUS: PASS | FAIL
# CONTRACT RULE: STATUS=PASS requires BLOCKERS=0 and SCENARIOS_PASSED=SCENARIOS_TOTAL
SCENARIOS_TOTAL: [count]
SCENARIOS_PASSED: [count]
BLOCKERS: [count]
SPEC_COMPLIANCE: PASS | FAIL
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
```

### Planner
```yaml
STATUS: PLAN_CREATED | NEEDS_CLARIFICATION
# CONTRACT RULE: STATUS=PLAN_CREATED requires PLAN_FILE is valid path and CONFIDENCE>=50
PLAN_FILE: "[path]"
PHASES: [count]
CONFIDENCE: [0-100]
CLAIMED_ARTIFACTS: ["docs/plans/YYYY-MM-DD-feature-plan.md"]
EVIDENCE_COMMANDS: []
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
1. If contract.BLOCKING == true OR contract.REQUIRES_REMEDIATION == true:
   → Create CC-TEAMS REM-FIX task with contract.REMEDIATION_REASON as description
   → Block downstream tasks
   → STOP

2. If contract.CRITICAL_ISSUES > 0 AND parallel phase (multiple reviewers):
   → Check for conflicts between reviewers
   → If security says CRITICAL but others disagree → security wins
   → AskUserQuestion if genuine conflict

3. Validate artifact/evidence integrity:
   → If CLAIMED_ARTIFACTS contains unauthorized paths or missing files, create REM-EVIDENCE and STOP
   → If teammate narrative claims artifacts but CLAIMED_ARTIFACTS is empty/missing, create REM-EVIDENCE and STOP
   → If role requires command proof and EVIDENCE_COMMANDS is empty/missing, create REM-EVIDENCE and STOP

4. Collect contract.MEMORY_NOTES for persistence

5. If none triggered → Proceed to next phase
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
