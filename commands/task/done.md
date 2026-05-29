---
name: "Task: Done"
description: Archive a completed task - moves it to archive with date prefix and summary
category: Workflow
tags: [workflow, task, archive]
---

Archive a completed task.

**Input**: Optionally specify a task name (e.g., `/task:done organize-photos`). If omitted, prompt for selection from active tasks.

**Steps**

Use the **Skill tool** to invoke `task-done` with the task name as context.

The skill will:
1. Check for incomplete tasks and warn
2. Append completion summary to proposal.md
3. Move `task-workflow/tasks/<name>/` to `task-workflow/tasks/archive/YYYY-MM-DD-<name>/`
4. Display archive summary
