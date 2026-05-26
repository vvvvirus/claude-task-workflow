---
name: task-plan
description: Plan a new task with all artifacts generated in one step. Use when the user wants to plan any multi-step operation — file processing, data migration, research, content creation, etc. Also use when the user says "plan this", "I need to organize", "help me think through", "break this down", or describes a complex operation they're about to start. Also use to revise an existing plan. Generates proposal, design, and task checklist ready for execution.
compatibility: Requires Claude Code (no external dependencies).
metadata:
  author: custom
  version: "1.0"
---

Plan a new task - create the task directory and generate all planning artifacts in one step. Can also re-plan an existing task to update its artifacts.

I'll create a task with artifacts:
- proposal.md (what & why)
- design.md (strategy & approach)
- tasks.md (step-by-step checklist)

When ready to execute, run /task:do

---

**Input**: The user's request should include a task name (kebab-case) OR a description of what they want to accomplish.

**Steps**

1. **If no clear input provided, ask what they want to do**

   Use the **AskUserQuestion tool** (open-ended, no preset options) to ask:
   > "What task do you want to plan? Describe what you want to accomplish."

   From their description, derive a kebab-case name (e.g., "organize photos by date" → `organize-photos`).

   **IMPORTANT**: Do NOT proceed without understanding what the user wants to do.

2. **Check for existing task with same name**

   Check if `tasks/<name>/` already exists.
   - If yes: tell the user this task exists. Offer two options:
     1. **Continue** — run `/task:do <name>` to resume execution
     2. **Revise** — run `/task:replan <name>` to edit the plan (preserves progress and history)
     3. **New name** — pick a different name and proceed with fresh planning
   - Do NOT regenerate artifacts from `/task:plan` itself. Editing belongs in `/task:replan`.
   - If no: proceed

3. **Create the task directory**

   ```bash
   mkdir -p tasks/<name>
   ```

4. **Create proposal.md**

   Write `tasks/<name>/proposal.md` with this structure:

   ```markdown
   # <Task Title>

   ## Goal
   <One sentence describing what success looks like>

   ## Motivation
   <Why this needs to be done, what problem it solves>

   ## Scope
   - In scope: <what will be done>
   - Out of scope: <what will NOT be done>

   ## Constraints
   - <Any limits, requirements, or boundaries>
   ```

   Guidelines:
   - Keep it concise - this is a brief, not a novel
   - Scope is the most important section: be specific about boundaries
   - If unclear, make reasonable assumptions and note them

5. **Create design.md**

   Write `tasks/<name>/design.md` with this structure:

   ```markdown
   # Design: <Task Title>

   ## Strategy
   <High-level approach - what's the overall plan>

   ## Steps Overview
   1. <Phase 1>
   2. <Phase 2>
   ...

   ## Key Decisions
   - <Decision>: <Rationale>

   ## Risks & Mitigations
   - <Risk>: <How to handle it>

   ## Resources Needed
   - <Files, tools, credentials, access, etc.>
   ```

   Guidelines:
   - Focus on the "how", not the "what" (that's in proposal.md)
   - Key Decisions should explain WHY certain approaches were chosen
   - If the task is straightforward, keep this short; complexity scales the document

6. **Create tasks.md**

   Write `tasks/<name>/tasks.md` with this structure:

   ```markdown
   # Tasks: <Task Title>

   ## Prerequisites
   - [ ] <Any setup or preparation needed before starting>

   ## Execution
   - [ ] <Task 1 - specific and actionable>
   - [ ] <Task 2 - specific and actionable>
   - [ ] <Task 3 - specific and actionable>
   ...

   ## Verification
   - [ ] <How to confirm everything was done correctly>
   ```

   Guidelines:
   - Each task must be a single, verifiable action
   - Use `- [ ]` checkbox format for progress tracking
   - Order matters: put dependent tasks after their prerequisites
   - Verification tasks confirm success, not redo the work
   - Aim for 3-15 tasks: too few means under-planned, too many means micro-managing

7. **Show summary**

   ```
   ## Task Planned: <task-name>

   **Location:** tasks/<name>/

   **Artifacts created:**
   - proposal.md — <one-line summary>
   - design.md — <one-line summary>
   - tasks.md — N steps

   Ready for execution. Run `/task:do <name>` to start.
   ```

**Guardrails**
- Create ALL three artifacts; don't skip any
- **NO GUESSING**: If any aspect of the goal, scope, constraints, or approach is unclear, STOP and use AskUserQuestion to clarify. Do NOT make assumptions about what the user wants.
- If context is partially unclear but has an obvious reasonable default, state the assumption explicitly in the artifact and flag it for user review
- Task names use kebab-case, lowercase, hyphen-separated
- Each checkbox item in tasks.md must be a concrete action, not a vague goal
- Verify each artifact file exists after writing before proceeding to next
- If the task is trivial (1-2 steps), suggest it may not need the full workflow
- Do NOT include speculation or filler in artifacts - every line should inform action
