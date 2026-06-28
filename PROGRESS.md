# Progress

## Current status

- Status: v0.2.0 implementation complete; pending PR review and merge
- Last updated: 2026-06-28

## Active branch

- Branch: `feature/v2-workflow-system`

## Active spec

- Spec: None (task-driven from prompt.md)
- Task IDs: None

## Recent work

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

## Next recommended step

- Review PR on GitHub
- Merge feature/v2-workflow-system into master
- Tag release v0.2.0
- Re-install global skill: `.\scripts\install-global.ps1`

## Open blockers

- None. Branch is clean and all tests pass.

## Future improvements

See the future backlog section in CHANGELOG.md under "Planned / Deferred."
