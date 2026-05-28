# CLAUDE.md

This is a Claude Code task workflow toolkit — a collection of slash commands and skills for planning, executing, logging, and archiving multi-step tasks inside Claude Code. Not a code framework. No dependencies, no config, no CLI.

## Language Rules

- **Public files**: English only. This includes README.md, all skill files (`skills/*/SKILL.md`), all command files (`commands/task/*.md`), `workflow-runtime.ts`, `CLAUDE.md`, install scripts, LICENSE, and `.gitignore`.
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

- `workflow-runtime.ts` is a standalone TypeScript CLI invoked via `npx tsx workflow-runtime.ts <command>`.
- TypeScript interfaces at the top of `workflow-runtime.ts` are the authoritative source for data structures.
- No separate JSON Schema files — the TS interfaces serve as both documentation and type enforcement.
