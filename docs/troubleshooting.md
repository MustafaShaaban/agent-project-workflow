# Troubleshooting

## Skill is absent from the global list

Run installation from this repository root, then verify:

```powershell
npx -y skills add . --skill project-workflow --global --agent claude-code --agent codex --copy
npx -y skills ls -g
```

Check that Node.js and `npx` are available and that `skills/project-workflow/SKILL.md` exists. Review CLI errors before attempting manual cleanup.

If Windows PowerShell reports that a script is not digitally signed, use a process-scoped bypass instead of changing the machine policy:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify-install.ps1
```

## Claude Code or Codex did not use the skill

Restart the agent so it reloads global skills. Name the skill explicitly in the prompt: `Use project-workflow to start safely in this repo.` Verify that the correct agent was included during installation.

## Accidental project-local install

Remove only the project-local skill through the skills CLI when supported, or inspect the repository's agent-skill directory and remove the unintended `project-workflow` copy. Then reinstall with `--global --copy`. Preserve unrelated local skills.

## Duplicate installation

List global skills and inspect `%USERPROFILE%\.claude\skills`, `%USERPROFILE%\.agents\skills`, and any legacy `%USERPROFILE%\.codex\skills` directory. Use the removal command, clean only stale `project-workflow` directories if necessary, and install once.

## Wrong workspace or worktree

Stop editing and run:

```powershell
git rev-parse --show-toplevel
git status --short --branch
git branch --show-current
git worktree list
```

Return to the intended real root. Do not copy changes between worktrees or delete a worktree until the owner confirms how to preserve existing work.

## `specify` command not found

Spec Kit is optional. Report that it is unavailable, suggest its supported installation procedure, and ask before installing it. After installation, run `specify integration list` before choosing an integration ID.
