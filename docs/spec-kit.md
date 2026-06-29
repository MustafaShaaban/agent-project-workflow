# Spec Kit relationship

The parts have distinct responsibilities:

- The global `project-workflow` skill is a generic startup, safety, verification, memory, and handoff routine.
- Project repository files are the law for that project and override the global routine.
- Spec Kit provides a structured specify/clarify, plan, tasks, implement, and verify workflow.

When Spec Kit is present, use it before implementation and reflect active paths and task IDs in `PROGRESS.md` and handoffs. When it is absent, ask before installing or initializing it. Do not silently change project tooling.

The initializer records one of these lock states: `disabled`, `requested-unavailable`, `existing-preserved`, `available-dry-run`, `initialized`, or `available-no-matching-integration`.

For new setup, it runs `specify integration list` first. Some Spec Kit versions require an initialized project for that command; in that case the initializer records the failed attempt, runs `specify check`, then uses the explicitly requested integration IDs. The first integration uses `specify init --here --force`; additional integrations use `specify integration install --force`.

Check current integrations before assuming identifiers:

```powershell
specify integration list
```

Depending on that output, initialization may use:

```powershell
specify init . --integration claude
specify init . --integration codex
```

Spec Kit is useful for durable, multi-step feature work. Do not force it into tiny throwaway experiments where the planning overhead has no practical value.
