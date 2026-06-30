# Spec Kit authority and enforcement

Project-workflow and Spec Kit have separate jobs:

- project-workflow owns startup, repository detection, safety, verification, and handoff.
- Spec Kit owns clarify, spec, plan, and tasks for non-trivial work.
- Guard skills enforce conditional safety rules.
- Optional executor/build/debug skills help only after active Spec Kit tasks exist.

For non-trivial work, implementation begins only after Spec Kit has produced
tasks. Superpowers or any similar workflow skill cannot replace Spec Kit
planning unless the project owner explicitly overrides that policy.

## Missing Spec Kit

Missing tooling triggers an ask, not an install. The agent should report whether
`.specify/`, the constitution, active specs, and the `specify` command exist. It
must explain the recommended initialization command and wait for approval.

The initializer records states such as `disabled`, `requested-unavailable`,
`existing-preserved`, `available-dry-run`, and `initialized` in the lock file.
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

The appropriate installed Spec Kit version may then support integrations such as
`codex` or `claude`.

## Create the first spec

```text
Use project-workflow for startup and Spec Kit for planning. Clarify this feature,
then create its spec, plan, and tasks. Stop before implementation and show me the
active spec path and next task.
```

## Continue an active spec

```text
Use project-workflow to continue the active Spec Kit work. Read the constitution,
spec, plan, tasks, PROGRESS.md, and DECISIONS.md. Report the next incomplete task,
then implement only that task.
```

## Recover from the wrong skill

```text
Stop the current planning workflow. Use project-workflow to re-check the repo and
preserve existing work. Spec Kit is the planning authority: reconcile any useful
notes into the active Spec Kit spec/plan/tasks, do not let Superpowers or another
skill replace them, and wait before implementation if tasks are missing.
```

Tiny throwaway work may explicitly use a minimal workflow without Spec Kit. That
is an owner decision, not an optional skill's decision.
