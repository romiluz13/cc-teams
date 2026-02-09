---
name: session-memory
description: "Internal skill. Use cc100x-lead for all development tasks."
allowed-tools: Read, Write, Edit, Bash
---

# Session Memory (MANDATORY)

## The Iron Law

```
EVERY WORKFLOW MUST:
1. LOAD memory at START (and before key decisions)
2. PERSIST learnings at END (direct edit by memory owner, or Memory Notes handoff to memory owner)
```

**Brevity Rule:** Memory is an index, not a document. Be brief—one line per item.

## Agent Teams Ownership Override (CC100x Default)

In CC100x team workflows, memory persistence is lead-owned by default:
- Teammates: read memory + emit `### Memory Notes (For Workflow-Final Persistence)`.
- Lead: executes the `CC100X Memory Update` task and writes `.claude/cc100x/*`.
- Only edit memory from a teammate if the prompt explicitly includes `MEMORY_OWNER: teammate`.

## What "Memory" Actually Is (The Guts)

CC100x memory is a **small, stable, permission-free Markdown database** used for:
- **Continuity:** survive compaction/session resets
- **Consistency:** avoid contradicting prior decisions
- **Compounding:** promote learnings into reusable patterns
- **Resumability:** recover where a workflow stopped

### Memory Surfaces (Types)

1. **Index / Working Memory**: `.claude/cc100x/activeContext.md`
   - "What matters right now": focus, next steps, active decisions, learnings
   - Links to durable artifacts (plans/research)
2. **Long-Term Project Memory**: `.claude/cc100x/patterns.md`
   - Conventions, architecture decisions, common gotchas, reusable solutions
3. **Progress + Evidence Memory**: `.claude/cc100x/progress.md`
   - What's done/remaining + verification evidence (commands + exit codes)
4. **Artifact Memory (Durable)**: `docs/plans/*`, `docs/research/*`
   - The details. Memory files are the index.
5. **Tasks (Execution State)**: Claude Code Tasks
   - Great for orchestration, but not guaranteed to be the only durable source.
   - Mirror key task subjects/status into `progress.md` for backup/resume.

### Promotion Ladder ("Rises To")

Information "graduates" to more durable layers:
- **One-off observation** → `activeContext.md` (Learnings / Recent Changes)
- **Repeated or reusable** → `patterns.md` (Pattern / Gotcha)
- **Needs detail** → `docs/research/*` or `docs/plans/*` + link from `activeContext.md`
- **Proven** → `progress.md` (Verification Evidence)

### READ Side (Equally Important)
**If memory is not loaded:** You work blind, repeat mistakes, lose context.
**If decisions made without checking memory:** You contradict prior choices, waste effort.

### WRITE Side
**If memory is not updated:** Next session loses everything learned.
**If learnings not recorded:** Same mistakes will be repeated.

**BOTH SIDES ARE NON-NEGOTIABLE.**

## Permission-Free Operations (CRITICAL)

**ALL memory operations are PERMISSION-FREE using the correct tools.**

| Operation | Tool | Permission |
|-----------|------|------------|
| Create memory directory | `Bash(command="mkdir -p .claude/cc100x")` | FREE |
| **Read memory files** | `Read(file_path=".claude/cc100x/activeContext.md")` | **FREE** |
| **Create NEW memory file** | `Write(file_path="...", content="...")` | **FREE** (file doesn't exist) |
| **Update EXISTING memory** | `Edit(file_path="...", old_string="...", new_string="...")` | **FREE** |
| Save plan/design files | `Write(file_path="docs/plans/...", content="...")` | FREE |

### CRITICAL: Write vs Edit

| Tool | Use For | Asks Permission? |
|------|---------|------------------|
| **Write** | Creating NEW files | NO (if file doesn't exist) |
| **Write** | Overwriting existing files | **YES - asks "Do you want to overwrite?"** |
| **Edit** | Updating existing files | **NO - always permission-free** |

**RULE: Use Write for NEW files, Edit for UPDATES.**

### CRITICAL: Use Read Tool, NOT Bash(cat)

**NEVER use Bash compound commands** (`mkdir && cat`) - they ASK PERMISSION.
**ALWAYS use Read tool** for reading files - it's PERMISSION-FREE.

```
# WRONG (asks permission - compound Bash command)
mkdir -p .claude/cc100x && cat .claude/cc100x/activeContext.md

# RIGHT (permission-free - separate tools)
Bash(command="mkdir -p .claude/cc100x")
Read(file_path=".claude/cc100x/activeContext.md")
```

**NEVER use heredoc writes** (`cat > file << 'EOF'`) - they ASK PERMISSION.
**Use Write for NEW files, Edit for EXISTING files.**

```
# WRONG (asks permission - heredoc)
cat > .claude/cc100x/activeContext.md << 'EOF'
content here
EOF

# RIGHT for NEW files (permission-free)
Write(file_path=".claude/cc100x/activeContext.md", content="content here")

# RIGHT for EXISTING files (permission-free)
Edit(file_path=".claude/cc100x/activeContext.md",
     old_string="# Active Context",
     new_string="# Active Context\n\n[new content]")
```

## Why This Matters

> "My memory resets between sessions. The Memory Bank is my ONLY link to previous work."

Without memory persistence:
- Context lost on conversation compaction
- Patterns relearned from scratch
- Decisions forgotten and remade differently
- Progress tracking lost
- Same mistakes repeated

**Memory is the difference between an expert who learns and a novice who forgets.**

## Memory Structure

```
.claude/
└── cc100x/
    ├── activeContext.md   # Current focus + learnings + decisions (MOST IMPORTANT)
    ├── patterns.md        # Project patterns, conventions, gotchas
    └── progress.md        # What works, what's left, verification evidence
```

## Who Reads/Writes Memory (Ownership)

### Read
- **Lead (always):** loads all 3 files before workflow selection and before resuming Tasks.
- **WRITE agents** (builder, planner): load memory files at task start via this skill.
- **READ-ONLY agents** (reviewers, hunter, verifier): receive memory summary in prompt, do NOT load this skill.

### Write
- **Lead (default in team workflows):** updates memory directly at workflow-final via the `CC100X Memory Update` task.
- **Teammates (default):** output `### Memory Notes (For Workflow-Final Persistence)` section; do not edit `.claude/cc100x/*`.
- **Explicit exception:** if prompt says `MEMORY_OWNER: teammate`, that teammate may use `Edit(...)` + `Read(...)` verify pattern.

### Concurrency Rule (Agent Teams)

During parallel phases (multiple reviewers in Review Arena, multiple investigators in Bug Court):
- Prefer **no memory edits during parallel phases**.
- If you must persist something mid-parallel, only the lead should do it, and only after ALL parallel teammates complete.
- Lead persists all Memory Notes AFTER parallel completion.

## Pre-Compaction Memory Safety

**Update memory IMMEDIATELY when you notice:**
- Extended debugging (5+ cycles)
- Long planning discussions
- Multi-file refactoring
- 30+ tool calls in session

**Checkpoint Pattern:**
```
Edit(file_path=".claude/cc100x/activeContext.md",
     old_string="## Current Focus",
     new_string="## Current Focus\n\n[Updated focus + key decisions]")
Read(file_path=".claude/cc100x/activeContext.md")  # Verify
```

**Rule:** When in doubt, update memory NOW. Better duplicate entries than lost context.

## File Purposes

Use these purposes to decide where information belongs:
- **activeContext.md:** current state + pointers (what we're doing, why, what's next)
- **patterns.md:** reusable knowledge (conventions, architecture, gotchas, "do it this way here")
- **progress.md:** execution tracking + hard evidence (tests/build/run commands, exit codes, scenario tables)

## Memory File Contract (Never Break)

CC100x memory files are not "notes" - they are **contracts** used as Edit anchors.

Hard rules:
- Do not rename the top-level headers (`# Active Context`, `# Project Patterns`, `# Progress Tracking`).
- Do not rename section headers (e.g., `## Current Focus`, `## Last Updated`).
- Only add content *inside* existing sections (append lists/rows).
  - If a **canonical section from this template** is missing (e.g., `## References`, `## Decisions`, `## Learnings`), add it by inserting it just above `## Last Updated`.
- After every `Edit(...)`, **Read back** the file and confirm the intended change exists.

If an Edit does not apply cleanly:
- STOP (do not guess).
- Re-read the file and re-apply using a correct, exact `old_string` anchor.

### activeContext.md (Read/Write EVERY session)

**Current state of work - ALWAYS check this first:**

```markdown
# Active Context
<!-- CC100X: Do not rename headings. Used as Edit anchors. -->

## Current Focus
[Active work]

## Recent Changes
- [Change] - [file:line]
- [DEBUG-N]: {what was tried} → {result}  <!-- Use for debug workflow -->

## Next Steps
1. [Step]

## Decisions
- [Decision]: [Choice] - [Why]

## Learnings
- [Insight]

## References
- Plan: `docs/plans/...` (or N/A)
- Design: `docs/plans/...` (or N/A)
- Research: `docs/research/...` → [insight]

## Blockers
- [None]

## Last Updated
[timestamp]
```

**Merged sections:**
- `## Active Decisions` + `## Learnings This Session` → `## Decisions` + `## Learnings`
- `## Plan Reference` + `## Design Reference` + `## Research References` → `## References`
- Removed: `## User Preferences Discovered` (goes in Learnings)

### patterns.md (Accumulates over time)

**Project-specific knowledge that persists:**

```markdown
# Project Patterns
<!-- CC100X MEMORY CONTRACT: Do not rename headings. Used as Edit anchors. -->

## Architecture Patterns
- [Pattern]: [How this project implements it]

## Code Conventions
- [Convention]: [Example]

## File Structure
- [File type]: [Where it goes, naming convention]

## Testing Patterns
- [Test type]: [How to write, where to put]

## Common Gotchas
- [Gotcha]: [How to avoid / solution]
- [Gotcha from research]: [Solution] (Source: docs/research/YYYY-MM-DD-topic.md)

## API Patterns
- [Endpoint pattern]: [Convention used]

## Error Handling
- [Error type]: [How project handles it]

## Dependencies
- [Dependency]: [Why used, how configured]
```

**Merged sections:**
- `## Active Workflow Tasks` + `## In Progress` + `## Remaining` → `## Tasks`
- `## Verification Evidence` table → `## Verification` bullets
- Removed: `## Known Issues`, `## Evolution of Decisions`, `## Implementation Results` (rarely used, clutters template)

### progress.md (Tracks completion)

**What's done, what's not:**

```markdown
# Progress Tracking
<!-- CC100X: Do not rename headings. Used as Edit anchors. -->

## Current Workflow
[PLAN | BUILD | REVIEW | DEBUG]

## Tasks
- [ ] Task 1
- [x] Task 2 - evidence

## Completed
- [x] Item - evidence

## Verification
- `command` → exit 0 (X/X)

## Last Updated
[timestamp]
```

## Stable Anchors (ONLY use these)

| Anchor | File | Stability |
|--------|------|-----------|
| `## Recent Changes` | activeContext | GUARANTEED |
| `## Learnings` | activeContext | GUARANTEED |
| `## References` | activeContext | GUARANTEED |
| `## Last Updated` | all files | GUARANTEED (fallback) |
| `## Common Gotchas` | patterns | GUARANTEED |
| `## Completed` | progress | GUARANTEED |
| `## Verification` | progress | GUARANTEED |

**NEVER use as anchors:**
- Table headers (`| Col | Col |`)
- Checkbox text (`- [ ] specific text`)
- Optional sections that may not exist

---

## Read-Edit-Verify (MANDATORY)

Every memory edit MUST follow this exact sequence:

### Step 1: READ
```
Read(file_path=".claude/cc100x/activeContext.md")
```

### Step 2: VERIFY ANCHOR
```
# Check if intended anchor exists in the content you just read
# If "## References" not found → use "## Last Updated" as fallback
```

### Step 3: EDIT
```
Edit(file_path=".claude/cc100x/activeContext.md",
     old_string="## Recent Changes",
     new_string="## Recent Changes\n- [New entry]\n")
```

### Step 4: VERIFY
```
Read(file_path=".claude/cc100x/activeContext.md")
# Confirm your change appears. If not → STOP and retry.
```

**Why this works:**
- Step 1 shows you what's actually there
- Step 2 prevents "anchor not found" errors
- Step 3 uses verified anchor
- Step 4 catches silent failures

---

## READ Triggers - When to Load Memory

### ALWAYS Read (Non-Negotiable)

| Trigger | Action | Why |
|---------|--------|-----|
| **Session start** | Load ALL 3 files | Fresh context needed |
| **Workflow start** | Load ALL 3 files | Before BUILD/REVIEW/DEBUG/PLAN |
| **Continuation session** | Load ALL 3 files | Resume from where we left |
| **User says "continue"** | Load activeContext.md | Get current state |

### Read BEFORE These Actions

| Before This Action | Read This File | Why |
|--------------------|----------------|-----|
| **Making architectural decision** | patterns.md | Check existing patterns |
| **Choosing implementation approach** | patterns.md + activeContext.md | Align with conventions + prior decisions |
| **Starting to build something** | progress.md | Check if already done |
| **Debugging an error** | activeContext.md + patterns.md | May have seen before + known gotchas |
| **Planning next steps** | progress.md | Know what's remaining |
| **Reviewing code** | patterns.md | Apply project conventions |
| **Making any decision** | activeContext.md (Decisions) | Check prior decisions |

### Read WHEN You Notice

| Situation | Action | Why |
|-----------|--------|-----|
| User references "what we did" | Load activeContext.md | Get history |
| You're about to repeat work | Load progress.md | Check if done |
| You're unsure of convention | Load patterns.md | Project standards |
| Error seems familiar | Load patterns.md (Common Gotchas) | Known issues |
| Decision feels arbitrary | Load activeContext.md | Prior reasoning |

### File Selection Matrix

```
What do I need?              → Which file?
─────────────────────────────────────────
Current state / focus        → activeContext.md
Prior decisions + reasoning  → activeContext.md (Decisions)
What we learned              → activeContext.md (Learnings)
Project conventions          → patterns.md
How to structure code        → patterns.md
Common gotchas to avoid      → patterns.md
What's done / remaining      → progress.md
Verification evidence        → progress.md
Prior research on topic      → activeContext.md (References) → docs/research/
```

### Decision Integration

**Before ANY decision, ask:**

1. **Did we decide this before?** → Check activeContext.md Decisions section
2. **Is there a project pattern?** → Check patterns.md
3. **Did we learn something relevant?** → Check activeContext.md Learnings

**If memory has relevant info:**
- Follow prior decision (or document why changing)
- Apply project pattern
- Use learned insight

**If memory is empty/irrelevant:**
- Make decision
- RECORD it in activeContext.md for next time

---

## Mandatory Operations

### At Workflow START (REQUIRED)

**Use separate tool calls (PERMISSION-FREE):**

```
# Step 1: Create directory (single Bash command - permission-free)
Bash(command="mkdir -p .claude/cc100x")

# Step 2: Load ALL 3 memory files using Read tool (permission-free)
Read(file_path=".claude/cc100x/activeContext.md")
Read(file_path=".claude/cc100x/patterns.md")
Read(file_path=".claude/cc100x/progress.md")

# Step 3: Git Context - Understand project state (RECOMMENDED)
Bash(command="git status")                 # Current working state
Bash(command="git ls-files | head -50")    # Project file structure
Bash(command="git log --oneline -10")      # Recent commits
```

**NEVER use this (asks permission):**
```bash
# WRONG - compound command asks permission
mkdir -p .claude/cc100x && cat .claude/cc100x/activeContext.md
```

**If file doesn't exist:** Read tool returns an error - that's fine, means starting fresh.

### At Workflow END (REQUIRED)

**MUST update before completing ANY workflow. Use Edit tool (NO permission prompt).**

```
# First, read existing content
Read(file_path=".claude/cc100x/activeContext.md")

# Prefer small, targeted edits. Avoid rewriting whole files.

# Example A: Add a bullet to Recent Changes (prepend)
Edit(file_path=".claude/cc100x/activeContext.md",
     old_string="## Recent Changes",
     new_string="## Recent Changes\n- [YYYY-MM-DD] [What changed] - [file:line]\n")

# Example B: Add a decision (stable anchor)
Edit(file_path=".claude/cc100x/activeContext.md",
     old_string="## Decisions",
     new_string="## Decisions\n- [Decision]: [Choice] - [Why]")

# Example C: Add verification evidence to progress.md (stable anchor)
Read(file_path=".claude/cc100x/progress.md")
Edit(file_path=".claude/cc100x/progress.md",
     old_string="## Verification",
     new_string="## Verification\n- `[cmd]` → exit 0 (X/X)")

# VERIFY (do not skip)
Read(file_path=".claude/cc100x/activeContext.md")
Read(file_path=".claude/cc100x/progress.md")
```

**WHY Edit not Write?** Write asks "Do you want to overwrite?" for existing files. Edit is always permission-free.

### When Learning Patterns (APPEND)

**Read existing patterns.md, then append using Edit:**

```
# Read existing content
Read(file_path=".claude/cc100x/patterns.md")

# Append under an existing section header (preferred: stable anchor)
Edit(file_path=".claude/cc100x/patterns.md",
     old_string="## Common Gotchas",
     new_string="## Common Gotchas\n- [Gotcha]: [Solution / how to avoid]\n")
```

### When Completing Tasks (UPDATE - Memory Owner Only)

```
# Read progress.md, then record completion with evidence
Read(file_path=".claude/cc100x/progress.md")

# Option A (preferred): append a completed line under "## Completed"
Edit(file_path=".claude/cc100x/progress.md",
     old_string="## Completed",
     new_string="## Completed\n- [x] [What was completed] - [evidence: command → exit 0]\n")

# Option B: flip an existing checkbox if one exists (more brittle)
Edit(file_path=".claude/cc100x/progress.md",
     old_string="- [ ] [Task being completed]",
     new_string="- [x] [Task being completed] - [verification evidence]")
```

## Integration with Agents

**ALL agents MUST:**

1. **START**: Load memory files before any work
2. **DURING**: Note learnings and decisions
3. **END**: Persist context via one of:
   - Memory owner path: update memory files directly
   - Teammate path: emit Memory Notes for lead-owned persistence

If an agent is NOT the memory owner (default for teammates in CC100x):
- Include "memory-worthy" notes in the agent output (decisions, learnings, verification evidence).
- The lead must persist those notes into `.claude/cc100x/*.md` using `Edit(...)` + Read-back verification.

**Failure to persist memory context (directly or via Memory Notes) = incomplete work.**

## Red Flags - STOP IMMEDIATELY

If you catch yourself:
- Starting work WITHOUT loading memory
- Making decisions WITHOUT checking Decisions section
- Completing work WITHOUT persisting memory context
- Saying "I'll remember" instead of writing to memory

**STOP. Load/update memory FIRST.**

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "I know what we decided" | Check the Decisions section. |
| "Small task, no need" | Small tasks have context too. Always update. |
| "I'll remember" | You won't. Conversation compacts. Write it down. |
| "Memory is optional" | Memory is MANDATORY. No exceptions. |

## Verification Checklist

- [ ] Memory loaded at workflow start
- [ ] Decisions checked before making new ones
- [ ] Learnings documented in activeContext.md
- [ ] Progress updated in progress.md

**Cannot check all boxes? Memory cycle incomplete.**
