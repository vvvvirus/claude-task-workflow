---
name: task-list
description: List all active and archived tasks. Use when the user wants to see current tasks, check progress, or review what has been completed. Also use when the user says "show tasks", "what tasks do I have", "list my work", or just runs /task:list.
compatibility: Requires Claude Code (no external dependencies).
metadata:
  author: custom
  version: "1.1"
---

List all active tasks with progress and recently archived tasks.

**Steps**

1. **List active tasks**

   Use Bash to list directories in `tasks/` excluding `archive/`:
   ```bash
   ls -d tasks/*/ 2>/dev/null | grep -v archive || echo ""
   ```

   For each active task directory found:
   - Read `tasks/<name>/proposal.md` and extract the first line under `## Goal`
   - Read `tasks/<name>/tasks.md` and count **top-level** checkbox lines only (lines matching `^- \[.\]` at the start, ignoring indented sub-items):
     - Total = count of `- [ ]` and `- [x]` at top level
     - Completed = count of `- [x]` at top level
   - Display: `| <name> | <goal> | N/M done |`

   If no active tasks found, show: "No active tasks."

2. **List recently archived tasks**

   Use Bash:
   ```bash
   ls -d tasks/archive/*/ 2>/dev/null | tail -10 || echo ""
   ```

   For each archive directory:
   - Parse the date prefix from the directory name (`YYYY-MM-DD-<name>`)
   - Read `tasks/archive/<dir>/proposal.md` and look for the `## Completion Summary` section
   - Extract the `- **Result:**` line if present
   - Display: `| <name> | <date> | <result or "—"> |`

   If no archives found, show: "No archived tasks yet."

3. **Display summary**

   ```
   ## Active Tasks

   | Task | Goal | Progress |
   |------|------|----------|
   | <name> | <goal> | N/M done |
   ...

   ## Recently Archived

   | Task | Archived | Result |
   |------|----------|--------|
   | <name> | <date> | <result> |
   ...

   ---
   Run `/task:plan <description>` to start a new task.
   Run `/task:do <name>` to execute an active task.
   ```

**Guardrails**
- Only count **top-level** checkbox items (`- [ ]` / `- [x]` at the start of a line). Ignore indented sub-tasks to avoid inflating the count.
- If a task directory has no `proposal.md` or `tasks.md`, show "(missing artifacts)" instead of crashing.
- Limit archived tasks to the 10 most recent.
- Keep goal summaries to one line; truncate with "..." if needed.
