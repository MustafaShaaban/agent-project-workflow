# Handoff Format

Use the full block after real project work. This is the v2 format, extended with
platform, project type, profile, branching strategy, and skills status sections.

```text
SUMMARY

* What was done or found.

WORKSPACE

* Repo root:
* Branch:
* Git status:
* Files changed:

DETECTED PLATFORM

* Platform: GitHub | Azure DevOps | Generic Git
* CI detected: GitHub Actions | Azure Pipelines | Other | None
* Remote:

DETECTED PROJECT TYPE

* Type: wordpress | laravel | react | vue | nextjs | php | js/ts | dotnet | python | unknown
* WordPress detected: Yes/No
* WordPress indicators found:

WORKFLOW PROFILE

* Profile: minimal | standard | strict | enterprise
* Mode: normal | observe-only | safe-bootstrap | strict-migration
* Branching strategy: git-flow | github-flow | trunk-based | custom

BRANCHING STRATEGY

* Production branch:
* Integration branch (Git Flow only):
* Current branch:
* Branch allowed: Yes/No/Warning

SKILLS STATUS

* project-workflow: Active
* wp-guard required: Yes/No
* wp-guard present: Yes/No/N/A
* Other required skills: (list or None)
* Missing skills: (list or None)
* Install mode: ask | auto-approved-only | never

MODE

* Planning / Implementation / Docs / Design / Release / Debugging / Review / Bootstrap

CHANGES MADE

* Files created:
* Files modified:
* Files skipped (already existed):

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

RISKS / BLOCKERS

* Any risk from missing skills, branch violations, or unverified changes.
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

For advice-only answers with no file changes, use:

```text
RECOMMENDED NEXT STEP

* Recommended:
* Why:
* Alternative:
* Decision needed:
```
