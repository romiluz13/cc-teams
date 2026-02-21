# Changelog

## [0.1.14] - 2026-02-12

### Fixed

- **Verifier Hanging / Systemic Response Awareness Gap** (ALL agents + lead + skills)
  - Root cause #1: Lead execution loop said "Wait for teammates" without connecting to escalation ladder
  - Root cause #2: Most agents had "Task Completion" but not "Task Response (MANDATORY)" with deadline awareness
  - Evidence: User session showed verifier (Task #9) started but lead passively waited with "Awaiting verifier evidence..."

  **Comprehensive fix across 10 files:**

  | File | Fix Applied |
  |------|-------------|
  | `verifier.md` | Added "Task Response (MANDATORY)" section |
  | `hunter.md` | Added "Task Response (MANDATORY)" section |
  | `builder.md` | Added "Task Response (MANDATORY)" section |
  | `investigator.md` | Added "Task Response (MANDATORY)" section |
  | `live-reviewer.md` | Added "Task Response (MANDATORY)" section |
  | `planner.md` | Added "Task Response (MANDATORY)" section |
  | `security-reviewer.md` | Added "Task Response (MANDATORY)" section (existing Challenge Round Response kept) |
  | `performance-reviewer.md` | Added "Task Response (MANDATORY)" section (existing Challenge Round Response kept) |
  | `quality-reviewer.md` | Added "Task Response (MANDATORY)" section (existing Challenge Round Response kept) |
  | `cc-teams-lead/SKILL.md` | Fixed execution loop step 4: explicit escalation when waiting |
  | `review-arena/SKILL.md` | Fixed Phase 1 Lead actions: explicit escalation |
  | `bug-court/SKILL.md` | Added Lead actions to Phase 2: explicit escalation |

### Task Response (MANDATORY) Pattern

All agents now include:
```markdown
## Task Response (MANDATORY)

1. **You MUST complete and respond** - Non-response triggers lead escalation
2. **Deadline awareness:** Lead monitors at T+2 (nudge), T+5 (deadline), T+8 (replacement)
3. **If blocked:** Reply immediately with BLOCKED: {reason}
4. **Upon completion:** Output Router Contract
5. **Non-response consequence:** At T+8, lead spawns replacement and reassigns
```

### Notes

- This fix ensures NO agent can silently hang the workflow
- Every parallel phase (review-arena, bug-court) now has explicit escalation in Lead actions
- Invariant #7 changed from "Wait for teammates" to "Monitor teammates with escalation"

## [0.1.13] - 2026-02-12

### Fixed

- **Challenge Round Response Not Mandatory** (security-reviewer, performance-reviewer, quality-reviewer)
  - Root cause: "Challenging Other Reviewers" section used PASSIVE language ("When you receive...")
  - Reviewers didn't know they MUST respond to challenge requests
  - Evidence: User session showed 2/3 reviewers went idle during challenge round
  - Fix: Added "Challenge Round Response (MANDATORY)" section to all 3 reviewer agents with:
    - "You MUST respond" requirement
    - T+5 deadline awareness (T+8 = synthesis without you)
    - Valid response types (AGREE, DISAGREE, ESCALATE)
    - Consequence warning for non-response

### Notes

- Comprehensive audit of all 17 files (9 agents + 8 skills) confirmed this as the ONLY critical flaw
- All other protocols (Router Contract, Memory, TDD, Escalation) are working correctly

## [0.1.12] - 2026-02-11

### Fixed

- **Planner Deadlock** (planner.md, cc-teams-lead/SKILL.md)
  - Root cause: Planner was spawned with `mode: "plan"` which is READ-ONLY
  - Planner couldn't save plan files or update memory
  - Fix: Removed `mode: "plan"` from planner spawning, added explicit Plan Mode Rule

## [0.1.11] - 2026-02-11

### Fixed

- **Test Process Discipline** (builder.md, verifier.md, cc-teams-lead/SKILL.md, test-driven-development/SKILL.md)
  - Root cause: Vitest watch mode left 61 hanging processes, froze user's computer
  - Fix: Added Test Process Discipline sections requiring `CI=true` or `--run` flag
  - Added Test Process Cleanup Gate (#13) to cc-teams-lead before Team Shutdown
  - Updated TDD skill examples with proper flags

## [0.1.10] - 2026-02-10

### Fixed

- **REM-EVIDENCE Timeout** (cc-teams-lead/SKILL.md)
  - Root cause: Builder didn't respond to REM-EVIDENCE request for Router Contract
  - Workflow hung indefinitely waiting for response
  - Fix: Added REM-EVIDENCE Timeout Rule connecting to Task Status Lag escalation ladder
  - Added Lead Synthesis Fallback for non-responsive teammates

## [0.1.9] - 2026-02-09

### Added

- **Babysitter Repo Pattern Integration** (multiple files)
  - Integrated 5 high-value patterns from a5c-ai/babysitter repo:
    - "Smallest correct change set" constraint
    - "Root cause + prevention" for investigators
    - Prioritized output formats
    - Evidence-first reasoning
    - Explicit confidence scoring

## [0.1.0] - 2026-02-01

### Added

- Initial CC-Teams release
- Agent Teams-based orchestration for Claude Code
- 9 specialized agents: builder, planner, verifier, hunter, investigator, live-reviewer, security-reviewer, performance-reviewer, quality-reviewer
- 8 skills: cc-teams-lead, review-arena, bug-court, pair-build, router-contract, session-memory, test-driven-development, verification
- Router Contract YAML format for machine-readable agent handoffs
- Challenge Round protocol for reviewer consensus
- Task Status Lag escalation ladder
- Memory persistence with lead ownership
