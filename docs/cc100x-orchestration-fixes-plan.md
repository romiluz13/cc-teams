# CC100x Orchestration Fixes Plan

> **Status**: ACTIVE
> **Created**: 2026-02-12
> **Purpose**: Fix confirmed orchestration flaws with validated, atomic changes

---

## Principles

1. **Only functional files** - Changes only to `plugins/cc100x/skills/` and `plugins/cc100x/agents/`
2. **Atomic fixes** - Each fix is self-contained and validated before moving to next
3. **Backward compatible** - Existing workflows must continue to work
4. **Agent Teams aware** - All instructions must work with Agent Teams runtime behavior

---

## Confirmed Flaws Summary

### HIGH PRIORITY (Orchestration Gaps)

| # | Flaw | Impact | Location |
|---|------|--------|----------|
| 1.1 | REM-FIX assignee not explicit | Orphan remediation task | cc100x-lead lines 1039-1053 |
| 1.2 | TeamDelete failure recovery incomplete | Zombie workflow | cc100x-lead lines 1486-1500 |
| 1.3 | Reviewer conflict priority incomplete | Inconsistent decisions | cc100x-lead lines 1290-1318 |
| 1.4 | Contract-diff checkpoint undefined | Skip verification | cc100x-lead lines 1314-1317 |
| 1.5 | Shutdown rejection handling vague | Shutdown loop | cc100x-lead lines 1491 |

### MEDIUM PRIORITY (Clarity Improvements)

| # | Flaw | Impact | Location |
|---|------|--------|----------|
| 2.1 | Challenge round termination unclear | Potential hang | cc100x-lead lines 1305-1308 |
| 2.2 | Debate phase termination unclear | Potential hang | bug-court lines 133 |
| 2.3 | Live-reviewer sync timeout not referenced | No escalation path | pair-build lines 126 |
| 2.4 | Memory Notes preservation undefined | Data loss risk | cc100x-lead lines 277-308 |
| 2.5 | Orphan task "treat cautiously" vague | Ambiguous action | cc100x-lead line 274 |
| 2.6 | Bug Court verdict criteria undefined | Arbitrary decisions | bug-court lines 137-151 |

---

## Phase 1: High-Impact Handoff Fixes

### Fix 1.1: REM-FIX Assignee Specification

**Problem**: When `REQUIRES_REMEDIATION=true`, a REM-FIX task is created but no explicit rule says who to assign it to.

**Location**: `plugins/cc100x/skills/cc100x-lead/SKILL.md` lines 1039-1053

**Current**:
```
→ TaskCreate({
    subject: "CC100X REM-FIX: {teammate_name}",
    description: contract.REMEDIATION_REASON,
    activeForm: "Fixing {teammate_name} issues"
  })
```

**Fix**: Add explicit assignee rule after TaskCreate:
```
→ Assign REM-FIX task:
  - Default: assign to `builder` (owns all file edits)
  - Exception: if issue is in builder's own output, AskUserQuestion for manual fix or self-review
```

**PRE-CHECK**: Verify builder.md mentions handling remediation
**POST-CHECK**: Read modified section, verify rule added
**CROSS-CHECK**: Check pair-build.md remediation flow (lines 320-330) for consistency

---

### Fix 1.2: TeamDelete Failure Recovery

**Problem**: After 3 TeamDelete retries, workflow "stays open" but no explicit next step.

**Location**: `plugins/cc100x/skills/cc100x-lead/SKILL.md` lines 1486-1500

**Current** (line 1494):
```
6. If `TeamDelete()` fails, retry up to 3 times and keep workflow open
```

**Fix**: Add explicit recovery after line 1494:
```
7. If TeamDelete() still fails after 3 retries:
   a. Check for running teammates: read `~/.claude/teams/{team-name}/config.json` → members array
   b. For each active member: SendMessage(type="shutdown_request", recipient="{name}")
   c. Wait for shutdown approvals (max 30s per teammate)
   d. Retry TeamDelete()
   e. If still fails: AskUserQuestion with options:
      - **Manual cleanup** → Provide cleanup commands to user
      - **Force continue** → Mark workflow complete despite orphaned resources
```

**PRE-CHECK**: Verify team config path matches Agent Teams docs
**POST-CHECK**: Read modified section, verify steps are clear
**CROSS-CHECK**: Check consistency with shutdown approval mechanism (lines 1489-1492)

---

### Fix 1.3: Reviewer Conflict Priority

**Problem**: Only "security wins on CRITICAL" is defined. No priority for Performance vs Quality.

**Location**: `plugins/cc100x/skills/cc100x-lead/SKILL.md` around line 544 (task description) and lines 1290-1318

**Current** (line 544):
```
Challenge and resolve conflicts (security wins on CRITICAL).
```

**Fix**: Add explicit priority hierarchy:
```
Challenge and resolve conflicts using priority hierarchy:
1. Security findings always take precedence on CRITICAL issues
2. Performance > Quality when both flag same issue (latency affects users)
3. If equal severity: require explicit user decision via AskUserQuestion
```

**PRE-CHECK**: Check all 3 reviewer agents for output format compatibility
**POST-CHECK**: Update all task descriptions that mention "security wins on CRITICAL"
**CROSS-CHECK**: Search for other "security wins" references in skills/

---

### Fix 1.4: Contract-Diff Checkpoint Definition

**Problem**: "Compare upstream contract claims vs downstream usage assumptions" is vague.

**Location**: `plugins/cc100x/skills/cc100x-lead/SKILL.md` lines 1314-1317

**Current**:
```
5. Before invoking verifier, run a contract-diff checkpoint:
   - Compare upstream contract claims vs downstream usage assumptions
   - If mismatch exists, create `CC100X REM-FIX:` task and block verifier
```

**Fix**: Add explicit comparison rules:
```
5. Before invoking verifier, run a contract-diff checkpoint:
   Contract-diff rules:
   a. CLAIMED_ARTIFACTS from builder/fix: verify each file exists on disk via `Read(file=path)`
   b. FILES_MODIFIED from builder: verify count matches expected scope
   c. EVIDENCE_COMMANDS: verify exit codes are internally consistent (no PASS with failing exits)
   - If any mismatch: create `CC100X REM-FIX: Contract-diff failure` and block verifier
```

**PRE-CHECK**: Verify Router Contract schema includes CLAIMED_ARTIFACTS, FILES_MODIFIED
**POST-CHECK**: Verify rules are actionable (can be executed by lead)
**CROSS-CHECK**: Check builder.md Router Contract output format

---

### Fix 1.5: Shutdown Rejection Handling

**Problem**: "check unfinished work, resolve, retry" is too vague.

**Location**: `plugins/cc100x/skills/cc100x-lead/SKILL.md` line 1491

**Current**:
```
3. If teammate rejects shutdown → check unfinished work, resolve, retry
```

**Fix**: Replace with explicit steps:
```
3. If teammate rejects shutdown:
   a. Parse rejection message for reason
   b. If "task in progress": wait for task completion (apply escalation ladder if stalled)
   c. If "blocking issue found": create REM-FIX task, complete remediation flow, then retry
   d. If "pending output": wait for Router Contract output, validate, then retry
   e. After resolution, retry shutdown request
   f. Max 3 rejection cycles per teammate; if exceeded: AskUserQuestion
```

**PRE-CHECK**: Verify Agent Teams docs shutdown rejection mechanism
**POST-CHECK**: Verify steps cover all rejection scenarios
**CROSS-CHECK**: Ensure consistency with escalation ladder (lines 1234-1251)

---

## Phase 2: Clarity Improvements

### Fix 2.1: Challenge Round Termination Criteria

**Problem**: No explicit criteria for when lead should mark challenge round complete.

**Location**: `plugins/cc100x/skills/cc100x-lead/SKILL.md` lines 1305-1308

**Current**:
```
3. For Challenge Round: Share each reviewer's findings with the others via peer messaging:
   SendMessage(type="message", recipient="security-reviewer",
     content="Here are findings from other reviewers: {...}. Challenge or agree?")
   # Repeat for other reviewers
```

**Fix**: Add termination criteria after line 1308:
```
Challenge round termination criteria:
- All reviewers have responded (agree or challenge)
- No new CRITICAL findings raised in final round
- Max 3 challenge rounds; if exceeded: escalate to user with summary
Lead marks challenge round task complete when criteria met.
```

**POST-CHECK**: Verify criteria are deterministic

---

### Fix 2.2: Debate Phase Termination Criteria

**Problem**: Only says "Lead monitors debate and allows 2-3 rounds of messaging."

**Location**: `plugins/cc100x/skills/bug-court/SKILL.md` line 133

**Current**:
```
**Lead monitors debate and allows 2-3 rounds of messaging.**
```

**Fix**: Replace with explicit criteria:
```
**Debate termination criteria:**
- All investigators have stated final position (agree, concede, or maintain)
- No new evidence submitted in final round
- Max 3 debate rounds; if still contested: present top 2 hypotheses to user
Lead proceeds to verdict when criteria met.
```

**POST-CHECK**: Verify works with variable investigator counts (2-5)

---

### Fix 2.3: Live-Reviewer Sync Timeout Reference

**Problem**: pair-build mentions message-based polling but no explicit timeout/escalation reference.

**Location**: `plugins/cc100x/skills/pair-build/SKILL.md` line 126

**Current**:
```
**Synchronization note (Agent Teams):** Agent Teams has no blocking wait primitive. Builder uses message-based polling...
```

**Fix**: Add escalation reference:
```
**Synchronization note (Agent Teams):** Agent Teams has no blocking wait primitive. Builder uses message-based polling — after sending review request, builder checks for reviewer response before starting next module. If no response within reasonable time, builder sends a nudge.

**Timeout handling:** If live-reviewer remains unresponsive after 2 nudges, builder applies escalation ladder from cc100x-lead (MEDIUM at T+5, HIGH at T+8, CRITICAL at T+10).
```

**POST-CHECK**: Verify escalation ladder section exists in cc100x-lead

---

### Fix 2.4: Memory Notes in Session Handoff

**Problem**: Session Handoff Payload doesn't explicitly include Memory Notes from completed teammates.

**Location**: `plugins/cc100x/skills/cc100x-lead/SKILL.md` lines 277-308

**Fix**: Add to handoff payload schema (after line 295):
```
memory_notes_collected:
  builder: "TDD pattern used: RED-GREEN-REFACTOR for auth module"
  hunter: "Silent failure found: error swallowed in line 45"
  security-reviewer: "JWT validation pattern documented"
```

And add collection rule:
```
Memory Notes collection (compaction-safe):
- After each teammate completes, extract MEMORY_NOTES from Router Contract
- Append to handoff payload before context compaction risk
- Memory Update task uses collected notes, not raw teammate context
```

**POST-CHECK**: Verify Memory Update task can use this format

---

### Fix 2.5: Orphan Task Explicit Handling

**Problem**: "treat cautiously and prefer fresh stamped tasks" is too vague.

**Location**: `plugins/cc100x/skills/cc100x-lead/SKILL.md` line 274

**Current**:
```
4. If stamp is missing (legacy task), treat cautiously and prefer fresh stamped tasks for new runs.
```

**Fix**: Replace with explicit action:
```
4. If stamp is missing (legacy task):
   a. Do NOT resume or mutate the task
   b. Log to Memory Notes: "Orphan legacy task ignored: {subject}"
   c. Create fresh stamped tasks for current workflow
   d. If legacy task blocks a stamped task: TaskUpdate({ taskId: legacy_id, status: "deleted" })
```

**POST-CHECK**: Verify doesn't accidentally delete valid current-run tasks

---

### Fix 2.6: Bug Court Verdict Criteria

**Problem**: Verdict criteria weights are listed but threshold for "clear winner" is undefined.

**Location**: `plugins/cc100x/skills/bug-court/SKILL.md` lines 137-151

**Current**:
```
Lead evaluates:

| Criterion | Weight |
|-----------|--------|
| Evidence strength (reproducible test) | Highest |
...
```

**Fix**: Add explicit decision rules after the table:
```
**Verdict decision rules:**
- **Clear winner**: Hypothesis with reproducible test AND survived all challenges AND explains primary symptom
- **Tie**: Two hypotheses both have reproducible tests; present both to user
- **All weak**: No hypothesis has reproducible test; require new investigation round (max 2 total)
- **Contested**: One has test, another has strong counter-evidence; present to user with evidence summary

If user decision required, format as AskUserQuestion with:
- Hypothesis A: [evidence summary] [reproduction command]
- Hypothesis B: [evidence summary] [reproduction command]
- Recommendation: [lead's assessment]
```

**POST-CHECK**: Verify investigator output format supports evidence summary

---

## Phase 3: Integration Validation

After all fixes are applied, validate end-to-end:

### 3.1 BUILD Workflow Walkthrough
- [ ] QUICK path: builder → live-reviewer → verifier → memory → shutdown
- [ ] FULL path: builder → live-reviewer → hunter → 3 reviewers → challenge → verifier → memory → shutdown
- [ ] QUICK-to-FULL escalation: blocking signal triggers full path
- [ ] Remediation: REM-FIX → re-review → re-challenge → re-hunt → verifier

### 3.2 DEBUG Workflow Walkthrough
- [ ] investigators (parallel) → debate → verdict → builder → 3 reviewers → challenge → verifier → memory → shutdown
- [ ] Contested verdict: user decision flow
- [ ] Re-investigation: max 2 rounds

### 3.3 REVIEW Workflow Walkthrough
- [ ] 3 reviewers → challenge → memory → shutdown
- [ ] Conflict resolution: priority hierarchy applied

### 3.4 Cross-Reference Check
- [ ] All task descriptions updated consistently
- [ ] All "security wins" references include full hierarchy
- [ ] All escalation references point to correct section

### 3.5 Derived Docs Update
- [ ] `docs/functional-governance/protocol-manifest.md` - update if invariants changed
- [ ] `docs/functional-governance/cc100x-bible-functional.md` - update if behavior changed
- [ ] `docs/cc100x-excellence/EXPECTED-BEHAVIOR-RUNBOOK.md` - update examples if needed

---

## Execution Checklist

| Fix | PRE | EDIT | POST | CROSS | Status |
|-----|-----|------|------|-------|--------|
| 1.1 REM-FIX Assignee | [x] | [x] | [x] | [x] | COMPLETE |
| 1.2 TeamDelete Recovery | [x] | [x] | [x] | [x] | COMPLETE |
| 1.3 Reviewer Priority | [x] | [x] | [x] | [x] | COMPLETE |
| 1.4 Contract-Diff | [x] | [x] | [x] | [x] | COMPLETE |
| 1.5 Shutdown Rejection | [x] | [x] | [x] | [x] | COMPLETE |
| 2.1 Challenge Termination | [x] | [x] | [x] | [x] | COMPLETE (via 1.3) |
| 2.2 Debate Termination | [x] | [x] | [x] | [x] | COMPLETE |
| 2.3 Live-Reviewer Timeout | [x] | [x] | [x] | [x] | COMPLETE |
| 2.4 Memory Notes Handoff | [x] | [x] | [x] | [x] | COMPLETE |
| 2.5 Orphan Task Handling | [x] | [x] | [x] | [x] | COMPLETE |
| 2.6 Verdict Criteria | [x] | [x] | [x] | [x] | COMPLETE |
| 3.1 BUILD Walkthrough | - | - | [x] | - | COMPLETE |
| 3.2 DEBUG Walkthrough | - | - | [x] | - | COMPLETE |
| 3.3 REVIEW Walkthrough | - | - | [x] | - | COMPLETE |
| 3.4 Cross-Reference | - | - | [x] | - | COMPLETE |
| 3.5 Derived Docs | - | - | [x] | - | COMPLETE |
