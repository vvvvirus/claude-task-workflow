---
name: task-do
description: Execute tasks from a planned task. Use when the user wants to start executing, continue execution, or work through task steps. Also use when resuming a previously paused task, picking up where you left off, or when the user says "continue with", "keep going on", "let's work on", "execute the plan", "do the tasks". Reads proposal, design, tasks, and log artifacts, then loops through pending tasks marking them complete.
compatibility: Requires Claude Code and Node.js >= 18 (for workflow-runtime.ts).
metadata:
  author: custom
  version: "2.0"
---

Execute tasks from a planned task. Uses workflow-runtime.ts for deterministic DAG-based task ordering, checkpointing, and verification.

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
   - `tasks/<name>/tasks.md` — the human-readable checklist
   - `tasks/<name>/log.md` — session history (if exists, otherwise create empty)

4. **Load runtime state**

   Run `npx tsx workflow-runtime.ts status <name>` to get the machine-verifiable state.
   - If `runtime/task-state.json` doesn't exist (old task pre-dating runtime), fall back to pure markdown mode: parse tasks.md checkboxes for progress and execute in markdown order (no dependency resolution available; dependencies live in runtime state per task-plan).
   - In runtime mode, all dependency and progress data comes from task-state.json. tasks.md checkboxes are updated for human visibility only.
   - If the runtime returns a `_runnable` result with a `done: true` flag, all tasks are complete — skip to step 7a.

   Check for latest checkpoint:
   ```bash
   npx tsx workflow-runtime.ts next-checkpoint <name>
   ```
   If a checkpoint exists, show recovery info: what step was in progress, files changed, checks status.

5. **Show current progress and session history**

   Parse runtime state to show:
   - Total tasks
   - Completed tasks
   - Pending tasks
   - Next runnable task (from `_runnable`)

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

6. **Write session start entry to log.md**

   Before beginning execution, append a session start marker to `tasks/<name>/log.md`:

   ```markdown
   ---
   ## Session: YYYY-MM-DD HH:MM
   **Starting progress:** N/M tasks complete
   **Status:** ACTIVE
   **Session start completed count:** N
   **Pending tasks:**
   - <task description>
   - <task description>
   ...
   ```

   If log.md doesn't exist yet, create it with a header.

7. **Execute tasks (loop until done or blocked)**

   In runtime mode, use the DAG loop:

   a. Call `npx tsx workflow-runtime.ts next <name>` to get the next runnable task.
      - If response is `{ done: true }` → all tasks complete. Go to step 8a.
      - If response is an error about deadlock → warn and pause. Show which tasks have unmet deps.
      - Otherwise, get `{ task: {...}, index: N }`.

   b. Announce: "Working on task <index+1>/M: <task description>"

   c. Before executing, review `design.md` for relevant **Strategy** and **Key Decisions** that apply to this task.

   d. Execute the task using the appropriate tools (Bash, Write, Edit, browser, etc.), guided by the design strategy.

   e. After successfully completing the task:
      - Mark it done in the runtime: `npx tsx workflow-runtime.ts step-done <name> <index>`
      - Write a checkpoint: `npx tsx workflow-runtime.ts checkpoint <name> "<step-description>" --files="<changed-files>"`
      - Update `- [ ]` → `- [x]` in tasks.md for the corresponding line
      - Show: "✓ Task complete"
      - Continue to next task (go to step 7a)

   f. If a task fails or cannot be completed, do NOT mark it done — report the error and pause.

   **Pause if:**
   - Task is unclear or ambiguous → STOP and ask for clarification. Do NOT reinterpret, guess, or assume what the task means. Present the ambiguity and ask the user to resolve it.
   - Execution reveals a design issue → suggest running `/task:plan <name>` to revise the plan
   - Error or blocker encountered → report and wait for guidance
   - User interrupts
   - Task requires manual user action → describe what the user needs to do, wait for confirmation

   **Fallback (no runtime):** If runtime/task-state.json doesn't exist, use the old markdown-based flow:
   - Parse tasks.md for `- [ ]` checkboxes in listed order
   - Execute and mark checkboxes directly
   - No dependency resolution, automatic checkpointing, or verification

8. **Run verification**

   After all execution tasks are done, run verification:
   ```bash
   npx tsx workflow-runtime.ts verify <name>
   ```
   Display the verification results (passed/failed per check). If any check fails, report which commands failed and their output.
   If no verify commands are configured, skip this step.

9. **On session end, record or prompt for logging**

   **a. All tasks complete → auto-write completion to log.md:**

   Call `npx tsx workflow-runtime.ts complete <name>` to finalize state.

   Calculate `tasks_completed_this_session = current_completed - session_start_completed`.

   Append:
   ```markdown
   ## Session end: YYYY-MM-DD HH:MM
   **Result:** Completed
   **Status:** COMPLETE
   **Tasks completed this session:** N
   **New progress:** M/M tasks complete
   **Verification:** <passed/failed summary>
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
   **Status:** BLOCKED
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
**Verification:** tests ✓, lint ✓, typecheck ✓

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
- In runtime mode, ALWAYS use `workflow-runtime.ts next` to determine task order — never parse tasks.md manually for ordering
- **NO GUESSING**: If a task description is ambiguous, the goal is unclear, or you're uncertain about what the user wants — STOP immediately and use AskUserQuestion to clarify. Never reinterpret vague instructions. Never assume intent.
- If execution reveals issues, pause and suggest artifact updates (explicitly: `/task:plan <name>`).
- Call `step-done` and `checkpoint` immediately after completing each task
- Write session start entry to log.md BEFORE executing. Auto-write session end only for completion or blockers (step 9); for other pauses, prompt user to run `/task:log`.
- Log entries should be specific: what was done, what worked, what didn't, what's next
- Pause on errors, blockers, or unclear requirements
- The Verification section must be completed — run `verify` command and report results. Each check must produce a concrete, observable result.
- For destructive or irreversible actions, confirm with user before proceeding

**Fluid Workflow Integration**

This skill supports the "actions on a task" model:

- **Can be invoked anytime**: After partial execution, interleaved with other actions
- **Allows artifact updates**: If execution reveals issues, suggest updating proposal.md or design.md - not phase-locked, work fluidly
- **Supports continuation**: Read log.md to understand what happened in previous sessions and pick up where it left off. Use `next-checkpoint` to get precise recovery data.
- **Full traceability**: Every session's actions are recorded in log.md AND checkpoints/ — what was done, when, and why they stopped
