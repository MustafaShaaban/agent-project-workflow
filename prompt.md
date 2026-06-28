You are working inside the `agent-project-workflow` repository.

Goal: enhance this repo from a basic safe AI workflow skill into a portable, professional AI project workflow system that can be used on any software project, mainly GitHub and Azure DevOps repos, with future support for other Git platforms.

Important:

* This repo is NOT CoreX-specific.
* Do not add CoreX-specific rules.
* WordPress support should be generic and based on detecting WordPress projects.
* Preserve existing work.
* Do not overwrite existing files blindly.
* Inspect the current repo first before editing.
* Use the current repo conventions.
* Keep the solution practical, documented, and easy to install/use.

Start by auditing the current repo:

1. Confirm Git root, current branch, remotes, and worktree status.
2. Read README, SKILL.md, scripts, docs, templates, and any existing workflow files.
3. Summarize the current behavior before changing anything.
4. Then implement the enhancements below.

Main features to implement:

1. Add workflow profiles

Add support for workflow profiles:

* minimal
* standard
* strict
* enterprise

Meaning:

* minimal: safe repo start, no heavy process.
* standard: normal AI workflow, branch safety, progress tracking, verification, PR-friendly workflow.
* strict: mandatory Git Flow, guard scripts, required checks, stronger handoff rules.
* enterprise: strict mode plus stronger governance, reviewers, branch policies, CODEOWNERS/required reviewers, auditability.

Default should be `standard`.

Document when each profile should be used.

2. Add `.ai-workflow.yml` as the central project config

Create a reusable template/config file that projects can copy.

It should include at least:

* project name/type
* platform provider: auto, github, azure-devops, generic-git
* workflow profile
* branching strategy
* production branch
* integration branch
* allowed work branch patterns
* agent safety settings
* required progress/decision docs
* verification requirements
* handoff requirements
* skills policy
* WordPress conditional guard settings

Example concepts to support:

* branching.strategy: git-flow | github-flow | trunk-based | custom
* branching.production_branch: main
* branching.integration_branch: develop
* skills.install_mode: ask | auto-approved-only | never
* skills.required
* skills.conditional_required
* wordpress.guard_required: true/false

3. Add `.ai-skills.json` template

Add a machine-readable skills config template.

It should define:

* globally required skills
* conditionally required skills
* approved install commands if available
* install mode
* detection rules
* reason for each skill

Required behavior:

* `project-workflow` is required for all projects.
* `wp-guard` is conditionally required only for WordPress projects.
* Do not silently install unknown skills/tools.
* In standard mode, detect missing skills and ask before installing.
* In strict/enterprise mode, if the skill is required and missing, stop until installed or explicitly bypassed.
* Only use approved install commands from `.ai-skills.json` or repo docs.
* Never invent install commands.

4. Add mandatory Git Flow support

Add a strict Git Flow policy.

Git Flow branches:

* main or master: production/release branch
* develop: integration branch
* feature/<short-name>: features from develop
* fix/<short-name>: normal fixes from develop
* chore/<short-name>: maintenance/docs/tooling from develop
* release/<version>: release preparation from develop
* hotfix/<short-name-or-version>: urgent production fixes from main/master

Rules:

* Never implement directly on main/master.
* Never implement directly on develop except owner-approved tiny docs/workflow changes.
* feature/*, fix/*, chore/* must start from develop.
* release/* must start from develop and merge into main/master and back into develop.
* hotfix/* must start from main/master and merge into main/master and back into develop.
* If develop does not exist, stop and ask whether to create it from the production branch.
* If the existing project already uses another branching model, stop and ask before changing it.
* Never rewrite history.
* Never delete or rename branches automatically.

Important: Git Flow should be mandatory only when selected by `.ai-workflow.yml` or strict/enterprise profile. Do not force Git Flow on every project by default unless config says so.

5. Add existing project handling modes

Add documentation and script support for these modes:

* observe-only
* safe-bootstrap
* strict-migration

Meaning:

observe-only:

* Audit only.
* Do not modify files.

safe-bootstrap:

* Add missing workflow files only.
* Do not overwrite existing files.
* Preserve existing branch strategy.

strict-migration:

* Propose converting project to strict Git Flow + workflow policies.
* Requires explicit owner approval.
* Never rewrite history.
* Never delete or rename branches automatically.

6. Add project audit script

Create a script like:

* `scripts/audit-project-workflow.ps1`

It should inspect a target project and report:

* Git initialized or not
* Git root
* current branch
* remotes
* detected platform: GitHub, Azure DevOps, generic/unknown
* detected CI: GitHub Actions, Azure Pipelines, other/none
* detected project type: WordPress, PHP, JS/TS, Laravel, React, unknown, etc. where practical
* detected branch strategy: Git Flow, GitHub Flow, trunk-based, unknown
* whether main/master exists
* whether develop exists
* whether current branch is allowed
* workflow files found/missing
* `.ai-workflow.yml` found/missing
* `.ai-skills.json` found/missing
* AGENTS.md / CLAUDE.md / PROJECT-WORKING-GUIDE.md / PROGRESS.md / DECISIONS.md found/missing
* WordPress indicators found
* whether wp-guard is required
* whether required skills are documented
* risks
* recommended next step

The audit must not modify files.

7. Add Git Flow guard script

Create a script like:

* `scripts/guard-git-flow.ps1`

It should validate:

* current branch
* profile/branching settings from `.ai-workflow.yml` when available
* no implementation work on main/master
* no implementation work on develop unless allowed
* branch naming matches allowed patterns
* develop exists when Git Flow is enabled
* release/hotfix branches follow expected source/target rules where practical

It should produce clear pass/fail output.

Do not make it destructive.

8. Add before-edit and before-merge guards

Create scripts or documented commands for:

* guard before edit
* guard before merge/release

They should check:

* real Git root
* clean or acknowledged worktree
* allowed branch
* no hidden unexpected worktrees
* required workflow files
* required skills status or at least required skills config
* verification commands discovered/documented
* progress/decision tracking expectations

9. Add platform adapters

Add platform-specific templates/docs for:

* GitHub
* Azure DevOps
* generic Git

Suggested structure:

* `templates/github/`
* `templates/azure-devops/`
* `templates/generic-git/`
* `docs/github.md`
* `docs/azure-devops.md`
* `docs/generic-git.md`

GitHub should include:

* PR template
* CODEOWNERS template
* branch protection/ruleset guidance
* GitHub Actions example or placeholder
* notes for required checks and reviews

Azure DevOps should include:

* PR template
* branch policy guidance
* required reviewers guidance
* build validation guidance
* linked work item guidance
* Azure Pipelines example or placeholder

Generic Git should include:

* manual process guidance
* branch naming
* PR/review equivalent
* release checklist

10. Add PR templates

Add reusable PR templates with sections:

* Summary
* Scope
* Linked issue/work item
* Branch type
* Risk level
* Testing/verification
* Screenshots if UI
* Rollback plan
* AI usage notes
* Files intentionally changed
* Files intentionally not changed
* Blockers
* Next step

Provide GitHub and Azure DevOps variants if needed.

11. Add release and hotfix checklists

Add templates/docs for:

* release checklist
* hotfix checklist

Release checklist should include:

* release branch from develop
* version/changelog/docs updated where applicable
* tests/lint/build passed
* PR to main/master
* merge back to develop
* tag/release notes if applicable

Hotfix checklist should include:

* hotfix branch from main/master
* minimal scoped fix
* verification
* PR to main/master
* merge/cherry-pick back to develop
* post-fix notes

12. Add conditional WordPress support with wp-guard

Add generic WordPress project detection and skill policy.

Detect WordPress using indicators such as:

* wp-config.php
* wp-content/
* wp-content/plugins/
* wp-content/themes/
* plugin file headers
* theme style.css with Theme Name
* composer/package indicators related to WordPress
* @wordpress packages

Required behavior:

* If project type is WordPress, `wp-guard` is required.
* If `wp-guard` is missing:

  * minimal/standard: warn and ask before installing/continuing.
  * strict/enterprise: stop until installed or explicitly bypassed.
* Do not install wp-guard silently unless an approved command exists and install mode allows it.
* Add docs explaining that project-workflow is universal and wp-guard is a WordPress-specific companion guard.

Do not put all WordPress rules into project-workflow. Keep project-workflow as orchestrator and let wp-guard be the specialized safety layer.

13. Update SKILL.md

Update the main skill so the agent must:

* detect project root
* read `.ai-workflow.yml` if present
* read `.ai-skills.json` if present
* detect platform
* detect project type
* detect active profile
* detect branching strategy
* enforce Git Flow only when configured
* require wp-guard for WordPress projects
* ask before installing missing tools/skills unless config explicitly allows approved install commands
* use observe-only/safe-bootstrap/strict-migration modes for existing projects
* produce a structured handoff

Handoff should include:

* SUMMARY
* WORKSPACE
* DETECTED PLATFORM
* DETECTED PROJECT TYPE
* WORKFLOW PROFILE
* BRANCHING STRATEGY
* SKILLS STATUS
* MODE
* CHANGES MADE
* VERIFICATION
* RISKS/BLOCKERS
* RECOMMENDED OPTIONS
* NEXT STEP

14. Update bootstrap behavior

Enhance the project bootstrap script/docs so it supports:

* new project bootstrap
* existing project safe-bootstrap
* observe-only audit
* strict migration proposal

Default behavior must remain safe:

* do not overwrite files by default
* skip existing files
* require force/approval to replace
* show what will be added before adding
* keep existing project rules when present

15. Update documentation

Update README and docs to explain:

* what the repo does
* what it does not do
* installation
* uninstall
* workflow profiles
* Git Flow mode
* existing project behavior
* GitHub support
* Azure DevOps support
* generic Git support
* WordPress/wp-guard conditional support
* required skills behavior
* audit mode
* bootstrap mode
* guard scripts
* recommended first commands
* examples for new project and existing project

Make the README clear that:

* this repo does not own the application architecture
* it does not force a framework/language
* it can enforce Git Flow when configured
* it can work with GitHub and Azure DevOps
* it asks before installing missing skills/tools unless explicitly configured otherwise
* WordPress projects should use wp-guard

16. Verification

After implementation:

* Run available tests/checks if the repo has them.
* If no tests exist, run reasonable validation:

  * script syntax checks where possible
  * markdown link/path sanity checks where practical
  * inspect generated template paths
  * run audit script against the current repo if safe
* Do not claim checks passed unless they actually ran.
* If something cannot be verified, explain why.

17. Final output

At the end, provide:

* summary of what changed
* files changed
* how to use the new workflow
* example commands
* how it behaves on new projects
* how it behaves on existing projects
* how it behaves on GitHub
* how it behaves on Azure DevOps
* how it behaves on WordPress projects with wp-guard
* verification results
* recommended next step

If the repo is dirty at the start, stop and report before editing unless the changes are clearly yours and safe to continue.
