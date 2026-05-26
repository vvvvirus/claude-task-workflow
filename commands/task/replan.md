---
name: "Task: Replan"
description: Revise an existing task plan — edits only what needs changing, preserves progress and history
category: Workflow
tags: [workflow, task]
---

Revise an existing task plan without regenerating from scratch. Use this to change scope, strategy, or steps mid-execution.

**Input**: Task name required. Optionally describe changes inline: `/task:replan <name> <what to change>`.

**Steps**

Use the **Skill tool** to invoke `task-replan` with the task name as context.

The skill will:
1. Read all current artifacts and show state
2. Ask what needs to change (or use your inline description)
3. Surgically edit only the relevant files — not regenerate everything
4. Preserve completed checkboxes and session history
5. Log the change in log.md

Prefer this over `/task:plan` when the task already exists — it doesn't ask "update or new?", it goes straight to editing.
