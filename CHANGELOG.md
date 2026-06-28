# Changelog

All notable changes to this project are documented here.

## 0.2.0 - 2026-06-28

### Added

- **Workflow profiles**: `minimal`, `standard` (default), `strict`, `enterprise` with profile-aware rule enforcement
- **`.ai-workflow.yml` template**: central project config for profile, platform, branching strategy, safety settings, skills policy, and WordPress config
- **`.ai-skills.json` template**: machine-readable skill requirements, conditional skills, install commands, and detection rules
- **`scripts/audit-project-workflow.ps1`**: read-only project audit reporting Git state, platform, CI, project type, branch strategy, workflow files, WordPress detection, and risks
- **`scripts/guard-git-flow.ps1`**: Git Flow / branch naming guard with PASS/FAIL output
- **`scripts/guard-before-edit.ps1`**: pre-edit safety guard (root, branch, worktree, docs, skills)
- **`scripts/guard-before-merge.ps1`**: pre-merge / pre-release guard (cleanliness, docs, verification, merge-back reminders)
- **Platform adapters**: GitHub, Azure DevOps, and generic Git templates and docs
- **GitHub templates**: PR template, CODEOWNERS, branch protection guide, Actions placeholder
- **Azure DevOps templates**: PR template, branch policy guide, pipeline placeholder
- **Generic Git templates**: PR checklist, release process guide
- **Release checklist** and **hotfix checklist** templates
- **WordPress / wp-guard support**: detection logic, profile-aware enforcement, documentation
- **Existing project modes**: `observe-only`, `safe-bootstrap`, `strict-migration`
- **New docs**: `profiles.md`, `git-flow.md`, `existing-projects.md`, `wordpress.md`, `github.md`, `azure-devops.md`, `generic-git.md`

### Changed

- **`SKILL.md`**: major rewrite — added config loading (`.ai-workflow.yml`, `.ai-skills.json`), platform/project type/CI detection, profile-aware branch enforcement, Git Flow rules, WordPress/wp-guard integration, observe-only/safe-bootstrap/strict-migration modes, and enhanced structured handoff with `DETECTED PLATFORM`, `DETECTED PROJECT TYPE`, `WORKFLOW PROFILE`, `BRANCHING STRATEGY`, `SKILLS STATUS`, and `CHANGES MADE` sections
- **`scripts/bootstrap-project.ps1`**: added `Mode` parameter (`observe-only`, `safe-bootstrap`), `IncludeConfig` flag for `.ai-workflow.yml`/`.ai-skills.json`, and structured output
- **`README.md`**: full rewrite covering all new features, template table, docs table, guard scripts, and platform support matrix
- **`docs/usage.md`**: updated with new prompt examples and guard/bootstrap script reference
- **`docs/handoff-format.md`**: updated to v2 format with new sections

## 0.1.0 - 2026-06-27

- Added the global `project-workflow` skill.
- Added generic workflow and Spec Kit starter templates.
- Added install, removal, verification, and project-bootstrap scripts.
- Added installation, usage, bootstrap, Spec Kit, handoff, and troubleshooting documentation.
