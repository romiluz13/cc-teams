---
name: cross-layer-build
description: "Cross-layer parallel BUILD protocol. Two builders own distinct file sets (frontend + backend) and implement in parallel with a mandatory API contract relay phase."
---

# Cross-Layer Build Protocol

## Overview

Cross-Layer Build runs two TDD builders in parallel — `backend-builder` (API/services/models) and `frontend-builder` (components/pages/hooks) — with a mandatory API contract relay phase ensuring the frontend implements against a verified, stable API contract.

**Core principle:** Distinct file ownership + verified contract relay = true parallel implementation without coordination overhead.

**When to use:** Features that require both UI changes AND API/service changes. Not for UI-only or API-only features (use standard BUILD FULL for those).

---

## Detection Signals

Lead applies cross-layer routing when ANY of these are present:

1. User requirements explicitly mention BOTH frontend (UI/components/pages) AND backend (API/services/DB)
2. Plan covers files in BOTH `src/components/` (or pages/) AND `src/api/` (or services/)
3. User explicitly requests "full-stack", "cross-layer", or "frontend and backend" implementation
4. AskUserQuestion confirms: "Will this feature require changes to both UI and API/services?"

---

## Team Composition

| Teammate | Phase | File Scope | Mode | When Active |
|---------|-------|------------|------|-------------|
| **backend-builder** | Phase 1a | `src/api/`, `src/services/`, `src/models/`, `src/db/` | READ+WRITE | First — publishes API contract |
| **frontend-builder** | Phase 1b | `src/components/`, `src/pages/`, `src/hooks/`, `src/styles/` | READ+WRITE | After contract relay |
| **live-reviewer** | Phase 1c (async) | All modified files | READ-ONLY | After BOTH builders complete |
| **hunter** | Phase 2 | All modified files | READ-ONLY | After live-reviewer |
| **security-reviewer** | Phase 3 | All modified files | READ-ONLY | Parallel (after hunter) |
| **performance-reviewer** | Phase 3 | All modified files | READ-ONLY | Parallel (after hunter) |
| **quality-reviewer** | Phase 3 | All modified files | READ-ONLY | Parallel (after hunter) |
| **accessibility-reviewer** | Phase 3 (conditional) | Frontend files | READ-ONLY | If UI files detected |
| **api-contract-reviewer** | Phase 3 (conditional) | Backend files | READ-ONLY | If API files detected |
| **verifier** | Phase 4 | Integration E2E | READ-ONLY | After challenge round |

**File isolation is ABSOLUTE.** Backend-builder and frontend-builder must NOT overlap in FILES_MODIFIED.

---

## Protocol Phases

### Phase 0: Scope Declaration (Lead, Before Spawning)

1. **Lead identifies file scope partition:**
   - Backend scope: `{list of dirs/files for backend-builder}`
   - Frontend scope: `{list of dirs/files for frontend-builder}`
   - Shared utilities (if any): assign to ONE builder only, flag for the other as read-only

2. **Lead checks for scope conflicts:**
   - Any file that would be in BOTH scopes must be resolved BEFORE spawning
   - If conflict → AskUserQuestion: "Who should own `{file}`? Backend-builder or frontend-builder?"

3. **Lead spawns backend-builder first** (it defines the contract)

---

### Phase 1a: Backend Implementation + Contract Publication

**backend-builder** implements:
- API routes/endpoints
- Service layer
- Data models/schema
- Database queries

After completing TDD phases, backend-builder MUST publish `API_CONTRACT_SPEC` in Memory Notes:

```markdown
#### API_CONTRACT_SPEC
**Endpoints:**
- `GET /api/users/:id` → 200: `{ id: string, name: string, email: string }` | 404: `{ error: string }`
- `POST /api/users` → 201: `{ id: string }` | 400: `{ error: string, fields: string[] }`

**Auth:** Bearer token required for POST; none for GET

**Types:**
```typescript
interface User {
  id: string;
  name: string;
  email: string;
  createdAt: string;
}
```
```

**Lead Contract Validation Gate:**
- Lead reads backend-builder's Memory Notes
- Extracts API_CONTRACT_SPEC
- Validates: Are all endpoints documented? Are types complete? Is auth specified?
- AskUserQuestion if ambiguities exist: "Is `metadata` field optional or always present?"
- Only proceed to Phase 1b after contract is validated

---

### Phase 1b: Frontend Implementation (Against Verified Contract)

**Lead spawns frontend-builder** with validated contract in spawn prompt:
```
API_CONTRACT_SPEC:
{validated contract from backend-builder}

IMPORTANT: Implement ONLY against this contract. Do not make assumptions about
undocumented API behavior. If the contract is insufficient, message the lead.
```

**frontend-builder** implements:
- UI components
- Pages/views
- Data fetching hooks (using contract endpoints)
- State management
- Loading/error/empty states

**Note:** frontend-builder and backend-builder run in **different worktrees** (isolation: worktree on both). They can run in parallel if backend is already done, or frontend starts immediately after contract relay.

---

### Phase 1c: Async Live Review (Both Builders)

**Unlike standard Pair Build (per-module blocking review), cross-layer uses async post-completion review:**

1. Both builders complete independently
2. Both notify lead they're done
3. Lead spawns `live-reviewer` with BOTH builders' changes
4. Live-reviewer reviews ALL modified files at once
5. If STOP issues → lead creates `CC-TEAMS REM-FIX` and assigns to appropriate builder

**Why async:** Blocking per-module review would serialize the parallel builders (frontend can't proceed if live-reviewer is reviewing backend modules). Async review preserves true parallelism.

**Live-reviewer spawn context:**
```
## Cross-Layer Review
Review ALL changes from BOTH builders:
- Backend changes: {FILES_MODIFIED from backend-builder contract}
- Frontend changes: {FILES_MODIFIED from frontend-builder contract}
Focus on: cross-layer integration points, API usage correctness, error handling
```

---

### Phase 2: Cross-Layer Silent Failure Hunt (Hunter)

Hunter scans ALL modified files across both builders:
- Backend: empty catches swallowing API errors, missing error responses
- Frontend: unhandled promise rejections, missing loading/error states
- Integration: frontend calling non-existent endpoints, assuming wrong response shapes

---

### Phase 3: Full Review Arena

All reviewers audit the COMPLETE cross-layer change set:

- **security-reviewer:** API auth, CORS, injection, token handling
- **performance-reviewer:** N+1 queries, bundle size, unnecessary re-renders
- **quality-reviewer:** Patterns, naming, duplication, error handling
- **accessibility-reviewer** (if UI files detected): WCAG audit on frontend changes
- **api-contract-reviewer** (always in cross-layer): Verify frontend correctly implements the backend contract

**Challenge round:** Conflict resolution follows standard review-arena rules.

---

### Phase 4: Integrated E2E Verification (Verifier)

Verifier runs integration tests that exercise the FULL stack:
- API endpoints are hit via HTTP (not mocked)
- Frontend renders with real API responses (if E2E tests available)
- Auth flow complete (login → protected route → API call → response)

---

## File Conflict Gate (MANDATORY)

Before proceeding to Phase 1c, lead validates no FILES_MODIFIED overlap:

```
backend_files = set(backend_builder.FILES_MODIFIED)
frontend_files = set(frontend_builder.FILES_MODIFIED)
overlap = backend_files ∩ frontend_files

if overlap is not empty:
  → Create CC-TEAMS REM-FIX: file scope conflict — {list of overlapping files}
  → Block live-reviewer and all downstream tasks
  → Ask user: "Both builders modified {files}. Which version should we keep?"
  → Only proceed after conflict resolved
```

---

## Task Structure (Lead Creates This Hierarchy)

```
CC-TEAMS BUILD-CROSSLAYER: {feature}
├── CC-TEAMS backend-builder: Implement backend
├── CC-TEAMS frontend-builder: Implement frontend (blocked by backend-builder: contract relay)
├── CC-TEAMS live-reviewer: Async post-build review (blocked by backend-builder + frontend-builder)
├── CC-TEAMS hunter: Cross-layer silent failure audit (blocked by live-reviewer)
├── CC-TEAMS security-reviewer: Security review (blocked by hunter)
├── CC-TEAMS performance-reviewer: Performance review (blocked by hunter)
├── CC-TEAMS quality-reviewer: Quality review (blocked by hunter)
├── CC-TEAMS accessibility-reviewer: A11y review (blocked by hunter, if UI detected)
├── CC-TEAMS api-contract-reviewer: Contract validation (blocked by hunter)
├── CC-TEAMS BUILD-CROSSLAYER Review Arena: Challenge round (blocked by all active reviewers)
├── CC-TEAMS verifier: Integrated E2E verification (blocked by challenge round)
└── CC-TEAMS Memory Update: Persist cross-layer learnings (blocked by verifier)
```

---

## Task Naming Convention

Use `CC-TEAMS backend-builder:` and `CC-TEAMS frontend-builder:` (not `CC-TEAMS builder:`).

The `CC-TEAMS builder:` task name is reserved for standard single-builder BUILD workflows.

---

## Per-Agent Spawn Context (Cross-Layer Additions)

### backend-builder (additional fields)
```
SCOPE:         src/api/**, src/services/**, src/models/**
CONTRACT_RESPONSIBILITY: You define the API contract. Frontend-builder implements against it.
```

### frontend-builder (additional fields)
```
SCOPE:         src/components/**, src/pages/**, src/hooks/**
API_CONTRACT_SPEC: {validated contract from backend-builder}
CONTRACT_RESPONSIBILITY: Implement against the provided contract exactly.
```

---

## Key Differences from Standard BUILD

| Aspect | Standard BUILD | Cross-Layer BUILD |
|--------|---------------|-------------------|
| Builders | 1 builder | 2 builders (frontend + backend) |
| Live review | Per-module blocking | Async post-completion |
| API contract | Implied | Explicit, validated, relayed |
| File scope | Single builder owns all | Partitioned by layer |
| Phase 0 | Not needed | Contract relay (mandatory) |
| Workflow duration | Standard | ~20-30% longer (contract relay phase) |

---

## When NOT to Use Cross-Layer BUILD

- Feature touches only UI files (no API changes) → use standard BUILD FULL
- Feature touches only backend files (no UI changes) → use standard BUILD FULL
- Feature is in QUICK depth eligibility → standard QUICK path (cross-layer disqualifies QUICK)
- Team is small and parallel overhead > benefit → standard BUILD FULL with single builder
