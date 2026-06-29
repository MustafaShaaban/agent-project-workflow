# Progress

## Current status

- Status: v0.3.0 initializer completion slice implemented locally; pending commit, push, PR, and merge
- Last updated: 2026-06-29

## Active branch

- Branch: `pw-initializer-completion`

## Active spec

- Spec: None (task-driven from prompt.md)
- Task IDs: None

## Recent work

### v0.3.0 CLI initializer MVP (2026-06-29)

- Added `scripts/project-workflow.ps1` with `init`, `new`, `audit`, `doctor`, `upgrade`, and `install-skills` command routing.
- Implemented safe `init` behavior: `-DryRun` default, `-Apply` required for writes, managed blocks, `.suggested.md` conflict proposals, user-owned progress/decision preservation, and `.agent-workflow.lock.json` creation.
- Added WordPress-first archetype/profile handling, Spec Kit requested-state recording, skill policy generation, and automatic activation instructions.
- Added CLI smoke coverage to `scripts/test-workflow.ps1` for dry-run, apply, lock file, automatic activation, and doctor readiness output.
- Added required docs: `docs/cli.md`, `docs/presets.md`, `docs/bundles.md`, `docs/wordpress-preset.md`, `docs/question-engine.md`, `docs/automatic-activation.md`, `docs/ci-enforcement.md`, and `docs/skills-policy.md`.
- Added preset structure under `presets/` for generic and WordPress archetypes.
- Updated `README.md`, `skills/project-workflow/SKILL.md`, and generated templates to describe the CLI, managed blocks, automatic activation, recommendation-first questions, and WordPress/WooCommerce safety rules.
- Verification run: `powershell -NoProfile -ExecutionPolicy Bypass -File scripts\test-workflow.ps1` passed with 65 pass, 4 expected YAML-parser warnings, 0 failures.
- Verification run: `git diff --check` passed with line-ending normalization warnings only.

### v0.3.0 initializer completion slice (2026-06-29)

- Added shared archetype detection for WordPress plugin, theme, block, site, Bedrock, and WooCommerce projects.
- Added WooCommerce indicators and required `woo-guard` validation.
- Added archetype data to audit JSON and structured doctor JSON output.
- Added doctor validation for profile/archetype-required skills and lock-file consistency.
- Added deterministic `scripts/generate-presets.ps1` and full template payloads for eight presets.
- Added Spec Kit lifecycle handling: existing-state preservation, integration-list attempt, tool-availability fallback, first integration init, additional integration install, and lock-file command/status recording.
- Added tests for unmanaged-file preservation, managed-block upgrade, five WordPress archetypes, audit archetypes, doctor JSON, missing WooCommerce guard, Spec Kit preservation/initialization, and complete preset payloads.
- Verification run: `powershell -NoProfile -ExecutionPolicy Bypass -File scripts\test-workflow.ps1` passed with 90 pass, 4 expected YAML-parser warnings, 0 failures.

### v0.2.0 (2026-06-28)

**Phase 1 (tasks 1-17):**
- Added workflow profiles: minimal, standard, strict, enterprise
- Added .ai-workflow.yml and .ai-skills.json config templates
- Added 4 PowerShell guard/audit scripts
- Added platform adapters for GitHub, Azure DevOps, generic Git
- Added PR templates, release/hotfix checklists
- Added WordPress detection and wp-guard integration
- Added observe-only, safe-bootstrap, strict-migration modes
- Updated SKILL.md, README, usage docs, handoff format, CHANGELOG

**Phase 2 (tasks 18-30):**
- Fixed consistency issues (project-bootstrap.md updated for v2)
- Added docs/definition-of-done.md with full completion checklist
- Added scripts/lib/WorkflowDetection.ps1 and WorkflowOutput.ps1 as shared helpers
- Added -OutputFormat Json to audit-project-workflow.ps1
- Added CI guard templates for GitHub Actions and Azure Pipelines
- Added security guardrails and vendor protection rules to SKILL.md (sections 10-11)
- Added test fixtures: generic-github-flow, git-flow, wordpress, non-git
- Added scripts/test-workflow.ps1 self-test script
- Added docs/compatibility.md, docs/upgrade.md, docs/testing.md
- Added PROGRESS.md (this file)

**Phase 3 (stabilization / quality pass):**
- Fixed runtime bug: `guard-before-edit.ps1` called undefined `Write-Ok` -> `Write-Pass`
- Resolved strict-migration inconsistency: `bootstrap-project.ps1` header now documents
  two script modes + clarifies strict-migration is an agent (skill) mode, not a script mode
- Added `-OutputFormat Text|Json` to `guard-git-flow.ps1` (mirrors audit; reuses WorkflowDetection lib)
- Aligned JSON schema across audit + guard-git-flow: `current_branch`, `failures`, `warnings`
- Added sensitive-file awareness scan to `guard-before-edit.ps1` (paths only, never contents;
  honors .gitignore so node_modules/vendor are skipped)
- Validated: all 11 .ps1 parse clean, .ai-skills.json valid JSON, .ai-workflow.yml valid YAML,
  CI templates valid YAML, self-test 53/0/0, self-audit clean

## Next recommended step

- Commit the v0.3.0 initializer completion slice.
- Push `pw-initializer-completion`.
- Open/update a PR into `master`.
- If checks and permissions allow, merge; otherwise leave the PR with exact blockers.

## Open blockers

- None. Branch is clean and all tests pass.

## Future improvements

See the future backlog section in CHANGELOG.md under "Planned / Deferred."
