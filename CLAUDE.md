# CLAUDE.md

This is a Claude Code task workflow toolkit — a collection of slash commands and skills for planning, executing, logging, and archiving multi-step tasks inside Claude Code. Not a code framework. No dependencies, no config, no CLI.

## Repo Structure

```
skills/           ← Skill source files (installed to ~/.claude/skills/)
commands/task/    ← Command source files (installed to ~/.claude/commands/task/)
task-workflow/    ← Runtime source files (installed to ~/.claude/task-workflow/)
install.sh        ← Linux/macOS installer
install.ps1       ← Windows installer
CLAUDE.md
README.md
LICENSE
```

## Language Rules

- **Public files**: English only. This includes README.md, all skill files (`skills/*/SKILL.md`), all command files (`commands/task/*.md`), `task-workflow/workflow-runtime.ts`, `CLAUDE.md`, install scripts, LICENSE, and `.gitignore`.
- **Plan files**: In the user's language. This includes `proposal.md`, `design.md`, `tasks.md`, and `log.md` inside any `tasks/<name>/` directory. Section headers in generated plan files should match the language the user communicates in.

## Code Standards

- Max 400 lines per file. Split if exceeded.
- Max 4 levels of nesting. Flatten if exceeded.
- Prefer targeted edits over rewriting entire files.
- No guessing: if unclear, ask the user before assuming.

## Skill / Command Architecture

- Each slash command (`commands/task/<name>.md`) delegates to a skill (`skills/task-<name>/SKILL.md`) via the Skill tool.
- Commands are thin wrappers — they describe the intent and invoke the skill. Skills contain the full step-by-step instructions.
- Exception: `/task:verify` has no dedicated skill. Its logic lives directly in the command file.

## Runtime

- `task-workflow/workflow-runtime.ts` is a standalone TypeScript CLI invoked via `npx tsx task-workflow/workflow-runtime.ts <command>` from the repo root, or `npx tsx ~/.claude/task-workflow/workflow-runtime.ts <command>` after installation.
- TypeScript interfaces at the top of `task-workflow/workflow-runtime.ts` are the authoritative source for data structures.
- No separate JSON Schema files — the TS interfaces serve as both documentation and type enforcement.
