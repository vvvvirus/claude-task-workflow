# Claude Task Workflow

Plan → execute → archive any multi-step task inside Claude Code. File processing, data migration, research, content creation — anything that takes more than one step and is worth remembering later.

Not a code framework. No dependencies, no config, no CLI. Four slash commands and a directory of markdown files.

## Why this exists

Claude Code's built-in `/plan` is designed for coding — plan once, implement, move on. The plan evaporates. There's no pause-and-resume, no execution log, no archive.

This gives you a persistent workflow for everything else:

- **Pause anytime.** Stop mid-task, close the laptop, come back next week. `/task:do` reads the log and picks up where you left off.
- **Full traceability.** Every session is timestamped in `log.md` — what was done, what broke, what changed.
- **Archived memory.** Completed tasks live in `archive/` with a completion summary. Searchable, re-readble, never lost.

## How it works

```
/task:plan "organize 5000 photos by year and rename them"

  Creates:  tasks/organize-photos/
            ├── proposal.md    ← What & why. Goal, scope, constraints.
            ├── design.md      ← How. Strategy, key decisions, risks.
            └── tasks.md       ← Step-by-step checklist. Each line one action.

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
    → Unresolved blockers
  Asks if you want to add freeform notes. Can accept as-is.

/task:replan organize-photos

  Edits the plan without starting over.
  Asks what to change, surgically updates only the relevant files.
  Preserves completed checkboxes and session history.

/task:done organize-photos

  Appends completion summary to proposal.md.
  Moves to tasks/archive/2026-05-26-organize-photos/.

/task:list

  Shows all active tasks with progress, and recently archived ones.
```

## Artifacts

| File | Purpose | Who writes it |
|------|---------|--------------|
| `proposal.md` | What & why. Goal, motivation, scope, constraints. | `/task:plan` |
| `design.md` | How. Strategy, phases, key decisions, risks. | `/task:plan` |
| `tasks.md` | Checklist. Each line one verifiable action. `- [ ]` / `- [x]`. | `/task:plan` (planned), `/task:do` (checked) |
| `log.md` | Execution journal. Session starts/ends, checkpoints, blockers. | `/task:do` (auto), `/task:log` (manual) |

## Re-planning

Already started but need to change direction?

```
/task:replan organize-photos
  → Shows current state
  → Asks: "What needs to change?"
  → Surgically edits only the relevant files
  → Preserves completed tasks and session history
```

Also works with inline input: `/task:replan organize-photos "narrow scope to PDF only, skip images"`

## Design decisions

**No guessing.** If a task description is ambiguous or the user's intent is unclear, the agent stops and asks. It never assumes. This is enforced in the skill instructions, not left to the model's discretion.

**Log.md is the backbone.** Every `/task:do` session writes a start entry before executing and an end entry on completion or blocker. Checkpoints capture deltas — only what changed since the last checkpoint, not the full task state. This keeps the log lean enough to read, detailed enough to resume from.

**Artifacts are just markdown.** No YAML config, no JSON schema, no database. You can read, edit, or delete them with any text editor. The skills parse checkbox syntax (`- [ ]` / `- [x]`) and `##` headings. That's it.

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
- Nothing else.

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
