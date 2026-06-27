# Agent Instructions

## Project purpose

`[Describe the project's purpose, users, and primary outcomes.]`

## First read

Before editing, read `AGENTS.md`, `CLAUDE.md`, `README.md`, `PROJECT-WORKING-GUIDE.md`, `PROGRESS.md`, `DECISIONS.md`, `specs/constitution.md`, and the active spec files that exist.

## Workspace safety

- Resolve the real root with `git rev-parse --show-toplevel` and work only there.
- Review status, branch, remotes, and `git worktree list` before changing files.
- Do not create or use hidden worktrees such as `.worktrees/` without explicit owner approval for the session.
- Stop if the directory, checkout, or worktree is unexpected.

## Branch and change safety

- Do not implement on `main` or `master` except for initial repository creation or explicit owner approval.
- Use a named branch for feature and fix work.
- Never discard, overwrite, or hide user changes.

## Planning and memory

- Use Spec Kit-first planning when the repository has adopted Spec Kit.
- Ask before installing or initializing Spec Kit.
- Record meaningful progress in `PROGRESS.md`.
- Record durable owner and architecture decisions in `DECISIONS.md`; do not log temporary thoughts as decisions.

## Verification and handoff

Discover and run the project's relevant tests and guards. Run focused checks first and broader checks before completion. End real work with the full handoff format documented in `PROJECT-WORKING-GUIDE.md`; always include a `NEXT STEP` with the recommended action, rationale, alternatives, and blockers.

