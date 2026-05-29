---
name: task-log
description: Record a checkpoint to a task's execution log. Use whenever the user wants to checkpoint progress mid-session, before switching tasks, or after completing a batch of work. Also use when the user says "note this", "log my progress", "checkpoint", "record what I did", or just runs /task:log without arguments. Auto-generates a structured summary; user can add notes on top.
compatibility: Requires Claude Code and Node.js >= 18 (for workflow-runtime.ts).
metadata:
  author: custom
  version: "2.1"
---

Append an auto-generated checkpoint to a task's log.md, with optional user notes. Reads runtime state for richer delta detection. Falls back to markdown-only when runtime unavailable.

**Input**: Optionally a task name and freeform notes: `/task:log <name> <notes>`.

**Steps**

1. **Select task** — Announce "Using task: <name>". Verify `tasks/<name>/` exists.

2. **Read all state** — proposal.md, design.md, tasks.md (parse top-level checkboxes), log.md. Try runtime: `npx tsx ~/.claude/task-workflow/workflow-runtime.ts status <name>` and `npx tsx ~/.claude/task-workflow/workflow-runtime.ts checkpoints <name>`. Graceful fallback if missing.

3. **Auto-detect changes since last checkpoint** — Compare current tasks.md against last log entry:
   - Progress delta: which tasks went `[ ]`→`[x]`
   - Runtime delta: check status vs last checkpoint JSON
   - Plan changes: proposal.md/design.md content vs last log description
   - Unresolved blockers: last entry's blocker still present?

4. **Generate checkpoint entry** — Append to `tasks/<name>/log.md`:
   ```markdown
   ---
   ## Checkpoint: YYYY-MM-DD HH:MM
   **Progress:** N/M done  **Status:** ACTIVE|BLOCKED|COMPLETE
   ### Done (since last checkpoint)
   - [x] <task> (or "No progress")
   ### Pending
   - [ ] <task>
   ### Verification
   <per-check status or "No runtime">
   ### Changes
   <plan updates or "None">
   ### Blockers
   <issues or "None">
   ### Notes
   <user notes or "—">
   ```
   Also write runtime checkpoint: `npx tsx ~/.claude/task-workflow/workflow-runtime.ts checkpoint <name> "manual" --files="..."`

5. **Ask user for notes** — Show generated content. Use AskUserQuestion: "Add anything to Notes?" If invoked with inline notes, use them, still offer to add more.

6. **Confirm** —
   ```
   ## Checkpoint recorded
   **Task:** <name>  **Log:** tasks/<name>/log.md  **Progress:** N/M
   Resume with `/task:do <name>`.
   ```

**Guardrails**
- **Language**: English only. Do not insert Chinese or mix languages.
- If delta detection, progress state, or user intent is ambiguous, STOP and use AskUserQuestion. Never assume.
- Done section = delta since last checkpoint only, not all-time.
- If no progress, still write entry as "still working" marker.
- Pending list = all remaining, not just new ones.
- If user provided inline notes, use them — don't discard.
- Runtime enhances but is never required. Always fall back gracefully.
