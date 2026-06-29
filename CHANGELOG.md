# Changelog

All notable changes to this project are documented here.

## 0.3.0 - 2026-06-29

### Added

- PowerShell-first `project-workflow` command with `init`, `new`, `audit`, `doctor`, `upgrade`, and `install-skills`.
- Safe dry-run/apply behavior, managed blocks, `.suggested.md` conflict proposals, and `.agent-workflow.lock.json`.
- Automatic repo-local activation through generated `AGENTS.md`, `CLAUDE.md`, and `PROJECT-WORKING-GUIDE.md`.
- Recommendation-first question and Tiny/Normal/High-risk task rules.
- Full generic and WordPress preset payloads for site, plugin, theme, block, WooCommerce, and Bedrock archetypes.
- Shared archetype detection and audit JSON reporting.
- Doctor readiness scoring, JSON output, required-skill validation, and lock consistency checks.
- Spec Kit initialization/preservation with integration-list attempt, availability fallback, multi-integration setup, and exact lock-file command/status recording.
- Deterministic preset generation with `scripts/generate-presets.ps1`.
- Expanded self-tests covering dry-run/apply, managed upgrades, no-overwrite proposals, lock files, automatic activation, archetypes, WooCommerce guards, presets, doctor JSON, and Spec Kit lifecycle.
- Recommendation-first no-write handling when `-Type auto` cannot detect a project type.
- Safe execution of approved-only `npx skills add` commands, with unapproved commands kept manual.
- CLI, presets, bundles, WordPress preset, question engine, automatic activation, CI enforcement, and skills policy documentation.

### Verification

- `scripts/test-workflow.ps1`: 92 passed, 4 expected warnings for unavailable PowerShell YAML parser modules, 0 failures.
- `git diff --check`: passed.
- PR #5 and PR #6 merged into `master`.

## 0.2.0 - 2026-06-28

### Added (Phase 1 — core workflow system)

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

### Added (Phase 2 — quality gates and consistency)

- **`docs/definition-of-done.md`**: full checklist of what must be true before a task is complete
- **`scripts/lib/WorkflowDetection.ps1`**: shared detection helpers (platform, project type, WordPress, branching strategy, config reader)
- **`scripts/lib/WorkflowOutput.ps1`**: shared output formatting helpers for future script reuse
- **`-OutputFormat Json` on audit script**: machine-readable JSON output for CI integration
- **CI guard examples**: `templates/github/ci-guards.yml` (GitHub Actions) and `templates/azure-devops/ci-guards.yml` (Azure Pipelines)
- **Security guardrails in SKILL.md** (section 10): rules for sensitive files, secrets, and never-print-secrets policy
- **Vendor/generated file protection in SKILL.md** (section 11): rules for `vendor/`, `node_modules/`, `dist/`, WordPress caches, etc.
- **Test fixtures**: `tests/fixtures/generic-github-flow/`, `tests/fixtures/git-flow/`, `tests/fixtures/wordpress/`, `tests/fixtures/non-git/`
- **`scripts/test-workflow.ps1`**: self-test runner (11 scripts + 2 JSON files + 4 YAML files + 4 fixtures + 14 templates + 17 docs = 53 checks)
- **`docs/compatibility.md`**: supported environments, agents, platforms, and cross-platform notes
- **`docs/upgrade.md`**: upgrade from older versions, adding config files, migrating to Git Flow
- **`docs/testing.md`**: automated and manual test procedures, fixture descriptions, CI integration
- **`PROGRESS.md`**: project progress tracking for this repo itself

### Changed

- **`SKILL.md`**: major rewrite — added config loading (`.ai-workflow.yml`, `.ai-skills.json`), platform/project type/CI detection, profile-aware branch enforcement, Git Flow rules, WordPress/wp-guard integration, observe-only/safe-bootstrap/strict-migration modes, and enhanced structured handoff with `DETECTED PLATFORM`, `DETECTED PROJECT TYPE`, `WORKFLOW PROFILE`, `BRANCHING STRATEGY`, `SKILLS STATUS`, and `CHANGES MADE` sections
- **`scripts/bootstrap-project.ps1`**: added `Mode` parameter (`observe-only`, `safe-bootstrap`), `IncludeConfig` flag for `.ai-workflow.yml`/`.ai-skills.json`, and structured output
- **`docs/project-bootstrap.md`**: updated to document `-Mode`, `-IncludeConfig`, audit script, and manual bootstrap steps for config files and platform templates
- **`README.md`**: full rewrite covering all new features, template table, docs table, guard scripts, and platform support matrix
- **`docs/usage.md`**: updated with new prompt examples and guard/bootstrap script reference
- **`docs/handoff-format.md`**: updated to v2 format with new sections

## Planned / Deferred (future backlog)

The following improvements are intentionally deferred from v0.2.0:

- **Deeper YAML parser**: Replace regex-based `.ai-workflow.yml` parsing with a proper
  YAML parser (PowerShell-YAML module or equivalent) to support nested keys and arrays correctly
- **Refactor shared lib adoption**: Update existing guard/audit scripts to import
  `scripts/lib/WorkflowDetection.ps1` and `WorkflowOutput.ps1` instead of duplicating detection logic
- **Linux/macOS shell support**: Port guard/audit scripts to Bash or cross-platform PowerShell 7
  with verified path handling on Unix systems
- **Stronger CI integration**: Add a `scripts/install-ci.ps1` that bootstraps the skill
  in CI environments (GitHub Actions, Azure Pipelines) without requiring a local npm setup
- **Automated GitHub ruleset generation**: Add a script or template to generate GitHub
  ruleset JSON from `.ai-workflow.yml` settings
- **Automated Azure DevOps policy generation**: Same concept for Azure DevOps REST API
- **Companion guard skills for Laravel, React, Python**: Framework-specific companion skills
  similar to `wp-guard`, covering framework-specific risks per project type
- **JSON output for guard scripts**: Extend `-OutputFormat Json` to `guard-git-flow.ps1`,
  `guard-before-edit.ps1`, and `guard-before-merge.ps1` (currently only in audit script)
- **YAML array parsing**: `.ai-workflow.yml` `allowed_work_branch_patterns` and
  `skills.conditional_required` arrays are not yet parsed from YAML; guard scripts use hardcoded defaults

---

## 0.1.0 - 2026-06-27

- Added the global `project-workflow` skill.
- Added generic workflow and Spec Kit starter templates.
- Added install, removal, verification, and project-bootstrap scripts.
- Added installation, usage, bootstrap, Spec Kit, handoff, and troubleshooting documentation.
