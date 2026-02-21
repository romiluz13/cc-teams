# Agent Teams - Complete Official Documentation

> **Source**: `docs.anthropic.com/en/docs/claude-code/agent-teams` (fetched Feb 21, 2026)
> **Status**: Experimental, disabled by default
> **Enable**: `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` in settings.json env
> **Latest CLI**: v2.1.50

---

## What Agent Teams Are

Agent teams coordinate **multiple independent Claude Code sessions** working together. One session acts as the **team lead**, coordinating work, assigning tasks, and synthesizing results. **Teammates** work independently, each in its own context window, and communicate **directly with each other**.

Unlike subagents (which run within a single session and can only report back to the main agent), you can interact with individual teammates directly without going through the lead.

---

## When To Use Agent Teams

**Strongest use cases:**
- **Research and review**: multiple teammates investigate different aspects simultaneously, then share and challenge each other's findings
- **New modules or features**: teammates each own a separate piece without stepping on each other
- **Debugging with competing hypotheses**: teammates test different theories in parallel and converge faster
- **Cross-layer coordination**: changes spanning frontend, backend, and tests, each owned by a different teammate

**When NOT to use (prefer single session or subagents):**
- Sequential tasks
- Same-file edits
- Work with many dependencies
- Routine/simple tasks

---

## Subagents vs. Agent Teams

| Dimension | Subagents | Agent Teams |
|-----------|-----------|-------------|
| **Context** | Own context window; results return to the caller | Own context window; fully independent |
| **Communication** | Report results back to main agent **only** | Teammates message each other **directly** |
| **Coordination** | Main agent manages all work | Shared task list with **self-coordination** |
| **Best for** | Focused tasks where only the result matters | Complex work requiring discussion and collaboration |
| **Token cost** | **Lower**: results summarized back to main context | **Higher**: each teammate is a separate Claude instance |

**Decision rule**: Use subagents when you need quick, focused workers that report back. Use agent teams when teammates need to share findings, challenge each other, and coordinate on their own.

---

## Enable Agent Teams

Disabled by default. Enable via settings.json:

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

Or shell environment: `export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`

---

## Starting a Team

Tell Claude in natural language to create an agent team:

```
I'm designing a CLI tool that helps developers track TODO comments across
their codebase. Create an agent team to explore this from different angles: one
teammate on UX, one on technical architecture, one playing devil's advocate.
```

Claude then:
1. Creates a team with a shared task list
2. Spawns teammates for each perspective
3. Has them explore the problem
4. Synthesizes findings
5. Cleans up the team when finished

**Two ways teams start:**
1. **You request a team**: explicitly ask for an agent team
2. **Claude proposes a team**: Claude suggests a team if it determines the task would benefit from parallel work. You confirm before it proceeds.

Claude will NOT create a team without your approval.

---

## Architecture

| Component | Role |
|-----------|------|
| **Team Lead** | Main Claude Code session. Creates team, spawns teammates, coordinates work. |
| **Teammates** | Separate Claude Code instances. Each works on assigned tasks. Own context window. |
| **Task List** | Shared list of work items. Teammates claim and complete tasks. |
| **Mailbox** | Messaging system for inter-agent communication. Messages delivered automatically. |

**Storage locations:**
- Team config: `~/.claude/teams/{team-name}/config.json`
- Task list: `~/.claude/tasks/{team-name}/`

The team config contains a `members` array with each teammate's name, agent ID, and agent type. Teammates can read this file to discover other team members.

Task dependencies managed automatically. When a teammate completes a task that others depend on, blocked tasks unblock without manual intervention.

---

## Display Modes

| Mode | Description | Setup Required |
|------|-------------|----------------|
| **In-process** | All teammates run inside main terminal. Shift+Up/Down to select. | None. Works in any terminal. |
| **Split panes** | Each teammate gets its own tmux/iTerm2 pane. See all output at once. | Requires tmux or iTerm2. |
| **Auto** (default) | Uses split panes if in tmux session, in-process otherwise. | - |

**Configure:**
```json
{ "teammateMode": "in-process" }
```

**CLI override:** `claude --teammate-mode in-process`

**Split pane setup:**
- **tmux**: install via package manager (works best on macOS)
- **iTerm2**: install `it2` CLI + enable Python API (iTerm2 > Settings > General > Magic > Enable Python API)
- **tmux in iTerm2**: `tmux -CC` is the suggested entrypoint

**NOT supported for split panes**: VS Code integrated terminal, Windows Terminal, Ghostty.

---

## Controlling the Team

### Specify Teammates and Models

```
Create a team with 4 teammates to refactor these modules in parallel.
Use Sonnet for each teammate.
```

Claude decides the count based on the task, or you specify exactly.

### Plan Approval Mode

Require teammates to plan before implementing:

```
Spawn an architect teammate to refactor the authentication module.
Require plan approval before they make any changes.
```

**Flow:**
1. Teammate works in **read-only plan mode**
2. Finishes planning → sends plan approval request to lead
3. Lead reviews → approves or rejects with feedback
4. If rejected → teammate revises, resubmits
5. If approved → teammate exits plan mode, implements

Lead approves/rejects **autonomously**. Influence with criteria: "only approve plans that include test coverage" or "reject plans that modify the database schema."

### Delegate Mode

Prevents lead from implementing. Restricts to coordination-only: spawning, messaging, shutting down teammates, managing tasks.

**Enable**: Start team → press **Shift+Tab** to cycle into delegate mode.

**Use when**: lead should focus entirely on orchestration (breaking down work, assigning tasks, synthesizing results) without touching code.

### Talk to Teammates Directly

Each teammate is a full, independent Claude Code session.

**In-process mode:**
| Action | Shortcut |
|--------|----------|
| Cycle through teammates | **Shift+Down** (wraps back to lead) |
| Send message to selected | **Type** |
| View teammate's session | **Enter** |
| Interrupt current turn | **Escape** |
| Toggle task list | **Ctrl+T** |
| Kill all background agents | **Ctrl+F** (two-press confirmation) |

> **Changed in v2.1.47**: Simplified to Shift+Down only (with wrapping). Shift+Up removed.

**Split-pane mode:** Click into a teammate's pane to interact directly.

---

## Enforce Quality Gates with Hooks

Use hooks to enforce rules when teammates finish work or tasks complete (added v2.1.33):

| Hook | Trigger | Effect of exit code 2 |
|------|---------|----------------------|
| **`TeammateIdle`** | Teammate about to go idle | Sends stderr as feedback; teammate keeps working |
| **`TaskCompleted`** | Task being marked complete | Prevents completion; sends stderr feedback to model |

`TeammateIdle` fires on every occurrence (no matchers). Input includes `teammate_name` and `team_name`.

`TaskCompleted` fires when a task is marked via `TaskUpdate` or when a teammate finishes with in-progress tasks. Input includes `task_id`, `task_subject`, and optionally `task_description`, `teammate_name`, `team_name`.

**Example `TeammateIdle` hook** (require build artifact before going idle):
```bash
#!/bin/bash
if [ ! -f "./dist/output.js" ]; then
  echo "Build artifact missing. Run the build before stopping." >&2
  exit 2
fi
exit 0
```

Other hooks added after v2.1.32:
- **`ConfigChange`** (v2.1.49): fires when config files change during a session — useful for enterprise auditing
- **`WorktreeCreate`** / **`WorktreeRemove`** (v2.1.50): fires when worktree isolation creates/removes worktrees — replaces default git behavior

---

## Worktree Isolation for Agents

Added v2.1.49-v2.1.50. Agents can run in isolated git worktrees:

```bash
# Start Claude in an isolated worktree
claude --worktree  # or -w
```

Agent definitions support declarative isolation:
```yaml
---
isolation: worktree
---
```

Subagents launched via `Task` tool also support `isolation: "worktree"` parameter. Hooks `WorktreeCreate` and `WorktreeRemove` fire during worktree lifecycle.

**`background: true` in agent definitions** (v2.1.49): agents always run as background tasks when defined with this field.

---

## Task System

Shared task list coordinates work. Tasks have 3 states: **pending**, **in progress**, **completed**. Tasks can depend on other tasks (blocked until dependencies completed).

**Assignment modes:**
- **Lead assigns**: tell lead which task for which teammate
- **Self-claim**: teammate picks up next unassigned, unblocked task after finishing

**Race condition safety**: Task claiming uses **file locking** to prevent simultaneous claims.

---

## Communication

Each teammate has its own context window. When spawned, loads same project context: **CLAUDE.md, MCP servers, skills**. Also receives spawn prompt from lead. **Lead's conversation history does NOT carry over.**

**Information sharing:**
| Mechanism | Description |
|-----------|-------------|
| Automatic message delivery | Messages delivered automatically. Lead doesn't poll. |
| Idle notifications | Teammate notifies lead when finished. |
| Shared task list | All agents see task status, claim available work. |

**Message types:**
| Type | Description | Cost |
|------|-------------|------|
| **message** | Send to one specific teammate | Single recipient |
| **broadcast** | Send to ALL teammates | Costs scale with team size. Use sparingly. |

---

## Permissions

- Teammates start with **lead's permission settings**
- `--dangerously-skip-permissions` on lead → all teammates too
- Can change individual teammate modes **after** spawning
- **Cannot** set per-teammate modes at spawn time

---

## Token Usage

Significantly more tokens than single session. Each teammate has own context window. Usage scales with active teammate count.

**Worth it**: research, review, new feature work (parallel exploration adds value)
**Not worth it**: routine tasks, simple fixes

---

## Best Practices

### 1. Give Teammates Enough Context
Teammates load project context (CLAUDE.md, MCP, skills) but **NOT** lead's conversation history. Include task-specific details in spawn prompt:

```
Spawn a security reviewer teammate with the prompt: "Review the authentication module
at src/auth/ for security vulnerabilities. Focus on token handling, session
management, and input validation. The app uses JWT tokens stored in
httpOnly cookies. Report any issues with severity ratings."
```

### 2. Size Tasks Appropriately
| Size | Assessment |
|------|------------|
| Too small | Coordination overhead exceeds benefit |
| Too large | Teammates work too long without check-ins, risk of wasted effort |
| Just right | Self-contained, clear deliverable (function, test file, review) |

**5-6 tasks per teammate** keeps everyone productive. Lets lead reassign if stuck.

### 3. Wait for Teammates to Finish
Lead sometimes implements instead of waiting:
```
Wait for your teammates to complete their tasks before proceeding
```

### 4. Start with Research and Review
Clear boundaries, no code writing → shows value without coordination challenges.

### 5. Avoid File Conflicts
**Two teammates editing same file = overwrites.** Each teammate owns different file set.

### 6. Monitor and Steer
Check in on progress, redirect bad approaches, synthesize findings. Don't run unattended too long.

---

## Use Case Examples

### Parallel Code Review
```
Create an agent team to review PR #142. Spawn three reviewers:
- One focused on security implications
- One checking performance impact
- One validating test coverage
Have them each review and report findings.
```
Each reviewer applies a different filter to the same PR. Lead synthesizes across all three.

### Competing Hypothesis Investigation
```
Users report the app exits after one message instead of staying connected.
Spawn 5 agent teammates to investigate different hypotheses. Have them talk to
each other to try to disprove each other's theories, like a scientific
debate. Update the findings doc with whatever consensus emerges.
```

**Key insight**: Sequential investigation suffers from anchoring (bias toward first theory explored). Multiple independent investigators actively disproving each other → surviving theory much more likely to be actual root cause.

### Other strong cases:
- **New modules/features**: each teammate owns separate piece
- **Cross-layer coordination**: frontend/backend/tests each owned by different teammate

---

## Shutdown and Cleanup

### Shut Down Teammates
```
Ask the researcher teammate to shut down
```
Lead sends request. Teammate can approve (exit) or reject with explanation.

### Clean Up Team
```
Clean up the team
```
Removes shared team resources. **Fails if teammates still running** → shut them down first. **Always use the lead to clean up** (teammate cleanup may leave resources inconsistent).

---

## Known Limitations (Updated Feb 21, 2026 — v2.1.50)

| Limitation | Details |
|-----------|---------|
| **No session resumption** | `/resume` and `/rewind` don't restore in-process teammates. Lead may message non-existent teammates. Tell lead to spawn new ones. |
| **Task status can lag** | Teammates sometimes forget to mark tasks completed → blocks dependents. Check manually or tell lead to nudge. |
| **Shutdown can be slow** | Teammates finish current request/tool call before shutting down. |
| **One team per session** | Clean up current team before starting new one. |
| **No nested teams** | Teammates cannot spawn their own teams. Only lead manages team. |
| **Lead is fixed** | Creator session = lead for lifetime. Cannot promote teammate or transfer leadership. |
| **Permissions at spawn** | All start with lead's mode. Can change after, not at spawn time. |
| **Split panes need tmux/iTerm2** | In-process works anywhere. Split panes not in VS Code terminal, Windows Terminal, Ghostty. |

**CLAUDE.md works normally**: teammates read CLAUDE.md from their working directory.

**Resolved issues (post-Feb 5)**:
- Fixed Agent Teams using wrong model identifier for Bedrock/Vertex/Foundry (v2.1.41)
- Fixed agent teammate sessions in tmux to send and receive messages (v2.1.33)
- Fixed custom agent `model` field in `.claude/agents/*.md` being ignored when spawning team teammates (v2.1.47)
- Fixed memory leak where completed teammate tasks were never garbage collected (v2.1.50)
- Fixed Agent Teams teammates failing on Bedrock/Vertex/Foundry (v2.1.45)

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Teammates not appearing | Press Shift+Down to cycle. Check task complexity. Verify tmux: `which tmux`. For iTerm2: verify `it2` CLI + Python API enabled. |
| Too many permission prompts | Pre-approve common operations in permission settings before spawning. |
| Teammates stopping on errors | Check output via Shift+Up/Down or pane click. Give instructions or spawn replacement. |
| Lead shuts down early | Tell it to keep going. Tell it to wait for teammates. |
| Orphaned tmux sessions | `tmux ls` then `tmux kill-session -t <name>` |

---

## Configuration Reference

| Setting | Location | Values | Purpose |
|---------|----------|--------|---------|
| `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` | env / settings.json | `"1"` | Enable feature |
| `teammateMode` | settings.json | `"auto"` / `"in-process"` / `"tmux"` | Display mode |
| `--teammate-mode` | CLI flag | `in-process` | Per-session override |
| `--worktree` / `-w` | CLI flag | — | Start in isolated git worktree (v2.1.49) |
| `isolation: worktree` | agent definition frontmatter | — | Declarative worktree isolation (v2.1.50) |
| `background: true` | agent definition frontmatter | — | Always run as background task (v2.1.49) |
| `memory` | agent definition frontmatter | `user`/`project`/`local` | Persistent agent memory (v2.1.33) |
| `CLAUDE_CODE_DISABLE_1M_CONTEXT` | env | `1` | Disable 1M context window support (v2.1.50) |
| Team config | `~/.claude/teams/{name}/config.json` | JSON | Team member registry |
| Task list | `~/.claude/tasks/{name}/` | Files | Shared task state |

**New CLI command** (v2.1.50): `claude agents` — lists all configured agents.

---

## Related Approaches

- **Subagents** (`/docs/en/sub-agents`): lightweight delegation, no inter-agent coordination needed
- **Git worktrees** (`/docs/en/common-workflows#git-worktrees`): manual parallel sessions without automated coordination
- **Feature comparison** (`/docs/en/features-overview#compare-similar-features`): side-by-side breakdown
