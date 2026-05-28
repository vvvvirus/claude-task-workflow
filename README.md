# Claude Task Workflow

Plan → execute → archive any multi-step task inside Claude Code. File processing, data migration, research, content creation — anything that takes more than one step and is worth remembering later.

Not a code framework. No dependencies, no config, no CLI. Six slash commands, five skills, and a directory of markdown files.

## Why this exists

Claude Code's built-in `/plan` is designed for coding — plan once, implement, move on. The plan evaporates. There's no pause-and-resume, no execution log, no archive.

This gives you a persistent workflow for everything else:

- **Pause anytime.** Stop mid-task, close the laptop, come back next week. `/task:do` reads the log and picks up where you left off.
- **Full traceability.** Every session is timestamped in `log.md` — what was done, what broke, what changed.
- **Archived memory.** Completed tasks live in `archive/` with a completion summary. Searchable, re-readable, never lost.

## How it works

```
/task:plan "organize 5000 photos by year and rename them"

  Creates:  tasks/organize-photos/
            ├── proposal.md    ← What & why. Goal, scope, constraints.
            ├── design.md      ← How. Strategy, key decisions, risks.
            ├── tasks.md       ← Step-by-step checklist. Each line one action.
            └── log.md         ← Execution journal. Created during planning.

/task:do organize-photos

  Reads all artifacts + log.md. Shows progress and last session summary.
  Writes session start to log.md.
  Executes pending tasks one by one, marking checkboxes as done.
  Writes session end to log.md (on completion or blocker).
  Prompts to run /task:log to checkpoint for other pauses.

/task:log organize-photos

  Auto-generates a structured checkpoint:
    → Progress delta since last checkpoint
    → Completed tasks this session
    → Still-pending tasks
    → Plan changes detected (proposal/design updated?)
    → Verification status (from runtime state)
    → Unresolved blockers
  Asks if you want to add freeform notes. Can accept as-is.

/task:plan organize-photos "narrow scope to PDF only"

  Same command for creating AND updating plans. If the task already exists,
  enters update mode: shows current state, asks what to change, surgically
  edits only the relevant files. Preserves completed checkboxes and session
  history. Immediately records the revision in log.md — no lost history.

  This replaces the old /task:replan. All plan changes use one command.

/task:done organize-photos

  Appends completion summary to proposal.md.
  Moves to tasks/archive/2026-05-26-organize-photos/.

/task:verify organize-photos

  Runs verification checks (tests, lint, typecheck, build) via
  workflow-runtime.ts. Displays per-check pass/fail results.

/task:list

  Lists all active tasks with goals, progress, and verification status.
  Shows the 10 most recently archived tasks with outcomes.
```

## Artifacts

| File | Purpose | Who writes it |
|------|---------|--------------|
| `proposal.md` | What & why. Goal, motivation, scope, constraints. | `/task:plan` |
| `design.md` | How. Strategy, phases, key decisions, risks. | `/task:plan` |
| `tasks.md` | Checklist. Each line one verifiable action. `- [ ]` / `- [x]`. | `/task:plan` (planned), `/task:do` (checked) |
| `log.md` | Execution journal. Session starts/ends, checkpoints, plan revisions, blockers. | `/task:plan` (created + revisions), `/task:do` (auto), `/task:log` (manual) |

## Updating plans

Need to change direction mid-execution? Use the same command:

```
/task:plan organize-photos "narrow scope to PDF only, skip images"
  → Shows current state
  → Surgically edits only the relevant files
  → Preserves completed tasks and session history
  → Immediately records the revision in log.md
```

No separate `/task:replan` command needed. Git handles rollback if the change was wrong.

## Design decisions

**No guessing.** If a task description is ambiguous or the user's intent is unclear, the agent stops and asks. It never assumes. This is enforced in the skill instructions, not left to the model's discretion.

**Log.md is the backbone.** Every `/task:do` session writes a start entry before executing and an end entry on completion or blocker. `/task:plan` creates log.md during initial planning and appends after every revision — no more lost planning history. Checkpoints capture deltas — only what changed since the last checkpoint, not the full task state. This keeps the log lean enough to read, detailed enough to resume from.

**Artifacts are just markdown.** No YAML config, no JSON schema, no database. You can read, edit, or delete them with any text editor. The skills parse checkbox syntax (`- [ ]` / `- [x]`) and `##` headings. That's it.

**Language separation.** Public files (README, skills, commands, runtime.ts, CLAUDE.md) are written in English. Plan files (proposal.md, design.md, tasks.md, log.md) are written in Chinese. This is enforced by `CLAUDE.md` at the project root.

## Project structure

```
claude-task-workflow/
├── CLAUDE.md                        # Project conventions and language rules
├── workflow-runtime.ts              # Standalone TypeScript CLI (verify, checkpoint, status)
├── package.json / tsconfig.json     # Only for workflow-runtime.ts
├── README.md
├── commands/task/                   # 6 slash commands
│   ├── plan.md                      # Create OR update (merged replan)
│   ├── do.md
│   ├── done.md
│   ├── list.md
│   ├── log.md
│   └── verify.md                    # Standalone (no skill dependency)
└── skills/                          # 5 skills
    ├── task-plan/SKILL.md           # v2.1 — create + update mode
    ├── task-do/SKILL.md
    ├── task-done/SKILL.md
    ├── task-list/SKILL.md           # v2.0 — runtime-aware
    └── task-log/SKILL.md            # v2.0 — runtime-aware
```

## Install

```bash
git clone https://github.com/<your-username>/claude-task-workflow.git
cd claude-task-workflow

# macOS / Linux
./install.sh

# Windows (PowerShell)
.\install.ps1
```

Copies skills to `~/.claude/skills/` and commands to `~/.claude/commands/task/`. Restart Claude Code. No other setup.

## Requirements

- Claude Code
- Node.js >= 18 (for workflow-runtime.ts verification features)

## Project structure after use

```
your-project/
├── tasks/                            # Active
│   ├── organize-photos/
│   │   ├── proposal.md
│   │   ├── design.md
│   │   ├── tasks.md
│   │   └── log.md
│   └── migrate-database/
│       └── ...
└── tasks/archive/                    # Done
    ├── 2026-05-20-clean-downloads/
    └── 2026-05-26-organize-photos/
```
