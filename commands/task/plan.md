---
name: "Task: Plan"
description: Plan a new task (or update an existing plan) - create proposal, design, and task checklist in one step
category: Workflow
tags: [workflow, task]
---

Plan a new task - create the task directory and generate all planning artifacts in one step.

I'll create a task with artifacts:
- proposal.md (what & why)
- design.md (strategy & approach)
- tasks.md (step-by-step checklist)

When ready to execute, run /task:do

---

**Input**: The argument after `/task:plan` is the task name (kebab-case), OR a description of what the user wants to accomplish.

**Steps**

Use the **Skill tool** to invoke `task-plan` with the user's input as context.

The skill will:
1. Derive a kebab-case name from the description
2. Create `tasks/<name>/` directory
3. Generate proposal.md, design.md, tasks.md
4. Show summary and prompt to run `/task:do <name>`
