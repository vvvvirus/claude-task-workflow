---
name: task-list
description: List all active and archived tasks. Use when the user wants to see current tasks, check progress, or review what has been completed. Also use when the user says "show tasks", "what tasks do I have", "list my work", or just runs /task:list.
compatibility: Requires Claude Code and Node.js >= 18 (for workflow-runtime.ts).
metadata:
  author: custom
  version: "2.1"
---

List all active tasks with progress and verification status, plus recently archived tasks.

**Steps**

1. **List active tasks** — `ls -d task-workflow/tasks/*/ 2>/dev/null | grep -v archive`. For each:
   - Extract goal from proposal.md (first line under goal/objective heading)
   - Count top-level checkboxes in tasks.md: total = `- [ ]` + `- [x]`, done = `- [x]`

2. **Check verification** — Per task: `npx tsx ~/.claude/task-workflow/workflow-runtime.ts status <name> 2>/dev/null`. Parse `checks`:
   - All true → "verified"
   - Some false → "N/M verified"
   - No `lastRun` → "not verified"
   - No runtime → skip, show empty

3. **Display active tasks** —
   ```
   ## Active Tasks
   | Task | Goal | Progress | Verification |
   |------|------|----------|-------------|
   | <name> | <goal> | N/M done | <status> |
   ```

4. **List recent archives** — `ls -d task-workflow/tasks/archive/*/ 2>/dev/null | tail -10`. For each: parse date from dir name, extract `Result:` from proposal.md's Completion Summary.

5. **Display summary** —
   ```
   ## Recently Archived
   | Task | Archived | Result |
   |------|----------|--------|
   | <name> | <date> | <result> |
   ---
   /task:plan <desc> — new task   /task:do <name> — execute   /task:verify <name> — verify
   ```

**Guardrails**
- **Language**: English only. Do not insert Chinese or mix languages.
- Only count top-level checkboxes (`- [ ]` / `- [x]` at line start). Ignore indented sub-tasks.
- Missing artifacts → show "(missing)" instead of crashing.
- Archives limited to 10 most recent. Goal summaries one line, truncate with "..." if needed.
- Runtime is optional — gracefully fall back. Never error on missing state.
