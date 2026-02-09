# CC100x Functional Target Model (Phase 2)

Date: 2026-02-09
Source class: functional files only
Purpose: capture exact current CC100x lifecycle behavior (Agent Teams architecture)

## 1) System Identity (Functional Truth)

CC100x is an Agent Teams orchestration system with a single entrypoint (`cc100x-lead`) that coordinates teammate workflows in delegate mode.

Primary evidence:
- `plugins/cc100x/CLAUDE.md:3`
- `plugins/cc100x/CLAUDE.md:13`
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:4`
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:17`
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:21`

## 2) Routing + Lifecycle Topology

### Decision Tree (priority order)

1. ERROR -> DEBUG (Bug Court)
2. PLAN -> PLAN (single planner, plan approval mode)
3. REVIEW -> REVIEW (Review Arena)
4. DEFAULT -> BUILD (Pair Build)

Conflict rule: ERROR wins.

Evidence:
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:25`
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:29`
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:30`
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:31`
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:32`
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:34`

### Workflow Protocol Mapping

- REVIEW -> `review-arena` (3 specialist reviewers + challenge)
- DEBUG -> `bug-court` (2-5 investigators + debate + builder fix)
- BUILD -> `pair-build` (builder + live-reviewer, then hunter, then verifier)
- PLAN -> single planner with approval handshake

Evidence:
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:36`
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:40`
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:41`
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:42`
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:43`

## 3) Core Substrates (Shared Across All Workflows)

### Memory Substrate

- Mandatory load before routing (`mkdir -> read 3 files`)
- Mandatory auto-heal template validation
- Mandatory workflow-final persistence
- Edit+readback update safety

Evidence:
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:51`
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:56`
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:69`
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:83`
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:103`
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:108`

### Task Substrate

- Mandatory active task check/resume flow
- Forward-only DAG dependency rules
- Workflow-specific task hierarchies with Memory Update task
- Task persistence, sharing, cleanup semantics explicitly defined

Evidence:
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:115`
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:124`
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:141`
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:143`
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:177`
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:185`
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:189`
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:195`
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:249`
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:321`
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:368`
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:395`

### Router Contract Substrate

- Contract-first validation after teammate execution
- Missing contract -> `REM-EVIDENCE`
- BLOCKING/REQUIRES_REMEDIATION -> `REM-FIX`
- Circuit breaker at 3+ remediations

Evidence:
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:593`
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:597`
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:601`
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:624`
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:632`
- `plugins/cc100x/skills/router-contract/SKILL.md:20`
- `plugins/cc100x/skills/router-contract/SKILL.md:48`
- `plugins/cc100x/skills/router-contract/SKILL.md:195`

## 4) Workflow-Level SDLC Behavior

### PLAN

Lifecycle behavior:
- Clarification gate
- Plan Approval Mode handshake
- Optional prerequisite research + persistence
- Planner produces plan artifact + memory reference

Evidence:
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:466`
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:468`
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:471`
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:477`
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:484`
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:497`
- `plugins/cc100x/agents/planner.md:32`
- `plugins/cc100x/agents/planner.md:60`
- `plugins/cc100x/agents/planner.md:64`
- `plugins/cc100x/agents/planner.md:82`

### BUILD

Lifecycle behavior:
- Plan-first gate and requirements clarification
- Builder owns all writes and uses TDD
- Live reviewer runs concurrently via message loop (LGTM/STOP)
- Hunter then verifier enforce post-build safety
- Memory update task closes workflow

Evidence:
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:409`
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:411`
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:414`
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:416`
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:417`
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:732`
- `plugins/cc100x/skills/pair-build/SKILL.md:47`
- `plugins/cc100x/skills/pair-build/SKILL.md:60`
- `plugins/cc100x/skills/pair-build/SKILL.md:94`
- `plugins/cc100x/skills/pair-build/SKILL.md:153`
- `plugins/cc100x/skills/pair-build/SKILL.md:174`
- `plugins/cc100x/agents/builder.md:15`
- `plugins/cc100x/agents/builder.md:49`
- `plugins/cc100x/agents/live-reviewer.md:54`
- `plugins/cc100x/agents/live-reviewer.md:64`

### REVIEW

Lifecycle behavior:
- Explicit review scope clarification
- Three specialist reviewers in parallel
- Challenge/debate round for cross-examination
- Consensus with security-first conflict rule
- Memory update task closes workflow

Evidence:
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:455`
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:457`
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:462`
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:464`
- `plugins/cc100x/skills/review-arena/SKILL.md:16`
- `plugins/cc100x/skills/review-arena/SKILL.md:123`
- `plugins/cc100x/skills/review-arena/SKILL.md:146`
- `plugins/cc100x/skills/review-arena/SKILL.md:174`
- `plugins/cc100x/skills/review-arena/SKILL.md:184`

### DEBUG

Lifecycle behavior:
- Clarify ambiguity + debug-attempt counting
- Trigger external research when required and persist it
- Generate multiple hypotheses
- Parallel READ-ONLY investigators + debate
- Builder implements winning fix with TDD
- Quality-reviewer + verifier + memory update complete lifecycle

Evidence:
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:420`
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:427`
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:432`
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:443`
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:449`
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:451`
- `plugins/cc100x/skills/bug-court/SKILL.md:28`
- `plugins/cc100x/skills/bug-court/SKILL.md:32`
- `plugins/cc100x/skills/bug-court/SKILL.md:97`
- `plugins/cc100x/skills/bug-court/SKILL.md:138`
- `plugins/cc100x/skills/bug-court/SKILL.md:145`
- `plugins/cc100x/agents/investigator.md:15`
- `plugins/cc100x/agents/investigator.md:83`

## 5) Agent Roles and Behavioral Contracts

| Agent | Mode | Write Ability | Router Contract STATUS set | Key hard gate |
|---|---|---|---|---|
| builder | build executor | READ+WRITE | `PASS | FAIL` | PASS requires TDD RED=1 and GREEN=0 |
| investigator | hypothesis executor | READ-ONLY | `EVIDENCE_FOUND | INVESTIGATING | BLOCKED` | EVIDENCE_FOUND requires root cause + evidence |
| planner | planning executor | plan+memory write | `PLAN_CREATED | NEEDS_CLARIFICATION` | PLAN_CREATED requires valid plan file and confidence |
| security-reviewer | reviewer | READ-ONLY | `APPROVE | CHANGES_REQUESTED` | APPROVE requires zero critical and confidence >=80 |
| performance-reviewer | reviewer | READ-ONLY | `APPROVE | CHANGES_REQUESTED` | APPROVE requires zero critical and confidence >=80 |
| quality-reviewer | reviewer | READ-ONLY | `APPROVE | CHANGES_REQUESTED` | APPROVE requires zero critical and confidence >=80 |
| live-reviewer | inline reviewer | READ-ONLY | `APPROVE | CHANGES_REQUESTED` | APPROVE requires no unresolved STOP issues |
| hunter | reliability reviewer | READ-ONLY | `CLEAN | ISSUES_FOUND` | CLEAN requires zero critical issues |
| verifier | end-to-end verifier | READ-ONLY | `PASS | FAIL` | PASS requires blockers=0 and full scenario pass |

Evidence:
- `plugins/cc100x/agents/builder.md:7`
- `plugins/cc100x/agents/builder.md:8`
- `plugins/cc100x/agents/builder.md:198`
- `plugins/cc100x/agents/builder.md:216`
- `plugins/cc100x/agents/investigator.md:15`
- `plugins/cc100x/agents/investigator.md:211`
- `plugins/cc100x/agents/investigator.md:230`
- `plugins/cc100x/agents/planner.md:8`
- `plugins/cc100x/agents/planner.md:247`
- `plugins/cc100x/agents/planner.md:266`
- `plugins/cc100x/agents/security-reviewer.md:171`
- `plugins/cc100x/agents/security-reviewer.md:188`
- `plugins/cc100x/agents/performance-reviewer.md:186`
- `plugins/cc100x/agents/performance-reviewer.md:203`
- `plugins/cc100x/agents/quality-reviewer.md:197`
- `plugins/cc100x/agents/quality-reviewer.md:214`
- `plugins/cc100x/agents/live-reviewer.md:179`
- `plugins/cc100x/agents/live-reviewer.md:196`
- `plugins/cc100x/agents/hunter.md:166`
- `plugins/cc100x/agents/hunter.md:182`
- `plugins/cc100x/agents/verifier.md:192`
- `plugins/cc100x/agents/verifier.md:209`

## 6) Skill Ecosystem (Target Capability Layer)

CC100x behavior uses two-layer skill loading:

1. Agent frontmatter preload (`session-memory`, `router-contract`, `verification` as appropriate)
2. Lead-driven `SKILL_HINTS` distribution by workflow/context

Evidence:
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:544`
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:548`
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:562`
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:569`
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:573`
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:587`

High-impact protocol skills (new Agent Teams layer):
- `review-arena` (parallel specialist review + challenge + consensus)
  - `plugins/cc100x/skills/review-arena/SKILL.md:10`
  - `plugins/cc100x/skills/review-arena/SKILL.md:146`
  - `plugins/cc100x/skills/review-arena/SKILL.md:174`
- `bug-court` (competing hypotheses + debate + no nested teams)
  - `plugins/cc100x/skills/bug-court/SKILL.md:10`
  - `plugins/cc100x/skills/bug-court/SKILL.md:75`
  - `plugins/cc100x/skills/bug-court/SKILL.md:97`
  - `plugins/cc100x/skills/bug-court/SKILL.md:149`
- `pair-build` (real-time builder/reviewer loop + post-build hunt/verify)
  - `plugins/cc100x/skills/pair-build/SKILL.md:10`
  - `plugins/cc100x/skills/pair-build/SKILL.md:43`
  - `plugins/cc100x/skills/pair-build/SKILL.md:94`
  - `plugins/cc100x/skills/pair-build/SKILL.md:153`
  - `plugins/cc100x/skills/pair-build/SKILL.md:174`
- `router-contract` (shared contract schema + agent-specific status semantics)
  - `plugins/cc100x/skills/router-contract/SKILL.md:20`
  - `plugins/cc100x/skills/router-contract/SKILL.md:48`
  - `plugins/cc100x/skills/router-contract/SKILL.md:135`

## 7) Agent Teams Constraints (Architectural Hard Rules)

The target system encodes Agent Teams-specific operational constraints that are mandatory for correctness:

1. Delegate mode mandatory for lead
2. No file write conflicts between teammates (builder owns writes)
3. No nested teams
4. Team history isolation requires explicit context passing
5. Peer messaging replaces router-only relay model
6. `/resume` does not restore teammates (requires recovery protocol)
7. Team shutdown is explicit gate

Evidence:
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:21`
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:157`
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:166`
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:701`
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:828`
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:832`
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:834`
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:835`
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:901`

## 8) SDLC Connectivity (Target Ecosystem Coupling)

CC100x remains lifecycle-connected, with Agent Teams-native wiring:

1. PLAN feeds BUILD through plan-file references and plan-first gate.
   - `plugins/cc100x/skills/cc100x-lead/SKILL.md:202`
   - `plugins/cc100x/skills/cc100x-lead/SKILL.md:411`
   - `plugins/cc100x/agents/builder.md:34`

2. BUILD includes real-time internal feedback (live-reviewer) before downstream hard gates (hunter/verifier).
   - `plugins/cc100x/skills/cc100x-lead/SKILL.md:223`
   - `plugins/cc100x/skills/cc100x-lead/SKILL.md:231`
   - `plugins/cc100x/skills/pair-build/SKILL.md:96`

3. DEBUG includes investigation/debate before fix implementation, then quality + verification.
   - `plugins/cc100x/skills/cc100x-lead/SKILL.md:267`
   - `plugins/cc100x/skills/cc100x-lead/SKILL.md:289`
   - `plugins/cc100x/skills/cc100x-lead/SKILL.md:297`
   - `plugins/cc100x/skills/cc100x-lead/SKILL.md:305`
   - `plugins/cc100x/skills/cc100x-lead/SKILL.md:313`

4. Read-only teammate outputs are aggregated at workflow-final memory persistence.
   - `plugins/cc100x/skills/cc100x-lead/SKILL.md:781`
   - `plugins/cc100x/skills/cc100x-lead/SKILL.md:797`

5. Remediation loop enforces re-review/re-hunt before verifier.
   - `plugins/cc100x/skills/cc100x-lead/SKILL.md:669`
   - `plugins/cc100x/skills/cc100x-lead/SKILL.md:684`

6. TODO tasks can spawn new workflows after current lifecycle closes.
   - `plugins/cc100x/skills/cc100x-lead/SKILL.md:804`
   - `plugins/cc100x/skills/cc100x-lead/SKILL.md:817`

## 9) Target Non-Negotiables (For Parity Decision)

1. Lead-only entrypoint and delegate mode non-bypass.
2. Workflow chain completion with mandatory Memory Update.
3. Task DAG correctness + contract validation gates.
4. Memory durability under parallel teammate execution.
5. Research prerequisite-and-persistence rules.
6. File-ownership safety in multi-agent execution.
7. Correct peer-messaging handoff patterns.

Evidence anchors:
- `plugins/cc100x/CLAUDE.md:3`
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:21`
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:694`
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:732`
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:593`
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:832`
- `plugins/cc100x/skills/cc100x-lead/SKILL.md:745`

## 10) Phase 2 Status

- Functional target model extracted from lead + workflow skills + agent prompts.
- Next step: Phase 3 parity diff (CC10x baseline vs CC100x target) at SDLC ecosystem level.
