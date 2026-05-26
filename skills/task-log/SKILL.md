---
name: task-log
description: Record a checkpoint to a task's execution log. Use whenever the user wants to checkpoint progress mid-session, before switching tasks, or after completing a batch of work. Also use when the user says "note this", "log my progress", "checkpoint", "record what I did", or just runs /task:log without arguments. Auto-generates a structured summary; user can add notes on top.
compatibility: Requires Claude Code (no external dependencies).
metadata:
  author: custom
  version: "1.1"
---

Append an auto-generated checkpoint to a task's log.md, with optional user notes. The checkpoint automatically captures progress, completed work, pending items, and any plan changes or blockers — no need for the user to manually summarize.

**Input**: Optionally specify a task name. If omitted, prompt for selection from active tasks. The user may also append freeform notes directly: `/task:log <name> <notes>`.

**Steps**

1. **Select the task**

   If a name is provided, use it. Otherwise list active tasks from `tasks/` (excluding `archive/`) and use the **AskUserQuestion tool** to let the user select.

   Verify `tasks/<name>/` exists. If not, show error with available tasks.

2. **Read all task state**

   Read every context file to build the checkpoint:
   - `tasks/<name>/proposal.md` — for goal and scope
   - `tasks/<name>/design.md` — for strategy context
   - `tasks/<name>/tasks.md` — for checkbox progress (parse top-level `- [x]` and `- [ ]` lines only; ignore indented sub-tasks)
   - `tasks/<name>/log.md` — for prior session and checkpoint history (if exists)

3. **Auto-detect key changes since last checkpoint**

   Compare current state against the most recent log.md entry (if any):

   - **Progress delta**: which top-level tasks went from `- [ ]` to `- [x]` since the last checkpoint (compare current tasks.md against the completed task descriptions mentioned in the last log entry)
   - **Plan changes**: compare the current content of proposal.md and design.md with any descriptions captured in the last log entry; if they differ, note the change
   - **Unresolved blockers**: if the last log entry mentions a blocker that's still not resolved (relevant pending tasks still not completable)

   If no prior log.md exists, treat all completed tasks as "this session."

4. **Generate the checkpoint entry**

   Compose and append to `tasks/<name>/log.md`:

   ```markdown
   ---
   ## Checkpoint: YYYY-MM-DD HH:MM
   **Progress:** N/M tasks complete

   ### Done
   - [x] <task> (or "No progress since last checkpoint")

   ### Pending
   - [ ] <task>

   ### Changes
   <plan updates made, or "None">

   ### Blockers
   <unresolved issues, or "None">

   ### Notes
   <user notes, or "—">
   ```

   Section guidelines:
   - **Done**: list only tasks completed since the last checkpoint, not all completed tasks. If nothing changed, write "No progress since last checkpoint."
   - **Pending**: all remaining incomplete tasks
   - **Changes**: note if proposal.md or design.md was updated (re-planned), what changed, and why. "None" if no changes.
   - **Blockers**: unresolved issues from prior sessions that still prevent progress. "None" if clear.
   - **Notes**: placeholder for user input (step 5)

   If log.md doesn't exist yet, create it with a header first:
   ```markdown
   # Execution Log: <task-name>
   ```

5. **Ask user to review and add notes**

   Display the auto-generated checkpoint content and use the **AskUserQuestion tool** (open-ended) to ask:
   > "Checkpoint above. Add anything to the Notes section? (Leave empty to accept as-is.)"

   If the user was invoked with `/task:log <name> <notes>`, use those notes directly — still show the auto-generated content and ask if they want to add more (one more round).

   After collecting input, fill in the **Notes** line:
   - If user provided notes: write them verbatim
   - If user left empty: keep "—"

6. **Confirm**

   ```
   ## Checkpoint recorded

   **Task:** <task-name>
   **Log:** tasks/<name>/log.md
   **Progress:** N/M tasks complete

   Resume anytime with `/task:do <name>`.
   ```

**Guardrails**
- The Done section MUST only list tasks completed since the last checkpoint — not all completed tasks from the beginning. This keeps each entry a useful delta.
- If the user provides notes via command line (`/task:log <name> <notes>`), use them — don't discard them
- If nothing changed since the last checkpoint, still write the entry — it serves as a timestamped "still working on this" marker
- The Pending list should be complete (all `- [ ]` items), not just ones added since last time
- Keep each section concise. One line per item. This is a breadcrumb, not a novel.
- If log.md has prior entries, append after the last one (don't overwrite)
- The date/time uses the CURRENT time
