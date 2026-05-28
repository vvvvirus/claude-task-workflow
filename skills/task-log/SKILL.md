---
name: task-log
description: Record a checkpoint to a task's execution log. Use whenever the user wants to checkpoint progress mid-session, before switching tasks, or after completing a batch of work. Also use when the user says "note this", "log my progress", "checkpoint", "record what I did", or just runs /task:log without arguments. Auto-generates a structured summary; user can add notes on top.
compatibility: Requires Claude Code and Node.js >= 18 (for workflow-runtime.ts).
metadata:
  author: custom
  version: "2.0"
---

Append an auto-generated checkpoint to a task's log.md, with optional user notes. Reads runtime state for richer delta detection and includes verification status. Falls back to markdown-only when runtime is unavailable.

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

   Attempt to load runtime state:
   ```bash
   npx tsx workflow-runtime.ts status <name> 2>/dev/null
   ```
   If available, parse the JSON and note:
   - `checks` — verification results (tests, lint, typecheck, build, lastRun)
   - `lastCheckpoint` — index of last runtime checkpoint
   Also try loading the latest checkpoints list:
   ```bash
   npx tsx workflow-runtime.ts checkpoints <name> 2>/dev/null
   ```
   Fall back gracefully if runtime is unavailable — the checkpoint still works with markdown alone.

3. **Auto-detect key changes since last checkpoint**

   Compare current state against the most recent log.md entry (if any):

   - **Progress delta**: which top-level tasks went from `- [ ]` to `- [x]` since the last checkpoint (compare current tasks.md against the completed task descriptions mentioned in the last log entry)
   - **Runtime delta** (if runtime available): compare current check status against the last stored checkpoint. If `lastCheckpoint > 0`, read the latest checkpoint JSON to see what changed.
   - **Plan changes**: compare the current content of proposal.md and design.md with any descriptions captured in the last log entry; if they differ, note the change
   - **Unresolved blockers**: if the last log entry mentions a blocker that's still not resolved (relevant pending tasks still not completable)

   If no prior log.md exists, treat all completed tasks as "this session."

4. **Generate the checkpoint entry**

   Compose and append to `tasks/<name>/log.md`:

   ```markdown
   ---
   ## Checkpoint: YYYY-MM-DD HH:MM
   **Progress:** N/M tasks complete
   **Status:** ACTIVE | BLOCKED | COMPLETE

   ### Done (since last checkpoint)
   - [x] <task> (or "No progress since last checkpoint")

   ### Pending
   - [ ] <task>

   ### Verification
   <checks status summary, or "No runtime state available">

   ### Changes
   <plan updates made, or "None">

   ### Blockers
   <unresolved issues, or "None">

   ### Notes
   <user notes, or "—">
   ```

   Section guidelines:
   - **Status**: one of `ACTIVE` (work in progress), `BLOCKED` (cannot proceed — see Blockers), `COMPLETE` (all tasks done — ready for /task:done). Single word, uppercase, for reliable parsing.
   - **Done**: list only tasks completed since the last checkpoint, not all completed tasks. If nothing changed, write "No progress since last checkpoint."
   - **Pending**: all remaining incomplete tasks, using `- [ ]` format
   - **Verification**: if runtime state is available, show per-check status (e.g., `tests: passed, lint: not run`). If all checks passed, show "All checks passed." If no runtime, show "No runtime state available."
   - **Changes**: note if proposal.md or design.md was updated (re-planned), what changed, and why. "None" if no changes.
   - **Blockers**: unresolved issues from prior sessions that still prevent progress. Use format: `- **<blocker title>**: <what's needed to unblock>`. "None" if clear.
   - **Notes**: placeholder for user input (step 5)

   If log.md doesn't exist yet, create it with a header first:
   ```markdown
   # Execution Log: <task-name>
   ```

   Also write a runtime checkpoint if available:
   ```bash
   npx tsx workflow-runtime.ts checkpoint <name> "manual-checkpoint" --files="proposal.md,design.md,tasks.md"
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
- Runtime state enhances checkpoint data but is never required. Always fall back to markdown-only gracefully.
