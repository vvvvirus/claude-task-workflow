---
name: task-done
description: Archive a completed task. Use when the user wants to finalize and archive a task after execution is complete. Also use when the user says "wrap up", "finalize", "this is done", "archive this", "mark as done", or indicates a task is finished and should be moved to the archive. Moves task directory to archive with date prefix and generates completion summary.
compatibility: Requires Claude Code (no external dependencies).
metadata:
  author: custom
  version: "1.1"
---

Archive a completed task.

**Input**: Optionally specify a task name. If omitted, check if it can be inferred from conversation context. If vague or ambiguous you MUST prompt for available tasks.

**Steps**

1. **Select the task**

   If a name is provided, use it. Otherwise:
   - Infer from conversation context if the user mentioned a task
   - Auto-select if only one active task exists
   - If ambiguous, list available tasks from `tasks/` directory and use the **AskUserQuestion tool** to let the user select

2. **Check task completion status**

   Read `tasks/<name>/tasks.md` and count:
   - Total tasks (all `- [ ]` and `- [x]` lines)
   - Completed tasks (`- [x]`)
   - Incomplete tasks (`- [ ]`)

   **If incomplete tasks found:**
   - Display warning showing incomplete tasks and their count
   - Use **AskUserQuestion tool** to confirm user wants to proceed
   - Proceed if user confirms

   **If no tasks.md exists:** Show error - this task wasn't properly planned.

3. **Generate completion summary**

   Append to `tasks/<name>/proposal.md`:

   ```markdown

   ---
   <!-- COMPLETION -->

   ## Completion Summary
   - **Completed:** YYYY-MM-DD
   - **Result:** <one-line summary of outcome>
   - **Tasks completed:** N/M
   - **Deviations from plan:** <any differences, or "None">
   ```

4. **Perform the archive**

   Create archive directory if needed:
   ```bash
   mkdir -p tasks/archive
   ```

   Generate base target name: `YYYY-MM-DD-<task-name>`

   **Check if target already exists:**
   - If yes: append a numeric suffix (`-2`, `-3`, etc.) until a unique name is found
   - If no: use the base name

   ```bash
   mv tasks/<name> tasks/archive/YYYY-MM-DD-<name>
   # or tasks/archive/YYYY-MM-DD-<name>-2 if collision occurred
   ```

5. **Display summary**

**Output On Success**

```
## Archive Complete

**Task:** <task-name>
**Archived to:** tasks/archive/YYYY-MM-DD-<name>/
**Result:** <one-line outcome>

All N tasks complete.
```

**Output On Success With Warnings**

```
## Archive Complete (with warnings)

**Task:** <task-name>
**Archived to:** tasks/archive/<actual-archive-name>/

**Warnings:**
- Archived with N incomplete tasks:
  - [ ] <task description>
  ...

Review the archive if this was not intentional.
```

**Guardrails**
- Always prompt for task selection if not provided
- Don't block archive on warnings - just inform and confirm
- The completion summary is important: future-you will read it
- Show clear summary of what happened
- If the task had significant deviations from the plan, note them in the summary
- The date prefix uses the CURRENT date at archive time, not the task creation date
