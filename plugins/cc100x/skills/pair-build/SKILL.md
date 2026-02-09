---
name: pair-build
description: "Real-time pair programming using Agent Teams. Builder implements with live reviewer feedback, then hunter, full Review Arena, and verifier enforce post-build quality."
---

# Pair Build Protocol

## Overview

Pair Build creates a real-time pair programming experience. The Builder implements code module by module, pausing after each to get feedback from the Live Reviewer. After implementation, the Hunter scans for silent failures, then a full Review Arena (security/performance/quality + challenge) runs before the Verifier executes E2E checks.

**Core principle:** If you didn't watch the test fail, you don't know if it tests the right thing.

---

## The TDD Iron Law

```
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
```

Write code before the test? Delete it. Start over.

**No exceptions:**
- Don't keep it as "reference"
- Don't "adapt" it while writing tests
- Don't look at it
- Delete means delete

Implement fresh from tests. Period.

---

## Team Composition

| Teammate | Role | Mode | When Active |
|----------|------|------|-------------|
| **builder** | Implements code using TDD | READ+WRITE | Phase 1 (entire implementation) |
| **live-reviewer** | Reviews in real-time as builder works | READ-ONLY | Phase 1 (alongside builder) |
| **hunter** | Scans for silent failures | READ-ONLY | Phase 2 (after builder completes) |
| **security-reviewer** | Full post-build security review | READ-ONLY | Phase 3 (after hunter completes) |
| **performance-reviewer** | Full post-build performance review | READ-ONLY | Phase 3 (after hunter completes) |
| **quality-reviewer** | Full post-build quality review | READ-ONLY | Phase 3 (after hunter completes) |
| **verifier** | Runs E2E verification | READ-ONLY | Phase 4 (after review challenge) |

**File ownership:** ONLY the builder edits files. All other teammates are READ-ONLY.

---

## Plan-First Gate

Before starting Pair Build, check:
1. Does a plan exist? (Check `activeContext.md ## References`)
2. If no plan → AskUserQuestion: "Plan first (Recommended) / Build directly"
3. If plan exists → builder receives plan file path in prompt

**Builder must read and follow the plan.** Plan is the source of truth for what to build.

---

## Protocol Phases

### Phase 1: Implementation Loop (Builder + Live Reviewer)

**Builder and Live Reviewer start simultaneously.**

#### Red-Green-Refactor (TDD Cycle)

```
    ┌─────────┐       ┌─────────┐       ┌───────────┐
    │   RED   │──────>│  GREEN  │──────>│ REFACTOR  │
    │ (Fail)  │       │ (Pass)  │       │ (Clean)   │
    └─────────┘       └─────────┘       └───────────┘
         ^                                    │
         │                                    │
         └────────────────────────────────────┘
                    Next Feature
```

**RED - Write Failing Test:**
- One minimal test showing what should happen
- Clear name, tests real behavior, one thing
- `npm test path/to/test.test.ts` → Confirm it FAILS (not errors)
- **Test passes? You're testing existing behavior. Fix test.**

**GREEN - Minimal Code:**
- Simplest code to pass the test. Nothing more.
- Don't add features, don't refactor, don't "improve" beyond the test
- Don't hard-code test values — implement general logic
- `npm test path/to/test.test.ts` → Confirm it PASSES
- **Test fails? Fix code, not test.**

**REFACTOR - Clean Up (After Green Only):**
- Remove duplication, improve names, extract helpers
- Keep tests green. Don't add behavior.

#### Builder-Reviewer Synchronization Pattern

```
Builder implements module 1 (TDD cycle)
  → Builder messages live-reviewer: "Review src/auth/middleware.ts"
  → Live Reviewer reads file, messages back: "LGTM" or "STOP: [issue]"
  → If STOP: Builder fixes inline, messages reviewer again
  → If LGTM: Builder continues to module 2

Builder implements module 2 (TDD cycle)
  → Same review loop

...

Builder messages live-reviewer: "Implementation complete"
  → Live Reviewer finishes their task
```

**Synchronization note (Agent Teams):** Agent Teams has no blocking wait primitive. Builder uses message-based polling — after sending review request, builder checks for reviewer response before starting next module. If no response within reasonable time, builder sends a nudge.

**Builder rules:**
- Follow TDD: RED → GREEN → REFACTOR for each module
- After each module, pause and request review
- Wait for reviewer response before continuing
- If reviewer says STOP → fix before continuing
- Own ALL file edits (no other teammate edits files)

**Live Reviewer rules:**
- READ-ONLY: never edit files
- When builder requests review:
  - Read the specific file(s)
  - Check: security, correctness, pattern adherence
  - Reply with: "LGTM" (continue) or "STOP: [critical issue]" (must fix)
  - Keep feedback focused (not a full review — save that for Review Arena)
- Only say STOP for actual blocking issues (security, correctness)
- Pattern suggestions are "NOTE: [suggestion]" (non-blocking)

#### Verify RED mandate (MANDATORY, never skip)

```bash
npm test path/to/test.test.ts
```

Confirm:
- Test fails (not errors)
- Failure message is expected
- Fails because feature missing (not typos)

#### Verify GREEN mandate (MANDATORY)

```bash
npm test path/to/test.test.ts
```

Confirm:
- Test passes
- Other tests still pass
- Output pristine (no errors, warnings)

### Phase 2: Silent Failure Hunt (Hunter)

**Starts after builder completes.**

Hunter scans the entire implementation for:
- Empty catch blocks
- Log-only error handlers
- Generic error messages ("Something went wrong")
- Swallowed exceptions
- Missing error boundaries

**Severity classification:**
| Severity | Definition | Blocks Ship? |
|----------|-----------|-------------|
| CRITICAL | Data loss, security, crash | YES |
| HIGH | Wrong behavior, degraded UX | Should fix |
| MEDIUM | Suboptimal but functional | Track as TODO |
| LOW | Code smell | Optional |

**If CRITICAL issues found:** Lead creates remediation task for builder.

### Phase 3: Comprehensive Review Arena (Security + Performance + Quality)

**Starts after hunter completes.**

Run a full review gate (not live-review quick checks):

1. Spawn security-reviewer, performance-reviewer, and quality-reviewer in parallel
2. Each reviewer performs full-stage review with Router Contract output
3. Lead runs challenge round and merges a unified verdict
4. If any CRITICAL issues remain, route remediation before verification

**Why this gate exists:** Live-reviewer is intentionally focused and fast. This phase restores full multi-dimensional depth before ship decisions.

**Non-bypass rule (hard):**
- Verifier must remain blocked until the Build Review Arena challenge round is complete.
- Hunter findings do not unlock verifier directly.
- Remediation completion does not unlock verifier directly; re-review + challenge must run first.

### Contract-First Relay for Dependency-Sensitive Changes

When BUILD work includes cross-layer dependencies (API contract, response shape, URL conventions, streaming semantics), run contract-first relay before downstream integration checks:

1. Upstream owner publishes explicit contract details to lead.
2. Lead verifies contract for ambiguity.
3. Lead forwards verified contract to affected teammates.
4. Downstream work proceeds only after contract relay.

This prevents parallel drift and late integration surprises.

### Phase 4: E2E Verification (Verifier)

**Starts after Review Arena challenge completes.**

Verifier runs:
1. All unit tests
2. Integration tests (if available)
3. E2E scenarios
4. Build verification

Verifier must consider findings from hunter + all reviewers.

Every scenario needs PASS/FAIL with exit code evidence.

**Fresh evidence mandate:** Every claim must have verifiable evidence. "Should pass" is not evidence. Run the command, cite the output.

#### Self-Critique Gate (Before claiming pass)

- [ ] Follows patterns from patterns.md?
- [ ] No unexpected files changed?
- [ ] Requirements fully met?
- [ ] No scope creep?

#### Goal-Backward Lens (After standard verification)

```
GOAL: [What user wants to achieve]

TRUTHS (observable):
- [ ] [User-facing behavior 1]
- [ ] [User-facing behavior 2]

ARTIFACTS (exist):
- [ ] [Required file/endpoint 1]
- [ ] [Required file/endpoint 2]

WIRING (connected):
- [ ] [Component] → [calls] → [API]
- [ ] [API] → [queries] → [Database]
```

Goal-backward asks: "Does the GOAL work?" not "Did the TASK complete?"

#### Stub Detection (Before claiming completion)

```bash
# Check for TODO/placeholder markers
grep -rE "(TODO|FIXME|placeholder|not implemented)" src/
# Check for empty handlers
grep -rE "onClick=\{?\(\) => \{\}\}?" src/
# Check for empty returns
grep -rE "return (null|undefined|\{\}|\[\])" src/
```

**If any stub patterns found:** DO NOT claim completion.

**If verification fails:**
- Option A: Create fix task (fixable issue)
- Option B: Revert changes (fundamental design issue)
- Option C: Document limitation + get user approval

---

## Good Tests

| Quality | Good | Bad |
|---------|------|-----|
| **Minimal** | One thing. "and" in name? Split it. | `test('validates email and domain and whitespace')` |
| **Clear** | Name describes behavior | `test('test1')` |
| **Shows intent** | Demonstrates desired API | Obscures what code should do |

## Mocking External Dependencies (When Unavoidable)

**Rule:** Prefer real code. Mock only when:
- External API (network calls)
- Database (test isolation)
- Time-dependent logic
- Third-party services

**Mock quality check:** If mock setup > test code, reconsider design.

---

## Task Structure

```
CC100X BUILD: {feature}
├── CC100X builder: Implement {feature}
├── CC100X live-reviewer: Real-time review (starts with builder)
├── CC100X hunter: Silent failure audit (blocked by builder)
├── CC100X security-reviewer: Security review (blocked by hunter)
├── CC100X performance-reviewer: Performance review (blocked by hunter)
├── CC100X quality-reviewer: Quality review (blocked by hunter)
├── CC100X BUILD Review Arena: Challenge round (blocked by all 3 reviewers)
├── CC100X verifier: E2E verification (blocked by challenge round)
└── CC100X Memory Update: Persist build learnings (blocked by verifier)
```

---

## Remediation Loop

If hunter finds CRITICAL issues or verifier fails:

1. Lead creates `CC100X REM-FIX: {issue}` task
2. **Circuit breaker:** If 3+ REM-FIX tasks exist → AskUserQuestion (research/fix/skip/abort)
3. Builder fixes the issue
4. Full-spectrum re-review (security + performance + quality) + challenge
5. Re-hunt for silent failures
6. Re-verification (affected scenarios only)
7. If passes → proceed to Memory Update
8. If fails again → escalate to user

**Code changes without re-review break orchestration integrity.**

---

## TDD Verification Checklist

Before marking build complete:

- [ ] Every new function/method has a test
- [ ] Watched each test fail before implementing
- [ ] Each test failed for expected reason (feature missing, not typo)
- [ ] Wrote minimal code to pass each test
- [ ] All tests pass
- [ ] Output pristine (no errors, warnings)
- [ ] Tests use real code (mocks only if unavoidable)
- [ ] Edge cases and errors covered

Can't check all boxes? You skipped TDD. Start over.

---

## Memory Notes Collection

At workflow end, lead collects from all teammates:

| Teammate | Memory Notes |
|----------|-------------|
| Builder | What was built, TDD evidence, patterns used |
| Live Reviewer | Code quality observations, pattern adherence |
| Hunter | Error handling patterns, silent failure risks |
| Security Reviewer | Security risks and mitigations |
| Performance Reviewer | Performance bottlenecks and optimizations |
| Quality Reviewer | Correctness and maintainability findings |
| Verifier | E2E results, integration observations |

All notes merged and persisted to `.claude/cc100x/` files.

---

## Red Flags - STOP and Start Over

If you catch yourself:

- Code before test
- Test after implementation
- Test passes immediately
- Can't explain why test failed
- Tests added "later"
- Rationalizing "just this once"
- "I already manually tested it"
- "Tests after achieve the same purpose"
- "Keep as reference" or "adapt existing code"
- "Already spent X hours, deleting is wasteful"
- "TDD is dogmatic, I'm being pragmatic"
- "This is different because..."
- "It's about spirit not ritual"

**All of these mean: Delete code. Start over with TDD.**

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "Too simple to test" | Simple code breaks. Test takes 30 seconds. |
| "I'll test after" | Tests passing immediately prove nothing. |
| "Tests after achieve same goals" | Tests-after = "what does this do?" Tests-first = "what should this do?" |
| "Already manually tested" | Ad-hoc ≠ systematic. No record, can't re-run. |
| "Deleting X hours is wasteful" | Sunk cost fallacy. Keeping unverified code is technical debt. |
| "Keep as reference, write tests first" | You'll adapt it. That's testing after. Delete means delete. |
| "Need to explore first" | Fine. Throw away exploration, start with TDD. |
| "Test hard = design unclear" | Listen to test. Hard to test = hard to use. |
| "TDD will slow me down" | TDD faster than debugging. Pragmatic = test-first. |
| "Manual test faster" | Manual doesn't prove edge cases. You'll re-test every change. |
| "Existing code has no tests" | You're improving it. Add tests for existing code. |
