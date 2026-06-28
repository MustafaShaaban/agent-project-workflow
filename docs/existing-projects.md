# Working with Existing Projects

The workflow system supports three modes for existing projects. Set the mode in
`.ai-workflow.yml` or pass it to the bootstrap script.

## observe-only

**Use when:** You want to audit a project before making any changes. The agent
and scripts will report the current state without modifying any file.

**What happens:**
- Reads Git root, branch, remotes, worktrees
- Detects platform, CI, project type, branch strategy
- Lists present and missing workflow files
- Reports risks and recommended next steps
- Makes **zero file modifications**

**How to use:**

Agent prompt:
```text
Use project-workflow in observe-only mode. Audit this repository and report its
current state, missing workflow files, detected platform, project type, and any
risks. Do not modify anything.
```

Script:
```powershell
.\scripts\audit-project-workflow.ps1 -TargetPath C:\path\to\project
.\scripts\bootstrap-project.ps1 -TargetPath C:\path\to\project -Mode observe-only
```

---

## safe-bootstrap (default)

**Use when:** You want to add the standard workflow files to a project that does
not have them yet, without touching existing files.

**What happens:**
- Adds missing workflow files (`AGENTS.md`, `CLAUDE.md`, `PROGRESS.md`, etc.)
- **Skips** any file that already exists
- Does not change branch strategy, CI config, or existing docs
- Optionally copies `.ai-workflow.yml` and `.ai-skills.json` templates

**How to use:**

```powershell
.\scripts\bootstrap-project.ps1 -TargetPath C:\path\to\project
# With config templates:
.\scripts\bootstrap-project.ps1 -TargetPath C:\path\to\project -IncludeConfig
```

After bootstrap, open each generated file and replace placeholders with
project-specific content before committing.

---

## strict-migration

**Use when:** You want to migrate an existing project to strict Git Flow and
full workflow policies.

**What happens:**
- Proposes a migration plan (does not execute automatically)
- Lists what would change: branching strategy, required docs, guard scripts
- Requires **explicit owner approval** for each step
- Never rewrites history
- Never deletes or renames branches automatically
- Produces a step-by-step migration checklist for the owner to review

**How to use:**

Agent prompt:
```text
Use project-workflow in strict-migration mode. Propose a migration plan for this
project to adopt strict Git Flow and the full workflow policy. Present the plan
and wait for my approval before making any changes.
```

**Migration checklist (example):**
1. Create `develop` from `main` (if not present)
2. Update `.ai-workflow.yml` to `strategy: git-flow` and `profile: strict`
3. Copy/update `AGENTS.md`, `CLAUDE.md`, `PROJECT-WORKING-GUIDE.md` from templates
4. Create/update `PROGRESS.md` and `DECISIONS.md`
5. Set up branch protection on `main` and `develop`
6. Add guard scripts to CI (optional)
7. Communicate branching rules to the team

---

## Preserving existing work

In all modes:
- **Never** overwrite existing files without `-Force` (scripts) or explicit owner approval (agent)
- **Never** discard uncommitted changes
- **Never** rewrite history
- Read existing `AGENTS.md`/`CLAUDE.md` as authoritative — they may override defaults

If the existing project has its own branching model, document it in `.ai-workflow.yml`
and set `branching.strategy: custom` so the agent knows to read project rules instead
of enforcing a default model.
