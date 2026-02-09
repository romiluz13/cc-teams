# Functional Sources Of Truth

Date: 2026-02-09
Owner: Codex (deep parity audit)
Scope: CC10x -> CC100x migration parity, with Agent Teams constraints

## Trust Policy (Non-Negotiable)

Only functional orchestrator/agent/skill instructions are trusted as truth.
If any architecture/bible/logic doc conflicts with functional files, functional files win.

Priority order:
1. Functional skills and agents
2. Runtime activation files (plugin CLAUDE + plugin manifest)
3. Explanatory docs (context only, not source of truth)

## Primary Functional Baseline (CC10x)

These are treated as the executable behavior baseline for parity checks:

- `reference/cc10x-router-SKILL.md`
- `reference/cc10x-agents/component-builder.md`
- `reference/cc10x-agents/code-reviewer.md`
- `reference/cc10x-agents/silent-failure-hunter.md`
- `reference/cc10x-agents/integration-verifier.md`
- `reference/cc10x-agents/bug-investigator.md`
- `reference/cc10x-agents/planner.md`
- `reference/cc10x-skills/architecture-patterns.md`
- `reference/cc10x-skills/brainstorming.md`
- `reference/cc10x-skills/cc10x-router.md`
- `reference/cc10x-skills/code-generation.md`
- `reference/cc10x-skills/code-review-patterns.md`
- `reference/cc10x-skills/debugging-patterns.md`
- `reference/cc10x-skills/frontend-patterns.md`
- `reference/cc10x-skills/github-research.md`
- `reference/cc10x-skills/planning-patterns.md`
- `reference/cc10x-skills/session-memory.md`
- `reference/cc10x-skills/test-driven-development.md`
- `reference/cc10x-skills/verification-before-completion.md`

## Primary Functional Target (CC100x)

These are treated as the real implementation under audit:

- `plugins/cc100x/skills/cc100x-lead/SKILL.md`
- `plugins/cc100x/skills/review-arena/SKILL.md`
- `plugins/cc100x/skills/bug-court/SKILL.md`
- `plugins/cc100x/skills/pair-build/SKILL.md`
- `plugins/cc100x/skills/session-memory/SKILL.md`
- `plugins/cc100x/skills/verification/SKILL.md`
- `plugins/cc100x/skills/router-contract/SKILL.md`
- `plugins/cc100x/skills/code-review-patterns/SKILL.md`
- `plugins/cc100x/skills/debugging-patterns/SKILL.md`
- `plugins/cc100x/skills/test-driven-development/SKILL.md`
- `plugins/cc100x/skills/code-generation/SKILL.md`
- `plugins/cc100x/skills/planning-patterns/SKILL.md`
- `plugins/cc100x/skills/github-research/SKILL.md`
- `plugins/cc100x/skills/architecture-patterns/SKILL.md`
- `plugins/cc100x/skills/frontend-patterns/SKILL.md`
- `plugins/cc100x/skills/brainstorming/SKILL.md`
- `plugins/cc100x/agents/builder.md`
- `plugins/cc100x/agents/live-reviewer.md`
- `plugins/cc100x/agents/hunter.md`
- `plugins/cc100x/agents/verifier.md`
- `plugins/cc100x/agents/investigator.md`
- `plugins/cc100x/agents/planner.md`
- `plugins/cc100x/agents/security-reviewer.md`
- `plugins/cc100x/agents/performance-reviewer.md`
- `plugins/cc100x/agents/quality-reviewer.md`

## Runtime Activation Files (Secondary Functional Layer)

Used to validate what actually activates and loads in practice:

- `plugins/cc100x/CLAUDE.md`
- `plugins/cc100x/.claude-plugin/plugin.json`
- `.claude-plugin/marketplace.json`

## Context-Only References (Not Source Of Truth)

These may help explain intent but are not trusted over functional files:

- `docs/cc100x-bible.md`
- `docs/cc100x-orchestration-logic-analysis.md`
- `reference/cc10x-orchestration-bible.md`
- `reference/cc10x-orchestration-logic-analysis.md`
- `README.md`
- `CLAUDE.md`
- `docs/BUILD-PLAN.md`
- `docs/audit/*`

## Audit Rule For Conflicts

If any conflict is found:
- Log both statements
- Mark source class (functional vs context-only)
- Resolve in favor of functional files
- Record whether conflict is documentation drift or logic break
