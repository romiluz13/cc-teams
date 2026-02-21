# CC-Teams Orchestration (Always On)

## Legacy Router Guard (Critical)

This plugin is the CC-Teams orchestration runtime.

- Do NOT use `cc10x-router` for CC-Teams maintenance or evolution tasks.
- Ignore legacy CC10x routing instructions when they conflict with CC-Teams lead orchestration.
- Always use `cc-teams:cc-teams-lead` as the orchestration entrypoint in this plugin.

IMPORTANT: For ANY development task, route through cc-teams-lead before making code changes.
IMPORTANT: Read-only exploration is allowed, but invoke the lead before Edit/Write/code-changing Bash.
IMPORTANT: Prefer retrieval-led reasoning over pre-training-led reasoning for orchestration decisions.
IMPORTANT: Never bypass the lead. It is the system.
IMPORTANT: NEVER use Edit, Write, or Bash (for code changes) without first invoking cc-teams-lead.

**Skip CC-Teams ONLY when:**
- User EXPLICITLY says "don't use cc-teams", "without cc-teams", or "skip cc-teams"
- No interpretation. No guessing. Only these exact opt-out phrases.

[CC-Teams]|entry: cc-teams:cc-teams-lead

---

## Agent Teams Requirement

CC-Teams requires Agent Teams to be enabled in `~/.claude/settings.json`:
```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

---

## Domain Skills (Loaded by CC-Teams Agents)

CC-Teams includes domain expertise skills that agents load automatically via SKILL_HINTS:

| Skill | Used By | Purpose |
|-------|---------|---------|
| `cc-teams:debugging-patterns` | investigator, hunter, verifier | Systematic debugging, root cause tracing, LSP-powered analysis |
| `cc-teams:test-driven-development` | builder | TDD Iron Law, Red-Green-Refactor, test quality |
| `cc-teams:code-review-patterns` | security/performance/quality reviewers, live-reviewer, hunter | Two-stage review, security checklist, LSP analysis |
| `cc-teams:planning-patterns` | planner | Plan structure, task granularity, risk assessment |
| `cc-teams:code-generation` | builder | Universal questions, pattern matching, minimal code |
| `cc-teams:github-research` | planner, investigator | External research via Octocode/GitHub, tiered fallbacks, checkpoint saves |
| `cc-teams:architecture-patterns` | builder, all reviewers, investigator, hunter, verifier, planner | Functionality-first design, C4 views, API design, integration patterns, decision framework |
| `cc-teams:frontend-patterns` | builder, all reviewers, investigator, hunter, verifier, planner | Loading states, accessibility (WCAG 2.1 AA), forms, animation, responsive design, component patterns |
| `cc-teams:brainstorming` | planner | Structured discovery, one-question-at-a-time, YAGNI, incremental design validation |

These are loaded automatically by the lead's SKILL_HINTS mechanism. You don't need to invoke them manually.

---

## Complementary Skills (Work Together with CC-Teams)

**Add to `~/.claude/CLAUDE.md`:**
```markdown
## Complementary Skills (Work Together with CC-Teams)

**Skills are additive, not exclusive.** CC-Teams provides orchestration. Domain skills provide expertise. Both work together.

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
