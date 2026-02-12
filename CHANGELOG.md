# Changelog

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

- **Planner Deadlock** (planner.md, cc100x-lead/SKILL.md)
  - Root cause: Planner was spawned with `mode: "plan"` which is READ-ONLY
  - Planner couldn't save plan files or update memory
  - Fix: Removed `mode: "plan"` from planner spawning, added explicit Plan Mode Rule

## [0.1.11] - 2026-02-11

### Fixed

- **Test Process Discipline** (builder.md, verifier.md, cc100x-lead/SKILL.md, test-driven-development/SKILL.md)
  - Root cause: Vitest watch mode left 61 hanging processes, froze user's computer
  - Fix: Added Test Process Discipline sections requiring `CI=true` or `--run` flag
  - Added Test Process Cleanup Gate (#13) to cc100x-lead before Team Shutdown
  - Updated TDD skill examples with proper flags

## [0.1.10] - 2026-02-10

### Fixed

- **REM-EVIDENCE Timeout** (cc100x-lead/SKILL.md)
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

- Initial CC100x release
- Agent Teams-based orchestration for Claude Code
- 9 specialized agents: builder, planner, verifier, hunter, investigator, live-reviewer, security-reviewer, performance-reviewer, quality-reviewer
- 8 skills: cc100x-lead, review-arena, bug-court, pair-build, router-contract, session-memory, test-driven-development, verification
- Router Contract YAML format for machine-readable agent handoffs
- Challenge Round protocol for reviewer consensus
- Task Status Lag escalation ladder
- Memory persistence with lead ownership
