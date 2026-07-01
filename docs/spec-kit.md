# Spec Kit authority and enforcement

Project-workflow and Spec Kit have separate jobs:

- project-workflow owns startup, repository detection,
  safety, verification, and handoff.
- Spec Kit owns constitution, specify, clarify, plan,
  checklist, tasks, analyze, implement, and conditional
  converge for non-trivial work.
- Guard skills enforce conditional safety rules.
- Optional executor/build/debug skills help only after
  active Spec Kit tasks exist.

For non-trivial work, implementation begins only after Spec
Kit checklist, tasks, and analyze stages complete.
Superpowers or any similar workflow skill cannot replace
Spec Kit planning unless the project owner explicitly
overrides that policy.

## Exact enforced Spec Kit order

The production command order is:

```text
/speckit.constitution
/speckit.specify
/speckit.clarify
/speckit.plan
/speckit.checklist
/speckit.tasks
/speckit.analyze
/speckit.implement
/speckit.converge when available/needed
```

For Codex skills mode, use:

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

Do not skip or reorder the first eight steps. Run `converge`
after implementation when it is available and the work needs
convergence; otherwise record that it was not available or
not needed. Optional executor skills can assist only within
the active implementation tasks.

## Missing Spec Kit

Missing tooling triggers an ask, not an install. The agent
should report whether `.specify/`, the constitution, active
specs, and the `specify` command exist. It must explain the
recommended initialization command and wait for approval.

The initializer records states such as `disabled`,
`requested-unavailable`, `existing-preserved`,
`available-dry-run`, and `initialized` in the lock file.
Existing `.specify/` state is preserved.

## Initialize Spec Kit

```text
Use project-workflow to verify this repo is ready for planning. Ask for my approval
before initializing Spec Kit for Codex and Claude Code. Do not install or change
tooling silently, and do not implement anything yet.
```

After approval, check current integration identifiers:

```powershell
specify integration list
```

The appropriate installed Spec Kit version may then support
integrations such as `codex` or `claude`.

## Create the first spec

```text
Use project-workflow for startup and Spec Kit for planning. Follow the exact
enforced order for this feature from constitution through analyze. Stop before
implementation and show me the active spec path and next stage.
```

## Continue an active spec

```text
Use project-workflow to continue the active Spec Kit work. Read the constitution,
spec, clarification, plan, checklist, tasks, analysis, PROGRESS.md, and DECISIONS.md.
Report the next incomplete stage and implement only after analyze passes.
```

## Recover from the wrong skill

```text
Stop the current planning workflow. Use project-workflow to re-check the repo and
preserve existing work. Spec Kit is the planning authority: reconcile any useful
notes into the active Spec Kit stages, do not let Superpowers or another skill
replace them, and wait before implementation if checklist, tasks, or analyze is missing.
```

Tiny throwaway work may explicitly use a minimal workflow
without Spec Kit. That is an owner decision, not an optional
skill's decision.
