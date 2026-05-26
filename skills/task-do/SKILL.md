---
name: task-do
description: Execute tasks from a planned task. Use when the user wants to start executing, continue execution, or work through task steps. Also use when resuming a previously paused task, picking up where you left off, or when the user says "continue with", "keep going on", "let's work on", "execute the plan", "do the tasks". Reads proposal, design, tasks, and log artifacts, then loops through pending tasks marking them complete.
compatibility: Requires Claude Code (no external dependencies).
metadata:
  author: custom
  version: "1.1"
---

Execute tasks from a planned task.

**Input**: Optionally specify a task name. If omitted, check if it can be inferred from conversation context. If vague or ambiguous you MUST prompt for available tasks.

**Steps**

1. **Select the task**

   If a name is provided, use it. Otherwise:
   - Infer from conversation context if the user mentioned a task
   - Auto-select if only one active task exists
   - If ambiguous, list available tasks from `tasks/` directory and use the **AskUserQuestion tool** to let the user select

   Always announce: "Using task: <name>" and how to override (e.g., `/task:do <other>`).

2. **Check the task exists and is valid**

   Verify `tasks/<name>/` exists and contains `tasks.md`.
   - If directory doesn't exist: show error with available tasks
   - If tasks.md missing: show error, suggest re-planning with `/task:plan`

3. **Read all context files**

   Read every artifact file:
   - `tasks/<name>/proposal.md` — what and why
   - `tasks/<name>/design.md` — strategy and approach
   - `tasks/<name>/tasks.md` — the execution checklist
   - `tasks/<name>/log.md` — session history (if exists, otherwise create empty)

4. **Show current progress and session history**

   Parse tasks.md to count **top-level** checkboxes only (lines starting with `- [ ]` or `- [x]`, ignoring indented sub-items):
   - Total tasks (top-level `- [ ]` and `- [x]` lines)
   - Completed tasks (top-level `- [x]`)
   - Pending tasks (top-level `- [ ]`)

   Record the current completed count as `session_start_completed = N`.

   If `log.md` exists, read the last session entry (search backward for `## Session:` or `## Checkpoint:`) and show a brief summary so the user knows where things left off.

   Display:
   ```
   ## Executing: <task-name>

   **Goal:** <from proposal.md>
   **Progress:** N/M tasks complete
   **Last session:** <date> — <brief summary from log.md, or "First session">

   ### Remaining
   - [ ] Task A
   - [ ] Task B
   ...
   ```

5. **Write session start entry to log.md**

   Before beginning execution, append a session start marker to `tasks/<name>/log.md`:

   ```markdown
   ---
   ## Session: YYYY-MM-DD HH:MM
   **Starting progress:** N/M tasks complete
   **Session start completed count:** N
   **Pending tasks:**
   - <task description>
   - <task description>
   ...
   ```

   If log.md doesn't exist yet, create it with the same structure but add a header:

   ```markdown
   # Execution Log: <task-name>

   ---
   ## Session: YYYY-MM-DD HH:MM
   ...
   ```

6. **Execute tasks (loop until done or blocked)**

   For each pending task (top-level `- [ ]` items only):
   - Announce: "Working on task N/M: <task description>"
   - Before executing, review `design.md` for relevant **Strategy** and **Key Decisions** that apply to this task
   - Execute the task using the appropriate tools (Bash, Write, Edit, browser, etc.), guided by the design strategy
   - After successfully completing the task, immediately mark it done: `- [ ]` → `- [x]` in tasks.md
   - Show brief confirmation: "✓ Task complete"
   - Continue to next task
   - If a task fails or cannot be completed, do NOT mark it done — report the error and pause

   **Pause if:**
   - Task is unclear or ambiguous → STOP and ask for clarification. Do NOT reinterpret, guess, or assume what the task means. Present the ambiguity and ask the user to resolve it.
   - Execution reveals a design issue → suggest running `/task:plan <name>` and choosing "update" to revise the plan
   - Error or blocker encountered → report and wait for guidance
   - User interrupts
   - Task requires manual user action → describe what the user needs to do, wait for confirmation

7. **On session end, record or prompt for logging**

   Claude cannot detect when the user closes the conversation — there is no OS-level "session end" event. Only write to log.md automatically when tasks are naturally complete or a blocker forces a pause. In all other cases, prompt the user to manually checkpoint.

   **a. All tasks complete → auto-write completion to log.md:**

   Calculate `tasks_completed_this_session = current_completed - session_start_completed`.

   Append:
   ```markdown
   ## Session end: YYYY-MM-DD HH:MM
   **Result:** Completed
   **Tasks completed this session:** N
   **New progress:** M/M tasks complete
   **Completed:**
   - [x] <task description>
   ...
   ```

   Then display completion output and suggest `/task:done <name>`.

   **b. Blocked by error/unresolvable issue → auto-write pause to log.md:**

   Calculate `tasks_completed_this_session = current_completed - session_start_completed`.

   Append:
   ```markdown
   ## Session end: YYYY-MM-DD HH:MM
   **Result:** Paused
   **Tasks completed this session:** N
   **New progress:** N/M tasks complete
   **Completed:**
   - [x] <task description>
   **Blocker:** <specific issue, what's needed to unblock>
   ```

   Then display pause output with options.

   **c. All other pauses (user said "stop", switching tasks, end of conversation):**

   Do NOT auto-write. Display status and prompt:
   > "To checkpoint your progress, run `/task:log <name>` to record what was done and what's next."

   This ensures log.md entries represent real decision points, not phantom "session boundaries" Claude guessed at.

**Output During Execution**

```
## Executing: <task-name>

Working on task 3/7: <task description>
[...execution happening...]
✓ Task complete

Working on task 4/7: <task description>
[...execution happening...]
✓ Task complete
```

**Output On Completion**

```
## Execution Complete

**Task:** <task-name>
**Progress:** 7/7 tasks complete ✓

### Completed This Session
- [x] Task 1
- [x] Task 2
...

All tasks complete! Archive this task with `/task:done <name>`.
**Session log:** tasks/<name>/log.md
```

**Output On Pause (Issue Encountered)**

```
## Execution Paused

**Task:** <task-name>
**Progress:** 4/7 tasks complete

### Issue Encountered
<description of the issue>

**Options:**
1. <option 1>
2. <option 2>
3. Other approach

What would you like to do?
**Session log:** tasks/<name>/log.md
```

**Guardrails**
- Keep going through tasks until done or blocked - don't stop early
- ALWAYS read all context files (proposal, design, tasks, log) before starting
- **NO GUESSING**: If a task description is ambiguous, the goal is unclear, or you're uncertain about what the user wants — STOP immediately and use AskUserQuestion to clarify. Never reinterpret vague instructions. Never assume intent.
- If execution reveals issues, pause and suggest artifact updates (explicitly: `/task:plan <name>` and "update")
- Update task checkbox in tasks.md IMMEDIATELY after completing each task
- Write session start entry to log.md BEFORE executing. Auto-write session end only for completion or blockers (step 7); for other pauses, prompt user to run `/task:log`.
- Log entries should be specific: what was done, what worked, what didn't, what's next
- Pause on errors, blockers, or unclear requirements
- The Verification section in tasks.md should be done last, not skipped
- For destructive or irreversible actions, confirm with user before proceeding

**Fluid Workflow Integration**

This skill supports the "actions on a task" model:

- **Can be invoked anytime**: After partial execution, interleaved with other actions
- **Allows artifact updates**: If execution reveals issues, suggest updating proposal.md or design.md - not phase-locked, work fluidly
- **Supports continuation**: Read log.md to understand what happened in previous sessions and pick up where it left off
- **Full traceability**: Every session's actions are recorded in log.md — who did what, when, and why they stopped
