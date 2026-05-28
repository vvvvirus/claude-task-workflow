---
name: task-plan
description: Plan a new task or update an existing plan. Use when the user wants to plan any multi-step operation — file processing, data migration, research, content creation, etc. Also use when the user says "plan this", "I need to organize", "help me think through", "break this down", or describes a complex operation they're about to start. For existing tasks, this replaces /task:replan — just invoke with the same task name to edit the plan.
compatibility: Requires Claude Code and Node.js >= 18 (for workflow-runtime.ts).
metadata:
  author: custom
  version: "2.1"
---

Plan a new task or update an existing one. Creates proposal.md, design.md, tasks.md, and runtime state. When the task already exists, enters update mode — shows current state, asks what to change, edits only what changed, and immediately records the revision in log.md.

**Input**: The user's request should include a task name (kebab-case) OR a description of what they want to accomplish. For updates, use the existing task name.

**Steps**

1. **If no clear input provided, ask what they want to do**

   Use the **AskUserQuestion tool** (open-ended, no preset options) to ask:
   > "What task do you want to plan? Describe what you want to accomplish."

   From their description, derive a kebab-case name (e.g., "organize photos by date" → `organize-photos`).

   **IMPORTANT**: Do NOT proceed without understanding what the user wants to do.

2. **Check for existing task with same name**

   Check if `tasks/<name>/` already exists.
   - If yes → **enter update mode** (skip to step 9). Do NOT offer redirects to other commands. This is the one command for all plan changes.
   - If no → continue with create mode (step 3).

3. **Detect verification commands**

   Run `npx tsx workflow-runtime.ts` to check it works. Then detect available verify commands:
   - If `package.json` exists with test/lint scripts → auto-detect
   - If `Cargo.toml`, `go.mod`, `pyproject.toml` exist → auto-detect
   - Ask user if they want to add custom verify commands

4. **Create the task directory and initialize log.md**

   ```bash
   mkdir -p tasks/<name>
   ```

   Create `tasks/<name>/log.md` immediately (not deferred to /task:do):

   ```markdown
   # Execution Log: <task-name>

   ## 概述
   Task created on YYYY-MM-DD.
   ```

   This ensures revision history is never lost — every plan change from this point forward gets recorded.

5. **Initialize runtime state**

   ```bash
   npx tsx workflow-runtime.ts init <name> --tasks="<task1>,<task2>,..."
   ```

   If tasks have dependencies, use the `--deps` flag with 0-based indices:
   ```bash
   npx tsx workflow-runtime.ts init <name> --tasks="Task A,Task B,Task C" --deps="1:0 2:1"
   ```
   This means: task at index 1 depends on task at index 0; task at index 2 depends on task at index 1.

   **Dependency format notes:**
   - Indices are 0-based and validated at init time — out-of-range indices are skipped with a warning
   - **Important**: if tasks are reordered, dependency indices must be recalculated. When updating a plan (step 14), always regenerate the `--deps` string from the updated task list
   - Format each entry as `task-index:dep-index[,dep-index]`, separate entries with spaces

   If workflow-runtime.ts is not available, fall back to creating tasks without runtime state and note the limitation.

6. **Create proposal.md**

   Write `tasks/<name>/proposal.md` with this structure:

   ```markdown
   # <Task Title>

   ## 目标
   <One sentence describing what success looks like>

   ## 动机
   <Why this needs to be done, what problem it solves>

   ## 范围

   ### 包含
   - <what will be done>

   ### 不包含
   - <what will NOT be done>

   ## 约束
   - <Any limits, requirements, or boundaries>
   ```

   Guidelines:
   - Keep it concise - this is a brief, not a novel
   - Scope is the most important section: be specific about boundaries
   - If unclear, make reasonable assumptions and note them

7. **Create design.md**

   Write `tasks/<name>/design.md` with this structure:

   ```markdown
   # 设计：<Task Title>

   ## 策略
   <High-level approach - what's the overall plan>

   ## 关键决策
   - <Decision>: <Rationale>

   ## 风险
   - <Risk>: <How to handle it>
   ```

   Guidelines:
   - Focus on the "how", not the "what" (that's in proposal.md)
   - Key Decisions should explain WHY certain approaches were chosen
   - If the task is straightforward, keep this short; complexity scales the document

8. **Create tasks.md**

   Write `tasks/<name>/tasks.md` with this structure:

   ```markdown
   # 任务清单：<Task Title>

   ## 前置
   - [ ] <Any setup or preparation needed before starting>

   ## 执行
   - [ ] <Task 1 - specific and actionable>
   - [ ] <Task 2 - specific and actionable>
   - [ ] <Task 3 - specific and actionable>
   ...

   ## 验证
   - [ ] <How to confirm everything was done correctly>
   ```

   Guidelines:
   - Each task must be a single, verifiable action
   - Use `- [ ]` checkbox format for progress tracking
   - Order matters: put dependent tasks after their prerequisites
   - **Dependencies are stored in runtime/task-state.json, NOT as inline text in tasks.md.** When declaring dependencies during planning, pass them to `workflow-runtime.ts init --deps=...` instead.
   - Verification tasks confirm success, not redo the work
   - Aim for 3-15 top-level tasks: too few means under-planned, too many means micro-managing
   - Sub-tasks may be indented under a top-level item, but they do NOT count toward the task total

9. **Verify all artifacts**

   Use Bash to confirm each file exists, is non-empty, and has required sections:
   ```bash
   # Check existence and non-empty
   ls -la tasks/<name>/proposal.md tasks/<name>/design.md tasks/<name>/tasks.md tasks/<name>/log.md tasks/<name>/runtime/task-state.json
   # Check required sections exist
   grep -c "## 目标" tasks/<name>/proposal.md
   grep -c "## 策略" tasks/<name>/design.md
   grep -c "## 执行" tasks/<name>/tasks.md
   grep -c "## 验证" tasks/<name>/tasks.md
   ```

   If any file is missing or missing a required section, recreate/fix it before proceeding.

10. **Show summary with full plan content** (create mode only — skip to update mode summary for updates)

    ```
    ## Task Planned: <task-name>

    **Goal:** <goal from proposal.md>

    **Strategy:** <strategy from design.md>

    ### Tasks (N total)
    1. [ ] <task from tasks.md>
    2. [ ] <task from tasks.md>
    ...

    **Verification:** <N verification items>

    ---
    Ready. Run `/task:do <name>` to start.
    ```

    Guidelines:
    - List ALL top-level tasks from tasks.md so the user sees the full scope
    - Show the strategy paragraph verbatim from design.md — this is the user's main chance to catch misaligned approach
    - Keep it structured: Goal → Strategy → Tasks → call to action
    - Do NOT elide or shorten task descriptions

---

### UPDATE MODE (task already exists)

11. **Read all existing artifacts**

    Read every artifact to understand current state:
    - `tasks/<name>/proposal.md` — goal, scope, constraints
    - `tasks/<name>/design.md` — strategy, decisions, risks
    - `tasks/<name>/tasks.md` — checklist progress
    - `tasks/<name>/log.md` — revision and session history

    Load runtime state:
    ```bash
    npx tsx workflow-runtime.ts status <name>
    ```
    Fall back gracefully if runtime state doesn't exist.

12. **Show current state and ask what to change**

    Display a concise summary:
    ```
    ## Update Plan: <task-name>

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

    If the user provided changes inline (`/task:plan <name> <changes>`), use that — still show the current state and ask if anything else needs changing.

13. **Edit only what changed**

    Identify which artifact(s) need updating based on the user's request:

    | Change type | Edit this file | Example |
    |------------|---------------|---------|
    | Goal, scope, constraints changed | `proposal.md` | "Only handle PDFs, not images" |
    | Strategy, approach, decisions changed | `design.md` | "Use a Python script instead of manual bash" |
    | Tasks added, removed, reordered | `tasks.md` + update runtime state | "Add a backup step before moving files" |

    Editing rules:
    - Modify ONLY the sections relevant to the change. Leave everything else verbatim.
    - If changing `tasks.md`: preserve checkbox states for tasks that are NOT being modified.
    - **When to reset `[x]` → `[ ]`**: if the rewritten task's **core action** (main verb + object) differs from the original, reset it. If only details, constraints, or ordering changed, keep `[x]`.
    - If a completed task's meaning changed significantly, flag it: "Task X was done, but the description changed — may need re-doing."
    - Do NOT rewrite the entire file. Use targeted edits.

14. **Sync runtime state**

    If the task list or dependencies changed, reinitialize the runtime state to match:
    ```bash
    npx tsx workflow-runtime.ts init <name> --tasks="<updated task list>"
    ```
    Then restore progress for completed tasks:
    ```bash
    npx tsx workflow-runtime.ts step-done <name> <index>  # for each completed task
    ```

    If only the goal/strategy changed (no task list changes), skip this step.

15. **Record the change in log.md IMMEDIATELY**

    This is mandatory. Do NOT defer to session end. After every plan edit, immediately append to `tasks/<name>/log.md`:

    ```markdown
    ---
    ## Plan update: YYYY-MM-DD HH:MM
    **触发：** <what prompted this change>
    **改动：** <one-line summary of what changed>
    **修改文件：** <list which files were edited>
    ```

    The log entry must be written BEFORE showing the confirmation. If log.md doesn't exist (legacy task), create it with a header first.

    Also write a checkpoint if runtime is available:
    ```bash
    npx tsx workflow-runtime.ts checkpoint <name> "plan-update-<summary>"
    ```

16. **Confirm**

    ```
    ## Plan updated: <task-name>

    **Files changed:**
    - <file> — <what changed>
    - <file> — <what changed>

    **Preserved:** N/M task completions, session history (log.md)

    Resume with `/task:do <name>`.
    ```

**Guardrails**
- Create ALL artifacts (proposal, design, tasks, log, runtime state); don't skip any
- **NO GUESSING**: If any aspect of the goal, scope, constraints, or approach is unclear, STOP and use AskUserQuestion to clarify. Do NOT make assumptions about what the user wants.
- If context is partially unclear but has an obvious reasonable default, state the assumption explicitly in the artifact and flag it for user review
- Task names use kebab-case, lowercase, hyphen-separated
- Each checkbox item in tasks.md must be a concrete action, not a vague goal
- Verify each artifact file exists after writing before proceeding to next
- If the task is trivial (1-2 steps), suggest it may not need the full workflow
- Do NOT include speculation or filler in artifacts - every line should inform action
- **Dependencies go in runtime/task-state.json via --deps flag, NOT in tasks.md.**
- **LOG.MD DISCIPLINE**: Create log.md during initial planning. After every plan update, immediately append to log.md — do not wait for session end. This is non-negotiable.
- In update mode, only edit files that actually need changing. Preserve completed checkboxes.
- If the user's requested change is unclear, ask for clarification — do NOT guess.
- No distinction between "small" and "large" plan changes. All edits follow the same flow: edit files + record log.
