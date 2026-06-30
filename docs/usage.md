# User guide

Use project-workflow when you open a new folder, adopt an existing repository,
audit workflow readiness, or continue work that already has a Spec Kit spec.
It works with generic Git, GitHub, Azure DevOps, Codex, and Claude Code. WordPress
is a supported archetype, not the default.

> Recommended first prompt
>
> `Use project-workflow to inspect this folder, recommend the safe setup path,
> preserve existing files, ask before Git or Spec Kit initialization, and stop
> after doctor/audit with the next step. Do not implement the project yet.`

## Which prompt should I use?

| I want to... | Use this section |
|---|---|
| Start in an empty folder | Empty folder, no Git |
| Initialize workflow files | Empty Git repository or Existing project |
| Inspect without changes | Audit only |
| Create a named starter | Create a new project starter |
| Continue work later | Continue an active spec |
| Enforce Spec Kit | Initialize Spec Kit planning |
| Enable WordPress guards | WordPress project |
| Make no changes yet | Audit only |

### Empty folder, no Git

Codex or Claude Code:

```text
Use project-workflow to bootstrap this empty folder with the standard workflow.
Detect the current state, ask whether to initialize Git, ask for project type only
if it cannot be inferred, preserve existing files, and ask before Spec Kit init.
Create only approved workflow files, run doctor/audit, and stop before implementation.
```

Expected behavior: the agent reports that the directory is empty and Git is not
initialized, asks about Git, then asks for an archetype only when needed. It must
not build the application yet.

### Empty Git repository

```text
Use project-workflow to initialize workflow files in this empty Git repository.
Ask for the project type only if it cannot be inferred. Ask before Spec Kit init,
run doctor/audit, and stop with the recommended next step.
```

Expected behavior: the agent recognizes the Git root, does not ask to run
`git init` again, and requests the missing project type before writing files.

### Existing project

```text
Use project-workflow to inspect and initialize this existing repo safely.
Detect Git, branch, remotes, worktrees, platform, CI, project type, workflow files,
skills, and Spec Kit status. Preview changes first, preserve owner files, and stop
before implementation if setup is incomplete.
```

Expected behavior: the agent infers the project type when possible, proposes
`.suggested.md` files instead of overwriting unmanaged files, and recommends
`upgrade -DryRun` when managed files are outdated.

### Create a new project starter

```text
Use project-workflow to create a new project starter named my-app. Ask for the
project archetype if it is not specified, initialize Git, apply the standard
workflow safely, ask before Spec Kit init, run doctor/audit, and stop before
application implementation.
```

Expected behavior: the agent uses `new` for a new named directory. It completes
workflow setup, then hands off to Spec Kit planning instead of immediately
generating application code.

### WordPress project

```text
Use project-workflow to audit this WordPress project. Detect whether it is a site,
plugin, theme, block, Bedrock, or WooCommerce project. Check the conditional
WordPress guards, ask before installing anything, and do not implement yet.
```

Expected behavior: `wp-guard` is required only after WordPress is detected;
`woo-guard` is additionally required for WooCommerce. Generic projects do not
inherit WordPress requirements.

### Unknown project type

```text
Use project-workflow to inspect this folder. If the project type is still unknown,
show the recommended type and alternatives, ask me to choose, and make no changes.
```

Expected behavior: detection runs first. The agent recommends `generic` when no
framework evidence exists and waits rather than guessing.

### Audit only

```text
Use project-workflow in observe-only mode. Report Git state, platform, CI, project
type, workflow files, required skills, Spec Kit status, authority policy, and the
recommended next step. Do not change files, install tools, commit, or push.
```

Expected behavior: zero writes. Use this when you want facts before deciding.

### Initialize Spec Kit planning

```text
Use project-workflow to verify the repo is ready, then ask for approval to initialize
Spec Kit for Codex and Claude Code. After approval, use Spec Kit to clarify the work
and produce the spec, plan, and tasks. Do not implement until tasks exist.
```

Expected behavior: project-workflow remains the startup authority. Spec Kit becomes
the planning source of truth. Missing Spec Kit triggers an ask, never silent install.

### Continue an active spec

```text
Use project-workflow to continue the active Spec Kit work. Read the repo rules,
PROGRESS.md, constitution, active spec, plan, and tasks. Report the next incomplete
task before implementation and preserve unrelated changes.
```

### Implement after tasks exist

```text
Use project-workflow to implement the next active Spec Kit task. Treat the spec,
plan, and tasks as the planning source of truth. Optional executor skills may help
with execution only; they must not replace or rewrite Spec Kit planning.
```

## CLI: preview, then apply

Safest preview for an existing project:

```powershell
.\scripts\project-workflow.ps1 init -Type auto -Profile standard -SpecKit -Agents codex,claude-code -DryRun
```

After reviewing the output and approving Spec Kit initialization:

```powershell
.\scripts\project-workflow.ps1 init -Type auto -Profile standard -SpecKit -Agents codex,claude-code -Apply
.\scripts\project-workflow.ps1 doctor
```

If auto-detection cannot identify the type, rerun with an explicit type such as
`generic`, `php`, `js-ts`, `react`, `laravel`, `python`, or a WordPress archetype.

## When to use this

Use it for repository startup, workflow adoption, audits, upgrades, durable Spec
Kit work, and safe handoffs.

## When not to use this

Do not use `init` to generate application source. Use `new` for a named starter,
then complete workflow and Spec Kit decisions before implementation. For a tiny
throwaway experiment, choose the minimal profile or explicitly decline Spec Kit.
