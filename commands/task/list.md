---
name: "Task: List"
description: List all active and archived tasks
category: Workflow
tags: [workflow, task]
---

List all tasks - active and archived.

**Steps**

1. **List active tasks**

   Check `tasks/` directory (excluding `archive/` subdirectory):
   ```bash
   ls -d tasks/*/ 2>/dev/null | grep -v archive
   ```

   For each active task, read its proposal.md and parse the goal line. Show progress from tasks.md.

2. **List recently archived tasks**

   Check `tasks/archive/` directory:
   ```bash
   ls -d tasks/archive/*/ 2>/dev/null | tail -10
   ```

3. **Display summary**

```
## Active Tasks

| Task | Goal | Progress |
|------|------|----------|
| <name> | <goal from proposal.md> | N/M done |

## Recently Archived

| Task | Archived | Result |
|------|----------|--------|
| <name> | <date> | <result from completion summary> |

---
Run `/task:plan <description>` to start a new task.
Run `/task:do <name>` to execute an active task.
```
