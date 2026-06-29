# agent-project-workflow

A portable, professional AI project workflow system for software repositories.
It provides the global `project-workflow` skill, workflow profiles, platform
adapters, guard scripts, PR templates, and project starter templates that work
with any Git repository—including GitHub and Azure DevOps projects.

## What it does

- Gives AI agents (Claude Code, Codex) a safe, consistent startup routine for
  any repository
- Detects platform (GitHub / Azure DevOps / generic Git), project type, and CI
- Enforces configurable workflow profiles: `minimal`, `standard`, `strict`,
  and `enterprise`
- Supports Git Flow, GitHub Flow, and trunk-based branching strategies
- Guards against unsafe edits, branch violations, and missing skills
- Requires `wp-guard` for WordPress projects (via companion skill)
- Produces structured handoffs with platform, project type, skills status,
  and next steps

## What it does NOT do

- It does not own your application architecture, framework, or language choices
- It does not force a branching strategy unless you configure one
- It does not install or initialize Spec Kit without approval
- It does not overwrite existing workflow files by default
- It does not create hidden worktrees or discard local changes
- It does not push to GitHub or Azure DevOps without explicit instruction
- It does not install missing skills silently (always asks unless configuration
  allows it)

## Quick install

```powershell
.\scripts\install-global.ps1
```

Or:

```powershell
npx -y skills add . --skill project-workflow --global --agent claude-code --agent codex --copy
```

## Quick usage

Initialize an existing WordPress project safely:

```powershell
.\scripts\project-workflow.ps1 init -Type wordpress-site -Profile standard -SpecKit -Agents codex,claude-code -DryRun
.\scripts\project-workflow.ps1 init -Type wordpress-site -Profile standard -SpecKit -Agents codex,claude-code -Apply
```

After `init -Apply`, supported agents follow the repo-local workflow automatically from `AGENTS.md`, `CLAUDE.md`, and `PROJECT-WORKING-GUIDE.md`; you should not need to repeat "use project-workflow" in normal work.

Create a new project starter:

```powershell
.\scripts\project-workflow.ps1 new -ProjectName my-wordpress-site -Type wordpress-site -Profile standard -SpecKit
```

Audit and validate an existing project:

```powershell
.\scripts\project-workflow.ps1 audit
.\scripts\project-workflow.ps1 doctor
```

Upgrade managed workflow blocks:

```powershell
.\scripts\project-workflow.ps1 upgrade -Apply
```

Install only approved skills:

```powershell
.\scripts\project-workflow.ps1 install-skills -ApprovedOnly
```

The older scripts remain available for focused checks, but `scripts/project-workflow.ps1` is the primary command surface.

## Project config

Copy `.ai-workflow.yml` to your project root and adjust:

```powershell
Copy-Item templates\.ai-workflow.yml C:\path\to\project\.ai-workflow.yml
```

Key settings:

```yaml
workflow:
  profile: standard        # minimal | standard | strict | enterprise
  mode: normal             # observe-only | safe-bootstrap | strict-migration | normal

branching:
  strategy: github-flow    # git-flow | github-flow | trunk-based | custom
  production_branch: main

skills:
  install_mode: ask        # ask | auto-approved-only | never
```

Optionally copy `.ai-skills.json` for machine-readable skill requirements.

## Workflow profiles

| Profile | Use case |
|---------|----------|
| `minimal` | Prototypes, experiments, throwaway scripts |
| `standard` | Most professional and team projects (default) |
| `strict` | Production systems, fintech, healthcare, regulated work |
| `enterprise` | Large teams, multi-team, compliance-required projects |

See [docs/profiles.md](docs/profiles.md) for full details.

## Platform support

| Platform | Detection | Templates | Docs |
|----------|-----------|-----------|------|
| GitHub | ✅ Auto | PR template, CODEOWNERS, Actions guide | [docs/github.md](docs/github.md) |
| Azure DevOps | ✅ Auto | PR template, pipeline guide, policy guide | [docs/azure-devops.md](docs/azure-devops.md) |
| Generic Git | ✅ Default | PR checklist, release process | [docs/generic-git.md](docs/generic-git.md) |

## Git Flow support

Git Flow is optional. Enable with:

```yaml
branching:
  strategy: git-flow
  production_branch: main
  integration_branch: develop
```

The skill and guard scripts enforce Git Flow rules when configured.
See [docs/git-flow.md](docs/git-flow.md).

## Existing project modes

| Mode | What happens |
|------|-------------|
| `observe-only` | Audit only — zero file changes |
| `safe-bootstrap` | Add missing files, skip existing (default) |
| `strict-migration` | Propose Git Flow migration, require owner approval |

See [docs/existing-projects.md](docs/existing-projects.md).

## WordPress support

If WordPress indicators are detected, the `wp-guard` companion skill is required.
`project-workflow` is the universal orchestrator; `wp-guard` handles
WordPress-specific safety rules (core protection, plugin/theme safety, etc.).

WordPress presets include site, plugin, theme, block, Bedrock, and WooCommerce-oriented modes. WooCommerce work requires `woo-guard` and treats checkout, orders, payments, shipping, tax, customer data, and PII as high-risk work that requires Spec Kit before implementation.

See [docs/wordpress.md](docs/wordpress.md).

## Guard scripts

| Script | Purpose |
|--------|---------|
| `scripts/audit-project-workflow.ps1` | Full project audit (read-only) |
| `scripts/guard-git-flow.ps1` | Validate branch state and Git Flow rules |
| `scripts/guard-before-edit.ps1` | Pre-edit safety check |
| `scripts/guard-before-merge.ps1` | Pre-merge / pre-release check |
| `scripts/bootstrap-project.ps1` | Add workflow files to a project |

## Templates

| Template | Path |
|----------|------|
| Project config | `templates/.ai-workflow.yml` |
| Skills config | `templates/.ai-skills.json` |
| GitHub PR template | `templates/github/pull_request_template.md` |
| GitHub CODEOWNERS | `templates/github/CODEOWNERS` |
| GitHub branch protection guide | `templates/github/branch-protection-guide.md` |
| Azure DevOps PR template | `templates/azure-devops/pull_request_template.md` |
| Azure DevOps policy guide | `templates/azure-devops/branch-policy-guide.md` |
| Generic Git PR checklist | `templates/generic-git/pr-checklist.md` |
| Generic Git release process | `templates/generic-git/release-process.md` |
| Release checklist | `templates/release-checklist.md` |
| Hotfix checklist | `templates/hotfix-checklist.md` |
| AGENTS.md starter | `templates/AGENTS.md` |
| CLAUDE.md starter | `templates/CLAUDE.md` |
| Project working guide | `templates/PROJECT-WORKING-GUIDE.md` |
| PROGRESS.md starter | `templates/PROGRESS.md` |
| DECISIONS.md starter | `templates/DECISIONS.md` |
| Spec Kit constitution | `templates/specs/constitution.md` |

## Documentation

| Doc | Purpose |
|-----|---------|
| [docs/install.md](docs/install.md) | Installation and removal |
| [docs/cli.md](docs/cli.md) | First-class command usage |
| [docs/usage.md](docs/usage.md) | Example prompts and usage patterns |
| [docs/presets.md](docs/presets.md) | Preset structure and archetypes |
| [docs/bundles.md](docs/bundles.md) | Bundle shortcuts |
| [docs/profiles.md](docs/profiles.md) | Workflow profile reference |
| [docs/git-flow.md](docs/git-flow.md) | Git Flow configuration and rules |
| [docs/existing-projects.md](docs/existing-projects.md) | observe-only, safe-bootstrap, strict-migration |
| [docs/project-bootstrap.md](docs/project-bootstrap.md) | Bootstrapping new and existing projects |
| [docs/wordpress.md](docs/wordpress.md) | WordPress detection and wp-guard |
| [docs/wordpress-preset.md](docs/wordpress-preset.md) | WordPress preset rules |
| [docs/question-engine.md](docs/question-engine.md) | Recommendation-first questions |
| [docs/automatic-activation.md](docs/automatic-activation.md) | Repo-local automatic startup |
| [docs/ci-enforcement.md](docs/ci-enforcement.md) | CI workflow enforcement |
| [docs/skills-policy.md](docs/skills-policy.md) | Skill install and guard policy |
| [docs/github.md](docs/github.md) | GitHub platform guidance |
| [docs/azure-devops.md](docs/azure-devops.md) | Azure DevOps platform guidance |
| [docs/generic-git.md](docs/generic-git.md) | Generic Git guidance |
| [docs/definition-of-done.md](docs/definition-of-done.md) | Definition of done for AI-assisted tasks |
| [docs/compatibility.md](docs/compatibility.md) | Supported environments and platforms |
| [docs/upgrade.md](docs/upgrade.md) | Upgrading from older versions |
| [docs/testing.md](docs/testing.md) | Running tests and manual verification |
| [docs/spec-kit.md](docs/spec-kit.md) | Spec Kit integration |
| [docs/handoff-format.md](docs/handoff-format.md) | Handoff format reference |
| [docs/troubleshooting.md](docs/troubleshooting.md) | Common issues and fixes |

## Uninstall

```powershell
.\scripts\remove-global.ps1
```
