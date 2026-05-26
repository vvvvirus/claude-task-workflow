---
name: "Task: Log"
description: Record a manual checkpoint note to a task's execution log
category: Workflow
tags: [workflow, task, log]
---

Record a checkpoint to a task's log.md. Auto-generates a structured summary (progress, done, pending, blockers, plan changes) — no need to manually summarize. Optionally add notes: `/task:log <name> <notes>`.

**Input**: Optionally specify a task name (e.g., `/task:log organize-photos`). If omitted, prompt for selection from active tasks.

**Steps**

Use the **Skill tool** to invoke `task-log` with the task name as context.

The skill will:
1. Read all task state (proposal, design, tasks, log)
2. Auto-detect: progress delta, plan changes, blockers since last checkpoint
3. Generate a structured checkpoint entry
4. Show the entry and ask if you want to add notes
5. Append to log.md and confirm

Just run `/task:log` mid-task — it figures out what to record.
