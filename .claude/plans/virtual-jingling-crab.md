# CC-Teams v0.1.18 — The Complete Upgrade: Parallel Architecture, Specialist Reviewers, Cross-Layer BUILD

## Context

Three categories of improvements to make CC-Teams the most capable AI coding harness on Claude Code:

1. **Missing specialist reviewers** — accessibility and API contract gaps that every production codebase needs
2. **Underutilized parallelism** — pre-spawn optimization + cross-layer BUILD variant that runs frontend/backend builders in true parallel
3. **Underutilized Claude Code features** — `memory` frontmatter for persistent agent intelligence, `isolation: worktree` on planner

All changes follow existing patterns (clone from security-reviewer template for reviewers, builder template for new builders), are lint-compatible, and maintain backward compatibility — existing BUILD/DEBUG/REVIEW/PLAN workflows are unchanged.

---

## Batch 1: New Specialist Reviewer Agents

### 1a. `plugins/cc-teams/agents/accessibility-reviewer.md` (CREATE)

**Trigger:** Spawned conditionally when builder's FILES_MODIFIED contains UI files (`.tsx`, `.jsx`, `.html`, `.css`, `.vue`) or requirements mention accessibility/WCAG/a11y.

```yaml
---
name: accessibility-reviewer
description: "Accessibility (WCAG 2.1 AA) specialist reviewer for Review Arena — spawned when UI changes are detected"
model: inherit
color: purple
context: fork
tools: Read, Grep, Glob, Skill, LSP, SendMessage
skills: cc-teams:router-contract, cc-teams:verification
---
```

**Body follows security-reviewer structure with these domain sections:**

- **WCAG 2.1 AA Checklist:** Perceivable (alt text, captions, color contrast ≥4.5:1), Operable (keyboard nav, focus management, skip links), Understandable (labels, error messages), Robust (ARIA, semantic HTML)
- **Quick Scan Patterns:**
  ```
  Grep(pattern="onClick=|onKeyDown=|tabIndex=", path="src")
  Grep(pattern="aria-label|role=|alt=", path="src")
  Grep(pattern="dangerouslySetInnerHTML", path="src")
  ```
- **Accessibility Checklist (10-point):**
  - [ ] All interactive elements keyboard-reachable
  - [ ] Focus order logical and visible
  - [ ] Images have descriptive alt text (not `alt=""` for informational images)
  - [ ] Form inputs have associated `<label>` elements
  - [ ] Error messages reference the field by name
  - [ ] Color alone not used to convey information
  - [ ] ARIA roles match element semantics (no `role="button"` on `<div>` without keyboard handler)
  - [ ] Headings are hierarchical (`h1`→`h2`→`h3`, no skips)
  - [ ] Screen reader announcements for dynamic content (`aria-live`, `aria-atomic`)
  - [ ] Touch targets ≥44×44px (WCAG 2.5.5)
- **Challenge Round Response** (same mandatory pattern as other reviewers)
- **One-response discipline** (from v0.1.17)
- **Router Contract** with `DEPENDENCY_AUDIT: SKIPPED` (no npm audit for a11y) and standard fields
- `CONTRACT_VERSION: "2.4"`

---

### 1b. `plugins/cc-teams/agents/api-contract-reviewer.md` (CREATE)

**Trigger:** Spawned conditionally when builder's FILES_MODIFIED contains API route files (`routes/`, `api/`, `endpoints/`, `handlers/`, `controllers/`) or TypeScript interface files that define request/response shapes.

```yaml
---
name: api-contract-reviewer
description: "API contract validator — detects breaking changes in routes, request/response schemas, and type exports"
model: inherit
color: orange
context: fork
tools: Read, Grep, Glob, Skill, LSP, SendMessage
skills: cc-teams:router-contract, cc-teams:verification
---
```

**Body follows security-reviewer structure with these domain sections:**

- **API Contract Checklist (9-point):**
  - [ ] No endpoints removed (existing routes still exist)
  - [ ] No required request fields removed or renamed
  - [ ] No response fields removed that clients may depend on
  - [ ] No response field types widened to null/undefined without versioning
  - [ ] HTTP method unchanged for existing routes
  - [ ] Status codes unchanged for success/error responses
  - [ ] Pagination/cursor shape unchanged
  - [ ] Authentication requirements unchanged (no route suddenly requires new scopes)
  - [ ] Rate limit headers unchanged (if present)
- **Quick Scan Patterns:**
  ```
  Glob(pattern="**/{routes,api,endpoints,handlers}/**/*.{ts,js}", path=".")
  Grep(pattern="export (type|interface).*(Request|Response|Schema|Params|Body)", path="src")
  Grep(pattern="router\.(get|post|put|delete|patch)\(", path="src")
  ```
- **Breaking Change Classification:**
  - CRITICAL (BLOCKING): Removed endpoint, removed required field, changed type to incompatible type
  - HIGH: Changed optional to required, removed response field, changed status code
  - MEDIUM: Added new optional response field (non-breaking but document), changed error message wording
- **Router Contract** with standard fields, `CONTRACT_VERSION: "2.4"`

---

### 1c. Update Routing for Conditional Reviewers

**File:** `plugins/cc-teams/skills/cc-teams-lead/SKILL.md`

**Change 1 — Phase-Scoped Teammate Activation (MANDATORY), BUILD section:**

Add conditional spawn rules after standard reviewer spawn:
```markdown
- When review tasks become runnable: spawn `security-reviewer`, `performance-reviewer`, `quality-reviewer`
  - **Conditionally also spawn:**
    - `accessibility-reviewer` if FILES_MODIFIED (from builder contract) contains `.tsx|.jsx|.html|.css|.vue` files
    - `api-contract-reviewer` if FILES_MODIFIED contains files in `routes/|api/|endpoints/|handlers/|controllers/` paths
  - Lead detects signal from builder Router Contract `FILES_MODIFIED` field before spawning
```

**Change 2 — Workflow Structural Integrity Guard, BUILD required task subjects:**

Add (conditional):
```markdown
- `CC-TEAMS accessibility-reviewer:` (if UI signals detected)
- `CC-TEAMS api-contract-reviewer:` (if API signals detected)
```

**Change 3 — BUILD Task Templates table:**

Add rows (conditional, with note):
```
| 8a | `CC-TEAMS accessibility-reviewer: Accessibility review` | hunter | CONDITIONAL (UI files). WCAG 2.1 AA audit. |
| 8b | `CC-TEAMS api-contract-reviewer: API contract review` | hunter | CONDITIONAL (API files). Breaking change detection. |
| 9  | `CC-TEAMS BUILD Review Arena: Challenge round` | sec, perf, qual [+a11y if present] [+api-contract if present] | Share findings, resolve conflicts. |
```

**Change 4 — Review Arena and Debug workflows:**

Add same conditional reviewers to REVIEW task template (rows 5a, 5b) and DEBUG Review Arena.

**Change 5 — Per-Agent Spawn Context section:**

Add `accessibility-reviewer` and `api-contract-reviewer` to the reviewer triad section (they share the same spawn context fields).

**Change 6 — Challenge completion criteria in Results Collection:**

Change "All 3 reviewers acknowledged" to "All active reviewers acknowledged (3–5 depending on signals detected)."

**File:** `plugins/cc-teams/skills/review-arena/SKILL.md`

Update Team Composition table to note conditional reviewers:
```markdown
| **accessibility-reviewer** | A11y specialist (conditional) | WCAG 2.1 AA, keyboard nav, ARIA, semantic HTML | READ-ONLY |
| **api-contract-reviewer** | Contract validator (conditional) | Breaking changes, route/schema diffs, type compatibility | READ-ONLY |
```

Add to Conflict Resolution Rules:
```markdown
| A11y says CRITICAL, others disagree | **A11y wins for compliance-critical projects** (WCAG is regulatory in many sectors) |
| API contract says CRITICAL, others disagree | **API contract wins** (breaking changes affect external clients) |
```

**File:** `plugins/cc-teams/skills/pair-build/SKILL.md`

Update Phase 3 section:
```markdown
3. Spawn `security-reviewer`, `performance-reviewer`, `quality-reviewer` in parallel
   + `accessibility-reviewer` if UI files detected in builder's FILES_MODIFIED
   + `api-contract-reviewer` if API route files detected in builder's FILES_MODIFIED
```

---

## Batch 2: Pre-Spawn Optimization

**The fix:** Spawn downstream agents when their PREDECESSOR starts (not when their predecessor finishes), using blocked tasks. Agent is in the team and context-loaded but has no task to run until its blocker clears. Eliminates 1-2 turn spawn overhead per phase.

**File:** `plugins/cc-teams/skills/cc-teams-lead/SKILL.md`

**Change — Phase-Scoped Teammate Activation, BUILD section:**

Replace:
```markdown
- Team create: `builder`, `live-reviewer`
- When hunter task becomes runnable: spawn `hunter`
- When review tasks become runnable: spawn `security-reviewer`, `performance-reviewer`, `quality-reviewer`
- When verifier task becomes runnable: spawn `verifier`
```

With:
```markdown
- Team create: `builder`, `live-reviewer`
- When builder task starts: **also pre-spawn `hunter`** (queued blocked by builder task — ready to execute the instant builder finishes)
- When hunter task starts: **also pre-spawn `security-reviewer`, `performance-reviewer`, `quality-reviewer`** (+ conditional reviewers if signals detected) queued blocked by hunter — ready immediately when hunter completes
- When review tasks start: **also pre-spawn `verifier`** queued blocked by challenge round — ready immediately when challenge completes
- Rationale: eliminates spawn latency between phases; blocked agents are idle (no output, no cost) until unblocked
```

**Same change for DEBUG workflow:**
- Pre-spawn builder when investigator tasks start
- Pre-spawn reviewers when builder-fix task starts
- Pre-spawn verifier when review tasks start

---

## Batch 3: Cross-Layer BUILD Variant

### 3a. New Agents

**`plugins/cc-teams/agents/frontend-builder.md` (CREATE)**

Same structure as `builder.md` with these differences:
- `name: frontend-builder`
- `description: "Implements frontend features using TDD — owns UI components, pages, and styles"`
- `color: cyan`
- `isolation: worktree` (same as builder)
- SCOPE guidance: "owns `src/components/`, `src/pages/`, `src/styles/`, `src/hooks/` — no API route edits"
- SKILL_HINTS: always includes `cc-teams:frontend-patterns`
- Cross-layer coordination: after completing, outputs API contract requirements to lead if backend integration needed
- Everything else identical to builder.md

**`plugins/cc-teams/agents/backend-builder.md` (CREATE)**

Same structure as `builder.md` with these differences:
- `name: backend-builder`
- `description: "Implements backend features using TDD — owns API routes, services, and data models"`
- `color: green` (different shade)
- `isolation: worktree` (same as builder)
- SCOPE guidance: "owns `src/api/`, `src/services/`, `src/models/`, `src/db/` — no UI component edits"
- SKILL_HINTS: always includes `cc-teams:architecture-patterns`
- Cross-layer coordination: after completing API routes, outputs contract spec for frontend-builder
- Everything else identical to builder.md

### 3b. New Skill: `plugins/cc-teams/skills/cross-layer-build/SKILL.md` (CREATE)

Protocol for running two builders in parallel with contract relay.

**Key sections:**
- **Overview:** When feature spans frontend + backend. Two builders own distinct file sets. One shared post-build review chain.
- **Detection Signals:** Requirements mention "frontend AND backend", plan covers both UI and API files, user explicitly requests cross-layer
- **Team Composition:**

| Teammate | Phase | File Scope | Mode |
|---------|-------|------------|------|
| `backend-builder` | Phase 1a | `src/api/`, `src/services/`, `src/models/` | READ+WRITE |
| `frontend-builder` | Phase 1b (starts after contract relay) | `src/components/`, `src/pages/`, `src/hooks/` | READ+WRITE |
| `live-reviewer` | Phase 1 (reviews BOTH builders' output post-completion) | all modified files | READ-ONLY |
| `hunter` | Phase 2 | all modified files | READ-ONLY |
| reviewers (3–5) | Phase 3 | all modified files | READ-ONLY |
| `verifier` | Phase 4 | integration E2E | READ-ONLY |

- **Contract-First Relay Phase (MANDATORY for cross-layer):**
  1. backend-builder completes its implementation first (owns API contract definition)
  2. backend-builder outputs `API_CONTRACT_SPEC` in its Memory Notes: endpoint paths, request/response shapes, auth requirements
  3. Lead extracts and validates the contract
  4. Lead passes validated contract to frontend-builder spawn prompt
  5. frontend-builder implements against verified contract

- **Live Reviewer (Async mode):** Unlike standard pair-build (per-module review), cross-layer uses async review — live-reviewer reviews ALL changes from BOTH builders AFTER both complete (before hunter). Eliminates per-module blocking that would serialize the parallel builders.

- **File Conflict Gate (MANDATORY):**
  Lead validates builder Router Contracts have no overlapping `FILES_MODIFIED`. If overlap detected → immediate `CC-TEAMS REM-FIX: file scope conflict`.

- **Task Structure:**

| Order | Subject | BlockedBy |
|-------|---------|-----------|
| 1 | `CC-TEAMS BUILD-CROSSLAYER: {feature}` | — |
| 2 | `CC-TEAMS backend-builder: Implement backend` | — |
| 3 | `CC-TEAMS frontend-builder: Implement frontend` | backend-builder (contract relay) |
| 4 | `CC-TEAMS live-reviewer: Async post-build review` | backend-builder + frontend-builder |
| 5 | `CC-TEAMS hunter: Cross-layer silent failure audit` | live-reviewer |
| 6-8 | Reviewer triad + conditional reviewers | hunter |
| 9 | `CC-TEAMS BUILD-CROSSLAYER Review Arena: Challenge round` | all reviewers |
| 10 | `CC-TEAMS verifier: Integrated E2E verification` | challenge |
| 11 | `CC-TEAMS Memory Update: Persist cross-layer learnings` | verifier |

### 3c. Lead Skill Updates for Cross-Layer

**File:** `plugins/cc-teams/skills/cc-teams-lead/SKILL.md`

**Change 1 — Decision Tree:** Add `BUILD-CROSSLAYER` as a BUILD sub-variant detection:

```markdown
### Cross-Layer Detection (within BUILD routing)
After selecting BUILD, check for cross-layer signals before spawning:
- User requirements explicitly mention BOTH frontend (UI/components) AND backend (API/services/DB)
- Plan covers files in BOTH `src/components/` (or pages/) AND `src/api/` (or services/)
- If cross-layer detected → use BUILD-CROSSLAYER task template and cross-layer skill
- Otherwise → use standard BUILD FULL or QUICK
```

**Change 2 — Add BUILD-CROSSLAYER task template** to Workflow Task Templates section.

**Change 3 — Structural Integrity Guard:** Add BUILD-CROSSLAYER required subjects list.

**Change 4 — Workflow Execution, BUILD section:** Add cross-layer decision branch.

---

## Batch 4: Feature Flags

### 4a. `isolation: worktree` on Planner

**File:** `plugins/cc-teams/agents/planner.md`

Change frontmatter:
```yaml
context: fork
isolation: worktree   # ← ADD (WorktreeCreate hook syncs .claude/cc-teams/ memory)
```

### 4b. `memory: project` on Investigator

**File:** `plugins/cc-teams/agents/investigator.md`

Change frontmatter:
```yaml
model: inherit
memory: project       # ← ADD (persistent bug patterns across sessions in this codebase)
```

NOTE: This is ADDITIVE to the manual `.claude/cc-teams/` system. The `memory: project` gives the investigator its own persistent store for codebase-specific bug patterns. It doesn't replace or conflict with workflow memory files.

### 4c. `memory: user` on Security-Reviewer

**File:** `plugins/cc-teams/agents/security-reviewer.md`

Change frontmatter:
```yaml
model: inherit
memory: user          # ← ADD (persistent vulnerability patterns across ALL codebases)
```

Same additive rationale — supplements cross-session security intelligence.

---

## Batch 5: Lint Scripts + Artifact Policy

**File:** `scripts/lint-cc-teams-agent-tools.sh`

**Change 1 — Add new reviewer agents to the reviewer case:**
```bash
# OLD:
live-reviewer|hunter|security-reviewer|performance-reviewer|quality-reviewer)
# NEW:
live-reviewer|hunter|security-reviewer|performance-reviewer|quality-reviewer|accessibility-reviewer|api-contract-reviewer)
```

**Change 2 — Add new builder agents to the builder case:**
```bash
# Add separate case for frontend-builder and backend-builder:
frontend-builder|backend-builder)
  assert_has "$agent" "$tools" "Write"
  assert_has "$agent" "$tools" "Edit"
  assert_has "$agent" "$tools" "Bash"
  ;;
```

**Change 3 — Add new agents to the agent iteration list** (lines 83-93):
```bash
for agent in \
  builder frontend-builder backend-builder \
  planner \
  investigator \
  verifier \
  live-reviewer \
  hunter \
  security-reviewer performance-reviewer quality-reviewer \
  accessibility-reviewer api-contract-reviewer; do
```

**File:** `scripts/lint-cc-teams-artifact-policy.sh`

Add new agents to the artifact/evidence checks:
```bash
# Add to reviewer artifact discipline loop:
for agent in live-reviewer hunter security-reviewer performance-reviewer quality-reviewer accessibility-reviewer api-contract-reviewer; do
  require_pattern "$file" "^## Artifact Discipline" ...
done

# Add frontend-builder/backend-builder to write policy loop:
for agent in builder planner frontend-builder backend-builder; do
  require_pattern "$file" "^## Write Policy" ...
done
```

---

## Batch 6: CHANGELOG + Versions

### `CHANGELOG.md` — Add v0.1.18

```markdown
## [0.1.18] - 2026-02-22

### Added

**Specialist Reviewer Agents (conditional)**
- `accessibility-reviewer`: WCAG 2.1 AA audit agent — 10-point checklist covering keyboard nav, ARIA, color contrast, semantic HTML, screen reader support. Spawned when UI files detected in builder's FILES_MODIFIED.
- `api-contract-reviewer`: API breaking-change detector — 9-point checklist for removed endpoints, schema diffs, type incompatibility, auth/status code changes. Spawned when API route files detected.
- Both integrate into Review Arena challenge round; conflict resolution: a11y and API contract win on CRITICAL (regulatory/client-facing impact)

**Cross-Layer BUILD Workflow**
- `frontend-builder` agent: TDD builder owning frontend scope (components/pages/hooks/styles), with isolation: worktree and frontend-patterns skill hints
- `backend-builder` agent: TDD builder owning backend scope (api/services/models/db), with isolation: worktree and architecture-patterns skill hints
- `cross-layer-build` skill: Protocol for running both builders in parallel with mandatory contract-first relay phase (backend defines API contract, lead validates, frontend implements against it)
- Async live-reviewer mode: reviews all changes from both builders post-completion (vs blocking per-module in standard pair-build)
- File conflict gate: lead validates no FILES_MODIFIED overlap across builders before proceeding

**Pre-Spawn Optimization**
- Downstream agents now pre-spawned when their predecessor STARTS (not when it finishes)
- hunter pre-spawned when builder task starts → hunter executes immediately when builder completes
- review triad pre-spawned when hunter starts → reviewers execute immediately when hunter completes
- verifier pre-spawned when review tasks start → executes immediately when challenge completes
- Eliminates 1-2 turn spawn overhead between each phase

**Persistent Agent Memory**
- `investigator`: `memory: project` — accumulates codebase-specific bug patterns across sessions
- `security-reviewer`: `memory: user` — accumulates vulnerability patterns across ALL codebases
- Both additive to existing .claude/cc-teams/ workflow memory system

**Planner Worktree Isolation**
- `planner`: `isolation: worktree` — plan file writes are now branch-isolated (WorktreeCreate hook syncs memory)
```

---

## Critical Files

| File | Type | Change |
|------|------|--------|
| `plugins/cc-teams/agents/accessibility-reviewer.md` | CREATE | New reviewer agent |
| `plugins/cc-teams/agents/api-contract-reviewer.md` | CREATE | New reviewer agent |
| `plugins/cc-teams/agents/frontend-builder.md` | CREATE | New builder variant |
| `plugins/cc-teams/agents/backend-builder.md` | CREATE | New builder variant |
| `plugins/cc-teams/skills/cross-layer-build/SKILL.md` | CREATE | New workflow skill |
| `plugins/cc-teams/skills/cc-teams-lead/SKILL.md` | EDIT | Pre-spawn; conditional routing; cross-layer detection; BUILD-CROSSLAYER template |
| `plugins/cc-teams/skills/review-arena/SKILL.md` | EDIT | Add 2 conditional reviewers; conflict resolution rules |
| `plugins/cc-teams/skills/pair-build/SKILL.md` | EDIT | Phase 3 conditional spawning |
| `plugins/cc-teams/agents/planner.md` | EDIT | Add `isolation: worktree` |
| `plugins/cc-teams/agents/investigator.md` | EDIT | Add `memory: project` |
| `plugins/cc-teams/agents/security-reviewer.md` | EDIT | Add `memory: user` |
| `scripts/lint-cc-teams-agent-tools.sh` | EDIT | Add new agents to case patterns |
| `scripts/lint-cc-teams-artifact-policy.sh` | EDIT | Add new agents to checks |
| `CHANGELOG.md` | EDIT | v0.1.18 entry |
| `package.json` + `plugin.json` | EDIT | Bump to 0.1.18 |

---

## Verification

1. `npm run check:agent-tools` — must pass for all 13 agents (9 existing + 4 new)
2. `npm run check:artifact-policy` — must pass (new agents added to discipline loops)
3. `npm run check:functional-bible` — must pass (no citation shifts from this batch)
4. Manual: BUILD workflow with UI files → accessibility-reviewer spawned
5. Manual: BUILD workflow with API route files → api-contract-reviewer spawned
6. Manual: BUILD workflow with no UI/API → only standard 3 reviewers
7. Manual: Cross-layer BUILD → both frontend-builder and backend-builder spawn, no FILES_MODIFIED overlap
8. Smoke: `planner.md` probe still runs correctly in worktree mode

## No-Conflict Guarantee

| Risk | Resolution |
|------|-----------|
| Conditional reviewers not spawned when needed | Lead detects FILES_MODIFIED from builder contract — explicit signal, not guesswork |
| memory: project conflicts with .claude/cc-teams/ | Additive (different storage; agent-level vs workflow-level memory) |
| Pre-spawn creates idle agent noise | Blocked tasks = no output, no tool calls; agents wait silently until unblocked |
| Cross-layer builders edit same file | File conflict gate: lead validates FILES_MODIFIED across both contracts before proceeding |
| async live-review in cross-layer loses real-time feedback | Accepted trade-off for true parallel implementation; post-completion review still catches issues before hunter |
