---
name: review-arena
description: "Multi-perspective adversarial code review using Agent Teams. Spawn 3 specialized reviewers who challenge each other's findings."
---

# Review Arena Protocol

## Overview

Review Arena uses 3 specialized reviewer teammates who first review independently, then challenge each other's findings via peer messaging, producing a unified verdict that's stronger than any single review.

**Core principle:** First verify it works, THEN verify it's good.

---

## Team Composition

| Teammate | Role | Focus Areas | Mode | When Active |
|----------|------|-------------|------|-------------|
| **security-reviewer** | Security specialist | Auth, injection, secrets, OWASP top 10, XSS, CSRF | READ-ONLY | Always |
| **performance-reviewer** | Performance specialist | N+1 queries, memory leaks, bundle size, caching, loops | READ-ONLY | Always |
| **quality-reviewer** | Quality specialist | Patterns, naming, complexity, error handling, tests, duplication | READ-ONLY | Always |
| **accessibility-reviewer** | A11y specialist (conditional) | WCAG 2.1 AA, keyboard nav, ARIA, semantic HTML, contrast | READ-ONLY | When UI files detected |
| **api-contract-reviewer** | Contract validator (conditional) | Breaking changes, route/schema diffs, type compatibility | READ-ONLY | When API files detected |

All reviewers are READ-ONLY. They cannot edit files. They output Router Contracts with Memory Notes.

**Conditional spawning:** Lead checks builder's `FILES_MODIFIED` field after hunter completes:
- Contains `.tsx|.jsx|.html|.css|.vue` → spawn `accessibility-reviewer`
- Contains `routes/|api/|endpoints/|handlers/|controllers/` → spawn `api-contract-reviewer`

---

## Two-Stage Review Process (Each Reviewer)

### Stage 1: Spec Compliance Review

**Does it do what was asked?**

1. **Read the Requirements** — What was requested? Acceptance criteria? Edge cases?
2. **Trace the Implementation** — Does the code implement each requirement? All edge cases handled?
3. **Test Functionality** — Run the tests. Manual test if needed. Verify outputs.

**Gate:** Only proceed to Stage 2 if Stage 1 passes.

### Stage 2: Code Quality Review (Per Specialty)

**Is it well-written?** Review in priority order:

1. **Security** — Vulnerabilities that could be exploited
2. **Correctness** — Logic errors, edge cases missed
3. **Performance** — Unnecessary slowness
4. **Maintainability** — Hard to understand or modify
5. **UX** — User experience issues (if UI involved)
6. **Accessibility** — A11y issues (if UI involved)

---

## Signal Quality Rule

**Flag ONLY when certain. False positives erode trust and waste remediation cycles.**

| Flag | Do NOT Flag |
|------|-------------|
| Will fail to compile/parse (syntax, type, import errors) | Style preferences not in project guidelines |
| Logic error producing wrong results for all inputs | Potential issues dependent on specific inputs/state |
| Clear guideline violation (quote the exact rule) | Subjective improvements or nitpicks |

### Do NOT Flag (False Positive Prevention)

- Pre-existing issues not introduced by this change
- Correct code that merely looks suspicious
- Pedantic nitpicks a senior engineer would not flag
- Issues linters already catch (don't duplicate tooling)
- General quality concerns not required by project guidelines
- Issues explicitly silenced via lint-ignore comments

---

## Severity Classification

| Severity | Definition | Action |
|----------|------------|--------|
| **CRITICAL** | Security vulnerability or blocks functionality | Must fix before merge |
| **MAJOR** | Affects functionality or significant quality issue | Should fix before merge |
| **MINOR** | Style issues, small improvements | Can merge, fix later |
| **NIT** | Purely stylistic preferences | Optional |

---

## Security Quick-Scan Commands

**Run before any review (by security-reviewer):**
```bash
# Check for hardcoded secrets
grep -rE "(api[_-]?key|password|secret|token)\s*[:=]" --include="*.ts" --include="*.js" src/

# Check for SQL injection risk
grep -rE "(query|exec)\s*\(" --include="*.ts" src/ | grep -v "parameterized"

# Check for dangerous patterns
grep -rE "(eval\(|innerHTML\s*=|dangerouslySetInnerHTML)" --include="*.ts" --include="*.tsx" src/

# Check for console.log (remove before production)
grep -rn "console\.log" --include="*.ts" --include="*.tsx" src/
```

## LSP-Powered Code Analysis

**Use LSP for semantic understanding during reviews:**

| Task | LSP Tool | Why Better Than Grep |
|------|----------|---------------------|
| Find all callers of a function | `lspCallHierarchy(incoming)` | Finds actual calls, not string matches |
| Find all usages of a type/variable | `lspFindReferences` | Semantic, not text-based |
| Navigate to definition | `lspGotoDefinition` | Jumps to actual definition |
| Understand what function calls | `lspCallHierarchy(outgoing)` | Maps call chain |

**Review Workflow with LSP:**
1. `localSearchCode` → find symbol + get lineHint
2. `lspGotoDefinition(lineHint=N)` → understand implementation
3. `lspFindReferences(lineHint=N)` → check all usages for consistency
4. `lspCallHierarchy(incoming)` → verify callers handle changes

**CRITICAL:** Always get lineHint from localSearchCode first. Never guess line numbers.

---

## Protocol Phases

### Phase 1: Independent Review

Each reviewer works independently on the same target code. No communication during this phase.

**Each reviewer must:**
1. Read memory files (`.claude/cc-teams/`)
2. **Stage 1: Spec Compliance** — verify it does what was asked
3. **Stage 2: Quality Review** — from their specialized perspective
4. Score each finding with confidence (report only >=80)
5. Run Self-Critique Gate before outputting:
   - [ ] Follows patterns from patterns.md?
   - [ ] No false positives (check Signal Quality Rule)?
   - [ ] Evidence for every claim?
6. Output their Router Contract

**Fresh evidence mandate:** Every claim must have verifiable evidence. "Should work" is not evidence. Run the command, cite the output.

**Lead actions:**
- Assign each reviewer their task from the task list
- Monitor for completion, applying Task Status Lag escalation (T+2 nudge → T+5 deadline → T+8 replacement)
- **Never passively wait** - if reviewer is `idle-unresponsive`, escalate immediately

### Phase 2: Challenge Round

After all 3 reviewers complete, lead shares findings and initiates cross-review:

**Lead sends to each reviewer:**
```
"Here are the findings from the other reviewers. Challenge anything you disagree with
or that affects your perspective:

Security Reviewer found: [summary of security findings]
Performance Reviewer found: [summary of performance findings]
Quality Reviewer found: [summary of quality findings]

Message the other reviewers directly to debate any findings."
```

**Expected interactions:**
- "Security reviewer: Your fix for XSS would introduce an N+1 query. Here's why..."
- "Performance reviewer: The caching you suggested would bypass auth checks. Security concern."
- "Quality reviewer: Both of you missed that this function violates SRP. Here's the refactor..."

**Lead actions:**
- Monitor teammate messages
- Allow 2-3 rounds of debate
- Intervene if debate becomes unproductive

**Challenge completion criteria (required):**
1. All 3 reviewers acknowledged peer findings (no silent reviewer).
2. At least one cross-review response from each reviewer (agreement or challenge).
3. Conflicts are resolved or explicitly escalated with rationale.
4. Lead publishes merged verdict before downstream verifier/remediation decisions.

**Memory concurrency rule:** NO memory edits during Phase 1 or Phase 2. All reviewers are READ-ONLY for memory files. Memory Notes are collected by lead at Phase 3.

### Phase 3: Consensus

Lead collects final verdicts from all reviewers after challenge round.

**Conflict Resolution Rules:**

| Scenario | Resolution |
|----------|------------|
| All active reviewers agree | Unified verdict (strongest case) |
| Majority agree | Majority rules, document dissent with reasoning |
| Security says CRITICAL, others disagree | **Security wins** (conservative principle) |
| A11y says CRITICAL, others disagree | **A11y wins** (WCAG is regulatory in many sectors; accessibility violations can block enterprise/government use) |
| API contract says CRITICAL, others disagree | **API contract wins** (breaking changes affect external clients; cannot be "fixed later") |
| Performance vs Quality conflict | Present both to user with trade-off analysis |
| No consensus among all active reviewers | Present all perspectives to user, let them decide |

**Severity Precedence:**
- CRITICAL always overrides MAJOR/MINOR
- If ANY active reviewer flags CRITICAL → overall verdict = CHANGES_REQUESTED
- BLOCKING=true if any active reviewer's CRITICAL_ISSUES > 0

---

## Individual Reviewer Output Format

Each reviewer must organize feedback by priority:

```markdown
## Code Review: {target} ({perspective})

### Stage 1: Spec Compliance ✅/❌

**Requirements:**
- [x] Requirement 1 - implemented at `file:line`
- [ ] Requirement 3 - NOT IMPLEMENTED

**Tests:** PASS (24/24)

---

### Stage 2: {Perspective} Review

### Critical (must fix before merge)
- [95] Issue at `src/file.ts:45`
  → Fix: [specific recommendation]

### Warnings (should fix)
- [85] Issue at `src/file.ts:23`
  → Fix: [specific recommendation]

### Suggestions (consider improving)
- [70] Issue at `src/file.ts:12`
  → Suggestion: [improvement]

---

### Summary
**Decision:** Approve / Request Changes
**Critical:** [count] | **Major:** [count] | **Minor:** [count]
```

**ALWAYS include specific examples of how to fix each issue.** Don't just say "this is wrong" — show the correct approach.

---

## Output: Unified Router Contract

After consensus, lead produces a merged Router Contract:

```yaml
STATUS: APPROVE | CHANGES_REQUESTED
CONFIDENCE: [minimum of 3 reviewer confidence scores — weakest-link principle]
CRITICAL_ISSUES: [sum across all reviewers, deduplicated]
HIGH_ISSUES: [sum across all reviewers, deduplicated]
BLOCKING: [true if any CRITICAL_ISSUES > 0]
REQUIRES_REMEDIATION: [true if CHANGES_REQUESTED]
REMEDIATION_REASON: "Fix critical issues: [merged list from all reviewers]"
MEMORY_NOTES:
  learnings: [merged from all 3 reviewers]
  patterns: [merged from all 3 reviewers]
  verification: ["Review Arena: {STATUS} with {CRITICAL_ISSUES} critical, {HIGH_ISSUES} high"]
```

---

## Deduplication Rules

When merging findings across reviewers:

1. **Same file:line, same issue** → Keep highest severity, merge fix recommendations
2. **Same file:line, different issues** → Keep both (different perspectives on same code)
3. **Conflicting recommendations** → Document both, flag for user decision
4. **Overlapping findings** → Credit the reviewer who found it first, combine evidence

---

## When to Use Review Arena

| Scenario | Use Full Arena? | Alternative |
|----------|-----------------|------------|
| PR review (significant changes) | Yes | - |
| Post-build review | Yes | - |
| Quick check (< 50 lines) | No | Single quality-reviewer |
| Security-critical code only | No | Single security-reviewer |
| Post-remediation re-review | Yes (full arena) | - |

---

## Reviewer Timeout/Failure Handling

| Situation | Action |
|-----------|--------|
| Reviewer takes too long (no response) | Lead sends nudge message |
| Reviewer crashes / exits | Lead re-spawns reviewer with same task context |
| Reviewer output missing Router Contract | Lead requests re-output or marks as non-compliant |
| All 3 reviewers fail | Escalate to user — manual review needed |

---

## Red Flags - STOP and Re-review

If you find yourself:

- Reviewing code style before checking functionality
- Not running the tests
- Skipping the security checklist
- Giving generic feedback ("looks good")
- Not providing file:line citations
- Not explaining WHY something is wrong
- Not providing fix recommendations

**STOP. Start over with Stage 1.**

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "Tests pass so it's fine" | Tests can miss requirements. Check spec compliance. |
| "Code looks clean" | Clean code can still be wrong. Verify functionality. |
| "I trust this developer" | Trust but verify. Everyone makes mistakes. |
| "It's a small change" | Small changes cause big bugs. Review thoroughly. |
| "No time for full review" | Bugs take more time than reviews. Do it properly. |
| "Security is overkill" | One vulnerability can sink the company. Check it. |

---

## Task Structure

```
CC-TEAMS REVIEW: {target}
├── CC-TEAMS security-reviewer: Security review of {target}
├── CC-TEAMS performance-reviewer: Performance review of {target}
├── CC-TEAMS quality-reviewer: Quality review of {target}
├── CC-TEAMS Review Arena: Challenge round (blocked by all 3 reviewers)
└── CC-TEAMS Memory Update: Persist review learnings (blocked by challenge round)
```
