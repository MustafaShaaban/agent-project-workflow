# Agent Instructions

<!-- agent-project-workflow:start -->
## Automatic activation

For every project request, even if the user does not mention `project-workflow`, automatically follow the project-workflow startup sequence before planning, editing, writing code, changing docs, running commands, committing, pushing, or merging.

Startup sequence:

1. Resolve the real Git root with `git rev-parse --show-toplevel`.
2. Confirm the current directory is the root or move to the root.
3. Check `git status --short --branch`.
4. Check the current branch.
5. Check remotes.
6. Check worktrees.
7. Detect platform.
8. Detect CI/CD.
9. Detect project type/archetype.
10. Read `.ai-workflow.yml`.
11. Read `.ai-skills.json`.
12. Read `.agent-workflow.lock.json` if present.
13. Read `AGENTS.md`.
14. Read `CLAUDE.md` if present.
15. Read `PROJECT-WORKING-GUIDE.md`.
16. Read `PROGRESS.md`.
17. Read `DECISIONS.md`.
18. Read `specs/constitution.md` or `.specify/memory/constitution.md`.
19. Read the active spec if present.
20. State detected mode and recommended next step before implementation.

## Workflow authority

- `project-workflow` owns startup, repository detection, safety, verification, and handoff.
- Spec Kit owns clarify, spec, plan, and tasks for non-trivial work when it is enabled, requested, or detected.
- Guard skills are safety authorities only when their project or risk condition applies.
- Optional executor, build, debug, Superpowers, or similar skills may help only after active Spec Kit tasks exist.
- Do not use competing planning skills to replace Spec Kit unless the owner explicitly overrides this repository policy.

## Before implementation

- Confirm setup is complete and report the active spec and task IDs.
- For non-trivial work, stop if Spec Kit tasks do not exist. Ask to initialize or continue Spec Kit; never install it silently.
- Do not move from an incomplete bootstrap or audit directly into application implementation.

## Empty directory or missing Git

- Detect whether the directory has project indicators and whether it is the actual Git root.
- Ask whether to initialize Git unless the owner explicitly requested full bootstrap.
- Ask for the project type only when it cannot be inferred.
- Apply only approved workflow files, run doctor/audit, and stop with a recommended next step.

## Safety

- Work from the real Git root only.
- Do not create hidden worktrees without explicit owner approval.
- Preserve user changes and never rewrite history.
- Do not implement on `main` or `master` unless the owner explicitly approves it.
- Do not edit generated, vendor, build, cache, or upload directories unless explicitly required.
- Use Spec Kit for non-trivial, multi-file, security, API, database, CI/CD, WordPress production, and WooCommerce work.
- Ask recommendation-first questions only when repo inspection cannot answer safely.
- Keep `PROGRESS.md` and `DECISIONS.md` current.
- End with verification, recommended options, and mandatory `NEXT STEP`.
- Preserve all content outside this managed block, including project-specific notes.
<!-- agent-project-workflow:end -->

## Project-specific notes

Add team/project notes here. This section is preserved during workflow upgrades.
