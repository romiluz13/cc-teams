# Claude Code Capability Validation

Validated on: `2026-04-09`
Validation scope: every Claude Code capability that CC Teams explicitly uses in runtime docs, prompts, hooks, or repo governance.
Source policy: official Claude Code docs only.

## Purpose

This file is the repo-owned validation matrix for Claude Code features used by CC Teams.

If a capability is not validated here against the official docs, CC Teams should not treat it as a contractual platform guarantee.

## Validation Matrix

### Agent Teams

| Capability | Repo usage | Validation | Official docs |
|---|---|---|---|
| Agent Teams experimental flag | `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` in runtime docs and setup | Validated | [Agent Teams](https://code.claude.com/docs/en/agent-teams) |
| Minimum version gate | Agent Teams version requirement in runtime expectations | Validated | [Agent Teams](https://code.claude.com/docs/en/agent-teams) |
| Team creation | `TeamCreate` in lead protocol | Validated | [Tools reference](https://code.claude.com/docs/en/tools-reference) |
| Team cleanup | `TeamDelete` in lead protocol | Validated | [Tools reference](https://code.claude.com/docs/en/tools-reference) |
| Shared task list | Task DAG orchestration | Validated | [Agent Teams](https://code.claude.com/docs/en/agent-teams) |
| Direct teammate messaging | `SendMessage` in lead and teammate protocols | Validated | [Tools reference](https://code.claude.com/docs/en/tools-reference) |
| Self-claim task coordination | lead/task policy | Validated | [Agent Teams](https://code.claude.com/docs/en/agent-teams) |
| File-locking task claims | concurrency assumptions | Validated | [Agent Teams](https://code.claude.com/docs/en/agent-teams) |

### Task Tools

| Capability | Repo usage | Validation | Official docs |
|---|---|---|---|
| `TaskCreate` | workflow task creation | Validated | [Tools reference](https://code.claude.com/docs/en/tools-reference) |
| `TaskGet` | resume and task inspection | Validated | [Tools reference](https://code.claude.com/docs/en/tools-reference) |
| `TaskList` | source-of-truth resume and DAG checks | Validated | [Tools reference](https://code.claude.com/docs/en/tools-reference) |
| `TaskUpdate` | state transitions, blockers, deletion | Validated | [Tools reference](https://code.claude.com/docs/en/tools-reference) |
| interactive sessions use task tools, not TodoWrite | repo assumes Task* tools in interactive mode | Validated | [Tools reference](https://code.claude.com/docs/en/tools-reference) |

### Teammate Definition Path

| Capability | Repo usage | Validation | Official docs |
|---|---|---|---|
| teammate can reference subagent definitions | role reuse across plugin/project/user scopes | Validated | [Agent Teams](https://code.claude.com/docs/en/agent-teams) |
| teammate honors definition `tools` and `model` | agent frontmatter contracts | Validated | [Agent Teams](https://code.claude.com/docs/en/agent-teams) |
| teammate appends definition body to prompt | role prompt composition | Validated | [Agent Teams](https://code.claude.com/docs/en/agent-teams) |
| teammate still has team coordination tools even when `tools` is restricted | SendMessage/task policy | Validated | [Agent Teams](https://code.claude.com/docs/en/agent-teams) |
| `skills` frontmatter is not applied on teammate path | lead skill-loading doctrine | Validated | [Agent Teams](https://code.claude.com/docs/en/agent-teams) |
| `mcpServers` frontmatter is not applied on teammate path | lead MCP doctrine | Validated | [Agent Teams](https://code.claude.com/docs/en/agent-teams) |
| teammates load `CLAUDE.md`, MCP servers, and skills from normal session context | runtime docs and prompts | Validated | [Agent Teams](https://code.claude.com/docs/en/agent-teams) |

### Subagent Frontmatter Used By CC Teams

| Capability | Repo usage | Validation | Official docs |
|---|---|---|---|
| `model: inherit` | agent definitions | Validated | [Sub-agents](https://code.claude.com/docs/en/sub-agents) |
| `tools:` allowlist | role capability boundaries | Validated | [Sub-agents](https://code.claude.com/docs/en/sub-agents) |
| `memory: user` | security-reviewer memory | Validated | [Sub-agents](https://code.claude.com/docs/en/sub-agents) |
| `memory: project` | investigator memory | Validated | [Sub-agents](https://code.claude.com/docs/en/sub-agents) |
| `isolation: worktree` | planner/builders | Validated | [Sub-agents](https://code.claude.com/docs/en/sub-agents) |
| plugin subagents do not support `hooks`, `mcpServers`, or `permissionMode` frontmatter | unsupported assumptions removed from runtime doctrine | Validated | [Sub-agents](https://code.claude.com/docs/en/sub-agents) |

### Plugin Runtime

| Capability | Repo usage | Validation | Official docs |
|---|---|---|---|
| plugin manifest at `.claude-plugin/plugin.json` | plugin packaging metadata | Validated | [Plugins reference](https://code.claude.com/docs/en/plugins-reference) |
| plugin may ship `agents/` | teammate definitions packaged with CC Teams | Validated | [Plugins reference](https://code.claude.com/docs/en/plugins-reference) |
| plugin may ship `skills/` | reusable skill modules packaged with CC Teams | Validated | [Plugins reference](https://code.claude.com/docs/en/plugins-reference) |
| plugin may ship `hooks/` | repo-distributed hook wrappers/scripts | Validated | [Plugins reference](https://code.claude.com/docs/en/plugins-reference) |
| plugin `settings.json` is documented for default agent settings only | repo does not rely on plugin settings auto-loading hook config | Validated | [Plugins reference](https://code.claude.com/docs/en/plugins-reference) |

### Session Context And MCP

| Capability | Repo usage | Validation | Official docs |
|---|---|---|---|
| project and user MCP servers remain available to teammates from normal session context | lead MCP doctrine and teammate prompts | Validated | [Agent Teams](https://code.claude.com/docs/en/agent-teams) |
| plugin/project/user skills available in session context can be used by teammates | SKILL_HINTS + explicit `Skill()` flow | Validated | [Agent Teams](https://code.claude.com/docs/en/agent-teams) |

### Hooks

| Capability | Repo usage | Validation | Official docs |
|---|---|---|---|
| `TeammateIdle` | Router Contract idle gate | Validated | [Hooks](https://code.claude.com/docs/en/hooks) |
| `TaskCreated` | identity-stamp creation gate | Validated | [Hooks](https://code.claude.com/docs/en/hooks) |
| `TaskCompleted` | completion guard | Validated | [Hooks](https://code.claude.com/docs/en/hooks) |
| `SessionStart` | resume context injection | Validated | [Hooks](https://code.claude.com/docs/en/hooks) |
| `InstructionsLoaded` | instruction-audit logging | Validated | [Hooks](https://code.claude.com/docs/en/hooks) |
| `PreCompact` | checkpoint preparation | Validated | [Hooks](https://code.claude.com/docs/en/hooks) |
| `PostCompact` | compaction telemetry | Validated | [Hooks](https://code.claude.com/docs/en/hooks) |
| `Stop` | stop snapshot persistence | Validated | [Hooks](https://code.claude.com/docs/en/hooks) |
| `StopFailure` | stop failure logging | Validated | [Hooks](https://code.claude.com/docs/en/hooks) |
| `WorktreeCreate` | custom worktree creation and memory sync | Validated | [Hooks](https://code.claude.com/docs/en/hooks) |
| `WorktreeCreate` replaces Claude Code's default worktree behavior when installed | repo custom worktree creation hook | Validated | [Hooks](https://code.claude.com/docs/en/hooks) |
| `WorktreeCreate` must print the created worktree absolute path to stdout | repo hook output contract | Validated | [Hooks](https://code.claude.com/docs/en/hooks) |
| exit code `2` feeds feedback / blocks event for `TeammateIdle`, `TaskCreated`, `TaskCompleted` | guard behavior | Validated | [Hooks](https://code.claude.com/docs/en/hooks) |
| hook scripts should resolve from `CLAUDE_PROJECT_DIR` | path-safe hook runtime | Validated | [Hooks](https://code.claude.com/docs/en/hooks) |

### Internal Tools Used In Agent Definitions

| Capability | Repo usage | Validation | Official docs |
|---|---|---|---|
| `AskUserQuestion` | clarification gates | Validated | [Tools reference](https://code.claude.com/docs/en/tools-reference) |
| `WebFetch` | external fetch/research in selected roles | Validated | [Tools reference](https://code.claude.com/docs/en/tools-reference) |
| `Skill` | SKILL_HINTS flow | Validated | [Tools reference](https://code.claude.com/docs/en/tools-reference) |
| `LSP` | code intelligence in multiple roles | Validated | [Tools reference](https://code.claude.com/docs/en/tools-reference) |

## Unsupported Or Undocumented Claims Removed

These were intentionally removed or downgraded because they were not verified in the official Claude Code docs:

1. `CLAUDE_CODE_TASK_LIST_ID` as a documented contract for cross-session task-list sharing
2. relying on hook `cwd` instead of `CLAUDE_PROJECT_DIR`
3. assuming subagent-definition `skills:` or `mcpServers:` frontmatter applies automatically when the definition runs as an Agent Teams teammate
4. assuming plugin `settings.json` auto-applies hook configuration when the plugin is present

## Repo Enforcement

This validation is backed by:

1. [settings.json](/Users/rom.iluz/Dev/cc10x_v5/cc100x/plugins/cc-teams/settings.json)
2. [cc-teams-lead/SKILL.md](/Users/rom.iluz/Dev/cc10x_v5/cc100x/plugins/cc-teams/skills/cc-teams-lead/SKILL.md)
3. [check-cc-teams-workflow-replay.py](/Users/rom.iluz/Dev/cc10x_v5/cc100x/scripts/check-cc-teams-workflow-replay.py)
4. [lint-cc-teams-hook-runtime.sh](/Users/rom.iluz/Dev/cc10x_v5/cc100x/scripts/lint-cc-teams-hook-runtime.sh)

This file should be updated whenever CC Teams adopts a new Claude Code capability or changes how an existing one is used.
