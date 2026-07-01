# agent-project-workflow

A portable, professional AI project workflow system for
software repositories. It provides the global
`project-workflow` skill, workflow profiles, platform
adapters, guard scripts, PR templates, and project starter
templates that work with any Git repository—including GitHub
and Azure DevOps projects.

## Start here

> **Recommended first prompt**
>
> `Use project-workflow to inspect this folder, recommend the safe setup path, preserve existing files, ask before Git or Spec Kit initialization, and stop after doctor/audit with the next step. Do not implement the project yet.`

Choose the scenario that matches what you have.

### A. Empty folder or greenfield project

Codex:

```text
Use project-workflow to bootstrap this empty folder with the standard workflow.
Ask whether to initialize Git, ask for project type only if it cannot be inferred,
preserve files, ask before Spec Kit init, run doctor/audit, and stop before implementation.
```

Claude Code:

```text
Use the project-workflow skill for this empty folder. Detect Git and project state,
ask for unresolved setup decisions, create only approved workflow files, ask before
Spec Kit init, run doctor/audit, and stop with the next step.
```

### B. Existing repository

Codex:

```text
Use project-workflow to audit and initialize this existing repo safely. Detect Git,
branch, remotes, worktrees, platform, CI, project type, workflow files, skills, and
Spec Kit. Preview first, preserve owner files, and stop if setup is incomplete.
```

Claude Code:

```text
Use the project-workflow skill to inspect this existing repository. Preserve all
owner files, recommend dry-run or upgrade where needed, and do not implement until
workflow and Spec Kit decisions are complete.
```

### C. Audit only

Codex:

```text
Use project-workflow in observe-only mode. Report repository and workflow readiness,
Spec Kit status, skill authority, and the next action. Do not change files.
```

Claude Code:

```text
Use the project-workflow skill for a read-only audit. Make no file, tool, Git,
commit, or push changes.
```

### D. Continue existing Spec Kit work

Codex:

```text
Use project-workflow to continue the active Spec Kit work. Read the constitution,
spec, clarification, plan, checklist, tasks, analysis, progress, and decisions;
report the next incomplete stage first.
```

Claude Code:

```text
Use the project-workflow skill for startup and Spec Kit as the planning source of
truth. Continue the next active task and preserve unrelated changes.
```

After successful initialization, future Codex and Claude
sessions should read `AGENTS.md` or `CLAUDE.md`
automatically. You normally do not need to repeat the
startup prompt.

## What it does

- Gives AI agents (Claude Code, Codex) a safe, consistent
  startup routine for any repository
- Detects platform (GitHub / Azure DevOps / generic Git),
  project type, and CI
- Enforces configurable workflow profiles: `minimal`,
  `standard`, `strict`, and `enterprise`
- Supports Git Flow, GitHub Flow, and trunk-based branching
  strategies
- Guards against unsafe edits, branch violations, and
  missing skills
- Requires `wp-guard` for WordPress projects (via companion
  skill)
- Produces structured handoffs with platform, project type,
  skills status, and next steps

## What not to expect

- It does not own your application architecture, framework,
  or language choices
- It does not force a branching strategy unless you
  configure one
- It does not install or initialize Spec Kit without
  approval
- It does not overwrite existing workflow files by default
- It does not create hidden worktrees or discard local
  changes
- It does not push to GitHub or Azure DevOps without
  explicit instruction
- It does not install missing skills silently (always asks
  unless configuration allows it)
- It does not let Superpowers or another optional skill
  replace Spec Kit planning unless the owner explicitly
  overrides the repository policy

## Exact enforced Spec Kit order

For non-trivial work, use this production order without
skipping or reordering:

```text
/speckit.constitution
/speckit.specify
/speckit.clarify
/speckit.plan
/speckit.checklist
/speckit.tasks
/speckit.analyze
/speckit.implement
/speckit.converge
```

Codex skills mode uses the equivalent order:

```text
$speckit-constitution
$speckit-specify
$speckit-clarify
$speckit-plan
$speckit-checklist
$speckit-tasks
$speckit-analyze
$speckit-implement
$speckit-converge
```

Run `converge` only when that command is available and
convergence is needed; record it as not applicable
otherwise. Optional skills cannot replace any step.

## Quick install

```powershell
.\scripts\install-global.ps1
```

Or:

```powershell
npx -y skills add . --skill project-workflow --global --agent claude-code --agent codex --copy
```

Without a local clone:

```powershell
npx -y skills add MustafaShaaban/agent-project-workflow --skill project-workflow --global --agent claude-code --agent codex --copy
```

## Quick CLI usage

Preview initialization first:

```powershell
.\scripts\project-workflow.ps1 init -Type auto -Profile standard -SpecKit -Agents codex,claude-code -DryRun
```

Apply only after reviewing the preview:

```powershell
.\scripts\project-workflow.ps1 init -Type auto -Profile standard -SpecKit -Agents codex,claude-code -Apply
.\scripts\project-workflow.ps1 doctor
```

If auto-detection is uncertain, the CLI stops without
writing and recommends an explicit type. WordPress is one
supported archetype, not the default.

After `init -Apply`, supported agents follow the repo-local
workflow automatically from `AGENTS.md`, `CLAUDE.md`, and
`PROJECT-WORKING-GUIDE.md`.

Create a new project starter:

```powershell
.\scripts\project-workflow.ps1 new -ProjectName my-app -Type react -Profile standard -SpecKit
```

Audit and validate an existing project:

```powershell
.\scripts\project-workflow.ps1 audit
.\scripts\project-workflow.ps1 doctor
```

Upgrade managed workflow blocks:

```powershell
.\scripts\project-workflow.ps1 upgrade -DryRun
.\scripts\project-workflow.ps1 upgrade -Apply
```

Upgrade changes only the content between the exact managed
markers. Text before or after the block remains
owner-managed. Files without one valid marker pair are never
overwritten; the CLI writes `<name>.suggested.md` for
review.

Install only approved skills:

```powershell
.\scripts\project-workflow.ps1 install-skills -ApprovedOnly
```

The older scripts remain available for focused checks, but
`scripts/project-workflow.ps1` is the primary command
surface.

The CLI auto-detects standalone WordPress plugins, themes,
blocks, Bedrock projects, WooCommerce extensions, and whole
WordPress sites. `audit -Json` reports the detected
archetype, and `doctor -Json` exposes readiness score,
warnings, blocking items, and the recommended next action.

## Project config

Copy `.ai-workflow.yml` to your project root and adjust:

```powershell
Copy-Item templates\.ai-workflow.yml C:\path\to\project\.ai-workflow.yml
```

Key settings:

```yaml
workflow:
  profile: standard # minimal | standard | strict | enterprise
  mode: normal # observe-only | safe-bootstrap | strict-migration | normal

branching:
  strategy: github-flow # git-flow | github-flow | trunk-based | custom
  production_branch: main

skills:
  install_mode: ask # ask | auto-approved-only | never
```

Optionally copy `.ai-skills.json` for machine-readable skill
requirements.

## Workflow profiles

| Profile      | Use case                                                |
| ------------ | ------------------------------------------------------- |
| `minimal`    | Prototypes, experiments, throwaway scripts              |
| `standard`   | Most professional and team projects (default)           |
| `strict`     | Production systems, fintech, healthcare, regulated work |
| `enterprise` | Large teams, multi-team, compliance-required projects   |

See [docs/profiles.md](docs/profiles.md) for full details.

## Platform support

| Platform     | Detection  | Templates                                 | Docs                                         |
| ------------ | ---------- | ----------------------------------------- | -------------------------------------------- |
| GitHub       | ✅ Auto    | PR template, CODEOWNERS, Actions guide    | [docs/github.md](docs/github.md)             |
| Azure DevOps | ✅ Auto    | PR template, pipeline guide, policy guide | [docs/azure-devops.md](docs/azure-devops.md) |
| Generic Git  | ✅ Default | PR checklist, release process             | [docs/generic-git.md](docs/generic-git.md)   |

## Git Flow support

Git Flow is optional. Enable with:

```yaml
branching:
  strategy: git-flow
  production_branch: main
  integration_branch: develop
```

The skill and guard scripts enforce Git Flow rules when
configured. See [docs/git-flow.md](docs/git-flow.md).

## Existing project modes

| Mode               | What happens                                       |
| ------------------ | -------------------------------------------------- |
| `observe-only`     | Audit only — zero file changes                     |
| `safe-bootstrap`   | Add missing files, skip existing (default)         |
| `strict-migration` | Propose Git Flow migration, require owner approval |

See [docs/existing-projects.md](docs/existing-projects.md).

## WordPress support

If WordPress indicators are detected, the `wp-guard`
companion skill is required. `project-workflow` is the
universal orchestrator; `wp-guard` handles
WordPress-specific safety rules (core protection,
plugin/theme safety, etc.).

WordPress presets include site, plugin, theme, block,
Bedrock, and WooCommerce-oriented modes. WooCommerce work
requires `woo-guard` and treats checkout, orders, payments,
shipping, tax, customer data, and PII as high-risk work that
requires Spec Kit before implementation.

The five companion guards are real installable skills from
`amElnagdy/guard-skills`: `clean-code-guard`, `test-guard`,
`docs-guard`, `wp-guard`, and `woo-guard`. Generated policy
includes their install commands, but leaves
`install_approved: false`; `install-skills -ApprovedOnly`
will not install them until the project owner explicitly
approves that source.

See [docs/wordpress.md](docs/wordpress.md).

## Guard scripts

| Script                               | Purpose                                  |
| ------------------------------------ | ---------------------------------------- |
| `scripts/audit-project-workflow.ps1` | Full project audit (read-only)           |
| `scripts/guard-git-flow.ps1`         | Validate branch state and Git Flow rules |
| `scripts/guard-before-edit.ps1`      | Pre-edit safety check                    |
| `scripts/guard-before-merge.ps1`     | Pre-merge / pre-release check            |
| `scripts/bootstrap-project.ps1`      | Add workflow files to a project          |

## Templates

| Template                       | Path                                              |
| ------------------------------ | ------------------------------------------------- |
| Project config                 | `templates/.ai-workflow.yml`                      |
| Skills config                  | `templates/.ai-skills.json`                       |
| GitHub PR template             | `templates/github/pull_request_template.md`       |
| GitHub CODEOWNERS              | `templates/github/CODEOWNERS`                     |
| GitHub branch protection guide | `templates/github/branch-protection-guide.md`     |
| Azure DevOps PR template       | `templates/azure-devops/pull_request_template.md` |
| Azure DevOps policy guide      | `templates/azure-devops/branch-policy-guide.md`   |
| Generic Git PR checklist       | `templates/generic-git/pr-checklist.md`           |
| Generic Git release process    | `templates/generic-git/release-process.md`        |
| Release checklist              | `templates/release-checklist.md`                  |
| Hotfix checklist               | `templates/hotfix-checklist.md`                   |
| AGENTS.md starter              | `templates/AGENTS.md`                             |
| CLAUDE.md starter              | `templates/CLAUDE.md`                             |
| Project working guide          | `templates/PROJECT-WORKING-GUIDE.md`              |
| PROGRESS.md starter            | `templates/PROGRESS.md`                           |
| DECISIONS.md starter           | `templates/DECISIONS.md`                          |
| Spec Kit constitution          | `templates/specs/constitution.md`                 |

## Documentation

| Doc                                                          | Purpose                                        |
| ------------------------------------------------------------ | ---------------------------------------------- |
| [docs/install.md](docs/install.md)                           | Installation and removal                       |
| [docs/cli.md](docs/cli.md)                                   | First-class command usage                      |
| [docs/usage.md](docs/usage.md)                               | Example prompts and usage patterns             |
| [docs/presets.md](docs/presets.md)                           | Preset structure and archetypes                |
| [docs/bundles.md](docs/bundles.md)                           | Bundle shortcuts                               |
| [docs/profiles.md](docs/profiles.md)                         | Workflow profile reference                     |
| [docs/git-flow.md](docs/git-flow.md)                         | Git Flow configuration and rules               |
| [docs/existing-projects.md](docs/existing-projects.md)       | observe-only, safe-bootstrap, strict-migration |
| [docs/project-bootstrap.md](docs/project-bootstrap.md)       | Bootstrapping new and existing projects        |
| [docs/wordpress.md](docs/wordpress.md)                       | WordPress detection and wp-guard               |
| [docs/wordpress-preset.md](docs/wordpress-preset.md)         | WordPress preset rules                         |
| [docs/question-engine.md](docs/question-engine.md)           | Recommendation-first questions                 |
| [docs/automatic-activation.md](docs/automatic-activation.md) | Repo-local automatic startup                   |
| [docs/ci-enforcement.md](docs/ci-enforcement.md)             | CI workflow enforcement                        |
| [docs/skills-policy.md](docs/skills-policy.md)               | Skill install and guard policy                 |
| [docs/github.md](docs/github.md)                             | GitHub platform guidance                       |
| [docs/azure-devops.md](docs/azure-devops.md)                 | Azure DevOps platform guidance                 |
| [docs/generic-git.md](docs/generic-git.md)                   | Generic Git guidance                           |
| [docs/definition-of-done.md](docs/definition-of-done.md)     | Definition of done for AI-assisted tasks       |
| [docs/compatibility.md](docs/compatibility.md)               | Supported environments and platforms           |
| [docs/upgrade.md](docs/upgrade.md)                           | Upgrading from older versions                  |
| [docs/testing.md](docs/testing.md)                           | Running tests and manual verification          |
| [docs/spec-kit.md](docs/spec-kit.md)                         | Spec Kit integration                           |
| [docs/handoff-format.md](docs/handoff-format.md)             | Handoff format reference                       |
| [docs/troubleshooting.md](docs/troubleshooting.md)           | Common issues and fixes                        |

## Uninstall

```powershell
.\scripts\remove-global.ps1
```

## Repository verification

The repository validates PowerShell syntax, JSON/YAML
structure, managed-block safety, presets, documentation,
anti-collapse line counts, and CLI behavior:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\test-workflow.ps1
git diff --check
```

For a focused byte-level check of GitHub raw readability and
hidden Unicode:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\verify-raw-readability.ps1
```

This check reports normalized line counts for the primary
README, Spec Kit guide, workflow YAML, and skills JSON. It
rejects collapsed content, embedded Markdown headings,
multiple workflow YAML keys on one line, compact policy
JSON, invalid UTF-8, and hidden or bidirectional Unicode
control characters.

`.github/workflows/verify.yml` runs the same checks for
pushes and pull requests targeting `master`.
