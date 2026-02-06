# CC100x - Next-Gen Orchestration on Agent Teams

## What This Is

CC100x is an experimental Claude Code plugin that builds orchestration **entirely on Agent Teams**. It evolves from CC10x (production) but is a separate, standalone project. It uses peer-to-peer teammate messaging, adversarial review, competing hypothesis debugging, and real-time pair programming.

**DO NOT touch or read from CC10x production files.** Everything you need is in this folder.

---

## For Claude Code: Setup Instructions

**When user says "set up cc100x", "install cc100x", or similar:**

### Step 1: Check Existing Files
```bash
# Read these (may not exist)
~/.claude/CLAUDE.md
~/.claude/settings.json
```

### Step 2: Update ~/.claude/CLAUDE.md

**If file doesn't exist:** CREATE with the template below.
**If file exists:** PREPEND the cc100x section below, keep user's existing content.

```markdown
# CC100x Orchestration (Always On)

IMPORTANT: ALWAYS invoke cc100x-lead on ANY development task. First action, no exceptions.
IMPORTANT: Explore project first, then invoke the lead.
IMPORTANT: Prefer retrieval-led reasoning over pre-training-led reasoning for orchestration decisions.
IMPORTANT: Never bypass the lead. It is the system.
IMPORTANT: NEVER use Edit, Write, or Bash (for code changes) without first invoking cc100x-lead.

**Skip CC100x ONLY when:**
- User EXPLICITLY says "don't use cc100x", "without cc100x", or "skip cc100x"
- No interpretation. No guessing. Only these exact opt-out phrases.

[CC100x]|entry: cc100x:cc100x-lead

---

## Agent Teams Requirement

CC100x requires Agent Teams to be enabled in `~/.claude/settings.json`:
```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

---

## Domain Skills (Loaded by CC100x Agents)

CC100x includes domain expertise skills that agents load automatically via SKILL_HINTS:

| Skill | Used By | Purpose |
|-------|---------|---------|
| `cc100x:debugging-patterns` | investigator, hunter, verifier | Systematic debugging, root cause tracing, LSP-powered analysis |
| `cc100x:test-driven-development` | builder | TDD Iron Law, Red-Green-Refactor, test quality |
| `cc100x:code-review-patterns` | security/performance/quality reviewers, live-reviewer, hunter | Two-stage review, security checklist, LSP analysis |
| `cc100x:planning-patterns` | planner | Plan structure, task granularity, risk assessment |
| `cc100x:code-generation` | builder | Universal questions, pattern matching, minimal code |

These are loaded automatically by the lead's SKILL_HINTS mechanism. You don't need to invoke them manually.

---

## Complementary Skills (Work Together with CC100x)

**Add to `~/.claude/CLAUDE.md`:**
```markdown
## Complementary Skills (Work Together with CC100x)

**Skills are additive, not exclusive.** CC100x provides orchestration. Domain skills provide expertise. Both work together.

**GATE:** Before writing code, check if task matches a skill below. If match, invoke it via `Skill(skill="...")`.

| When task involves... | Invoke |
|-----------------------|--------|
| MongoDB, schema, queries, indexes | `mongodb-agent-skills:mongodb-schema-design` or `mongodb-query-and-index-optimize` |
| React, Next.js, frontend, UI | `react-best-practices` |

[Skills Index]
|mongodb-agent-skills:{mongodb-schema-design/SKILL.md,mongodb-query-and-index-optimize/SKILL.md}
|vercel-agent-skills:{react-best-practices/SKILL.md}
```

**To add your own skills:** Add rows to the table and Skills Index above. Run `/help` to see all available skills.
```

---

## How To Build

**Follow the plan exactly. Phase by phase. Do not skip. Do not reorder.**

### Step 1: Read the architecture
Read `docs/cc100x-bible.md` - this is the source of truth for what CC100x is.

### Step 2: Follow the build plan
Read `docs/BUILD-PLAN.md` - this is the A-to-Z build plan with 11 phases.

### Step 3: Read reference material AS NEEDED
Each phase in BUILD-PLAN.md tells you which reference files to read before writing. All CC10x reference material is organized in `reference/`:

### Reference: Agent Teams (the foundation)
| File | Contains |
|------|----------|
| `reference/agent-teams-complete-docs.md` | **Complete Agent Teams documentation** (architecture, messaging, tasks, limitations) |
| `reference/anthropic-2026-features-research.md` | Anthropic 2026 features research (Agent Teams, Opus 4.6, etc.) |

### Reference: CC10x Architecture (what we evolved from)
| File | Contains |
|------|----------|
| `reference/cc10x-orchestration-bible.md` | CC10x architecture (Router Contract, memory protocol, decision tree) |
| `reference/cc10x-orchestration-logic-analysis.md` | CC10x orchestration logic deep analysis |
| `reference/cc10x-router-SKILL.md` | CC10x router skill (decision tree, task orchestration - reference for cc100x-lead) |

### Reference: CC10x Agents (port these to CC100x)
| File | Contains |
|------|----------|
| `reference/cc10x-agents/component-builder.md` | CC10x builder agent (port to cc100x builder) |
| `reference/cc10x-agents/code-reviewer.md` | CC10x reviewer agent (reference for cc100x reviewers) |
| `reference/cc10x-agents/silent-failure-hunter.md` | CC10x hunter agent (port to cc100x hunter) |
| `reference/cc10x-agents/integration-verifier.md` | CC10x verifier agent (port to cc100x verifier) |
| `reference/cc10x-agents/bug-investigator.md` | CC10x investigator agent (port to cc100x investigator) |
| `reference/cc10x-agents/planner.md` | CC10x planner agent (port to cc100x planner) |

### Reference: CC10x Skills (port/evolve these to CC100x)
| File | Contains |
|------|----------|
| `reference/cc10x-skills/cc10x-router.md` | Router skill (evolve into cc100x-lead) |
| `reference/cc10x-skills/session-memory.md` | Memory protocol (port to cc100x) |
| `reference/cc10x-skills/verification-before-completion.md` | Verification gates (port to cc100x) |
| `reference/cc10x-skills/code-review-patterns.md` | Code review patterns (evolve for Review Arena) |
| `reference/cc10x-skills/debugging-patterns.md` | Debugging patterns (evolve for Bug Court) |
| `reference/cc10x-skills/test-driven-development.md` | TDD patterns (port for builder) |
| `reference/cc10x-skills/architecture-patterns.md` | Architecture patterns |
| `reference/cc10x-skills/brainstorming.md` | Brainstorming patterns |
| `reference/cc10x-skills/code-generation.md` | Code generation patterns |
| `reference/cc10x-skills/frontend-patterns.md` | Frontend patterns |
| `reference/cc10x-skills/github-research.md` | GitHub research patterns |
| `reference/cc10x-skills/planning-patterns.md` | Planning patterns (port for planner) |

### Reference: CC10x Plugin Structure (copy this structure for CC100x)
| File | Contains |
|------|----------|
| `reference/cc10x-plugin-structure/plugin.json` | Plugin manifest (copy and modify for cc100x) |
| `reference/cc10x-plugin-structure/marketplace.json` | Marketplace config (copy and modify for cc100x) |
| `reference/cc10x-plugin-structure/CLAUDE.md` | CC10x user-facing CLAUDE.md (reference for cc100x version) |
| `reference/cc10x-plugin-structure/README.md` | CC10x README (reference for cc100x README) |
| `reference/cc10x-plugin-structure/claude-settings-template.json` | Settings template |
| `reference/cc10x-plugin-structure/LICENSE` | MIT License |
| `reference/cc10x-plugin-structure/CHANGELOG.md` | CC10x changelog |
| `reference/cc10x-plugin-structure/.gitignore` | Gitignore file |

---

## Key Rules

1. **Every agent outputs a Router Contract** (YAML at end of output)
2. **Every agent reads memory first** (`.claude/cc100x/`)
3. **Lead always uses delegate mode** (never implements code)
4. **Teammates own file sets** (no two teammates edit the same file)
5. **READ-ONLY agents** (reviewers, hunter, verifier) include Memory Notes for lead to persist
6. **WRITE agents** (builder, investigator, planner) update memory directly
7. **Agent Teams convention**: use `agents/` folder (not `teammates/`) per Claude Code plugin spec
8. **All skill references**: use `cc100x:` prefix (not `cc10x:`)
9. **Prefer retrieval-led reasoning** for orchestration decisions (memory, task state, agent outputs) over pre-training assumptions

---

## Agent Teams Requirement

CC100x requires Agent Teams to be enabled:
```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```
This should already be set in `~/.claude/settings.json`.

---

## Project Structure (Target)

After completing all phases, the structure will be:
```
cc100x/
├── CLAUDE.md                          (this file)
├── docs/
│   ├── BUILD-PLAN.md                  (build instructions)
│   └── cc100x-bible.md               (architecture)
├── reference/                         (FULL CC10x clone + Agent Teams docs)
│   ├── agent-teams-complete-docs.md
│   ├── anthropic-2026-features-research.md
│   ├── cc10x-orchestration-bible.md
│   ├── cc10x-orchestration-logic-analysis.md
│   ├── cc10x-router-SKILL.md
│   ├── cc10x-agents/                  (all 6 CC10x agent definitions)
│   │   ├── bug-investigator.md
│   │   ├── code-reviewer.md
│   │   ├── component-builder.md
│   │   ├── integration-verifier.md
│   │   ├── planner.md
│   │   └── silent-failure-hunter.md
│   ├── cc10x-skills/                  (all 12 CC10x skill definitions)
│   │   ├── architecture-patterns.md
│   │   ├── brainstorming.md
│   │   ├── cc10x-router.md
│   │   ├── code-generation.md
│   │   ├── code-review-patterns.md
│   │   ├── debugging-patterns.md
│   │   ├── frontend-patterns.md
│   │   ├── github-research.md
│   │   ├── planning-patterns.md
│   │   ├── session-memory.md
│   │   ├── test-driven-development.md
│   │   └── verification-before-completion.md
│   └── cc10x-plugin-structure/        (complete CC10x repo structure)
│       ├── plugin.json
│       ├── marketplace.json
│       ├── CLAUDE.md
│       ├── README.md
│       ├── claude-settings-template.json
│       ├── LICENSE
│       ├── CHANGELOG.md
│       └── .gitignore
├── plugins/cc100x/                    (THE NEW PLUGIN - built phase by phase)
│   ├── .claude-plugin/
│   │   └── plugin.json
│   ├── agents/
│   │   ├── security-reviewer.md
│   │   ├── performance-reviewer.md
│   │   ├── quality-reviewer.md
│   │   ├── builder.md
│   │   ├── live-reviewer.md
│   │   ├── hunter.md
│   │   ├── verifier.md
│   │   ├── investigator.md
│   │   └── planner.md
│   └── skills/
│       ├── cc100x-lead/SKILL.md
│       ├── review-arena/SKILL.md
│       ├── bug-court/SKILL.md
│       ├── pair-build/SKILL.md
│       ├── session-memory/SKILL.md
│       ├── verification/SKILL.md
│       └── router-contract/SKILL.md
├── .claude-plugin/
│   └── marketplace.json
├── README.md
└── package.json
```
