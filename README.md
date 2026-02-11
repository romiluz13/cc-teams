# cc100x

### Next-Gen Orchestration on Agent Teams

**Current version:** 0.1.6

**Requires: Agent Teams enabled (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`)**

<p align="center">
  <strong>1 Lead</strong> &nbsp;•&nbsp; <strong>9 Agents</strong> &nbsp;•&nbsp; <strong>8 Workflow Skills</strong> &nbsp;•&nbsp; <strong>4 Workflows</strong> &nbsp;•&nbsp; <strong>9 Domain Skills</strong>
</p>

<p align="center">
  <em>Agent Teams do the work. You review the results.</em>
</p>

---

## What Makes CC100x Different From CC10x

CC10x uses **sequential agent delegation** - one agent at a time, orchestrated by the router.

CC100x uses **Agent Teams** - real teammates that message each other, debate, and work in parallel:

| Feature | CC10x | CC100x |
|---------|-------|--------|
| **Code Review** | Single reviewer | **3 reviewers** (security + performance + quality) who **challenge each other** |
| **Debugging** | Single investigator | **Multiple investigators** each championing a different hypothesis, then **debating** |
| **Building** | Builder then reviewer | Builder and reviewer work **simultaneously** - real-time pair programming |
| **Communication** | Router passes results between agents | Agents **message each other directly** |
| **Architecture** | Hub and spoke | **Peer-to-peer mesh** |

---

## How It Works

```
YOU: "build a user auth system"

                    ┌──────────────────────────────────────────────┐
                    │              cc100x-lead                       │
                    │       (creates team, delegates)                │
                    └───────────────┬──────────────────────────────┘
                                    │
                    ┌───────────────▼──────────────────────────────┐
                    │           PAIR BUILD TEAM                      │
                    │                                                │
                    │   builder ◄──────► live-reviewer               │
                    │     │        real-time         (LGTM/STOP)    │
                    │     │        messaging                        │
                    │     ▼                                          │
                    │   hunter (silent failure scan)                 │
                    │     │                                          │
                    │     ▼                                          │
                    │   review arena (sec/perf/quality + challenge) │
                    │     │                                          │
                    │     ▼                                          │
                    │   verifier (E2E tests)                        │
                    └──────────────────────────────────────────────┘
```

---

## The 4 Workflows

| Intent | Trigger Words | What Happens |
|--------|---------------|--------------|
| **BUILD** | build, implement, create, make | **Pair Build**: Builder + Live Reviewer, then Hunter, Review Arena (triad + challenge), then Verifier |
| **DEBUG** | debug, fix, error, bug, broken | **Bug Court**: Multiple investigators compete with hypotheses, then debate |
| **REVIEW** | review, audit, check, analyze | **Review Arena**: 3 specialized reviewers challenge each other's findings |
| **PLAN** | plan, design, architect, roadmap | Single planner in Plan Approval Mode |

---

## The 3 Protocols

### Review Arena (REVIEW)

Three reviewers independently analyze your code, then cross-examine each other:

```
Security Reviewer: "Found XSS vulnerability at line 45"
Performance Reviewer: "The fix for that XSS would create an N+1 query"
Quality Reviewer: "Here's a pattern that solves both - extract to middleware"
```

**Conflict resolution:** Security concerns always win. Majority rules otherwise.

### Bug Court (DEBUG)

Multiple investigators each champion a different hypothesis, gather evidence, then debate:

```
Investigator 1: "Race condition in auth middleware" (evidence: timing logs)
Investigator 2: "Stale cache after deploy" (evidence: cache timestamps)
Investigator 3: "Your theory doesn't explain intermittent failures"
Investigator 1: "Look at my test - concurrent requests reproduce it every time"
```

**Verdict:** Strongest evidence + survived cross-examination wins.

### Pair Build (BUILD)

Builder and reviewer work simultaneously with real-time messaging:

```
Builder: "Review src/auth/middleware.ts"
Reviewer: "LGTM - JWT validation looks correct"
Builder: "Review src/auth/session.ts"
Reviewer: "STOP - token stored in localStorage. Use httpOnly cookie."
Builder: "Fixed. Re-review?"
Reviewer: "LGTM"
```

---

## The 9 Agents

| Agent | Role | Mode |
|-------|------|------|
| **security-reviewer** | OWASP top 10, auth, injection, secrets | READ-ONLY |
| **performance-reviewer** | N+1, memory leaks, caching, bundle size | READ-ONLY |
| **quality-reviewer** | Patterns, naming, complexity, test coverage | READ-ONLY |
| **builder** | TDD implementation (RED-GREEN-REFACTOR) | READ+WRITE |
| **live-reviewer** | Real-time review during Pair Build | READ-ONLY |
| **hunter** | Silent failure detection | READ-ONLY |
| **verifier** | E2E integration verification | READ-ONLY |
| **investigator** | Hypothesis champion in Bug Court | READ-ONLY |
| **planner** | Comprehensive plan creation | WRITE (plan files only) |

---

## The 8 Workflow Skills

| Skill | Purpose |
|-------|---------|
| **cc100x-lead** | Entry point - creates teams, delegates, collects results |
| **review-arena** | Multi-perspective adversarial review protocol |
| **bug-court** | Competing hypothesis debugging protocol |
| **pair-build** | Real-time pair programming protocol |
| **session-memory** | Context persistence across sessions |
| **verification** | Evidence-before-claims enforcement |
| **router-contract** | YAML contract format for all agents |
| **github-research** | External code research via Octocode/GitHub with tiered fallbacks |

## The 9 Domain Skills

Domain skills provide deep expertise. Loaded automatically by the lead via SKILL_HINTS:

| Skill | Used By | Purpose |
|-------|---------|---------|
| **debugging-patterns** | investigator, hunter, verifier | Systematic debugging, root cause tracing, LSP analysis |
| **test-driven-development** | builder | TDD Iron Law, Red-Green-Refactor cycle |
| **code-review-patterns** | reviewers, live-reviewer, hunter | Two-stage review, security checklist |
| **planning-patterns** | planner | Plan structure, task granularity, risk assessment |
| **code-generation** | builder | Pattern matching, minimal code, universal questions |
| **github-research** | planner, investigator | External research, tiered fallbacks, checkpoint saves |
| **architecture-patterns** | builder, reviewers, investigator, hunter, verifier, planner | Architecture consistency, API/layer patterns |
| **frontend-patterns** | builder, reviewers, investigator, hunter, verifier, planner | UX/accessibility/loading-state frontend standards |
| **brainstorming** | planner | Structured discovery and option framing |

---

## What Makes CC100x TRULY 100x (Not Just Renamed CC10x)

CC100x isn't just CC10x with Agent Teams bolted on. It's architecturally different:

| Dimension | CC10x (Sequential) | CC100x (Agent Teams) |
|-----------|---------------------|----------------------|
| **Review quality** | 1 reviewer sees everything | 3 specialists see what others miss, then **cross-examine** |
| **Debug speed** | 1 hypothesis at a time, try → fail → next | 3+ hypotheses **in parallel**, strongest evidence wins |
| **Build safety** | Build → review (reviewer sees cold code) | Build + review **simultaneously** (reviewer sees hot code) |
| **Error handling** | Hunter finds issues, builder may miss context | Hunter + Verifier + Remediation Loop (task-enforced) |
| **Memory** | Session memory survives context loss | Same + **task-enforced** memory (can't skip Memory Update) |
| **Skill loading** | Frontmatter injection (auto) | SKILL_HINTS (lead detects workflow, passes domain skills) |
| **Research** | Lead does research inline | Full tiered research chain with checkpoints + persistence |
| **Conflict resolution** | Router decides | **Agents debate**, lead arbitrates with evidence |
| **Communication** | Hub-spoke (router relays) | **Peer-to-peer mesh** (agents message each other directly) |

**The fundamental shift:** CC10x = one brain orchestrating one agent at a time. CC100x = one coordinator managing a team of specialists who challenge each other.

---

## Memory Persistence

CC100x survives context compaction:

```
.claude/cc100x/
├── activeContext.md   # Current focus, decisions, learnings
├── patterns.md        # Project conventions, common gotchas
└── progress.md        # Completed work, verification evidence
```

**Iron Law:** Every workflow loads memory at START and persists at END (lead-owned Memory Update task by default).

---

## Quality Validation Harness (Phase D)

CC100x includes reproducible benchmark scaffolding for production change-control gates.

```bash
# Run static protocol checks
npm run check:cc100x

# Create a benchmark run scaffold
npm run eval:run -- --candidate cc100x --profile deterministic

# Score a filled run scaffold
npm run eval:score -- --run-dir artifacts/eval/<run-id>/deterministic
```

Generated benchmark artifacts:
- `artifacts/eval/<run-id>/<profile>/summary-input.json`
- `artifacts/eval/<run-id>/<profile>/case-results.jsonl`
- `artifacts/eval/<run-id>/<profile>/summary.json`
- `artifacts/eval/<run-id>/<profile>/scorecard.json`

---

## Installation

### Step 1: Install Plugin

```bash
/plugin marketplace add romiluz13/cc100x-experiment-next-version-of-cc10x
/plugin install cc100x@romiluz13
```

`/plugin install` uses the plugin package name (`name` in `plugin.json`), not the repository slug.

### Step 2: Enable Agent Teams

Add to `~/.claude/settings.json`:
```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

### Step 3: Activate

Copy this README, paste it into Claude Code, and say: **"Set up cc100x for me"**

### Step 4: Restart Claude Code

---

## For Claude Code: Setup Instructions

**When user says "set up cc100x", "install cc100x", or similar:**

### Step 1: Check Existing Files
- Read `~/.claude/CLAUDE.md` (may not exist)
- Read `~/.claude/settings.json` (may not exist)

### Step 2: Update `~/.claude/CLAUDE.md`

**If file doesn't exist:** CREATE with the template below.
**If file exists:** PREPEND the cc100x section below, keep user's existing content.

```markdown
# CC100x Orchestration (Always On)

IMPORTANT: For ANY development task, route through cc100x-lead before making code changes.
IMPORTANT: Read-only exploration is allowed, but invoke the lead before Edit/Write/code-changing Bash.
IMPORTANT: Never bypass the lead. It is the system.
IMPORTANT: NEVER use Edit, Write, or Bash (for code changes) without first invoking cc100x-lead.

**Skip CC100x ONLY when:**
- User EXPLICITLY says "don't use cc100x", "without cc100x", or "skip cc100x"
- No interpretation. No guessing. Only these exact opt-out phrases.

[CC100x]|entry: cc100x:cc100x-lead
```

### Step 3: Update `~/.claude/settings.json`

Ensure Agent Teams is enabled:
```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

Add permissions:
```json
"Bash(mkdir -p .claude/cc100x)",
"Bash(mkdir -p docs/plans)",
"Bash(mkdir -p docs/research)",
"Bash(git status)",
"Bash(git diff:*)",
"Bash(git log:*)",
"Bash(git branch:*)"
```

### Step 4: Confirm
> "cc100x is set up! Please restart Claude Code to activate."

---

## Architecture

```
USER REQUEST
     │
     ▼
┌─────────────────────────────────────────────────────────────┐
│              cc100x-lead (TEAM COORDINATOR)                   │
│         Detects intent → Creates Agent Team → Delegates       │
└─────────────────────────────────────────────────────────────┘
     │
     ├── BUILD ──► [builder ◄──► live-reviewer] ──► hunter ──► [security ∥ performance ∥ quality] ──► challenge ──► verifier
     │
     ├── DEBUG ──► [investigator-1 ... investigator-N] ──► debate ──► fix ──► [security ∥ performance ∥ quality] ──► challenge ──► verifier
     │
     ├── REVIEW ─► [security ∥ performance ∥ quality] ──► challenge round ──► consensus
     │
     └── PLAN ───► planner

MEMORY (.claude/cc100x/)
├── activeContext.md  ◄── Current focus, decisions, learnings
├── patterns.md       ◄── Project conventions, common gotchas
└── progress.md       ◄── Completed work, remaining tasks
```

---

## File Structure

```
plugins/cc100x/
├── .claude-plugin/
│   └── plugin.json
├── CLAUDE.md
├── agents/
│   ├── security-reviewer.md
│   ├── performance-reviewer.md
│   ├── quality-reviewer.md
│   ├── builder.md
│   ├── live-reviewer.md
│   ├── hunter.md
│   ├── verifier.md
│   ├── investigator.md
│   └── planner.md
└── skills/
    ├── cc100x-lead/SKILL.md
    ├── review-arena/SKILL.md
    ├── bug-court/SKILL.md
    ├── pair-build/SKILL.md
    ├── session-memory/SKILL.md
    ├── verification/SKILL.md
    ├── router-contract/SKILL.md
    └── github-research/SKILL.md
```

---

## Router Contract

Every agent outputs a machine-readable YAML block:

```yaml
STATUS: PASS | FAIL | APPROVE | CHANGES_REQUESTED | ...
CONFIDENCE: [0-100]
CRITICAL_ISSUES: [count]
BLOCKING: [true|false]
REQUIRES_REMEDIATION: [true|false]
MEMORY_NOTES:
  learnings: ["insight"]
  patterns: ["gotcha"]
  verification: ["evidence"]
```

The lead uses these contracts to:
- Validate agent output
- Decide whether to proceed or block
- Resolve conflicts between agents
- Persist memory notes

---

## Safety

For safe modification of CC100x orchestration, use the companion safety skill:

```
/cc100x-orchestration-safety
```

This enforces extreme caution when editing lead, agents, or workflow skills. Available as a user-level skill at `~/.claude/skills/cc100x-orchestration-safety/SKILL.md`.

---

## Evolved From CC10x

CC100x evolves from [CC10x](https://github.com/romiluz13/cc10x) (250+ commits, 12 skills, 6 agents). Everything that worked in CC10x is preserved:

- All 8 orchestration invariants
- Memory protocol (load-first, edit-verify, stable anchors)
- Router Contract format (YAML machine-readable output)
- TDD enforcement (Red-Green-Refactor)
- Research persistence (docs/research/ + memory links)
- Verification gates (evidence before claims)

What's new is the **Agent Teams architecture** that enables parallel work, peer debate, and adversarial review.

---

## License

MIT License

---

<p align="center">
  <strong>cc100x v0.1.6</strong><br>
  <em>Next-Gen Orchestration on Agent Teams</em>
</p>
