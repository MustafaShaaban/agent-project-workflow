# Usage

The global skill supplies a generic routine. Project-owned `AGENTS.md`, `CLAUDE.md`, constitution, specs, and docs remain authoritative.

## Claude Code

```text
Use the project-workflow skill. Start safely in this repo, read its rules, and report the current mode before editing.
```

## Codex

```text
Use project-workflow to continue from PROGRESS.md. Verify the real root, branch, worktree, and active spec first.
```

## Example prompts

Initialize a repository:

```text
Use project-workflow to initialize this repo with my standard workflow. Preserve existing files and ask before Spec Kit init.
```

Start safely:

```text
Use project-workflow and start safely in this repo. Do not edit until you have checked the real root, status, branch, remotes, worktrees, and project rules.
```

Review status:

```text
Use project-workflow to review current project status, active specs, progress, decisions, blockers, and the recommended next step. Make no file changes.
```

Continue durable work:

```text
Use project-workflow to continue from PROGRESS.md and the active spec. Preserve unrelated changes and update durable state when meaningful progress is complete.
```

Create a Spec Kit plan:

```text
Use project-workflow to detect the existing Spec Kit setup, clarify the requested feature, and create its plan and tasks. Ask before installing or initializing anything missing.
```

Close a session:

```text
Use project-workflow to verify the work, update PROGRESS.md and any durable decisions, then close the session with the full handoff and NEXT STEP block.
```
