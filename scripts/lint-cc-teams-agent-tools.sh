#!/usr/bin/env bash
set -euo pipefail

failures=0

repo="$(cd "$(dirname "$0")/.." && pwd)"
agents_dir="$repo/plugins/cc-teams/agents"

fail() {
  echo "FAIL: $*" >&2
  failures=$((failures + 1))
}

require_file() {
  local file="$1"
  [[ -f "$file" ]] || fail "Missing agent file: $file"
}

tools_for() {
  local file="$1"
  sed -n 's/^tools:[[:space:]]*//p' "$file" | head -n1 | tr -d ' '
}

has_tool() {
  local tools="$1"
  local tool="$2"
  [[ ",$tools," == *",$tool,"* ]]
}

assert_has() {
  local agent="$1"
  local tools="$2"
  local tool="$3"
  if ! has_tool "$tools" "$tool"; then
    fail "$agent must include tool '$tool'"
  fi
}

assert_not_has() {
  local agent="$1"
  local tools="$2"
  local tool="$3"
  if has_tool "$tools" "$tool"; then
    fail "$agent must NOT include tool '$tool'"
  fi
}

check_agent() {
  local agent="$1"
  local file="$agents_dir/$agent.md"
  require_file "$file"
  local tools
  tools="$(tools_for "$file")"
  [[ -n "$tools" ]] || fail "$agent missing tools definition"
  echo "$agent => $tools"

  case "$agent" in
    builder|frontend-builder|backend-builder)
      assert_has "$agent" "$tools" "Write"
      assert_has "$agent" "$tools" "Edit"
      assert_has "$agent" "$tools" "Bash"
      ;;
    planner)
      assert_has "$agent" "$tools" "Write"
      assert_has "$agent" "$tools" "Edit"
      assert_has "$agent" "$tools" "Bash"
      ;;
    investigator|verifier)
      assert_has "$agent" "$tools" "Bash"
      assert_not_has "$agent" "$tools" "Write"
      assert_not_has "$agent" "$tools" "Edit"
      ;;
    live-reviewer|hunter|security-reviewer|performance-reviewer|quality-reviewer|accessibility-reviewer|api-contract-reviewer)
      assert_not_has "$agent" "$tools" "Write"
      assert_not_has "$agent" "$tools" "Edit"
      assert_not_has "$agent" "$tools" "Bash"
      assert_not_has "$agent" "$tools" "AskUserQuestion"
      assert_not_has "$agent" "$tools" "WebFetch"
      ;;
  esac
}

for agent in \
  builder frontend-builder backend-builder \
  planner \
  investigator \
  verifier \
  live-reviewer \
  hunter \
  security-reviewer \
  performance-reviewer \
  quality-reviewer \
  accessibility-reviewer \
  api-contract-reviewer; do
  check_agent "$agent"
done

if (( failures > 0 )); then
  echo "Agent tool lint failed with $failures error(s)." >&2
  exit 1
fi

echo "OK: CC-Teams agent tool boundaries are valid."
