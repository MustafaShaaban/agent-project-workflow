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

## Agent used Superpowers or another skill instead of Spec Kit

This happens when a globally installed workflow skill activates before the agent
reads repository-local authority rules, or when older generated files do not
state precedence clearly.

Detect it by checking whether the agent created planning artifacts outside the
active Spec Kit spec/plan/tasks, skipped `.specify/`, or started implementation
without completing checklist, tasks, and analyze.

Stop safely: do not delete the other skill's notes, do not continue coding, and
do not initialize new tooling. Re-run project-workflow and reconcile only useful
material into Spec Kit after owner review.

Recovery prompt:

```text
Stop the competing planning workflow. Use project-workflow to inspect the repo and
preserve current work. Spec Kit owns clarify/spec/plan/tasks. Reconcile useful notes
into the active Spec Kit files, report missing decisions, and do not implement until
active tasks exist.
```

Then run:

```powershell
.\scripts\project-workflow.ps1 audit
.\scripts\project-workflow.ps1 doctor
```

## I started from an empty folder and the agent did not ask me anything

Stop before implementation. The expected order is state detection, Git decision,
project type decision when unknown, workflow-file preview, Spec Kit decision,
doctor/audit, and a recommended next step.

Use:

```text
Use project-workflow to restart this empty-folder setup. Report whether the folder
is empty and whether Git is initialized. Ask before Git or Spec Kit init, ask for
project type only if unknown, and stop after doctor/audit without implementing.
```

## The examples are confusing or I do not know which one to use

Start with the recommended first prompt in [usage.md](usage.md). For CLI use,
run `init -Type auto -Profile standard -DryRun`. Dry-run detects the path and
prints the next decision without changing files.

## Spec Kit was not initialized because I said ask before init

That is correct behavior. "Ask before" is not approval. Review the proposed
integration and then explicitly approve initialization, or run the documented
`init ... -SpecKit -Apply` command. Until then, the workflow should stop before
non-trivial implementation.
