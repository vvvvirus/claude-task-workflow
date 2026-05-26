---
name: "Task: List"
description: List all active and archived tasks
category: Workflow
tags: [workflow, task]
---

List all tasks - active and archived.

**Steps**

Use the **Skill tool** to invoke `task-list`.

The skill will:
1. Scan `tasks/` (excluding `archive/`) for active tasks
2. Read each task's proposal.md and tasks.md to show goal and progress
3. Scan `tasks/archive/` for recently archived tasks
4. Display a formatted summary table
