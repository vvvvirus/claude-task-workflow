---
name: task-list
description: List all active and archived tasks. Use when the user wants to see current tasks, check progress, or review what has been completed. Also use when the user says "show tasks", "what tasks do I have", "list my work", or just runs /task:list.
compatibility: Requires Claude Code and Node.js >= 18 (for workflow-runtime.ts).
metadata:
  author: custom
  version: "2.0"
---

List all active tasks with progress and verification status, plus recently archived tasks. Reads runtime state when available, falls back to pure markdown parsing otherwise.

**Steps**

1. **List active tasks**

   Use Bash to list directories in `tasks/` excluding `archive/`:
   ```bash
   ls -d tasks/*/ 2>/dev/null | grep -v archive || echo ""
   ```

   For each active task directory found:
   - Read `tasks/<name>/proposal.md` and extract the first line under `## 目标`
   - Read `tasks/<name>/tasks.md` and count **top-level** checkbox lines only (lines matching `^- \[.\]` at the start, ignoring indented sub-items):
     - Total = count of `- [ ]` and `- [x]` at top level
     - Completed = count of `- [x]` at top level

2. **Check runtime state for verification status**

   For each active task, attempt to load runtime state:
   ```bash
   npx tsx workflow-runtime.ts status <name> 2>/dev/null
   ```

   If runtime state exists, parse the JSON and extract verification status:
   - `checks` field contains per-check results (tests, lint, typecheck, build)
   - Determine overall verification status:
     - **All passed**: all checks are `true` → show "(verified)"
     - **Some failed**: at least one check is `false` → show "(N/M verified)"
     - **Not run**: no `lastRun` timestamp → show "(not verified)"
   - If runtime state doesn't exist or command fails, show "(no runtime)" — fall back gracefully.

3. **Display active tasks**

   ```
   ## Active Tasks

   | Task | Goal | Progress | Verification |
   |------|------|----------|-------------|
   | <name> | <goal> | N/M done | <status> |
   ...
   ```

   Verification column values:
   - `All passed` → green
   - `N/M passed` → yellow
   - `Not run` → dim
   - `(no runtime)` → not shown, empty column

   If no active tasks found, show: "No active tasks."

4. **List recently archived tasks**

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

5. **Display summary**

   ```
   ## Active Tasks

   | Task | Goal | Progress | Verification |
   |------|------|----------|-------------|
   | <name> | <goal> | N/M done | <status> |
   ...

   ## Recently Archived

   | Task | Archived | Result |
   |------|----------|--------|
   | <name> | <date> | <result> |
   ...

   ---
   Run `/task:plan <description>` to start a new task.
   Run `/task:do <name>` to execute an active task.
   Run `/task:verify <name>` to run verification checks.
   ```

**Guardrails**
- Only count **top-level** checkbox items (`- [ ]` / `- [x]` at the start of a line). Ignore indented sub-tasks to avoid inflating the count.
- If a task directory has no `proposal.md` or `tasks.md`, show "(missing artifacts)" instead of crashing.
- Limit archived tasks to the 10 most recent.
- Keep goal summaries to one line; truncate with "..." if needed.
- Runtime state is optional — gracefully fall back to markdown-only when it doesn't exist. Never error out on missing runtime/TaskState.
