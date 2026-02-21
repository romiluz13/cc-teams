# CC-Teams v0.1.16 — Spawn Context, Dependency Security, Phase Gates

## Context

Three real gaps were identified from a deep audit and validated against functional files. This is NOT
assumption-based: every gap is proven with file:line evidence.

---

## GAP 1 — Spawn Prompt Is Undefined Per Agent (cc-teams-lead/SKILL.md:609-613)

**Evidence:** The Agent Invocation Template contains two undefined placeholders:
- `{brief summary from activeContext.md}` — "brief" is never defined
- `{key patterns from patterns.md}` — "key" is never defined
- No per-agent spec exists anywhere for what builder, investigator, security-reviewer, or verifier needs

**Impact:** Lead writes whatever feels right. Builder may not know the test command. Security reviewer
may not know the auth method. Verifier may not receive hunter/reviewer findings in a structured way.

**Fix:** Add a `## Per-Agent Spawn Context Requirements` section to cc-teams-lead/SKILL.md immediately
after the existing Agent Invocation Template. Each agent gets a canonical block of REQUIRED fields.

---

## GAP 2 — Dependency Security Is Documentation-Only (security-reviewer.md:62)

**Evidence:**
- security-reviewer.md line 62: `| **Vulnerable Components** | Known CVEs in dependencies |`
- No `npm audit`, `pip audit`, or any executable check exists in any agent
- Hunter scans for silent failures only, not supply chain
- security-reviewer has NO Bash access (lint-enforced) — cannot run `npm audit`
- verifier.md already has Bash + runs test/build commands — correct place for executable audit

**Fix (split):**
1. `security-reviewer.md` — Add `## Dependency Security (Read-Only Scan)` using grep/glob: check
   package.json for unmaintained/known-risk patterns, flag if no lock file present, note that
   executable audit runs in verifier. Grep-only, no Bash needed.
2. `verifier.md` — Add `npm audit --json` to verification commands. Parse output for high/critical.
   Add `DEPENDENCY_AUDIT` field to Router Contract. CRITICAL if high+ vulnerabilities found.

---

## GAP 3 — Phase Exit Criteria Are Prose, Not Executable (planner.md:108, builder.md:84-94)

**Evidence:**
- planner.md line 108: `> **Exit Criteria:** [What must be true when complete]` — prose only
- builder.md lines 84-94: Module-level TDD cycles, no phase-level milestone check
- planning-patterns/SKILL.md lines 427-440: Phase tasks created with exit criteria description
  but NO executable validation subtask or command field
- After Phase 1 tasks complete, Phase 2 unblocks automatically with no gate command run

**Fix:**
1. `planner.md` — Add `**Gate Command:**` field (optional) to Plan Format task section
2. `planning-patterns/SKILL.md` — Update phase task template with gate_command field + guidance
3. `builder.md` — In Verify step (step 5): if plan has gate_command for this phase, run it
   and add `PHASE_GATE_RESULT` + `PHASE_GATE_CMD` to Router Contract output
4. `cc-teams-lead/SKILL.md` — In contract validation: check `PHASE_GATE_RESULT` —
   FAIL → create `CC-TEAMS REM-FIX: phase-gate failed` and block downstream

---

## Critical Files

| File | Change |
|------|--------|
| `plugins/cc-teams/skills/cc-teams-lead/SKILL.md` | Add Per-Agent Spawn Context Requirements; add PHASE_GATE_RESULT to contract validation |
| `plugins/cc-teams/agents/security-reviewer.md` | Add Dependency Security read-only scan section + Router Contract DEPENDENCY_AUDIT field |
| `plugins/cc-teams/agents/verifier.md` | Add npm audit command + DEPENDENCY_AUDIT to Router Contract |
| `plugins/cc-teams/agents/builder.md` | Add gate_command check to Verify step + PHASE_GATE_RESULT to Router Contract |
| `plugins/cc-teams/agents/planner.md` | Add Gate Command field to Plan Format |
| `plugins/cc-teams/skills/planning-patterns/SKILL.md` | Update phase task template with gate_command |
| `CHANGELOG.md` | Add v0.1.16 |
| `package.json` + `plugin.json` | Bump to 0.1.16 |

---

## Detailed Changes

### Fix 1: Per-Agent Spawn Context Requirements

**File:** `plugins/cc-teams/skills/cc-teams-lead/SKILL.md`

Add immediately after the closing of the existing Agent Invocation Template block
(after the line `Execute the task and include 'Task {TASK_ID}: COMPLETED' in your output when done.`):

```markdown
## Per-Agent Spawn Context Requirements (MANDATORY)

The generic template above applies to all agents. Below are **required additions per agent type**.
The lead MUST include every field listed. Use `N/A` only if genuinely unavailable — never omit silently.

### builder
```
TECH_STACK: {language} / {framework} / {test-runner}
TEST_CMD: {exact command, e.g., "CI=true npm test" or "npx vitest run"}
BUILD_CMD: {exact command, e.g., "npm run build" or "N/A if no build step"}
SCOPE: {files/modules this implementation touches}
REQUIREMENTS: {all AskUserQuestion responses from requirements clarification}
```

### investigator-{N}
```
ASSIGNED_HYPOTHESIS: H{N}: {title}
CONFIDENCE: {score}/100 — {rationale}
NEXT_TEST: {smallest discriminating command to prove/disprove}
ERROR_CONTEXT: {full error message / stack trace / observed symptom}
REPRODUCTION: {steps or exact command to reproduce}
GIT_CONTEXT: {output of git log --oneline -5 -- <affected-files>}
ALL_HYPOTHESES: {list of all HN titles, so investigator can challenge others}
```

### security-reviewer / performance-reviewer / quality-reviewer
```
SCOPE: {specific files list OR "full codebase" — from user's AskUserQuestion response}
FOCUS: {security|performance|quality|all — from user's AskUserQuestion response}
BLOCKING_ONLY: {yes|no — from user's AskUserQuestion response}
AUTH_METHOD: {JWT|session|OAuth|API-key|N/A — from activeContext.md or codebase}
SENSITIVE_FILES: {files containing auth/secrets/payments — from patterns.md or grep}
```
_(Only `AUTH_METHOD` and `SENSITIVE_FILES` are required for security-reviewer. Others apply to all 3.)_

### verifier
```
TEST_CMD: {exact test command}
BUILD_CMD: {exact build command or N/A}
HUNTER_FINDINGS: {STATUS + CRITICAL_ISSUES count from hunter Router Contract}
REVIEWER_FINDINGS: {STATUS + CRITICAL_ISSUES from each of 3 reviewer contracts}
PLAN_EXIT_CRITERIA: {prose from plan phase, or N/A}
PHASE_GATE_CMD: {gate_command from plan phase, or N/A}
```

### planner
```
RESEARCH_SUMMARY: {if research was executed — key findings + path to research file}
EXISTING_PATTERNS: {top 3 relevant entries from patterns.md for this feature}
PRIOR_DECISIONS: {decisions from activeContext.md ## Decisions relevant to this feature}
REQUIREMENTS: {all AskUserQuestion responses}
```
```

---

### Fix 2a: Security Reviewer — Read-Only Dependency Scan

**File:** `plugins/cc-teams/agents/security-reviewer.md`

Add new section `## Dependency Security (Read-Only Scan)` after the OWASP Top 10 table:

```markdown
## Dependency Security (Read-Only Scan)

This is a static analysis of dependency configuration. Executable audit (`npm audit`) runs in the verifier.

### Lock File Check
```
Glob(pattern="package-lock.json", path=".")
Glob(pattern="yarn.lock", path=".")
Glob(pattern="Pipfile.lock", path=".")
Glob(pattern="poetry.lock", path=".")
```
**If no lock file found:** Report HIGH — reproducible builds not enforced, supply chain unpredictable.

### Package Configuration Check
```
Read(file_path="package.json")
Grep(pattern="\"scripts\"", path="package.json")
Grep(pattern="postinstall|preinstall", path="package.json")
```
**Flag as CRITICAL** if `postinstall` script executes arbitrary code (e.g., `postinstall: "bash ..."`).
**Flag as HIGH** if dependencies include packages with known risk keywords:
```
Grep(pattern="\"(node-serialize|serialize-to-js|cryo|funcster)\"", path="package.json")
```

### Dependency Hygiene Notes
- Cannot run `npm audit` (no Bash access) — this is enforced by design to preserve read-only status
- Verifier runs `npm audit --json` as part of E2E verification and reports DEPENDENCY_AUDIT result
- Document any dependency concerns as MAJOR/HIGH findings for verifier to cross-reference

### Router Contract Update
Add `DEPENDENCY_AUDIT` to the security-reviewer contract:
```yaml
DEPENDENCY_AUDIT: LOCK_FILE_PRESENT | LOCK_FILE_MISSING | SUSPICIOUS_SCRIPT | SKIPPED
```
```

**Also update the Router Contract YAML template in security-reviewer.md** to add:
```yaml
DEPENDENCY_AUDIT: [LOCK_FILE_PRESENT|LOCK_FILE_MISSING|SUSPICIOUS_SCRIPT|SKIPPED]
```

---

### Fix 2b: Verifier — Executable Dependency Audit

**File:** `plugins/cc-teams/agents/verifier.md`

**Change 1 — Add to `## Verification Commands` section:**
```bash
# Dependency vulnerability audit (after npm install / if package.json exists)
if [ -f "package.json" ]; then
  npm audit --json 2>/dev/null | jq '.metadata.vulnerabilities' || \
  npm audit 2>&1 | tail -5
fi
```
Report CRITICAL finding in Router Contract if `high` or `critical` vulnerabilities found.
Report WARN if `moderate` vulnerabilities found.

**Change 2 — Add to `## Scenarios` table example:**
```
| Dependency audit | PASS/FAIL/WARN | npm audit → exit 0 (0 high/critical) |
```

**Change 3 — Add `DEPENDENCY_AUDIT` to verifier Router Contract YAML:**
```yaml
DEPENDENCY_AUDIT: PASS | WARN | FAIL | SKIPPED
DEPENDENCY_AUDIT_DETAIL: "0 high, 0 critical" | "2 high vulns in lodash@4.x" | "N/A"
```

**CONTRACT RULE addition:** DEPENDENCY_AUDIT=FAIL (high/critical vulns found) → BLOCKING=true.

---

### Fix 3a: Planner — Gate Command Field

**File:** `plugins/cc-teams/agents/planner.md`

**Change — In `## Plan Format`, update the task template** from:
```markdown
### Task 1: [Component Name]

**Files:**
- Create: `exact/path/to/file.ts`
- Test: `tests/exact/path/to/test.ts`

**Step 1:** Write failing test
**Step 2:** Run test, verify fails
**Step 3:** Implement
**Step 4:** Run test, verify passes
**Step 5:** Commit
```

To:
```markdown
### Task 1: [Component Name]

**Files:**
- Create: `exact/path/to/file.ts`
- Test: `tests/exact/path/to/test.ts`

**Gate Command:** `CI=true npm test -- --testPathPattern=auth` ← exact command proving this phase complete
_(Omit if phase has no isolated test suite; leave blank if full test suite covers it)_

**Step 1:** Write failing test
**Step 2:** Run test, verify fails
**Step 3:** Implement
**Step 4:** Run test, verify passes
**Step 5:** Commit
```

---

### Fix 3b: Planning Patterns — Phase Task Template

**File:** `plugins/cc-teams/skills/planning-patterns/SKILL.md`

**Change — In the phase task template (where `TaskCreate` calls are shown):**

Update description template to explicitly include gate_command:
```javascript
TaskCreate({
  subject: "CC-TEAMS Phase 1: {phase_title}",
  description: `Workflow Instance: {team_name}
Workflow Kind: BUILD
Project Root: {cwd}

**Plan:** docs/plans/YYYY-MM-DD-{feature}-plan.md
**Section:** Phase 1
**Exit Criteria:** {demonstrable_milestone}
**Gate Command:** {gate_command or "N/A"}

{phase_details}`,
  activeForm: "Working on {phase_title}"
})
```

Add guidance bullet:
```markdown
- **Gate Command** is the SINGLE EXECUTABLE COMMAND that proves phase completion.
  Examples: `CI=true npm test -- --testPathPattern=auth`, `npm run build && npm run lint`
  If phase has no isolated command, use `CI=true npm test` (full suite) or `N/A`.
```

---

### Fix 3c: Builder — Phase Gate Check in Verify Step

**File:** `plugins/cc-teams/agents/builder.md`

**Change — Step 5 in `## Process`** from:
```
5. **Verify** - All tests pass, functionality works
```

To:
```
5. **Verify** - All tests pass, functionality works. If plan specifies a **Gate Command** for
   this phase, run it and capture exit code for Router Contract `PHASE_GATE_RESULT`.
   ```bash
   # Run phase gate command from plan (if specified)
   {gate_command}  # e.g., CI=true npm test -- --testPathPattern=auth
   # Expected: exit 0. Capture actual exit code.
   ```
   PHASE_GATE_RESULT=FAIL → do NOT proceed. Fix until gate passes, then re-run.
```

**Change — Add to `## Output` Router Handoff section and Router Contract YAML:**
```yaml
PHASE_GATE_RESULT: PASS | FAIL | N/A
PHASE_GATE_CMD: "{gate_command from plan or N/A}"
```

**CONTRACT RULE addition:** If `PHASE_GATE_RESULT=FAIL` → `BLOCKING=true`, `REQUIRES_REMEDIATION=true`.

---

### Fix 3d: Lead — Phase Gate Contract Validation

**File:** `plugins/cc-teams/skills/cc-teams-lead/SKILL.md`

**Change — In `### Validation Steps` (Post-Team Validation / Router Contract section):**

Add to Step 3 (PARSE AND VALIDATE CONTRACT):
```
If contract.PHASE_GATE_RESULT == "FAIL":
  → Create `CC-TEAMS REM-FIX: phase-gate failed — {PHASE_GATE_CMD}`
  → Block downstream tasks via TaskUpdate
  → STOP until builder re-runs gate and reports PASS
```

---

## Router Contract Version

Bump `CONTRACT_VERSION` from `"2.3"` to `"2.4"` in:
- `plugins/cc-teams/skills/router-contract/SKILL.md` (definition)
- `plugins/cc-teams/agents/builder.md` (template)
- `plugins/cc-teams/agents/verifier.md` (template)
- `plugins/cc-teams/agents/security-reviewer.md` (template)
- `plugins/cc-teams/agents/performance-reviewer.md` (template)
- `plugins/cc-teams/agents/quality-reviewer.md` (template)
- `plugins/cc-teams/agents/hunter.md` (template)
- `plugins/cc-teams/agents/investigator.md` (template)
- `plugins/cc-teams/agents/planner.md` (template)
- `plugins/cc-teams/agents/live-reviewer.md` (template)

---

## CHANGELOG Entry

```markdown
## [0.1.16] - 2026-02-22

### Added
- **Per-Agent Spawn Context Requirements** (cc-teams-lead/SKILL.md)
  - Each agent type now has a canonical list of REQUIRED fields the lead must pass at spawn
  - builder: TECH_STACK, TEST_CMD, BUILD_CMD, SCOPE, REQUIREMENTS
  - investigator: ASSIGNED_HYPOTHESIS, ERROR_CONTEXT, REPRODUCTION, GIT_CONTEXT, ALL_HYPOTHESES
  - reviewer triad: SCOPE, FOCUS, BLOCKING_ONLY, AUTH_METHOD, SENSITIVE_FILES
  - verifier: TEST_CMD, BUILD_CMD, HUNTER_FINDINGS, REVIEWER_FINDINGS, PHASE_GATE_CMD
  - planner: RESEARCH_SUMMARY, EXISTING_PATTERNS, PRIOR_DECISIONS, REQUIREMENTS
- **Dependency Security audit** (security-reviewer.md, verifier.md)
  - security-reviewer: read-only lock file + package.json scan, DEPENDENCY_AUDIT contract field
  - verifier: `npm audit --json` added to verification suite, DEPENDENCY_AUDIT + detail in contract
  - DEPENDENCY_AUDIT=FAIL (high/critical vulns) → BLOCKING=true in verifier contract
- **Phase Gate Commands** (planner.md, planning-patterns, builder.md, cc-teams-lead)
  - Planner Plan Format adds optional `**Gate Command:**` field per phase
  - Builder Verify step now runs gate_command if present, captures PHASE_GATE_RESULT
  - Lead contract validation blocks on PHASE_GATE_RESULT=FAIL
  - Phase exit criteria become executable and verified, not just prose
- **Router Contract v2.4** — new fields: PHASE_GATE_RESULT, PHASE_GATE_CMD (builder);
  DEPENDENCY_AUDIT, DEPENDENCY_AUDIT_DETAIL (verifier + security-reviewer)
```

---

## Verification Steps

1. `npm run check:agent-tools` — must pass (no Bash added to security-reviewer)
2. `npm run check:functional-bible` — must pass
3. `npm run check:artifact-policy` — must pass
4. Manual: spawn prompt templates — verify builder section contains all 5 required fields
5. Manual: planner output for a test plan — verify `Gate Command:` field is present
6. Manual: verifier contract — verify `DEPENDENCY_AUDIT` field is present and `npm audit` runs
7. Manual: builder contract — verify `PHASE_GATE_RESULT` field is present
8. Smoke test: `echo '{"task_subject":"CC-TEAMS Memory Update"}' | bash plugins/cc-teams/hooks/task-completed.sh` — still exits 2 (hooks unchanged)

---

## No-Conflict Guarantee

| Risk | Resolution |
|------|-----------|
| security-reviewer adding Bash for npm audit | NOT done — read-only scan only, npm audit goes to verifier |
| CONTRACT_VERSION bump breaks existing contracts | Agents check for `2.3` OR `2.4` during transition; lead synthesizes from narrative if needed |
| gate_command is optional — planner may not write one | Builder skips gate check and sets PHASE_GATE_RESULT=N/A (no block) |
| Per-agent context requirements add overhead | Lead uses N/A for unavailable fields — never silently omits |
| npm audit fails if no package.json | Verifier wraps in `if [ -f "package.json" ]` check → SKIPPED if absent |
