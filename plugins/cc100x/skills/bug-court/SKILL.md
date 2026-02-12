---
name: bug-court
description: "Competing hypothesis debugging using Agent Teams. Multiple investigators each champion a hypothesis, then debate to find root cause."
---

# Bug Court Protocol

## Overview

Bug Court replaces single-threaded debugging with **competing hypotheses**. Multiple investigators each champion a different root cause hypothesis, gather evidence, then debate each other. The hypothesis that survives cross-examination wins.

**Core principle:** ALWAYS find root cause before attempting fixes. Symptom fixes are failure.

**Violating the letter of this process is violating the spirit of debugging.**

---

## The Iron Law

```
NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST
```

If you haven't completed Phase 1, you cannot propose fixes.

---

## Team Composition

| Teammate | Role | Mode |
|----------|------|------|
| **investigator-1** through **investigator-N** | Hypothesis champion | **READ-ONLY** (gather evidence, run tests, NO source edits) |
| **builder** (Phase 5 only) | Fix implementer | READ+WRITE (implements the winning fix) |
| **security-reviewer** (Phase 6) | Security review of fix | READ-ONLY |
| **performance-reviewer** (Phase 6) | Performance review of fix | READ-ONLY |
| **quality-reviewer** (Phase 6) | Quality review of fix | READ-ONLY |
| **verifier** (Phase 7) | E2E verification of fix | READ-ONLY |

**CRITICAL:** Investigators are READ-ONLY. They gather evidence and run diagnostic commands but do NOT edit source code. Only the builder (spawned after verdict) implements the fix. This prevents file conflicts between parallel investigators.

Number of investigators = number of plausible hypotheses (typically 2-5).

## Activation Strategy (Agent Teams-Native)

Use phase-scoped activation for cleaner debugging flow:

1. Team kickoff: spawn only `investigator-*` roles for current hypotheses.
2. Spawn `builder` only after debate verdict confirms root cause.
3. Spawn review triad only after fix task is runnable.
4. Spawn `verifier` only after challenge round task is runnable.

Do not pre-spawn downstream roles before their phase.

---

## Protocol Phases

### Phase 1: Hypothesis Generation (Lead)

Before spawning investigators, the lead generates hypotheses:

1. **Gather initial evidence:**
   - Error message / stack trace
   - Reproduction steps
   - Recent changes (`git log --oneline -10 -- <affected-files>`)
   - Memory patterns (`patterns.md ## Common Gotchas`)

2. **Generate 2-5 hypotheses:**
   ```
   H1: [Most likely cause based on evidence]
   H2: [Alternative cause]
   H3: [Less likely but possible cause]
   ```

3. **Each hypothesis must be:**
   - **Falsifiable**: Can be proven wrong with a specific test
   - **Specific**: "Race condition in auth middleware" not "timing issue"
   - **Testable**: Clear experiment to confirm or deny

4. **Each hypothesis must include:**
   - **Confidence score (0-100)** with rationale explaining WHY
   - **Next test**: The smallest discriminating test to prove/disprove

   ```
   H1: Race condition in auth middleware
   - Confidence: 75 (logs show timing variance, but no direct evidence yet)
   - Next test: Run with PARALLEL=true and check for interleaved logs

   H2: Stale cache returning old auth token
   - Confidence: 40 (possible but no cache invalidation errors in logs)
   - Next test: Clear cache and retry - if bug disappears, cache is cause
   ```

**Bad (unfalsifiable):**
- "Something is wrong with the state"
- "The timing is off"
- "There's a race condition somewhere"

**Good (falsifiable with confidence + next test):**
- "User state resets because component remounts when route changes" (Confidence: 80, Next test: Add console.log in useEffect cleanup)
- "API call completes after unmount, causing state update on unmounted component" (Confidence: 65, Next test: Check React warnings in console)
- "Two async operations modify same array without locking, causing data loss" (Confidence: 70, Next test: Add mutex and see if bug disappears)

### Phase 2: Investigation (Parallel)

Each investigator works independently to test their hypothesis.

**Each investigator must:**
1. Read memory files
2. Gather evidence FOR their hypothesis
3. Gather evidence AGAINST other hypotheses (if accessible)
4. Produce diagnostic test commands/scripts in their report (RED phase — demonstrate the bug)
5. Document root cause analysis with evidence
6. Output Router Contract

**File ownership during investigation:**
- Investigators are READ-ONLY — they read code, run tests, and provide reproduction scripts/commands in their output
- Investigators do NOT modify source files
- Only ONE agent (builder) will implement the fix after verdict
- The lead decides which hypothesis wins based on evidence

**Fresh evidence mandate:** Every claim must have verifiable evidence. "Should be the cause" is not evidence. Run the diagnostic, cite the output.

**Lead actions:**
- Assign each investigator their hypothesis task from the task list
- Monitor for completion, applying Task Status Lag escalation (T+2 nudge → T+5 deadline → T+8 replacement)
- **Never passively wait** - if investigator is `idle-unresponsive`, escalate immediately

**Memory concurrency rule:** NO memory edits during Phase 2 (parallel investigation). All investigators include Memory Notes in their Router Contract for lead to persist after completion.

### Phase 3: Debate (Peer Messaging)

After all investigators complete:

**Lead shares all evidence and initiates debate:**
```
"All investigators have completed their analysis. Here are the findings:

Investigator 1 ({h1}): [evidence summary]
Investigator 2 ({h2}): [evidence summary]
Investigator 3 ({h3}): [evidence summary]

Challenge each other's findings. Message the other investigators directly.
Try to disprove the other hypotheses using your evidence."
```

**Expected interactions:**
- "Investigator 2: Your theory doesn't explain why the bug only occurs with concurrent requests."
- "Investigator 1: I can disprove your hypothesis. Look at the logs from test X - the timing doesn't match."
- "Investigator 3: Both of you are wrong. The stack trace clearly shows the error originates from..."

**Lead monitors debate and allows 2-3 rounds of messaging.**

**Debate completion criteria (lead checks before moving to verdict):**
1. All investigators have had opportunity to challenge (at least 1 response from each)
2. No new evidence being presented (repeat arguments = done)
3. Maximum 3 rounds OR unanimous stand-down
4. If investigator goes silent after prompt → send nudge, then proceed without their input

### Phase 4: Verdict (Lead)

Lead evaluates:

| Criterion | Weight |
|-----------|--------|
| Evidence strength (reproducible test) | Highest |
| Survived cross-examination | High |
| Explains ALL symptoms | High |
| Simplicity (Occam's razor) | Medium |
| Counter-evidence against alternatives | Medium |

**Verdict decision rules:**
- **Clear winner**: Hypothesis has reproducible test AND survived all challenges AND explains primary symptom → Proceed to fix
- **Tie**: Two hypotheses both have reproducible tests; present both to user with evidence summaries
- **All weak**: No hypothesis has reproducible test → require new investigation round (max 2 rounds total)
- **Contested**: One has test, another has strong counter-evidence; present to user with evidence summary
- **Investigator has diagnostic proof**: Winning investigator has reproduction script → Pass to builder

**If user decision required, format as AskUserQuestion:**
```
Hypothesis A: [evidence summary] [reproduction command]
Hypothesis B: [evidence summary] [reproduction command]
Recommendation: [lead's assessment based on weight criteria]
```

### Phase 5: Fix Implementation

Assign builder to implement fix based on winning root cause:
- Builder reads winning investigator's evidence + reproduction script
- Builder must follow TDD: regression test FIRST (must fail before fix), then minimal fix
- Builder verifies regression test passes + full test suite passes

### Phase 6: Full-Spectrum Review the Fix

Run Review Arena triad on the fix:
- security-reviewer checks auth/injection/secrets/OWASP regressions
- performance-reviewer checks latency/throughput/memory regressions
- quality-reviewer checks correctness/patterns/maintainability
- lead runs challenge round to resolve conflicts

**CRITICAL: No nested teams.** Do NOT create a new Agent Team for the review. Spawn all 3 reviewers into the existing Bug Court team.

### Phase 7: Verify the Fix

Verifier runs after challenge round and must consider all reviewer findings plus root-cause evidence.

### Phase 8: Persist Memory

Lead persists:
- Root cause → `patterns.md ## Common Gotchas`
- Debug journey → `activeContext.md ## Learnings`
- Fix verification → `progress.md ## Verification`

---

## Root Cause Tracing Technique

```
1. Observe symptom - Where does error manifest?
2. Find immediate cause - Which code produces the error?
3. Ask "What called this?" - Map call chain upward
4. Keep tracing up - Follow invalid data backward
5. Find original trigger - Where did problem actually start?
```
**Never fix solely where errors appear—trace to the original trigger.**

## LSP-Powered Root Cause Tracing

**Use LSP to trace execution flow systematically:**

| Debugging Need | LSP Tool | Usage |
|----------------|----------|-------|
| "Where is this function defined?" | `lspGotoDefinition` | Jump to source |
| "What calls this function?" | `lspCallHierarchy(incoming)` | Trace callers up |
| "What does this function call?" | `lspCallHierarchy(outgoing)` | Trace callees down |
| "All usages of this variable?" | `lspFindReferences` | Find all access points |

**Systematic Call Chain Tracing:**
```
1. localSearchCode("errorFunction") → get file + lineHint
2. lspGotoDefinition(lineHint=N) → see implementation
3. lspCallHierarchy(incoming, lineHint=N) → who calls this?
4. For each caller: lspCallHierarchy(incoming) → trace up
5. Continue until you find the root cause
```

**CRITICAL:** Always get lineHint from localSearchCode first. Never guess line numbers.

---

## Common Debugging Scenarios

### Build & Type Errors

| Error Pattern | Cause | Fix |
|---------------|-------|-----|
| `Parameter 'x' implicitly has 'any' type` | Missing type annotation | Add `: Type` annotation |
| `Object is possibly 'undefined'` | Null safety violation | Add `?.` or null check |
| `Property 'x' does not exist on type` | Missing property | Add to interface or fix typo |
| `Cannot find module 'x'` | Import path wrong | Fix path or `npm install` |
| `Type 'string' is not assignable to 'number'` | Type mismatch | Parse string or fix type |

### Test Failures
```
1. Read FULL error message and stack trace
2. Identify which assertion failed and why
3. Check test setup - is environment correct?
4. Check test data - are mocks/fixtures correct?
5. Trace to source of unexpected value
```

### Runtime Errors
```
1. Capture full stack trace
2. Identify line that throws
3. Check what values are undefined/null
4. Trace backward to where bad value originated
5. Add validation at the source
```

### "It worked before"
```
1. Use `git bisect` to find breaking commit
2. Compare change with previous working version
3. Identify what assumption changed
4. Fix at source of assumption violation
```

### Intermittent Failures
```
1. Look for race conditions
2. Check for shared mutable state
3. Examine async operation ordering
4. Look for timing dependencies
5. Add deterministic waits or proper synchronization
```

### Frontend Browser Errors
```
1. Request clean console: AskUserQuestion → "F12 → Console → Clear → reproduce → Copy all"
2. Analyze grouped messages for repetition patterns
3. Check for hidden CORS errors
4. If insufficient: request user add console.log at suspected locations
5. Trace to source of unexpected value
```

---

## Cognitive Biases in Debugging

| Bias | Trap | Antidote |
|------|------|----------|
| **Confirmation** | Only look for evidence supporting your hypothesis | "What would prove me wrong?" |
| **Anchoring** | First explanation becomes your anchor | Generate 3+ hypotheses before investigating any |
| **Availability** | Recent bugs → assume similar cause | Treat each bug as novel until evidence suggests otherwise |
| **Sunk Cost** | Spent 2 hours on path, keep going despite evidence | Every 30 min: "If fresh, would I take this path?" |

## When to Restart Investigation

Consider starting over when:
1. **2+ hours with no progress** — You're likely tunnel-visioned
2. **3+ "fixes" that didn't work** — Your mental model is wrong
3. **You can't explain the current behavior** — Don't add changes on top of confusion
4. **You're debugging the debugger** — Something fundamental is wrong
5. **The fix works but you don't know why** — This isn't fixed, this is luck

**Restart protocol:**
1. Close all files and terminals
2. Write down what you know for certain
3. Write down what you've ruled out
4. List new hypotheses (different from before)
5. Begin again from Phase 1

---

## When Process Reveals "No Root Cause"

If systematic investigation reveals issue is truly environmental, timing-dependent, or external:

1. You've completed the process
2. Document what you investigated
3. Implement appropriate handling (retry, timeout, error message)
4. Add monitoring/logging for future investigation

**But:** 95% of "no root cause" cases are incomplete investigation.

---

## Context Retrieval Pattern (3-Cycle)

When stuck, follow this evidence-gathering cycle:

```
Cycle 1: Read error → Read code → Read tests
Cycle 2: Read similar working code → Read git history → Read docs
Cycle 3: Read memory (patterns.md) → Read external research → Read framework source
```

Each cycle broadens scope. Most bugs resolve by Cycle 2.

---

## Task Structure

```
CC100X DEBUG: {error_summary}
├── CC100X investigator-1: Test hypothesis - {h1}
├── CC100X investigator-2: Test hypothesis - {h2}
├── CC100X investigator-3: Test hypothesis - {h3}
├── CC100X Bug Court: Debate round (blocked by all investigators)
├── CC100X builder: Implement winning fix (blocked by debate)
├── CC100X security-reviewer: Review fix security (blocked by fix)
├── CC100X performance-reviewer: Review fix performance (blocked by fix)
├── CC100X quality-reviewer: Review fix quality (blocked by fix)
├── CC100X DEBUG Review Arena: Challenge round (blocked by all 3 reviewers)
├── CC100X verifier: Verify fix E2E (blocked by challenge round)
└── CC100X Memory Update: Persist debug learnings (blocked by verifier)
```

---

## Anti-Hardcode Gate (REQUIRED)

Before implementing any fix, the builder must check:

**Variant dimensions to consider (only if relevant to this bug):**
- Locale/i18n, configuration, roles/permissions, platform/runtime
- Time/timezone, data shape, concurrency, network, caching

**Regression test MUST cover at least one non-default variant.**

---

## Debug Attempt Tracking

Investigators record attempts in standardized format:
```
[DEBUG-N]: {what was tried} → {result}
```

This enables:
- Lead counting attempts for escalation decisions (3+ → external research)
- Memory preservation of investigation path
- Avoiding repeated failed approaches in future sessions

---

## Investigator Timeout/Failure Handling

| Situation | Action |
|-----------|--------|
| Investigator takes too long | Lead sends nudge message |
| Investigator crashes / exits | Lead re-spawns with same hypothesis + context |
| Investigator output missing Router Contract | Lead requests re-output or marks non-compliant |
| All investigators fail to find evidence | Generate new hypotheses (max 2 rounds) then escalate to user |

---

## File Conflict Resolution (Agent Teams)

Since investigators are READ-ONLY, file conflicts are avoided by design. However:

| Scenario | Resolution |
|----------|------------|
| Investigator needs to add debug logging | Use `Bash(command="...")` to run diagnostic commands instead of editing files |
| Investigator wants to test a code change | Describe the change in evidence; builder implements after verdict |
| Two investigators want to modify same file | Not possible — they're READ-ONLY. Only builder edits. |

---

## Red Flags - STOP and Follow Process

If you catch yourself:

- "Quick fix for now, investigate later"
- "Just try changing X and see if it works"
- "Add multiple changes, run tests"
- "Skip the test, I'll manually verify"
- "It's probably X, let me fix that"
- "I don't fully understand but this might work"
- "Pattern says X but I'll adapt it differently"
- "Here are the main problems: [lists fixes without investigation]"
- Proposing solutions before tracing data flow
- **"One more fix attempt" (when already tried 2+)**
- **Each fix reveals new problem in different place**

**ALL of these mean: STOP. Return to Phase 1.**

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "Issue is simple, don't need process" | Simple issues have root causes too. Process is fast for simple bugs. |
| "Emergency, no time for process" | Systematic debugging is FASTER than guess-and-check thrashing. |
| "Just try this first, then investigate" | First fix sets the pattern. Do it right from the start. |
| "I'll write test after confirming fix works" | Untested fixes don't stick. Test first proves it. |
| "Multiple fixes at once saves time" | Can't isolate what worked. Causes new bugs. |
| "Reference too long, I'll adapt the pattern" | Partial understanding guarantees bugs. Read it completely. |
| "I see the problem, let me fix it" | Seeing symptoms ≠ understanding root cause. |
| "One more fix attempt" (after 2+ failures) | 3+ failures = architectural problem. Question pattern, don't fix again. |
