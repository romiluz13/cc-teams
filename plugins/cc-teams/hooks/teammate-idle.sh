#!/usr/bin/env bash
# CC-Teams TeammateIdle hook: enforce Router Contract YAML presence before idle.
# Input: JSON on stdin with teammate_name, team_name, last_assistant_message.
# Exit 2 → teammate stays working and receives stderr as feedback.
# Core orchestration is unchanged if this hook is not installed.
set -euo pipefail

INPUT=$(cat)
TEAMMATE=$(echo "$INPUT" | jq -r '.teammate_name // ""' 2>/dev/null || echo "")
LAST_MSG=$(echo "$INPUT" | jq -r '.last_assistant_message // ""' 2>/dev/null || echo "")

# Only enforce for CC-Teams agent roles that must emit Router Contracts
ENFORCE=0
case "$TEAMMATE" in
  builder|live-reviewer|hunter|security-reviewer|performance-reviewer|quality-reviewer|verifier|planner)
    ENFORCE=1 ;;
  investigator-*)
    ENFORCE=1 ;;
esac

# If role not recognized or no message available, pass through safely
if [[ "$ENFORCE" -eq 0 ]] || [[ -z "$LAST_MSG" ]]; then
  exit 0
fi

# Check for Router Contract YAML block
if ! echo "$LAST_MSG" | grep -q "Router Contract (MACHINE-READABLE)"; then
  echo "[CC-Teams] $TEAMMATE is missing Router Contract YAML block." >&2
  echo "Include '### Router Contract (MACHINE-READABLE)' with complete YAML before going idle." >&2
  echo "See cc-teams:router-contract skill for the required CONTRACT_VERSION 2.3 schema." >&2
  exit 2
fi

exit 0
