---
name: project-workflow
description: Use when starting, continuing, planning, implementing, debugging, reviewing, documenting, designing, releasing, or bootstrapping work in a software repository and a safe repo-root, branch, Spec Kit, verification, durable-memory, and handoff routine is needed.
---

# Project Workflow

Use one real repository root, make repository-owned instructions authoritative, preserve user work, and leave durable state plus a clear next step.

## 1. Establish the workspace

Before project work, run from the current directory:

```powershell
git rev-parse --show-toplevel
git status --short --branch
git branch --show-current
git remote -v
git worktree list
```

If Git is not initialized, identify the intended project directory and ask before initialization unless the user explicitly requested repository bootstrap.

Work only from the real repo root. Do not create or use hidden worktrees such as `.worktrees/` unless the owner explicitly approves one for this session. Stop before editing if the current directory, checkout, or worktree is wrong or suspicious.

## 2. Protect branches and user work

- Do not implement on `main` or `master` unless creating the initial repository or the owner explicitly approves it.
- For feature or fix work, create or continue a descriptive branch.
- Never overwrite, reset, clean, discard, or conceal user changes.
- Inspect existing files before modifying them and preserve useful content.

## 3. Read project rules first

Before editing, read the files that exist in this order:

1. `AGENTS.md`
2. `CLAUDE.md`
3. `README.md`
4. `PROJECT-WORKING-GUIDE.md`
5. `PROGRESS.md`
6. `DECISIONS.md`
7. `specs/constitution.md`
8. Active files under `specs/`

Resolve conflicts with this source-of-truth hierarchy:

1. User's latest explicit instruction
2. Repository instructions such as `AGENTS.md` and `CLAUDE.md`
3. `specs/constitution.md`
4. Active spec files
5. `PROGRESS.md` and `DECISIONS.md`
6. `README.md` and other docs
7. Implementation code

## 4. Identify the mode

State the current mode before working: **Planning**, **Implementation**, **Docs**, **Design**, **Debugging**, **Review**, **Release**, or **Bootstrap**. If the task spans modes, name the primary mode and transition explicitly.

## 5. Handle missing workflow files safely

If `AGENTS.md`, `PROJECT-WORKING-GUIDE.md`, `PROGRESS.md`, `DECISIONS.md`, or `specs/constitution.md` is missing, offer to create it. Create missing files only after approval unless the user explicitly requested initialization. Never overwrite an existing workflow file without first summarizing the proposed change.

## 6. Use Spec Kit when adopted

Detect Spec Kit by checking for `.specify/`, `specs/constitution.md`, spec commands, or existing spec workflow files.

- If Spec Kit is missing, ask before installing or initializing it.
- If `specify` is unavailable, suggest installation; do not install silently.
- Run `specify integration list` before assuming current integration identifiers.
- Depending on supported identifiers, recommend:

```powershell
specify init . --integration claude
specify init . --integration codex
```

When Spec Kit exists, use this sequence: **specify / clarify -> plan -> tasks -> implement -> verify -> handoff**. Do not force Spec Kit onto a tiny throwaway project where it adds no value.

## 7. Keep durable memory

- Keep long-term project state in repository files, not only chat.
- Update `PROGRESS.md` after meaningful progress.
- Update `DECISIONS.md` after durable owner or architecture decisions.
- Do not promote temporary thoughts, guesses, or implementation notes into permanent decisions.

## 8. Test and guard changes

Discover commands from `README` files, package manifests, Composer files, Makefiles, CI configuration, and project docs. Run the smallest relevant test first, then broader checks before declaring completion. If a check cannot run, explain why and state the resulting risk.

## 9. Close the work

For real project work, end with this exact structure:

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

For advice-only answers with no file changes, end with:

```text
RECOMMENDED NEXT STEP

* Recommended:
* Why:
* Alternative:
* Decision needed:
```

## Stop conditions

Stop and ask the owner when the real root is ambiguous, a checkout appears unintended, a destructive operation would be required, instructions conflict materially, or a missing decision would change project scope. Lack of a remote, optional tooling, or Spec Kit is not permission to invent configuration.
