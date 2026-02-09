# CC100x Maintainer Guide

This repository contains CC100x, the Agent Teams-based orchestration plugin.

## Runtime Source of Truth

Only these paths define functional runtime behavior:

- `plugins/cc100x/skills`
- `plugins/cc100x/agents`

All other docs are derived from those files and must be kept in sync.

## Canonical Derived Docs

- `docs/functional-governance/protocol-manifest.md`
- `docs/functional-governance/cc100x-bible-functional.md`
- `docs/cc100x-excellence/EXPECTED-BEHAVIOR-RUNBOOK.md`

## Setup (Claude Code)

CC100x requires Agent Teams enabled:

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

Recommended CLAUDE entry:

```markdown
# CC100x Orchestration (Always On)

IMPORTANT: For ANY development task, route through cc100x-lead before making code changes.
IMPORTANT: Read-only exploration is allowed, but invoke the lead before Edit/Write/code-changing Bash.
IMPORTANT: Prefer retrieval-led reasoning over pre-training-led reasoning for orchestration decisions.
IMPORTANT: Never bypass the lead. It is the system.
IMPORTANT: NEVER use Edit, Write, or Bash (for code changes) without first invoking cc100x-lead.

**Skip CC100x ONLY when:**
- User EXPLICITLY says "don't use cc100x", "without cc100x", or "skip cc100x"
- No interpretation. No guessing. Only these exact opt-out phrases.

[CC100x]|entry: cc100x:cc100x-lead
```

## Orchestration Invariants

1. `cc100x-lead` is the only orchestration entrypoint.
2. Routing is deterministic: ERROR > PLAN > REVIEW > BUILD.
3. Lead is coordinator-only (delegate mode), not code implementer.
4. Builder owns source writes; reviewers/investigators/hunter/verifier/live-reviewer are read-only.
5. Every teammate must output Router Contract YAML.
6. Memory persistence is lead-owned by default (`MEMORY_OWNER: lead`).
7. Workflow completion requires the `CC100X Memory Update` task.
8. Remediation paths must re-enter full review + challenge before verifier.
9. Agent Teams hooks are optional and disabled-by-default in core runtime.
10. Self-claim is explicit opt-in; default is lead-assigned role routing.

## Current Project Structure

```text
cc100x/
├── .claude-plugin/
│   └── marketplace.json
├── docs/
│   ├── cc100x-excellence/
│   └── functional-governance/
├── plugins/cc100x/
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

1. Update functional files in `plugins/cc100x/skills` or `plugins/cc100x/agents`.
2. Update derived docs in `docs/functional-governance`.
3. Update user-facing docs (`README.md`, runbooks) for any changed behavior.
4. Run:

```bash
npm run check:functional-bible
```

Do not leave behavior drift between runtime and docs.
