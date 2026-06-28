# Workflow Profiles

The `profile` setting in `.ai-workflow.yml` controls how strictly the AI agent
enforces workflow rules. Choose the profile that matches your team's needs.

## minimal

**When to use:** Throwaway experiments, quick prototypes, personal scripts,
projects where process overhead has no value.

**What it does:**
- Detects the real Git root and branch
- Does not implement on production branches
- No required workflow files
- No forced branching strategy
- No required verification before handoff
- Brief handoff format acceptable

**What it skips:** Progress tracking, decision tracking, Spec Kit, guard scripts.

---

## standard (default)

**When to use:** Most software projects — professional work, client projects,
open-source repositories, team projects without heavy governance.

**What it does everything in `minimal` plus:**
- Requires `PROGRESS.md` and `DECISIONS.md`
- Detects and reads `AGENTS.md`, `CLAUDE.md`, `PROJECT-WORKING-GUIDE.md`
- Enforces feature/fix/chore branch naming (warns on violations)
- Reads `.ai-workflow.yml` and `.ai-skills.json` if present
- Detects platform (GitHub, Azure DevOps, generic)
- Detects project type (WordPress, Laravel, React, etc.)
- Requires wp-guard for WordPress projects (warns and asks)
- Asks before installing missing skills
- Requires verification before handoff
- Full structured handoff

---

## strict

**When to use:** Production systems, regulated projects, fintech, healthcare,
or any project where a mistake is costly.

**Everything in `standard` plus:**
- Mandatory `AGENTS.md`
- Git Flow branch naming violations are **failures** (not warnings)
- Requires `develop` branch if strategy is `git-flow`
- Stops if required skills are missing (does not just warn)
- Requires wp-guard for WordPress (stops, does not just warn)
- `require_clean_worktree` is enforced more strictly
- `guard-before-edit.ps1` and `guard-git-flow.ps1` must run clean

---

## enterprise

**When to use:** Large teams, multi-team projects, projects with compliance
requirements (SOC 2, ISO 27001, etc.), projects with required code owners or reviewers.

**Everything in `strict` plus:**
- Requires `CODEOWNERS` (GitHub) or required reviewer config (Azure DevOps)
- Enforces auditability: all decisions must be in `DECISIONS.md`
- Requires linked work items in PRs
- No AI agent may merge directly; PRs are mandatory
- Stronger handoff format with explicit governance section

---

## Changing profiles

Edit `.ai-workflow.yml` in the project root:

```yaml
workflow:
  profile: standard  # change to: minimal | strict | enterprise
```

Commit the change so all agents and team members use the same profile.
