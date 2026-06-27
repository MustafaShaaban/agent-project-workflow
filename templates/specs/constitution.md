# Project Constitution

## Quality principles

- Prefer clear, maintainable solutions that meet documented requirements.
- Keep changes scoped, reviewable, and reversible where practical.
- Preserve security, privacy, accessibility, and operational safety appropriate to the project.

## Source of truth

Resolve conflicts in this order: latest explicit owner instruction; repository agent instructions; this constitution; active specs; progress and decision records; README and docs; implementation code.

## Testing expectations

- Discover supported commands from project documentation and manifests.
- Run focused tests during development and broader checks before completion.
- Add or update tests when behavior changes.
- Report checks that could not run and the remaining risk.

## Documentation expectations

Keep user-facing, operational, architectural, progress, and decision documentation synchronized with meaningful changes. Do not use durable files as a scratchpad.

## Agent workflow

- Work from the real Git root and inspect status, branch, remotes, and worktrees first.
- Use no hidden worktree without explicit owner approval.
- Preserve user changes and use safe branches.
- Follow Spec Kit-first planning when Spec Kit is present; ask before initialization when absent.
- End work with verification evidence, blockers, recommended options, and a concrete next step.
