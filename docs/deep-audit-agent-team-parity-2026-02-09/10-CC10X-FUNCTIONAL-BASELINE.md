# CC10x Functional Baseline Model (Phase 1)

Date: 2026-02-09
Source class: functional files only
Purpose: establish exact CC10x lifecycle behavior to compare against CC100x

## 1) System Identity (Functional Truth)

CC10x is an orchestration system with a single entrypoint (`cc10x-router`) that routes every development task into one lifecycle workflow: PLAN, BUILD, REVIEW, or DEBUG.

Primary evidence:
- `reference/cc10x-router-SKILL.md:4`
- `reference/cc10x-router-SKILL.md:15`
- `reference/cc10x-router-SKILL.md:19`
- `reference/cc10x-router-SKILL.md:30`

## 2) Routing + Lifecycle Topology

### Decision Tree (priority order)

1. ERROR -> DEBUG
2. PLAN -> PLAN
3. REVIEW -> REVIEW
4. DEFAULT -> BUILD

Conflict rule: ERROR wins over all other intent signals.

Evidence:
- `reference/cc10x-router-SKILL.md:19`
- `reference/cc10x-router-SKILL.md:23`
- `reference/cc10x-router-SKILL.md:24`
- `reference/cc10x-router-SKILL.md:25`
- `reference/cc10x-router-SKILL.md:26`
- `reference/cc10x-router-SKILL.md:28`

### Agent Chain Definitions

- BUILD: `component-builder -> [code-reviewer || silent-failure-hunter] -> integration-verifier`
- DEBUG: `bug-investigator -> code-reviewer -> integration-verifier`
- REVIEW: `code-reviewer`
- PLAN: `planner`

Evidence:
- `reference/cc10x-router-SKILL.md:32`
- `reference/cc10x-router-SKILL.md:34`
- `reference/cc10x-router-SKILL.md:35`
- `reference/cc10x-router-SKILL.md:36`
- `reference/cc10x-router-SKILL.md:37`
- `reference/cc10x-router-SKILL.md:39`

## 3) Core Substrates (Shared Across All Workflows)

### Memory Substrate

- Mandatory load before routing (`mkdir -> read 3 files`)
- Mandatory template validation + auto-heal
- Mandatory workflow-final persistence
- Edit-only update rule with read-back verification

Evidence:
- `reference/cc10x-router-SKILL.md:45`
- `reference/cc10x-router-SKILL.md:50`
- `reference/cc10x-router-SKILL.md:63`
- `reference/cc10x-router-SKILL.md:77`
- `reference/cc10x-router-SKILL.md:97`
- `reference/cc10x-router-SKILL.md:102`
- `reference/cc10x-router-SKILL.md:103`
- `reference/cc10x-router-SKILL.md:104`

### Task Substrate

- Mandatory TaskList check for active workflow
- Resume/orphan/legacy handling
- Forward-only DAG dependencies (no cycles)
- Workflow-specific task hierarchies + mandatory Memory Update task

Evidence:
- `reference/cc10x-router-SKILL.md:109`
- `reference/cc10x-router-SKILL.md:114`
- `reference/cc10x-router-SKILL.md:116`
- `reference/cc10x-router-SKILL.md:125`
- `reference/cc10x-router-SKILL.md:133`
- `reference/cc10x-router-SKILL.md:135`
- `reference/cc10x-router-SKILL.md:149`
- `reference/cc10x-router-SKILL.md:189`
- `reference/cc10x-router-SKILL.md:213`
- `reference/cc10x-router-SKILL.md:229`
- `reference/cc10x-router-SKILL.md:246`

### Router Contract Substrate

- Contract is primary post-agent validation mechanism
- Missing contract triggers `REM-EVIDENCE`
- Blocking/remediation signals create `REM-FIX`
- Circuit breaker at 3+ remediation loops

Evidence:
- `reference/cc10x-router-SKILL.md:382`
- `reference/cc10x-router-SKILL.md:384`
- `reference/cc10x-router-SKILL.md:388`
- `reference/cc10x-router-SKILL.md:411`
- `reference/cc10x-router-SKILL.md:419`
- `reference/cc10x-router-SKILL.md:432`

## 4) Workflow-Level SDLC Behavior

### PLAN

Lifecycle behavior:
- Clarify requirements first
- Run research first when triggered (and persist it)
- Create planner task + memory update task
- Persist plan reference into memory

Evidence:
- `reference/cc10x-router-SKILL.md:310`
- `reference/cc10x-router-SKILL.md:312`
- `reference/cc10x-router-SKILL.md:315`
- `reference/cc10x-router-SKILL.md:318`
- `reference/cc10x-router-SKILL.md:320`
- `reference/cc10x-agents/planner.md:29`
- `reference/cc10x-agents/planner.md:57`
- `reference/cc10x-agents/planner.md:61`
- `reference/cc10x-agents/planner.md:78`

### BUILD

Lifecycle behavior:
- Plan-first gate
- Requirements clarification gate
- Builder implements via TDD
- Reviewer + Hunter run in parallel
- Verifier runs after both
- Memory update task completes workflow

Evidence:
- `reference/cc10x-router-SKILL.md:258`
- `reference/cc10x-router-SKILL.md:261`
- `reference/cc10x-router-SKILL.md:263`
- `reference/cc10x-router-SKILL.md:264`
- `reference/cc10x-router-SKILL.md:265`
- `reference/cc10x-router-SKILL.md:565`
- `reference/cc10x-agents/component-builder.md:13`
- `reference/cc10x-agents/component-builder.md:27`
- `reference/cc10x-agents/component-builder.md:44`
- `reference/cc10x-agents/component-builder.md:45`

### REVIEW

Lifecycle behavior:
- Explicit review scope clarification
- Single reviewer workflow
- Memory update enforced

Evidence:
- `reference/cc10x-router-SKILL.md:300`
- `reference/cc10x-router-SKILL.md:302`
- `reference/cc10x-router-SKILL.md:306`
- `reference/cc10x-router-SKILL.md:307`
- `reference/cc10x-router-SKILL.md:308`
- `reference/cc10x-agents/code-reviewer.md:48`

### DEBUG

Lifecycle behavior:
- Clarify ambiguity first
- Trigger external research for explicit request/external errors/3+ attempts
- Persist research before execution
- Investigator performs evidence-first debugging and applies fix with TDD
- Reviewer + Verifier complete quality and integration checks
- Memory update persists root-cause learning

Evidence:
- `reference/cc10x-router-SKILL.md:268`
- `reference/cc10x-router-SKILL.md:270`
- `reference/cc10x-router-SKILL.md:275`
- `reference/cc10x-router-SKILL.md:291`
- `reference/cc10x-router-SKILL.md:294`
- `reference/cc10x-router-SKILL.md:297`
- `reference/cc10x-router-SKILL.md:298`
- `reference/cc10x-agents/bug-investigator.md:13`
- `reference/cc10x-agents/bug-investigator.md:17`
- `reference/cc10x-agents/bug-investigator.md:48`
- `reference/cc10x-agents/bug-investigator.md:71`
- `reference/cc10x-agents/bug-investigator.md:72`

## 5) Agent Roles and Behavioral Contracts

| Agent | Mode | Write Ability | Router Contract STATUS set | Key hard gate |
|---|---|---|---|---|
| component-builder | build executor | READ+WRITE | `PASS | FAIL` | PASS requires TDD RED=1 and GREEN=0 |
| bug-investigator | debug executor | READ+WRITE | `FIXED | INVESTIGATING | BLOCKED` | FIXED requires TDD + variants covered |
| planner | planning executor | plan+memory write | `PLAN_CREATED | NEEDS_CLARIFICATION` | PLAN_CREATED requires valid plan file and confidence |
| code-reviewer | reviewer | READ-ONLY | `APPROVE | CHANGES_REQUESTED` | APPROVE requires zero critical and confidence >=80 |
| silent-failure-hunter | reliability reviewer | READ-ONLY | `CLEAN | ISSUES_FOUND` | CLEAN requires zero critical issues |
| integration-verifier | end-to-end verifier | READ-ONLY | `PASS | FAIL` | PASS requires blockers=0 and full scenario pass |

Evidence:
- `reference/cc10x-agents/component-builder.md:7`
- `reference/cc10x-agents/component-builder.md:8`
- `reference/cc10x-agents/component-builder.md:140`
- `reference/cc10x-agents/component-builder.md:153`
- `reference/cc10x-agents/bug-investigator.md:7`
- `reference/cc10x-agents/bug-investigator.md:8`
- `reference/cc10x-agents/bug-investigator.md:185`
- `reference/cc10x-agents/bug-investigator.md:199`
- `reference/cc10x-agents/planner.md:8`
- `reference/cc10x-agents/planner.md:187`
- `reference/cc10x-agents/planner.md:200`
- `reference/cc10x-agents/code-reviewer.md:15`
- `reference/cc10x-agents/code-reviewer.md:125`
- `reference/cc10x-agents/code-reviewer.md:137`
- `reference/cc10x-agents/silent-failure-hunter.md:15`
- `reference/cc10x-agents/silent-failure-hunter.md:147`
- `reference/cc10x-agents/silent-failure-hunter.md:158`
- `reference/cc10x-agents/integration-verifier.md:15`
- `reference/cc10x-agents/integration-verifier.md:132`
- `reference/cc10x-agents/integration-verifier.md:144`

## 6) Skill Ecosystem (Baseline Capability Layer)

CC10x functional behavior is reinforced by 12 internal skills loaded via agent frontmatter (primary) plus SKILL_HINTS (conditional, especially research).

Evidence for loading hierarchy:
- `reference/cc10x-router-SKILL.md:492`
- `reference/cc10x-router-SKILL.md:496`
- `reference/cc10x-router-SKILL.md:505`

High-impact skill capabilities (must preserve functionally):
- `architecture-patterns`: functionality-first architecture gating and decision framework
  - `reference/cc10x-skills/architecture-patterns.md:23`
- `frontend-patterns`: UI/UX/a11y flow-first design and anti-pattern blocks
  - `reference/cc10x-skills/frontend-patterns.md:46`
- `brainstorming`: structured discovery and phased requirement shaping
  - `reference/cc10x-skills/brainstorming.md:17`
- `test-driven-development`: RED->GREEN->REFACTOR hard enforcement
  - `reference/cc10x-skills/test-driven-development.md:32`
- `verification-before-completion`: evidence-before-claims gate
  - `reference/cc10x-skills/verification-before-completion.md:17`
- `github-research`: multi-tier external research + persistence protocol
  - `reference/cc10x-skills/github-research.md:11`
  - `reference/cc10x-skills/github-research.md:130`

## 7) SDLC Connectivity (Why This Is One Ecosystem)

CC10x is explicitly coupled across lifecycle stages:

1. PLAN influences BUILD via plan file references and Plan-First gate.
   - `reference/cc10x-router-SKILL.md:155`
   - `reference/cc10x-router-SKILL.md:261`
   - `reference/cc10x-agents/component-builder.md:27`

2. BUILD quality is enforced through parallel review/hunt and verifier dependency.
   - `reference/cc10x-router-SKILL.md:177`
   - `reference/cc10x-router-SKILL.md:181`
   - `reference/cc10x-router-SKILL.md:185`

3. DEBUG reuses quality and integration gates before closure.
   - `reference/cc10x-router-SKILL.md:201`
   - `reference/cc10x-router-SKILL.md:205`
   - `reference/cc10x-router-SKILL.md:208`

4. READ-ONLY agent memory notes are aggregated at workflow-final persistence.
   - `reference/cc10x-router-SKILL.md:587`
   - `reference/cc10x-router-SKILL.md:602`

5. Remediation loops enforce re-review before shipping.
   - `reference/cc10x-router-SKILL.md:456`
   - `reference/cc10x-router-SKILL.md:471`

6. TODO tasks can trigger next lifecycle workflows, extending the SDLC graph.
   - `reference/cc10x-router-SKILL.md:606`
   - `reference/cc10x-router-SKILL.md:619`

## 8) Baseline Non-Negotiables To Preserve In CC100x

1. Single orchestrator entrypoint and deterministic routing.
2. Workflow chain completion (never stop early).
3. Task DAG integrity with required Memory Update task.
4. Memory load-first and durable update-at-end behavior.
5. Router Contract-driven validation and remediation.
6. TDD + verification evidence gates.
7. Research-first-then-persist before dependent planning/debug steps.
8. Cross-workflow handoff integrity (plan/build/review/debug as one system).

Evidence anchors:
- `reference/cc10x-router-SKILL.md:4`
- `reference/cc10x-router-SKILL.md:512`
- `reference/cc10x-router-SKILL.md:524`
- `reference/cc10x-router-SKILL.md:565`
- `reference/cc10x-router-SKILL.md:322`
- `reference/cc10x-router-SKILL.md:456`

## 9) Phase 1 Status

- Baseline model extracted from functional files.
- Next step: build equivalent CC100x functional model (Phase 2) using same structure and evidence standard.
