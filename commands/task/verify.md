---
name: "Task: Verify"
description: Run verification commands (tests, lint, typecheck) for a task and display results
category: Workflow
tags: [workflow, task, verify]
---

Run verification for a task using workflow-runtime.ts. Detects project type, runs configured verify commands, and displays results.

**Input**: Optionally specify a task name. If omitted, prompt for selection from active tasks.

**Steps**

1. **Select the task**

   If a task name is provided, use it. Otherwise list active tasks from `task-workflow/tasks/` and use the **AskUserQuestion tool** to let the user select.

   Verify `task-workflow/tasks/<name>/` exists. If not, show error with available tasks.

2. **Run the verification**

   ```bash
   npx tsx workflow-runtime.ts verify <name>
   ```

   This command reads verifyCommands from runtime state, runs each one, and outputs:
   - JSON lines to stderr (per-check results with output)
   - JSON to stdout (overall result)

   If `workflow-runtime.ts` or the task's runtime state doesn't exist, fall back to auto-detection:
   ```bash
   npx tsx workflow-runtime.ts init <name>
   npx tsx workflow-runtime.ts verify <name>
   ```

3. **Parse results and display**

   Parse the JSON output from stdout and stderr. Display a formatted summary:

   ```
   ## Verification: <task-name>

   | Check | Command | Result |
   |-------|---------|--------|
   | tests | npm test | Passed |
   | lint  | npm run lint | Failed |
   ...

   **Overall:** N/M checks passed
   ```

   If any checks failed, show the error output (truncated to 500 chars):
   ```
   ### Failed: lint
   <error output>
   ```

4. **Display final status**

   - All passed: "All verification checks passed. Task can be archived with `/task:done <name>`."
   - Some failed: "Some checks failed. Fix the issues above, then re-run `/task:verify <name>`."
   - No commands configured: "No verification commands configured for auto-detected project type."
