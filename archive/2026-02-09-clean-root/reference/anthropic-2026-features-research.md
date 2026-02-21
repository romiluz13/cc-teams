# Anthropic Claude Code Features Research (2026)

> **⚠️ ARCHIVED:** External reference material about Claude Code capabilities.
> Not CC10x-specific. Kept for historical context on Claude Code features.
>
> For CC10x specification, see `cc10x-orchestration-bible.md`.

---

**Last Updated**: February 21, 2026 (latest CLI: v2.1.50)
**Purpose**: External reference for Claude Code features and capabilities (not CC10x-specific)

---

## February 2026 Releases (Post-Launch Updates — v2.1.33 through v2.1.50)

### TeammateIdle + TaskCompleted Hooks (v2.1.33)

**Quality gates for multi-agent workflows.**

Two new hook events enable enforcement of completion criteria before agents stop or tasks close:

| Hook | Fires when | Exit code 2 effect |
|------|-----------|-------------------|
| `TeammateIdle` | Teammate about to go idle | Sends stderr feedback; teammate stays working |
| `TaskCompleted` | Task being marked complete | Prevents completion; feeds stderr to model |

**`TeammateIdle` input**: common fields + `teammate_name`, `team_name`
**`TaskCompleted` input**: common fields + `task_id`, `task_subject`, optionally `task_description`, `teammate_name`, `team_name`

Neither hook supports matchers — both fire on every occurrence.

Also in v2.1.33:
- Fixed agent teammate sessions in tmux to send/receive messages
- Added `Task(agent_type)` syntax for restricting which sub-agents can be spawned
- Added `memory` frontmatter for agents (`user`/`project`/`local` scope)

---

### Worktree Isolation (v2.1.49-v2.1.50)

**Isolated git worktrees for agents and subagents.**

- `--worktree` / `-w` flag: start Claude in an isolated git worktree
- `isolation: "worktree"` in subagent Task calls: subagent works in a temporary worktree
- `isolation: worktree` in agent definition frontmatter: declarative worktree isolation
- `background: true` in agent definition frontmatter: agent always runs as background task

New hooks for worktree lifecycle:
- `WorktreeCreate` (v2.1.50): fires when worktree created via `--worktree` or `isolation: "worktree"`. Replaces default git behavior.
- `WorktreeRemove` (v2.1.50): fires when worktree removed at session exit or subagent finish.

---

### Additional New Hooks (v2.1.49-v2.1.50)

- `ConfigChange` (v2.1.49): fires when configuration files change during a session. Useful for enterprise security auditing. Can optionally block settings changes.
- `PostToolUseFailure`: fires after a tool call fails
- `PermissionRequest`: fires when a permission dialog appears
- `SubagentStart`: fires when a subagent is spawned
- `PreCompact`: fires before context compaction
- `SessionEnd`: fires when a session terminates

---

### Sonnet 4.6 + Fast Mode (v2.1.45, v2.1.36)

- Claude Sonnet 4.6 added (v2.1.45) — Sonnet 4.5 with 1M context being removed from Max plan
- Fast mode for Opus 4.6 available (v2.1.36) — now includes full 1M context window (v2.1.50)
- `CLAUDE_CODE_DISABLE_1M_CONTEXT` env var to disable 1M context support

---

### Simplified Teammate Navigation (v2.1.47)

**Changed**: Shifted to Shift+Down only (with wrapping) for cycling teammates. Shift+Up removed.

Also in v2.1.47:
- Fixed custom agent `model` field in `.claude/agents/*.md` being ignored when spawning team teammates
- Added `last_assistant_message` field to Stop and SubagentStop hook inputs
- Ctrl+F to kill all background agents (two-press confirmation)

---

### `claude agents` CLI Command (v2.1.50)

Lists all configured agents:
```bash
claude agents
```

---

### Agent Teams Bug Fixes (Post-Feb 5)

| Version | Fix |
|---------|-----|
| v2.1.33 | Fixed agent teammate sessions in tmux not sending/receiving messages |
| v2.1.33 | Fixed warnings about agent teams not being available on your plan |
| v2.1.34 | Fixed crash when agent teams setting changed between renders |
| v2.1.41 | Fixed Agent Teams using wrong model identifier for Bedrock/Vertex/Foundry |
| v2.1.45 | Fixed Agent Teams teammates failing on Bedrock/Vertex/Foundry (env var propagation to tmux) |
| v2.1.47 | Fixed custom agent `model` field being ignored when spawning team teammates |
| v2.1.50 | Fixed memory leak where completed teammate tasks were never garbage collected |

---

### Other Notable v2.1.28-v2.1.50 Features

| Version | Feature |
|---------|---------|
| v2.1.30 | `pages` param for Read tool on PDFs; token count + tool metrics in Task results |
| v2.1.32 | Agent Teams launch; automatic memory recording and recall |
| v2.1.41 | `claude auth login/status/logout` CLI subcommands; Windows ARM64 support |
| v2.1.42 | Improved prompt cache hit rates by moving date out of system prompt |
| v2.1.45 | claude.ai MCP connectors support in Claude Code |
| v2.1.49 | Plugins can ship `settings.json` for default configuration |
| v2.1.50 | `CLAUDE_CODE_SIMPLE` disables MCP tools, attachments, hooks, CLAUDE.md loading |

---

## February 5, 2026 Release - Agent Teams (Research Preview)

> **Source**: Official Anthropic docs at `code.claude.com/docs/en/agent-teams`, Anthropic blog post `anthropic.com/news/claude-opus-4-6`, TechCrunch reporting.
> **Status**: Experimental, disabled by default.
> **Availability**: Claude Code (CLI). Requires opt-in.

---

### What Agent Teams Are

Agent Teams let you coordinate **multiple independent Claude Code sessions** working together. One session acts as the **team lead** (coordinator), and the others are **teammates** (workers). Each teammate is a full, independent Claude Code instance with its own context window.

This is fundamentally different from subagents:
- **Subagents** (the `Task` tool): fork context, do work, return results to the parent. One-way communication. Parent controls everything.
- **Agent Teams**: each teammate is an independent session. Teammates can **message each other directly** (peer-to-peer). They share a task list and self-coordinate.

---

### Architecture

An agent team consists of 4 components:

| Component | Role |
|-----------|------|
| **Team Lead** | The main Claude Code session that creates the team, spawns teammates, and coordinates work. |
| **Teammates** | Separate Claude Code instances that each work on assigned tasks. Each has its own context window. |
| **Task List** | Shared list of work items that teammates claim and complete. Stored at `~/.claude/tasks/{team-name}/`. |
| **Mailbox** | Messaging system for communication between agents. Messages delivered automatically. |

**Storage locations:**
- Team config: `~/.claude/teams/{team-name}/config.json`
- Task list: `~/.claude/tasks/{team-name}/`

The team config contains a `members` array with each teammate's name, agent ID, and agent type. Teammates can read this file to discover other team members.

---

### How To Enable

Agent Teams are **disabled by default**. Enable via environment variable or settings.json:

**Option 1 - settings.json:**
```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

**Option 2 - Shell environment:**
```bash
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
```

---

### How To Start a Team

Tell Claude in natural language to create an agent team. Describe the task and team structure:

```
Create an agent team to review PR #142. Spawn three reviewers:
- One focused on security implications
- One checking performance impact
- One validating test coverage
Have them each review and report findings.
```

Claude then:
1. Creates a team with a shared task list
2. Spawns teammates for each role
3. Has them explore the problem
4. Synthesizes findings
5. Cleans up the team when finished

**Two ways teams start:**
1. **You request a team**: explicitly ask for an agent team.
2. **Claude proposes a team**: Claude determines the task would benefit from parallel work and suggests creating a team. You confirm before it proceeds.

Claude will NOT create a team without your approval.

---

### Subagents vs. Agent Teams (Official Comparison)

| Dimension | Subagents (`Task` tool) | Agent Teams |
|-----------|------------------------|-------------|
| **Context** | Own context window; results return to the caller | Own context window; fully independent |
| **Communication** | Report results back to the main agent **only** | Teammates message each other **directly** |
| **Coordination** | Main agent manages all work | Shared task list with **self-coordination** |
| **Best for** | Focused tasks where only the result matters | Complex work requiring discussion and collaboration |
| **Token cost** | **Lower**: results summarized back to main context | **Higher**: each teammate is a separate Claude instance |

**Official guidance**: "Use subagents when you need quick, focused workers that report back. Use agent teams when teammates need to share findings, challenge each other, and coordinate on their own."

---

### Display Modes

Agent teams support two display modes:

| Mode | Description | Setup |
|------|-------------|-------|
| **In-process** (default) | All teammates run inside your main terminal. Use Shift+Up/Down to select a teammate. | No extra setup. Works in any terminal. |
| **Split panes** | Each teammate gets its own tmux/iTerm2 pane. See everyone's output at once. | Requires tmux or iTerm2. |

**Auto mode** (default `"auto"`): uses split panes if already in tmux session, in-process otherwise.

**Configure in settings.json:**
```json
{
  "teammateMode": "in-process"
}
```

**Or per-session flag:**
```bash
claude --teammate-mode in-process
```

**Split pane requirements:**
- **tmux**: install via package manager (see tmux wiki for platform instructions)
- **iTerm2**: install `it2` CLI, enable Python API in iTerm2 > Settings > General > Magic > Enable Python API
- **NOT supported**: VS Code integrated terminal, Windows Terminal, Ghostty

---

### Controlling the Team

#### Specifying Teammates and Models

Claude decides how many teammates to spawn based on the task, or you can specify:

```
Create a team with 4 teammates to refactor these modules in parallel.
Use Sonnet for each teammate.
```

#### Plan Approval Mode

Require teammates to plan before implementing. Teammate works in **read-only plan mode** until lead approves:

```
Spawn an architect teammate to refactor the authentication module.
Require plan approval before they make any changes.
```

**Flow:**
1. Teammate finishes planning → sends plan approval request to lead
2. Lead reviews plan → approves or rejects with feedback
3. If rejected → teammate stays in plan mode, revises, resubmits
4. If approved → teammate exits plan mode, begins implementation

**Lead makes approval decisions autonomously.** Influence with criteria in prompt: "only approve plans that include test coverage" or "reject plans that modify the database schema."

#### Delegate Mode

Prevents the lead from implementing tasks itself. Restricts lead to coordination-only tools: spawning, messaging, shutting down teammates, and managing tasks.

**Enable**: Start a team first, then press **Shift+Tab** to cycle into delegate mode.

**Use when**: you want the lead to focus entirely on orchestration (breaking down work, assigning tasks, synthesizing results) without touching code directly.

---

### Talking to Teammates Directly

Each teammate is a full, independent Claude Code session. You can message any teammate directly.

**In-process mode:**
- **Shift+Up/Down**: Select a teammate
- **Type**: Send message to selected teammate
- **Enter**: View a teammate's session
- **Escape**: Interrupt their current turn
- **Ctrl+T**: Toggle the task list

**Split-pane mode:**
- Click into a teammate's pane to interact with their session directly
- Each teammate has a full view of their own terminal

---

### Task System Within Agent Teams

The shared task list coordinates work across the team. Tasks have three states: **pending**, **in progress**, **completed**. Tasks can depend on other tasks (pending task with unresolved dependencies cannot be claimed until dependencies are completed).

**Task assignment:**
- **Lead assigns**: tell the lead which task to give to which teammate
- **Self-claim**: after finishing a task, a teammate picks up the next unassigned, unblocked task on its own

**Race condition safety**: Task claiming uses **file locking** to prevent race conditions when multiple teammates try to claim the same task simultaneously.

**Dependency management**: The system manages task dependencies automatically. When a teammate completes a task that other tasks depend on, blocked tasks unblock without manual intervention.

---

### Communication Between Agents

Each teammate has its own context window. When spawned, a teammate loads the same project context as a regular session: **CLAUDE.md, MCP servers, and skills**. It also receives the spawn prompt from the lead. **The lead's conversation history does NOT carry over.**

**How teammates share information:**

| Mechanism | Description |
|-----------|-------------|
| **Automatic message delivery** | When teammates send messages, they're delivered automatically. Lead doesn't need to poll. |
| **Idle notifications** | When a teammate finishes and stops, they automatically notify the lead. |
| **Shared task list** | All agents can see task status and claim available work. |

**Teammate messaging types:**

| Type | Description | Cost note |
|------|-------------|-----------|
| **message** | Send to one specific teammate | Single recipient |
| **broadcast** | Send to ALL teammates simultaneously | Costs scale with team size. Use sparingly. |

---

### Enforce Quality Gates with Hooks (v2.1.33+)

Use hooks to enforce rules at key agent lifecycle points:

- **`TeammateIdle`**: runs when a teammate is about to go idle. Exit code 2 sends stderr as feedback and keeps teammate working.
- **`TaskCompleted`**: runs when a task is being marked complete. Exit code 2 prevents completion and sends feedback to the model.

Configure in `settings.json` under `hooks.TeammateIdle` or `hooks.TaskCompleted`.

---

### Shutting Down Teammates

Gracefully end a teammate's session:
```
Ask the researcher teammate to shut down
```

The lead sends a shutdown request. The teammate can **approve** (exits gracefully) or **reject** with an explanation.

### Cleaning Up the Team

```
Clean up the team
```

This removes the shared team resources.

**Rules:**
- Lead checks for active teammates. **Fails if any are still running** - shut them down first.
- **Always use the lead to clean up.** Teammates should NOT run cleanup because their team context may not resolve correctly, potentially leaving resources in an inconsistent state.

---

### Permissions

- Teammates start with the **lead's permission settings**
- If the lead runs with `--dangerously-skip-permissions`, all teammates do too
- After spawning, you CAN change individual teammate modes
- You CANNOT set per-teammate modes at spawn time

---

### Token Usage

Agent teams use **significantly more tokens** than a single session. Each teammate has its own context window, and token usage scales with the number of active teammates.

**When worth it**: research, review, new feature work (parallel exploration adds value)
**When not worth it**: routine tasks, simple fixes (single session more cost-effective)

---

### Best Practices (From Official Docs)

#### 1. Give Teammates Enough Context

Teammates load project context automatically (CLAUDE.md, MCP, skills) but **do NOT inherit the lead's conversation history**. Include task-specific details in the spawn prompt:

```
Spawn a security reviewer teammate with the prompt: "Review the authentication module
at src/auth/ for security vulnerabilities. Focus on token handling, session
management, and input validation. The app uses JWT tokens stored in
httpOnly cookies. Report any issues with severity ratings."
```

#### 2. Size Tasks Appropriately

| Size | Assessment |
|------|------------|
| Too small | Coordination overhead exceeds the benefit |
| Too large | Teammates work too long without check-ins, increasing risk of wasted effort |
| Just right | Self-contained units that produce a clear deliverable (a function, a test file, a review) |

**Tip**: If the lead isn't creating enough tasks, ask it to split work into smaller pieces. **5-6 tasks per teammate** keeps everyone productive and lets the lead reassign work if someone gets stuck.

#### 3. Wait for Teammates to Finish

Sometimes the lead starts implementing tasks itself instead of waiting. If you notice this:
```
Wait for your teammates to complete their tasks before proceeding
```

#### 4. Start with Research and Review

For new users: start with tasks that have clear boundaries and don't require writing code (reviewing a PR, researching a library, investigating a bug). These show the value of parallel exploration without coordination challenges.

#### 5. Avoid File Conflicts

**Two teammates editing the same file leads to overwrites.** Break work so each teammate owns a different set of files.

#### 6. Monitor and Steer

Check in on teammates' progress, redirect approaches that aren't working, and synthesize findings as they come in. Letting a team run unattended for too long increases risk of wasted effort.

---

### Recommended Use Cases (From Official Docs)

#### Parallel Code Review

Split review criteria into independent domains so security, performance, and test coverage all get thorough attention simultaneously:

```
Create an agent team to review PR #142. Spawn three reviewers:
- One focused on security implications
- One checking performance impact
- One validating test coverage
Have them each review and report findings.
```

Each reviewer works from the same PR but applies a different filter. The lead synthesizes findings across all three after they finish.

#### Competing Hypothesis Investigation (Debugging)

When root cause is unclear, a single agent tends to find one plausible explanation and stop. Multiple investigators with an adversarial structure fight anchoring bias:

```
Users report the app exits after one message instead of staying connected.
Spawn 5 agent teammates to investigate different hypotheses. Have them talk to
each other to try to disprove each other's theories, like a scientific
debate. Update the findings doc with whatever consensus emerges.
```

**Key insight**: The debate structure is the mechanism. Sequential investigation suffers from anchoring (once one theory is explored, subsequent investigation is biased toward it). With multiple independent investigators actively trying to disprove each other, the surviving theory is much more likely to be the actual root cause.

#### Other Strong Use Cases (from official docs)

- **New modules or features**: teammates each own a separate piece without stepping on each other
- **Cross-layer coordination**: changes spanning frontend, backend, and tests, each owned by a different teammate

---

### Known Limitations (Official - Updated Feb 21, 2026)

| Limitation | Description |
|-----------|-------------|
| **No session resumption** | `/resume` and `/rewind` do NOT restore in-process teammates. After resuming, lead may message teammates that no longer exist. Tell lead to spawn new ones. |
| **Task status can lag** | Teammates sometimes fail to mark tasks as completed, which blocks dependent tasks. Check if work is done and update manually or tell lead to nudge. |
| **Shutdown can be slow** | Teammates finish their current request or tool call before shutting down. |
| **One team per session** | A lead can only manage one team at a time. Clean up current team before starting a new one. |
| **No nested teams** | Teammates cannot spawn their own teams or teammates. Only the lead can manage the team. |
| **Lead is fixed** | The session that creates the team is the lead for its lifetime. Cannot promote a teammate or transfer leadership. |
| **Permissions set at spawn** | All teammates start with lead's permission mode. Can change after spawning but not at spawn time. |
| **Split panes require tmux/iTerm2** | Default in-process mode works anywhere. Split-pane NOT supported in VS Code terminal, Windows Terminal, or Ghostty. |

---

### When NOT to Use Agent Teams

From official docs, agent teams add coordination overhead and use significantly more tokens. They work best when teammates can operate independently.

**Prefer a single session or subagents when:**
- Tasks are **sequential** (each step depends on the previous)
- Work involves **same-file edits** (risk of overwrites)
- Work has **many dependencies** between steps
- Tasks are routine/simple (coordination overhead not justified)

---

### Agent Teams vs. Manual Parallel Sessions

**Agent Teams** provide automated team coordination (shared task list, messaging, lead orchestration).

**Git worktrees** (`git worktree add`) let you run multiple Claude Code sessions manually without automated coordination. See official docs at `code.claude.com/docs/en/common-workflows#run-parallel-claude-code-sessions-with-git-worktrees`.

Agent Teams automate what you'd otherwise do manually with multiple terminal sessions.

---

### Configuration Reference Summary

| Setting | Location | Values | Purpose |
|---------|----------|--------|---------|
| `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` | env / settings.json | `"1"` | Enable agent teams feature |
| `teammateMode` | settings.json | `"auto"` / `"in-process"` / `"tmux"` | Display mode |
| `--teammate-mode` | CLI flag | `in-process` | Per-session display mode override |
| Team config | `~/.claude/teams/{team-name}/config.json` | JSON | Team member registry |
| Task list | `~/.claude/tasks/{team-name}/` | Files | Shared task state |

---

### Key Keyboard Shortcuts (In-Process Mode)

| Shortcut | Action |
|----------|--------|
| **Shift+Down** | Cycle through teammates (wraps back to lead). **Note**: Shift+Up removed in v2.1.47. |
| **Enter** | View selected teammate's session |
| **Escape** | Interrupt teammate's current turn (background agents keep running) |
| **Ctrl+T** | Toggle the task list |
| **Shift+Tab** | Cycle into delegate mode |
| **Ctrl+F** | Kill all background agents (two-press confirmation) — added v2.1.47/v2.1.49 |
| **Type** | Send message to selected teammate |

---

### Troubleshooting (From Official Docs)

| Problem | Solution |
|---------|----------|
| **Teammates not appearing** | In in-process mode, press Shift+Down to cycle through active teammates. Check task was complex enough to warrant a team. For split panes, verify `which tmux` resolves. For iTerm2, verify `it2` CLI installed and Python API enabled. |
| **Too many permission prompts** | Teammate permission requests bubble up to the lead. Pre-approve common operations in permission settings before spawning teammates. |
| **Teammates stopping on errors** | Check their output via Shift+Up/Down or click pane. Give additional instructions directly, or spawn a replacement teammate. |
| **Lead shuts down before work is done** | Tell it to keep going. Also tell lead to wait for teammates to finish before proceeding if it starts doing work instead of delegating. |
| **Orphaned tmux sessions** | `tmux ls` to list sessions, then `tmux kill-session -t <session-name>` to clean up. |

---

### Official Documentation Links

- Agent Teams docs: `code.claude.com/docs/en/agent-teams`
- Subagents docs: `code.claude.com/docs/en/sub-agents`
- Announcement blog post: `anthropic.com/news/claude-opus-4-6`
- Agent team token costs: `code.claude.com/docs/en/costs#agent-team-token-costs`
- Feature comparison: `code.claude.com/docs/en/features-overview#compare-similar-features`

---

## January 2026 Releases

### Tasks System (v2.1.16 - January 2026)

**Replaces TodoWrite completely.**

The old TodoWrite had critical issues:
- Overwrote entire lists (Bug #2250)
- No visibility across agents (Bug #1173)
- Shared state issues (Bug #1824)
- Memory-bound - vanished when sessions closed

**New Task Tools:**
- `TaskCreate` - Creates task with subject, description, activeForm
- `TaskUpdate` - Updates status, dependencies (blockedBy, blocks)
- `TaskGet` - Retrieves full task details
- `TaskList` - Lists all tasks with summary

**Key Features:**
| Feature | Description |
|---------|-------------|
| Dependency Graphs | Tasks support DAGs via `blockedBy`/`blocks` |
| Filesystem Persistence | Stored in `~/.claude/tasks` - survives crashes |
| Cross-Session Sharing | `CLAUDE_CODE_TASK_LIST_ID` env var shares state |
| Status Workflow | `pending` → `in_progress` → `completed` |
| Task Deletion | v2.1.20 added ability to delete tasks via TaskUpdate |

**Opt-out:** `CLAUDE_CODE_ENABLE_TASKS=false` (v2.1.19)

**Source:** [VentureBeat - Tasks Update](https://venturebeat.com/orchestration/claude-codes-tasks-update-lets-agents-work-longer-and-coordinate-across)

---

### MCP Tool Search (v2.1.0 - January 15, 2026)

**Lazy loading for MCP tools - 85% token reduction.**

**The Problem:**
- MCP servers have 50+ tools each
- Users had setups with 7+ servers consuming 67k+ tokens
- Single Docker MCP = 125,000 tokens for 135 tools
- 33%+ of context consumed before user typed anything

**How It Works:**
1. System monitors context usage
2. When tool definitions exceed 10% of context → switches to search mode
3. Loads lightweight search index instead of all definitions
4. Claude searches for tools on-demand when needed
5. Only relevant definitions loaded into context

**Performance:**
| Metric | Before | After |
|--------|--------|-------|
| Token usage | ~134k | ~5k |
| Opus 4 accuracy | 49% | 74% |
| Opus 4.5 accuracy | 79.5% | 88.1% |

**Developer Note:** The `server instructions` field in MCP definition is now critical for discoverability.

**Source:** [VentureBeat - Tool Search](https://venturebeat.com/orchestration/claude-code-just-got-updated-with-one-of-the-most-requested-user-features)

---

### Cowork Desktop (January 12, 2026)

**Claude Code capabilities for knowledge work - no coding required.**

- New tab in Claude Desktop app
- User designates a folder where Claude can read/modify files
- Runs in local VM for sandboxed execution
- Available to Pro subscribers (Jan 16), Team/Enterprise (Jan 23)

**Capabilities:**
- File creation, editing, organization
- Document processing and analysis
- Multi-source task delegation
- Works with local files without cloud upload

**Source:** [TechCrunch - Cowork](https://techcrunch.com/2026/01/12/anthropics-new-cowork-tool-offers-claude-code-without-the-code/)

---

### Claude in Chrome (Beta - v2.0.72)

**Browser control directly from Claude Code.**

- Works with Chrome extension (https://claude.ai/chrome)
- Control browser from terminal
- Navigate, click, extract content

---

### Recent Changelog Highlights (v2.1.17 - v2.1.50)

| Version | Key Features |
|---------|-------------|
| v2.1.50 | `WorktreeCreate`/`WorktreeRemove` hooks, `claude agents` CLI, memory leak fixes in agent teams, `CLAUDE_CODE_DISABLE_1M_CONTEXT` |
| v2.1.49 | `--worktree` flag, `isolation: "worktree"` for subagents, `ConfigChange` hook, `background: true` agent def, Ctrl+F kill agents |
| v2.1.47 | Shift+Down only teammate nav, `last_assistant_message` in Stop hooks, fix custom agent model field ignored |
| v2.1.45 | Sonnet 4.6 support, fix Agent Teams on Bedrock/Vertex/Foundry |
| v2.1.41 | `claude auth login/status/logout` subcommands, Windows ARM64, fix Agent Teams model ID on Bedrock |
| v2.1.36 | Fast mode for Opus 4.6 |
| v2.1.33 | `TeammateIdle` + `TaskCompleted` hooks, `memory` frontmatter for agents, `Task(agent_type)` restriction |
| v2.1.32 | **Agent Teams launch** (research preview), automatic memory recording/recall |
| v2.1.30 | `pages` param for PDF reading, token/tool metrics in Task results |
| v2.1.27 | `--from-pr` flag to resume sessions by PR, auto PR linking |
| v2.1.23 | Customizable spinner verbs, mTLS/proxy fixes |
| v2.1.21 | Python venv auto-activation, prefer Read/Edit over bash cat/sed |
| v2.1.20 | PR status indicator in footer, CLAUDE.md from `--add-dir` |
| v2.1.19 | CLAUDE_CODE_ENABLE_TASKS toggle, bracket arg syntax `$ARGUMENTS[0]` |
| v2.1.18 | Customizable keyboard shortcuts (`/keybindings`) |

---

## November 2025 Releases

### Programmatic Tool Calling (PTC)

**Claude writes Python to orchestrate multiple tools instead of one-by-one.**

**The Problem:**
- 10MB log file = entire file in context
- Each tool call = full model inference pass
- Manual synthesis of each result

**How It Works:**
1. Mark tools with `allowed_callers: ["code_execution_20250825"]`
2. Claude writes orchestration code (loops, conditionals, transforms)
3. Tool results processed in sandbox, NOT in Claude's context
4. Only final output enters context

**Performance:**
| Metric | Improvement |
|--------|-------------|
| Token usage | 37% reduction |
| Knowledge retrieval | 25.6% → 28.5% |

**Example:** Budget check - Traditional: 20 tool calls, 2000+ line items in context. With PTC: Python script processes all, only 1KB result in context.

**Source:** [Anthropic Engineering - Advanced Tool Use](https://www.anthropic.com/engineering/advanced-tool-use)

---

### Tool Use Examples

**Concrete examples in tool definitions showing correct usage.**

JSON Schema defines structure but NOT:
- Date format conventions (YYYY-MM-DD vs "Nov 6, 2024")
- ID patterns (UUID vs "USR-12345")
- When to use optional parameters

**API Implementation:**
```json
{
  "name": "create_ticket",
  "input_schema": {...},
  "input_examples": [
    {
      "title": "Login page returns 500 error",
      "priority": "critical",
      "labels": ["bug", "authentication"],
      "due_date": "2024-11-06"
    }
  ]
}
```

**Performance:** Complex parameter handling: 72% → 90%

---

### Background Agents

**Non-blocking agent execution.**

- Append `&` to commands for background execution
- Multiple agents work simultaneously
- Use `TaskOutput` to retrieve results later
- Ctrl+B keystroke for backgrounding (v2.1.0+)

---

## API Features (Beta)

### Memory Tool

**API-level memory persisting across conversations.**

- Beta Header: `context-management-2025-06-27`
- Create, read, update memory files
- Stored OUTSIDE context window
- Survives conversation restarts

---

### Context Editing & Compaction

**Server-side automatic context management.**

- System monitors token usage
- Approaching limits → generates summaries
- Older messages compacted
- Key information preserved

---

### Agent Skills (API)

**API-level skills beyond prompts.**

- Beta Headers: `code-execution-2025-08-25`, `skills-2025-10-02`
- Available across Claude.ai, Claude Code, Agent SDK

---

## Hooks System

| Hook Type | Trigger |
|-----------|---------|
| `SessionStart` | When session begins or resumes |
| `UserPromptSubmit` | Before Claude processes prompt |
| `PreToolUse` | Before tool execution (can block) |
| `PermissionRequest` | When a permission dialog appears |
| `PostToolUse` | After tool completes |
| `PostToolUseFailure` | After a tool call fails |
| `Notification` | When Claude sends a notification |
| `SubagentStart` | When a subagent is spawned |
| `SubagentStop` | When subagent completes |
| `Stop` | When Claude stops working |
| `TeammateIdle` | When agent team teammate about to go idle (v2.1.33) |
| `TaskCompleted` | When a task is being marked complete (v2.1.33) |
| `ConfigChange` | When config file changes during session (v2.1.49) |
| `WorktreeCreate` | When worktree created via `--worktree` or `isolation: "worktree"` (v2.1.50) |
| `WorktreeRemove` | When worktree removed at session exit or subagent finish (v2.1.50) |
| `PreCompact` | Before context compaction |
| `SessionEnd` | When a session terminates |

**Prompt-Based Hooks:** For Stop/SubagentStop - Claude makes intelligent, context-aware decisions.

**`TeammateIdle` and `TaskCompleted`** use exit codes only (no JSON decision control). Exit code 2 sends stderr as feedback and blocks the idle/completion.

---

## Model Updates

### Opus 4.5 (November 2025)
- Better memory utilization
- 50-75% reduction in tool calling errors
- Memory tool support
- Context editing support

### Sonnet 4.5 (September 2025)
- Default model for Claude Code
- Strong coding and tool use

### Haiku 4.5
- Robust coding at lower cost

---

## Key Environment Variables

| Variable | Purpose |
|----------|---------|
| `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` | Enable agent teams feature (set to `"1"`) |
| `CLAUDE_CODE_TASK_LIST_ID` | Share task state across sessions |
| `CLAUDE_CODE_ENABLE_TASKS` | Toggle new Tasks system (default: true) |
| `CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS` | Disable beta features |
| `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD` | Load CLAUDE.md from --add-dir paths |
| `CLAUDE_CODE_DISABLE_1M_CONTEXT` | Disable 1M context window support (v2.1.50) |
| `CLAUDE_CODE_SIMPLE` | Minimal mode: disables skills, memory, agents, MCP, hooks, CLAUDE.md (v2.1.50) |

---

## Research Sources

### Official
- [Claude Code CHANGELOG](https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md)
- [Claude Developer Platform Docs](https://platform.claude.com/docs)
- [Anthropic Engineering Blog](https://www.anthropic.com/engineering)

### News & Analysis
- [VentureBeat - Tool Search](https://venturebeat.com/orchestration/claude-code-just-got-updated-with-one-of-the-most-requested-user-features) (Jan 15, 2026)
- [VentureBeat - Tasks](https://venturebeat.com/orchestration/claude-codes-tasks-update-lets-agents-work-longer-and-coordinate-across) (Jan 26, 2026)
- [TechCrunch - Cowork](https://techcrunch.com/2026/01/12/anthropics-new-cowork-tool-offers-claude-code-without-the-code/) (Jan 12, 2026)

### Community
- [Releasebot - Claude Code](https://releasebot.io/updates/anthropic/claude-code)
- [ClaudeLog Changelog](https://www.claudelog.com/claude-code-changelog/)
- Reddit: r/ClaudeAI, r/ClaudeCode
