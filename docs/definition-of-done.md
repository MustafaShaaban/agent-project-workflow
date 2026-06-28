# Definition of Done

An AI-assisted task in any project using `project-workflow` is considered **complete**
only when all of the following conditions are true.

---

## Workspace

- [ ] Real Git root confirmed with `git rev-parse --show-toplevel`
- [ ] Current branch confirmed; not on a protected branch (`main`, `master`, `develop`) without explicit owner approval
- [ ] Worktree is the intended one (no unexpected hidden worktrees)
- [ ] No user work has been overwritten, discarded, or hidden

## Project rules

- [ ] `AGENTS.md` read (if present)
- [ ] `CLAUDE.md` read (if present)
- [ ] `README.md` read (if present)
- [ ] `PROJECT-WORKING-GUIDE.md` read (if present)
- [ ] `PROGRESS.md` read (if present)
- [ ] `DECISIONS.md` read (if present)
- [ ] `.ai-workflow.yml` read (if present) — profile, mode, and branching strategy applied
- [ ] `.ai-skills.json` read (if present) — required and conditional skills checked

## Detection

- [ ] Platform detected (GitHub / Azure DevOps / generic Git)
- [ ] Project type detected (WordPress / Laravel / React / etc. / unknown)
- [ ] Branching strategy detected or read from config
- [ ] Workflow profile applied (minimal / standard / strict / enterprise)

## Skills

- [ ] `project-workflow` skill is active
- [ ] If WordPress detected: `wp-guard` status checked; missing guard is noted or resolved per profile
- [ ] No required skills from `.ai-skills.json` are silently missing
- [ ] No skills were installed without owner approval

## Guards

- [ ] `scripts/guard-before-edit.ps1` ran (or was not available, reason noted)
- [ ] `scripts/guard-git-flow.ps1` ran when Git Flow is configured (or was not available, reason noted)
- [ ] `scripts/guard-before-merge.ps1` ran before any merge or release (or was not available)
- [ ] All guards that ran produced PASS or PROCEED WITH CAUTION (not BLOCKED)

## Tests and verification

- [ ] Available tests/build/lint were discovered from project docs or manifests
- [ ] Smallest relevant check was run first
- [ ] Broader checks were run before completion
- [ ] Any check that could not run is documented with the reason and remaining risk

## Changes

- [ ] Only files in scope for this task were modified
- [ ] No unrelated files were changed
- [ ] No generated, vendor, or build artifacts were modified without explicit approval
- [ ] No sensitive files (`.env`, secrets, private keys, production config) were modified without explicit approval
- [ ] No secrets appear in diffs, handoffs, prompts, or documentation

## Durable state

- [ ] `PROGRESS.md` updated after meaningful progress (if present or if profile requires it)
- [ ] `DECISIONS.md` updated after any durable owner or architecture decision
- [ ] No temporary implementation notes were promoted to permanent decisions

## Handoff

- [ ] Full structured handoff produced (see [docs/handoff-format.md](handoff-format.md))
- [ ] Handoff includes: `DETECTED PLATFORM`, `DETECTED PROJECT TYPE`, `WORKFLOW PROFILE`, `BRANCHING STRATEGY`, `SKILLS STATUS`, `CHANGES MADE`, `VERIFICATION`, `RISKS / BLOCKERS`
- [ ] At least one `RECOMMENDED OPTION` provided
- [ ] `NEXT STEP` block is present with: what was done, recommended next, why, alternatives, blockers

---

## Quick checklist (minimal / standard profiles)

For smaller tasks where the full list is disproportionate:

1. Right root, right branch ✓
2. Project rules read ✓
3. Profile and skills checked ✓
4. Guards ran or were unavailable (documented) ✓
5. Tests ran or were unavailable (documented) ✓
6. Only scoped files changed; no secrets touched ✓
7. PROGRESS.md updated (if required) ✓
8. Handoff with NEXT STEP produced ✓

---

See also: [handoff-format.md](handoff-format.md) | [profiles.md](profiles.md) | [SKILL.md](../skills/project-workflow/SKILL.md)
