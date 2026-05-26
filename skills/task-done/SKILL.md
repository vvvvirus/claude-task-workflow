---
name: task-done
description: Archive a completed task. Use when the user wants to finalize and archive a task after execution is complete. Also use when the user says "wrap up", "finalize", "this is done", "archive this", "mark as done", or indicates a task is finished and should be moved to the archive. Moves task directory to archive with date prefix and generates completion summary.
compatibility: Requires Claude Code (no external dependencies).
metadata:
  author: custom
  version: "1.0"
---

Archive a completed task.

**Input**: Optionally specify a task name. If omitted, check if it can be inferred from conversation context. If vague or ambiguous you MUST prompt for available tasks.

**Steps**

1. **If no task name provided, prompt for selection**

   List directories in `tasks/` (excluding `archive/`). Use the **AskUserQuestion tool** to let the user select.

   **IMPORTANT**: Do NOT guess or auto-select a task. Always let the user choose.

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

   Generate target name: `YYYY-MM-DD-<task-name>`

   **Check if target already exists:**
   - If yes: fail with error, suggest renaming existing archive or using different approach
   - If no: move the task directory

   ```bash
   mv tasks/<name> tasks/archive/YYYY-MM-DD-<name>
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
**Archived to:** tasks/archive/YYYY-MM-DD-<name>/

**Warnings:**
- Archived with N incomplete tasks:
  - [ ] <task description>
  ...

Review the archive if this was not intentional.
```

**Output On Error (Archive Exists)**

```
## Archive Failed

**Task:** <task-name>
**Target:** tasks/archive/YYYY-MM-DD-<name>/

Target archive directory already exists.

**Options:**
1. Rename the existing archive
2. Delete the existing archive if it's a duplicate
3. Use a different approach
```

**Guardrails**
- Always prompt for task selection if not provided
- Don't block archive on warnings - just inform and confirm
- The completion summary is important: future-you will read it
- Show clear summary of what happened
- If the task had significant deviations from the plan, note them in the summary
- The date prefix uses the CURRENT date at archive time, not the task creation date
