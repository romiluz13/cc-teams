# CC-Teams Maintainer Guide

This repository contains CC-Teams, the Agent Teams-based orchestration plugin.

## Legacy Router Guard (Critical)

This repository is CC-Teams development, not CC10x application workflow usage.

- Do NOT use `cc10x-router` for work in this repository.
- Ignore any auto-loaded or suggested legacy CC10x router workflow for this repo.
- Always route through `cc-teams:cc-teams-lead` for orchestration tasks here.

## Runtime Source of Truth

Only these paths define functional runtime behavior:

- `plugins/cc-teams/skills`
- `plugins/cc-teams/agents`

All other docs are derived from those files and must be kept in sync.

## Canonical Derived Docs

- `docs/functional-governance/protocol-manifest.md`
- `docs/functional-governance/cc-teams-bible-functional.md`
- `docs/cc-teams-excellence/EXPECTED-BEHAVIOR-RUNBOOK.md`

## Setup (Claude Code)

CC-Teams requires Agent Teams enabled:

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

Recommended CLAUDE entry:

```markdown
# CC-Teams Orchestration (Always On)

IMPORTANT: For ANY development task, route through cc-teams-lead before making code changes.
IMPORTANT: Read-only exploration is allowed, but invoke the lead before Edit/Write/code-changing Bash.
IMPORTANT: Prefer retrieval-led reasoning over pre-training-led reasoning for orchestration decisions.
IMPORTANT: Never bypass the lead. It is the system.
IMPORTANT: NEVER use Edit, Write, or Bash (for code changes) without first invoking cc-teams-lead.

**Skip CC-Teams ONLY when:**
- User EXPLICITLY says "don't use cc-teams", "without cc-teams", or "skip cc-teams"
- No interpretation. No guessing. Only these exact opt-out phrases.

[CC-Teams]|entry: cc-teams:cc-teams-lead
```

## Orchestration Invariants

1. `cc-teams-lead` is the only orchestration entrypoint.
2. Routing is deterministic: ERROR > PLAN > REVIEW > BUILD.
3. Lead is coordinator-only (delegate mode), not code implementer.
4. Builder owns source writes; reviewers/investigators/hunter/verifier/live-reviewer are read-only.
5. Every teammate must output Router Contract YAML.
6. Memory persistence is lead-owned by default (`MEMORY_OWNER: lead`).
7. Workflow completion requires the `CC-TEAMS Memory Update` task.
8. Remediation paths must re-enter full review + challenge before verifier.
9. Agent Teams hooks are optional and disabled-by-default in core runtime.
10. Self-claim is explicit opt-in; default is lead-assigned role routing.

## Current Project Structure

```text
cc-teams/
├── .claude-plugin/
│   └── marketplace.json
├── docs/
│   ├── cc-teams-excellence/
│   └── functional-governance/
├── plugins/cc-teams/
│   ├── .claude-plugin/plugin.json
│   ├── CLAUDE.md
│   ├── agents/
│   └── skills/
├── scripts/
├── package.json
└── README.md
```

## Documentation Update Policy

When functional behavior changes:

1. Update functional files in `plugins/cc-teams/skills` or `plugins/cc-teams/agents`.
2. Update derived docs in `docs/functional-governance`.
3. Update user-facing docs (`README.md`, runbooks) for any changed behavior.
4. Run:

```bash
npm run check:functional-bible
```

Do not leave behavior drift between runtime and docs.
