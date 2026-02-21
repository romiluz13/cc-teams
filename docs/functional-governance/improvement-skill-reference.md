# Improvement Skill Reference Contract

This is the operating contract for any future "improvement" workflow that updates CC-Teams orchestration.

## Read Order (Mandatory)

1. `docs/functional-governance/protocol-manifest.md`
2. `docs/functional-governance/cc-teams-bible-functional.md`
3. Functional targets only:
   - `plugins/cc-teams/skills`
   - `plugins/cc-teams/agents`

## Hard Rules

- Do not treat README/docs/reference as runtime truth.
- Do not add bible statements without a functional citation.
- Do not change workflow chains without updating manifest + functional bible together.
- Do not merge if drift check fails.

## Required Validation

Run before commit/PR:

```bash
npm run check:functional-bible
```

## Merge Checklist

- [ ] Functional change implemented in `plugins/cc-teams/skills` or `plugins/cc-teams/agents`
- [ ] `protocol-manifest.md` updated if behavior changed
- [ ] `cc-teams-bible-functional.md` updated with citations
- [ ] Drift check passes
