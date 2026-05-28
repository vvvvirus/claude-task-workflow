#!/usr/bin/env bash
set -e

CLAUDE_DIR="${HOME}/.claude"

if [ ! -d "$CLAUDE_DIR" ]; then
    echo "Error: $CLAUDE_DIR not found. Is Claude Code installed?"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Installing Claude Task Workflow..."

# Create directories
mkdir -p "$CLAUDE_DIR/skills"
mkdir -p "$CLAUDE_DIR/commands/task"

# Copy skills (-r copies entire directories)
cp -r "$SCRIPT_DIR/skills/task-plan" "$CLAUDE_DIR/skills/"
cp -r "$SCRIPT_DIR/skills/task-do" "$CLAUDE_DIR/skills/"
cp -r "$SCRIPT_DIR/skills/task-done" "$CLAUDE_DIR/skills/"
cp -r "$SCRIPT_DIR/skills/task-log" "$CLAUDE_DIR/skills/"

cp -r "$SCRIPT_DIR/skills/task-list" "$CLAUDE_DIR/skills/"

# Copy commands
cp "$SCRIPT_DIR/commands/task/"*.md "$CLAUDE_DIR/commands/task/"

echo ""
echo "Done. Restart Claude Code for commands to take effect."
echo ""
echo "Try: /task:plan \"your first task\""
