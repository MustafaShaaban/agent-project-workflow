# Project Working Guide

## Start a session

From the project directory, resolve the real root and inspect state:

```powershell
git rev-parse --show-toplevel
git status --short --branch
git branch --show-current
git remote -v
git worktree list
```

Change to the returned root. Stop before editing if the checkout or worktree is unexpected. Read the project instruction, progress, decision, constitution, and active-spec files.

## Choose a mode

Name the primary mode: Planning, Implementation, Docs, Design, Debugging, Review, Release, or Bootstrap. Use Spec Kit's specify/clarify, plan, tasks, implement, verify, and handoff sequence when Spec Kit is present.

## Avoid workspace conflicts

Use one real root. Do not create or use `.worktrees/` or another hidden worktree without explicit owner approval for this session. Do not implement on `main` or `master` except for initial repository creation or explicit approval. Preserve all unrelated and uncommitted user changes.

## Record progress

After meaningful progress, update `PROGRESS.md` with current state, branch, active spec, completed work, next step, and blockers. Add only durable owner or architecture decisions to `DECISIONS.md`.

## Verify work

Discover project commands from its docs and manifests. Run the smallest relevant checks first, then broader tests and guards. Record commands, results, and any checks that could not run.

## Close a session

For real project work, use this complete handoff:

```text
SUMMARY

* What was done or found.

WORKSPACE

* Repo root:
* Branch:
* Git status:
* Files changed:

MODE

* Planning / Implementation / Docs / Design / Release / Debugging / Review / Bootstrap

SPEC KIT STATUS

* Spec Kit detected: Yes/No
* Spec path:
* Task IDs:
* Completed:
* Remaining:

VERIFICATION

* Commands run:
* Tests:
* Guards/checks:
* Results:

BLOCKERS / DECISIONS NEEDED

* Any decision needed from the owner.
* Any blocker that prevents safe progress.

RECOMMENDED OPTIONS

1. Recommended:

   * What:
   * Why:
2. Alternative:

   * What:
   * When to choose it:
3. Defer:

   * What:
   * Why defer:

---

NEXT STEP

* Just completed:
* Recommended next:
* Why:
* Alternatives:
* Blockers/decisions needed from you:

---
```

For advice-only work with no file changes, end with:

```text
RECOMMENDED NEXT STEP

* Recommended:
* Why:
* Alternative:
* Decision needed:
```
