# CC-Teams v0.1.17 — Systematic Flaw Fixes

## Context

Deep adversarial audit + reference doc validation produced a prioritized list of real bugs.
One false alarm removed: Challenge Round vs Delegate Mode — reference docs confirm delegate mode
ALLOWS messaging, so the challenge round (done entirely via SendMessage) is valid. No fix needed.

---

## CRITICAL FIXES

### Fix 1 — Planner sends to invalid recipient `"lead"` (`planner.md:32`)

**Problem:** `SendMessage(recipient: "lead")` fails silently. No agent is named "lead" in Agent Teams.
Config.json has a `members` array — the lead's actual name is unknown to the planner at plan-mode-detection time.

**Fix:** Drop SendMessage entirely. Output plain BLOCKED text and stop.
Idle notifications deliver the planner's output to the lead automatically (confirmed in reference docs).
No recipient discovery needed.

**File:** `plugins/cc-teams/agents/planner.md`
Replace the SendMessage block (lines 29-36) with:
```markdown
2. Output this message and stop:

   ```
   BLOCKED: I am in plan mode. Claude Code auto-enabled plan mode because my role
   involves planning work. I CANNOT write plan files in plan mode.

   Lead: Re-spawn me with "DO NOT ENTER PLAN MODE" at the top of my prompt,
   or use mode: dontAsk when spawning. See PLAN workflow step 7.
   ```

3. Go idle. The idle notification will carry this message to the lead.
   Do NOT attempt any further work.
```

---

### Fix 2 — Memory Update blocked forever when verifier stalls (`cc-teams-lead/SKILL.md:416`)

**Problem:** `CC-TEAMS Memory Update` is blocked by verifier. If verifier enters `in_progress`
and its agent crashes, the task never completes. Memory Update stays blocked forever.
Workflow learnings are silently lost with no documented escape path.

**Fix:** Add an escape hatch rule to the execution loop and to the Memory Update task description.

**File:** `plugins/cc-teams/skills/cc-teams-lead/SKILL.md`

1. In the execution loop step 4 (after escalation ladder), add after "CRITICAL stalled" action:
   ```
   MEMORY UPDATE ESCAPE HATCH (if verifier is stalled):
   - If verifier is declared stalled/aborted (T+10 CRITICAL path exhausted):
     - Collect whatever verification evidence exists (from handoff payload or last known contract)
     - Manually unblock Memory Update: TaskUpdate({ taskId: memory_update_id, addBlockedBy: [] })
     - Run Memory Update with note: "Verifier stalled — persisting partial learnings"
     - Document stall in progress.md ## Verification
   ```

2. In BUILD Task template row 10, update Key Description Points:
   ```
   Collect Memory Notes, persist via Read-Edit-Read.
   ESCAPE: If verifier stalls at CRITICAL, Memory Update runs with partial evidence.
   ```

---

### Fix 3 — Hunter cannot proactively signal BLOCKED (`hunter.md:7`)

**Problem:** Hunter tools: `Read, Grep, Glob, Skill, LSP` — no SendMessage.
If hunter is stuck (skill load failure, LSP unavailable), it can only output text and go idle.
The idle notification delivers the message, but hunter cannot proactively message the lead
mid-task if it discovers it's going to be blocked before finishing.

**Fix:** Add `SendMessage` to hunter tools. The lint script does NOT forbid SendMessage
for hunter (`assert_not_has` only covers Write, Edit, Bash, AskUserQuestion, WebFetch).

**File:** `plugins/cc-teams/agents/hunter.md`
Change: `tools: Read, Grep, Glob, Skill, LSP`
To: `tools: Read, Grep, Glob, Skill, LSP, SendMessage`

Also add to hunter's Task Response section after "If you cannot proceed":
```markdown
```
SendMessage({
  type: "message",
  recipient: "{lead_name_from_task_context}",
  content: "BLOCKED: {reason}. Cannot complete silent failure hunt.",
  summary: "BLOCKED: hunter cannot proceed"
})
```
```

---

### Fix 4 — Verifier cannot proactively signal BLOCKED (`verifier.md:7`)

**Same problem as hunter.** Verifier is the final gate — a silent block here loses the entire
verification result. Verifier has `AskUserQuestion` for user-facing questions but no peer messaging.

**Fix:** Add `SendMessage` to verifier tools. Lint allows it.

**File:** `plugins/cc-teams/agents/verifier.md`
Change: `tools: Read, Bash, Grep, Glob, Skill, LSP, AskUserQuestion, WebFetch`
To: `tools: Read, Bash, Grep, Glob, Skill, LSP, AskUserQuestion, WebFetch, SendMessage`

Also update verifier's BLOCKED response section to include SendMessage example
(same pattern as hunter fix above).

---

### Fix 5 — Orphan sweep silently deletes valid workflow trees (`cc-teams-lead/SKILL.md:172-176`)

**Problem:** If two CC-TEAMS workflows exist for the same project, the sweep picks the newest
and marks siblings as `deleted` — silently, permanently, with no confirmation.
A user who paused workflow A and started workflow B loses A's entire task tree.

**Fix:** Change "mark as deleted" to "ask user first" for sibling workflow deletion.

**File:** `plugins/cc-teams/skills/cc-teams-lead/SKILL.md`

Replace step 4 of Orphan Task Recovery:
```markdown
4. If multiple workflow parent tasks are active in this project, keep only one canonical instance:
   - If current team name matches a workflow in memory → that instance is canonical (delete others)
   - Otherwise → DO NOT auto-delete. Use AskUserQuestion:
     "Multiple active workflows found for this project:
      A: {subject_A} (started {timestamp_A})
      B: {subject_B} (started {timestamp_B})
      Which should I resume? The other will be archived (marked pending, not deleted)."
   - Mark non-canonical instances as `pending` (NOT deleted) — archived, resumable later
   - ONLY mark as `deleted` if user explicitly confirms deletion
```

---

### Fix 6 — All-investigators-BLOCKED has no exit path (`bug-court/SKILL.md`)

**Problem:** Bug Court handles individual investigator timeouts but defines no behavior
when ALL investigators simultaneously reach BLOCKED status. Workflow deadlocks with no exit.

**Fix:** Add explicit all-blocked exit path to Bug Court Phase 3 (Debate) lead actions.

**File:** `plugins/cc-teams/skills/bug-court/SKILL.md`

In Phase 3 (Debate) or Phase 4 (Verdict) lead actions, add after the T+8 replacement rule:
```markdown
**All-Investigators-BLOCKED Exit Path:**
If ALL active investigators simultaneously report BLOCKED (or are replaced and their replacements
also block within T+10):
1. AskUserQuestion:
   "All investigators are blocked. Choose next step:
    A) Spawn new investigators with revised hypotheses (lead generates 2-3 new Hn)
    B) Declare root cause unknown — user provides fix direction
    C) Abort Bug Court and treat as exploratory spike"
2. If A: generate new hypotheses from accumulated evidence, spawn fresh investigators
3. If B: skip to Phase 5 with user-provided fix description instead of winning hypothesis
4. If C: shut down team, persist accumulated evidence to patterns.md ## Common Gotchas
```

---

## HIGH-PRIORITY FIXES

### Fix 7 — Handoff payload missing `teammate_roster` (`cc-teams-lead/SKILL.md:237-280`)

**Problem:** On session resume, the lead tries to message teammates by name but the payload
has no record of which teammates were spawned and which need re-spawning.

**Fix:** Add `teammate_roster` field to canonical handoff payload template.

**File:** `plugins/cc-teams/skills/cc-teams-lead/SKILL.md`

In the canonical payload YAML, add after `team_name`:
```yaml
teammate_roster:
  spawned: ["builder", "live-reviewer"]   # currently active teammates
  pending_spawn: ["hunter"]               # not yet spawned but needed for next phase
  completed: ["builder", "live-reviewer"] # finished their tasks
```

---

### Fix 8 — TEAM_SHUTDOWN rejection retry unbound (`cc-teams-lead/SKILL.md:1282-1287`)

**Problem:** "If rejected: check for incomplete tasks → fix/re-assign → retry" has no bound.
If a teammate rejects for non-task reasons (bug, network glitch), the loop runs forever.

**Fix:** Change retry logic to: max 1 rejection → ask user immediately.

**File:** `plugins/cc-teams/skills/cc-teams-lead/SKILL.md`

Replace step 2 of Team Shutdown:
```markdown
2. Wait for approvals.
   - If approved: proceed to TeamDelete()
   - If rejected: check rejection reason
     - If reason is "incomplete tasks": fix/re-assign the task, retry ONCE
     - If still rejected after one fix attempt → AskUserQuestion: "Force shutdown / Investigate?"
     - If reason is NOT task-related (error, bug, other): AskUserQuestion IMMEDIATELY
   - Do NOT retry more than once per rejection. Infinite retry loops cause workflow hang.
```

---

### Fix 9 — Pre-compaction "30+ tool calls" is unenforced (`cc-teams-lead/SKILL.md:281, 315`)

**Problem:** "Every 30+ tool calls" has no counter, no gate, no enforcement.
We added a PreCompact hook in v0.1.15 that writes a checkpoint marker to progress.md.
The lead skill doesn't reference this hook as the trigger mechanism.

**Fix:** Replace the vague 30-call rule with a reference to the PreCompact hook.

**File:** `plugins/cc-teams/skills/cc-teams-lead/SKILL.md`

Replace:
```
3. long-running workflow crosses pre-compaction checkpoint (every 30+ tool calls);
```
With:
```
3. `CC-TEAMS COMPACT_CHECKPOINT` marker appears in `.claude/cc-teams/progress.md`
   (written automatically by the PreCompact hook before every context compaction);
```

Also update the Prevention note:
Replace:
```
**Prevention:** For long-running workflows (Bug Court multi-round, Pair Build multi-module),
trigger pre-compaction memory checkpoint every 30+ tool calls.
```
With:
```
**Prevention:** The PreCompact hook (`plugins/cc-teams/hooks/pre-compact.sh`) writes a
`CC-TEAMS COMPACT_CHECKPOINT: {timestamp}` marker to progress.md before every compaction.
When your next turn starts and you see this marker in progress.md → emit handoff payload immediately.
```

---

### Fix 10 — Synthesized contract has no BLOCKING merge algorithm (`router-contract/SKILL.md`)

**Problem:** When the lead synthesizes a merged contract from 3 reviewers, the spec says
"weighted average" but provides no algorithm. BLOCKING resolution is undefined.

**Fix:** Add explicit conservative merge rules to the Unified Router Contract section.

**File:** `plugins/cc-teams/skills/router-contract/SKILL.md` and `review-arena/SKILL.md`

In the lead validation logic section, add:
```markdown
### Synthesized Contract Merge Rules (Conservative Defaults)

When lead synthesizes a unified contract from multiple reviewer contracts:

| Field | Merge Rule |
|-------|-----------|
| `BLOCKING` | `true` if ANY individual contract has `BLOCKING=true` |
| `CRITICAL_ISSUES` | Sum of all individual CRITICAL_ISSUES (deduplicated by file:line) |
| `HIGH_ISSUES` | Sum of all individual HIGH_ISSUES (deduplicated) |
| `CONFIDENCE` | Minimum of all individual confidence scores (weakest link) |
| `STATUS` | `CHANGES_REQUESTED` if ANY reviewer has CHANGES_REQUESTED |
| `REQUIRES_REMEDIATION` | `true` if ANY individual contract has it `true` |
| `REMEDIATION_REASON` | Concatenation of all non-null REMEDIATION_REASONs |
```

---

### Fix 11 — Debate round limit is advisory, not enforced (`bug-court/SKILL.md:152-158`)

**Problem:** "Max 3 rounds" is stated but no lead action is specified to enforce it.
Debate can stall indefinitely while lead subjectively decides "done."

**Fix:** Add explicit round-tracking action to lead's Phase 3 execution.

**File:** `plugins/cc-teams/skills/bug-court/SKILL.md`

In Phase 3 (Debate) lead actions, add:
```markdown
**Round Tracking (MANDATORY):**
After initiating debate, track each "round" as: one message sent by each active investigator.
```
round_count = 0
After each investigator message exchange: round_count += 1
When round_count >= 3 → close debate phase:
  SendMessage(broadcast, "Debate round 3 complete. Submit your final verdict now.
  Include your final Router Contract. No further challenge messages.")
```
Do not wait for "consensus" — 3 rounds is the hard cap.
```

---

## MEDIUM-PRIORITY FIXES

### Fix 12 — Confidence weighting formula undefined (`review-arena/SKILL.md:250`)

**Fix:** Replace vague "weighted by finding severity" with exact formula.
Use minimum (weakest-link principle — if any reviewer is uncertain, overall is uncertain).

**File:** `plugins/cc-teams/skills/review-arena/SKILL.md`

Change: `CONFIDENCE: [average of 3 reviewers, weighted by finding severity]`
To: `CONFIDENCE: [minimum of 3 reviewer confidence scores — weakest-link principle]`

---

### Fix 13 — npm audit silent fail when `jq` not installed (`hooks/teammate-idle.sh`, `verifier.md`, `security-reviewer.md`)

**Problem:** `npm audit --json 2>/dev/null | jq -r ...` silently produces empty output if jq missing.
DEPENDENCY_AUDIT gets set incorrectly.

**Fix:** Add jq availability check before piping.

**Files:** `plugins/cc-teams/agents/verifier.md`, `plugins/cc-teams/hooks/teammate-idle.sh`

In verifier.md, replace the npm audit command with:
```bash
# Dependency vulnerability audit
if [ -f "package.json" ]; then
  if command -v jq >/dev/null 2>&1; then
    npm audit --json 2>/dev/null | jq -r '.metadata.vulnerabilities | "critical=\(.critical) high=\(.high) moderate=\(.moderate)"' 2>/dev/null
  else
    # jq not available — fall back to text parsing
    npm audit 2>&1 | grep -E "^[0-9]+ (critical|high|moderate|low)" | head -5
  fi
fi
```

In teammate-idle.sh, add size guard before jq:
```bash
# Guard against very large messages (>500KB) that could OOM jq
MSG_SIZE=${#LAST_MSG}
if [[ "$MSG_SIZE" -gt 524288 ]]; then
  # Large message — grep directly without jq parse
  if echo "$LAST_MSG" | grep -q "Router Contract (MACHINE-READABLE)"; then exit 0; else exit 2; fi
fi
```

---

### Fix 14 — Planner probe race condition on `.probe` file (`planner.md:18-20`)

**Problem:** Two planners writing to `docs/plans/.probe` simultaneously can cause false
plan-mode detection when the second planner's `rm` fails on an already-deleted file.

**Fix:** Use PID-based temp file to avoid collision.

**File:** `plugins/cc-teams/agents/planner.md`

Change probe command:
```bash
# BEFORE (race condition)
Bash(command="mkdir -p docs/plans && echo 'probe' > docs/plans/.probe && rm docs/plans/.probe && echo OK")

# AFTER (PID-unique, no collision)
Bash(command="mkdir -p docs/plans && F=\"docs/plans/.probe-$$\" && echo 'probe' > \"$F\" && rm \"$F\" && echo OK")
```

---

### Fix 15 — Investigator sends challenge messages before lead opens debate (`investigator.md:112-131`)

**Problem:** Investigators have SendMessage and instructions to "challenge peers." No gate
says "wait for lead's debate-start signal." An early investigator can message peers before
all others have submitted their findings, breaking sequencing.

**Fix:** Add explicit wait instruction at the top of the Challenging section.

**File:** `plugins/cc-teams/agents/investigator.md`

Prefix the "## Challenging Other Investigators" section with:
```markdown
**WAIT FOR LEAD SIGNAL:** Do NOT message other investigators until the lead explicitly
sends you a message initiating the debate phase. Complete your own investigation first,
output your Router Contract, then wait. The lead will share all findings and open debate.
Unsolicited peer messages before lead's debate signal are out-of-order and break the verdict.
```

---

### Fix 16 — Builder output section inconsistent with v2.4 contract (`builder.md:219-227`)

**Problem:** `## Router Handoff (Stable Extraction)` (plain text section) doesn't include
`PHASE_GATE_RESULT` or `PHASE_GATE_CMD`, but the YAML block below does.
Two output sections now disagree.

**Fix:** Add PHASE_GATE_RESULT to the Router Handoff stable extraction section.

**File:** `plugins/cc-teams/agents/builder.md`

In `### Router Handoff (Stable Extraction)`, add after `EVIDENCE_COMMANDS`:
```
PHASE_GATE_RESULT: [PASS/FAIL/N/A]
PHASE_GATE_CMD: [gate command from plan or N/A]
```

---

### Fix 17 — Reviewers send unlimited messages after challenge complete (`security/performance/quality-reviewer.md`)

**Problem:** After responding to the challenge round, reviewers continue messaging peers
indefinitely. No close signal exists. Challenge phase can overshoot its deadline.

**Fix:** Add one-response discipline to all 3 reviewer agents.

**Files:** `plugins/cc-teams/agents/security-reviewer.md`, `performance-reviewer.md`, `quality-reviewer.md`

Add to each reviewer's "## Challenge Round Response (MANDATORY)" section:
```markdown
**One-response discipline:** After you send your challenge response (AGREE/DISAGREE/ESCALATE),
you are DONE with the challenge round. Do NOT send additional messages unless another reviewer
directly messages you with a new argument that changes your assessment.
Maximum one unsolicited challenge message per reviewer. The lead will synthesize consensus.
```

---

### Fix 18 — teammate-idle.sh has stale CONTRACT_VERSION check (`hooks/teammate-idle.sh:34`)

**Problem:** The hook's error message says "CONTRACT_VERSION 2.3 schema" but we're now on 2.4.

**Fix:** Update the version reference.

**File:** `plugins/cc-teams/hooks/teammate-idle.sh`
Change: `"See cc-teams:router-contract skill for the required CONTRACT_VERSION 2.3 schema."`
To: `"See cc-teams:router-contract skill for the required CONTRACT_VERSION 2.4 schema."`

---

## Critical Files Modified

| File | Changes |
|------|---------|
| `plugins/cc-teams/agents/planner.md` | Fix SendMessage recipient (plain text output), fix probe race condition |
| `plugins/cc-teams/agents/hunter.md` | Add SendMessage to tools |
| `plugins/cc-teams/agents/verifier.md` | Add SendMessage to tools; fix npm audit jq check |
| `plugins/cc-teams/agents/builder.md` | Add PHASE_GATE fields to Router Handoff section |
| `plugins/cc-teams/agents/investigator.md` | Add debate phase gate (wait for lead signal) |
| `plugins/cc-teams/agents/security-reviewer.md` | Add one-response discipline |
| `plugins/cc-teams/agents/performance-reviewer.md` | Add one-response discipline |
| `plugins/cc-teams/agents/quality-reviewer.md` | Add one-response discipline |
| `plugins/cc-teams/skills/cc-teams-lead/SKILL.md` | Memory Update escape; orphan sweep confirmation; handoff payload roster; shutdown retry bound; pre-compaction hook reference |
| `plugins/cc-teams/skills/bug-court/SKILL.md` | All-BLOCKED exit path; debate round counter |
| `plugins/cc-teams/skills/review-arena/SKILL.md` | Confidence formula; reviewer message discipline |
| `plugins/cc-teams/skills/router-contract/SKILL.md` | Synthesized contract merge rules |
| `plugins/cc-teams/hooks/teammate-idle.sh` | Size guard; version string update |
| `CHANGELOG.md` | Add v0.1.17 |
| `package.json` + `plugin.json` | Bump to 0.1.17 |

## Verification

1. `npm run check:functional-bible` — pass
2. `npm run check:agent-tools` — pass (SendMessage added to hunter/verifier, allowed by lint)
3. `npm run check:artifact-policy` — pass
4. Smoke test: planner probe with PID file — no race condition on concurrent spawn
5. Smoke test: teammate-idle hook with large message — size guard prevents OOM
6. Manual review: orphan sweep no longer silently deletes — asks user for multi-workflow case

## False Alarms (No Fix Needed)

| Flaw # | Why No Fix |
|--------|-----------|
| Challenge Round vs Delegate Mode | Reference docs: delegate mode allows messaging. Challenge round is SendMessage-only. Valid as-is. |
| "Advisory pre-check" boundary | Already defined precisely: destructive commands and secret exposure are the examples. Sufficient for now. |
| QUICK path condition 4 vacuously true | Acceptable: fresh workflow has no open REM-FIX by definition. QUICK escalates to FULL if blocker discovered. |
