---
name: task-replan
description: Revise an existing task plan without regenerating from scratch. Use when the user wants to change scope, strategy, or task steps mid-execution. Also use when the user says "update the plan", "change the approach", "revise the tasks", "modify the scope", or "/task:replan". Edits only what needs changing, leaves the rest intact.
compatibility: Requires Claude Code (no external dependencies).
metadata:
  author: custom
  version: "1.1"
---

Revise an existing task plan by editing only what changed. Does NOT regenerate all artifacts from scratch — reads the current state, asks what needs to change, and surgically edits the relevant files.

**Input**: Task name (required). The user may also describe what they want to change inline: `/task:replan <name> <what to change>`.

**Steps**

1. **Select the task**

   If a name is provided, use it. Otherwise list active tasks from `tasks/` (excluding `archive/`) and use the **AskUserQuestion tool** to let the user select.

   Verify `tasks/<name>/` exists. If not, show error with available tasks.

2. **Read all existing artifacts**

   Read every artifact to understand current state:
   - `tasks/<name>/proposal.md` — goal, scope, constraints
   - `tasks/<name>/design.md` — strategy, decisions, risks
   - `tasks/<name>/tasks.md` — checklist progress
   - `tasks/<name>/log.md` — session history (if exists)

3. **Show current state and ask what to change**

   Display a concise summary:
   ```
   ## Re-plan: <task-name>

   **Current goal:** <from proposal.md>
   **Progress:** N/M top-level tasks complete (preserved)
   **Scope:** <in-scope summary>

   ### Current tasks
   1. [x] <task>
   2. [ ] <task>
   ...
   ```

   Use the **AskUserQuestion tool** (open-ended) to ask:
   > "What needs to change? (e.g., 'narrow scope to only PDF files', 'change strategy from manual to scripted', 'add a verification step')"

   If the user provided changes inline (`/task:replan <name> <changes>`), use that — still show the current state and ask if anything else needs changing.

4. **Edit only what changed**

   Identify which artifact(s) need updating based on the user's request:

   | Change type | Edit this file | Example |
   |------------|---------------|---------|
   | Goal, scope, constraints changed | `proposal.md` | "Only handle PDFs, not images" |
   | Strategy, approach, decisions changed | `design.md` | "Use a Python script instead of manual bash" |
   | Tasks added, removed, reordered | `tasks.md` | "Add a backup step before moving files" |

   Editing rules:
   - Modify ONLY the sections relevant to the change. Leave everything else verbatim.
   - If changing `tasks.md`: preserve checkbox states for tasks that are NOT being modified.
   - **When to reset `[x]` → `[ ]`**: apply this mechanically — if the rewritten task's **core action** (the main verb + object, e.g., "rename files", "run migration") differs from the original, reset it. If only details, constraints, or ordering changed while the core action stays the same, keep `[x]`.
   - If a completed task's meaning changed significantly, flag it: "Task X was done, but the description changed — may need re-doing."
   - If adding new tasks, insert them in the correct dependency order among existing tasks.
   - Do NOT rewrite the entire file. Use targeted edits.

5. **Record the change in log.md**

   Append to `tasks/<name>/log.md`:

   ```markdown
   ---
   ## Plan updated: YYYY-MM-DD HH:MM
   **What changed:** <one-line summary>
   **Files modified:** proposal.md, design.md, tasks.md (list which ones)
   ```

   If log.md doesn't exist yet, create it with a header first.

6. **Confirm**

   ```
   ## Plan updated: <task-name>

   **Files changed:**
   - proposal.md — <what changed>
   - tasks.md — <what changed>

   **Preserved:** N/M task completions, session history (log.md)

   Resume with `/task:do <name>`.
   ```

**Guardrails**
- Only edit files that actually need changing. If the user says "change the strategy", don't touch proposal.md or tasks.md.
- Preserve completed task checkboxes unless the task description itself changed materially.
- If the user's requested change is unclear, ask for clarification — do NOT guess what they meant.
- Log the plan change in log.md so future sessions know why the plan diverged.
- If no tasks have been completed yet, it's fine to rewrite tasks.md more freely — nothing to preserve.
- Keep changes minimal. One section edit is better than a full file rewrite.
