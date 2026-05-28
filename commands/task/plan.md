---
name: "Task: Plan"
description: Plan a new task or update an existing plan — create proposal, design, and task checklist in one step
category: Workflow
tags: [workflow, task]
---

Plan a new task or update an existing one. Creates (or edits) the task directory and all planning artifacts.

I'll create or update:
- proposal.md (what & why)
- design.md (strategy & approach)
- tasks.md (step-by-step checklist)

When ready to execute, run /task:do

---

**Input**: The argument after `/task:plan` is the task name (kebab-case), OR a description of what the user wants to accomplish. For existing tasks, the same command enters update mode — describe changes inline or when prompted.

**Steps**

Use the **Skill tool** to invoke `task-plan` with the user's input as context.

The skill will:
1. Derive a kebab-case name from the description
2. Check if the task already exists — if so, enter update mode
3. In create mode: generate proposal.md, design.md, tasks.md, log.md, and runtime state
4. In update mode: show current state, ask what to change, surgically edit, and immediately record the revision in log.md
5. Show summary and prompt to run `/task:do <name>`
