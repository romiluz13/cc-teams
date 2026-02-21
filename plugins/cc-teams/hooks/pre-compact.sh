#!/usr/bin/env bash
# CC-Teams PreCompact hook: write checkpoint marker before context compaction (v2.1.49+).
# The lead skill already handles pre-compaction every 30+ tool calls; this hook is an
# additional safety net that fires on unexpected compaction triggers.
# Appends a marker to progress.md so the lead can detect and emit a handoff payload.
set -euo pipefail

PROGRESS=".claude/cc-teams/progress.md"

# Only act if cc-teams memory system is active in this session
if [[ ! -f "$PROGRESS" ]]; then
  exit 0
fi

# Append a compact checkpoint marker (lead detects and emits handoff payload)
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
printf '\n<!-- CC-TEAMS COMPACT_CHECKPOINT: %s -->\n' "$TIMESTAMP" >> "$PROGRESS"

exit 0
