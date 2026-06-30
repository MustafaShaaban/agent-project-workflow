# Skills policy

## Skill precedence and anti-drift policy

| Authority | Owner | Scope |
|---|---|---|
| Startup | project-workflow | Root, Git, branch, platform, project type, setup, verification, handoff |
| Planning | Spec Kit | Clarify, spec, plan, tasks for non-trivial work |
| Safety | Guard skills | Conditional code, test, docs, WordPress, and WooCommerce checks |
| Execution | Optional helpers | Build, debug, or execute active Spec Kit tasks |

Superpowers and similar workflow skills are optional executor/helpers in managed
repositories. They may not replace Spec Kit clarify/spec/plan/tasks unless the
owner explicitly overrides the repository policy. Record an override in durable
project state so later agents do not guess.

## Required and conditional skills

`project-workflow` is always required. Standard and stricter professional profiles
require `clean-code-guard`, `test-guard`, and `docs-guard`. `wp-guard` is
conditional on WordPress detection; `woo-guard` is conditional on WooCommerce.
WordPress is never mandatory for generic, PHP, JavaScript, React, Laravel,
Python, or .NET projects.

## Install modes

- `ask`: report missing skills and ask before installation. This is the default.
- `auto-approved-only`: install only entries with a verified command and
  `install_approved: true`.
- `never`: do not install; report the missing requirement and next action.

No skill is silently installed unless both repository configuration and owner
approval allow it. An install command in `.ai-skills.json` is documentation, not
approval by itself.

## Approved-only safety

`install-skills -ApprovedOnly` accepts only allowlisted
`npx -y skills add ...` commands. It rejects shell operators, redirects, and
unsupported commands. Companion guard commands default to
`install_approved: false` until the owner reviews their source.
