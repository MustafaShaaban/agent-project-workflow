# Skills policy

## Skill precedence and anti-drift policy

| Authority | Owner | Scope |
|---|---|---|
| Startup | project-workflow | Root, Git, branch, platform, project type, setup, verification, handoff |
| Planning | Spec Kit | Constitution, specify, clarify, plan, checklist, tasks, analyze, implement, and conditional converge |
| Safety | Guard skills | Conditional code, test, docs, WordPress, and WooCommerce checks |
| Execution | Optional helpers | Build, debug, or execute active Spec Kit tasks |

Superpowers and similar workflow skills are optional executor/helpers in managed
repositories. They may not replace any enforced Spec Kit stage unless the
owner explicitly overrides the repository policy. Record an override in durable
project state so later agents do not guess.

### Exact planning order

Optional skills must preserve this command order:

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

Codex skills mode must preserve the equivalent order:

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

`converge` is conditional on availability and need. No executor skill may start
implementation before checklist, tasks, and analyze are complete.

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
