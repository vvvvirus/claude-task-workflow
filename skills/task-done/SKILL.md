---
name: task-done
description: Archive a completed task. Use when the user wants to finalize and archive a task after execution is complete. Also use when the user says "wrap up", "finalize", "this is done", "archive this", "mark as done", or indicates a task is finished and should be moved to the archive. Moves task directory to archive with date prefix and generates completion summary.
compatibility: Requires Claude Code and Node.js >= 18 (for workflow-runtime.ts).
metadata:
  author: custom
  version: "2.1"
---

Archive a completed task. Checks verification status via the task-workflow runtime before archiving.

**Input**: Optionally a task name. If omitted, infer from context or prompt for selection.

**Steps**

1. **Select task** — Announce "Using task: <name>". Verify `tasks/<name>/` exists.

2. **Check completion** —
   ```bash
   npx tsx ~/.claude/task-workflow/workflow-runtime.ts status <name>
   ```
   - If `checks` exist but some false → warn. If `status: "verified"` → all good.
   - Parse tasks.md for top-level `- [x]` / `- [ ]` counts.
   - If verification incomplete: ask user to confirm proceeding without it.
   - If incomplete tasks remain: warn with count, ask to confirm.
   - If no tasks.md: error — task wasn't properly planned.

3. **Prompt for knowledge graph** — Ask: "Record service dependencies?" If yes: `npx tsx ~/.claude/task-workflow/workflow-runtime.ts kg-add <svc> --depends-on="..." --used-by="..."`

4. **Generate completion summary** — Append to proposal.md:
   ```markdown
   ---
   ## Completion Summary
   - **Completed:** YYYY-MM-DD
   - **Result:** <one-line outcome>
   - **Tasks:** N/M done
   - **Verification:** <passed | skipped | failed: X>
   - **Deviations:** <or "None">
   ```

5. **Archive** —
   ```bash
   mkdir -p tasks/archive
   mv tasks/<name> tasks/archive/YYYY-MM-DD-<name>
   ```
   If target exists, append `-2`, `-3`, etc.

6. **Display** —
   ```
   ## Archive Complete
   **Task:** <name>  **Archived to:** tasks/archive/YYYY-MM-DD-<name>/
   **Result:** <outcome>  **Verification:** <status>
   ```
   With warnings: show incomplete tasks and verification issues.

**Guardrails**
- **Language**: English only. Do not insert Chinese or mix languages.
- If the archive target, completion status, or user intent is unclear, STOP and use AskUserQuestion. Never assume.
- Check verification before archiving — warn but don't block.
- Show clear summary. Significant plan deviations → note them.
- Date prefix = archive date (not creation date).
