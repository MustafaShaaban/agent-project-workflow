---
name: project-workflow
description: Use when starting, continuing, planning, implementing, debugging, reviewing, documenting, designing, releasing, or bootstrapping work in a software repository and a safe repo-root, branch, platform detection, skills check, profile-aware verification, and structured handoff routine is needed.
---

# Project Workflow

Use one real repository root, read project config and rules first, enforce the
active profile and branching strategy, check required skills, preserve user work,
and leave durable state plus a clear structured handoff.

---

## 0. Load project config

At the very start of every session, before any other step:

**Read `.ai-workflow.yml`** from the project root if it exists. Extract:
- `workflow.profile` (minimal / standard / strict / enterprise — default: standard)
- `workflow.mode` (observe-only / safe-bootstrap / strict-migration / normal — default: normal)
- `branching.strategy` (git-flow / github-flow / trunk-based / custom)
- `branching.production_branch` (default: main)
- `branching.integration_branch` (default: develop, Git Flow only)
- `branching.allowed_work_branch_patterns`
- `agent_safety.*` settings
- `skills.install_mode` and `skills.conditional_required`
- `wordpress.guard_required`

**Read `.ai-skills.json`** if it exists. Extract required and conditional skills,
install commands, and detection rules.

If neither file exists, use safe defaults:
- Profile: standard
- Strategy: github-flow
- Production branch: main
- Install mode: ask

---

## 1. Establish the workspace

Run from the current directory:

```powershell
git rev-parse --show-toplevel
git status --short --branch
git branch --show-current
git remote -v
git worktree list
```

Work only from the real Git root. Stop before editing if:
- The current directory is not the Git root
- A checkout appears unintended (wrong branch, detached HEAD)
- An unexpected hidden worktree such as `.worktrees/` is detected

If Git is not initialized: identify the intended project directory and ask before
initialization, unless the owner explicitly requested bootstrap.

---

## 2. Detect platform, project type, and profile

After reading config and establishing the workspace, detect:

**Platform:**
- GitHub: remote URL contains `github.com` OR `.github/` directory exists
- Azure DevOps: remote URL contains `dev.azure.com` / `visualstudio.com` OR `azure-pipelines.yml` / `.azure/` exists
- Generic Git: all other cases

**CI:**
- GitHub Actions: `.github/workflows/` exists
- Azure Pipelines: `azure-pipelines.yml` or `.azure/pipelines/` exists
- Other: `Jenkinsfile`, `.circleci/`, `.travis.yml`, `bitbucket-pipelines.yml`

**Project type (check these indicators in order):**
- WordPress: `wp-config.php` OR `wp-content/` OR `wp-login.php` OR `wp-blog-header.php` OR `composer.json` with `johnpbloch/wordpress` or `roots/bedrock` OR `package.json` with `@wordpress/`
- Laravel: `artisan` file exists
- React: `package.json` with `"react"` dependency
- Vue: `package.json` with `"vue"` dependency
- Next.js: `package.json` with `"next"` dependency
- Svelte: `package.json` with `"svelte"` dependency
- JS/TS: any `package.json`
- PHP: `composer.json` (non-Laravel)
- .NET: `*.sln` or `*.csproj`
- Python: `requirements.txt` or `pyproject.toml`
- Unknown: no recognized indicators

**Branching strategy (if not set in config):**
- Git Flow: `develop` branch exists AND (`release/*` or `hotfix/*` branches exist)
- Partial Git Flow: `develop` exists but no release/hotfix branches
- GitHub Flow: feature branches from `main`, no `develop`
- Trunk-based: all work on `main` or short-lived branches

State detected values before proceeding.

---

## 3. Check skills status

After detecting the project type:

**Required skills:**
- `project-workflow` is always required. It is already active if you are reading this.
- Check `.ai-skills.json` for any additional required skills.

**Conditional skills:**
- If **WordPress is detected** AND `wordpress.guard_required` is true (default):
  - Check if `wp-guard` skill is available
  - If missing:
    - `minimal`: warn, continue
    - `standard`: warn and ask the owner before continuing
    - `strict` / `enterprise`: **stop** until `wp-guard` is installed or explicitly bypassed by the owner
  - Never install `wp-guard` (or any skill) silently
  - Only suggest an install command if one is documented in `.ai-skills.json` with `install_approved: true`
  - If the owner explicitly acknowledges the missing skill and asks to continue, note it as a risk in the handoff

**Install mode:**
- `ask`: detect missing skills and ask before installing (default)
- `auto-approved-only`: install only skills with `install_approved: true` and a documented `install_command`
- `never`: report missing skills and stop; never install

---

## 4. Protect branches and user work

**Branch safety (enforced for all profiles except minimal):**
- Do NOT implement on the production branch (`main`, `master`, or configured `production_branch`)
- Do NOT implement on `develop` unless the owner explicitly approves small docs/chore changes
- For feature or fix work, create or continue a descriptive branch

**Git Flow branch rules (enforced when `strategy: git-flow`):**
- `feature/*`, `fix/*`, `chore/*` → must branch from `develop`
- `release/*` → branch from `develop`; merge into production AND back into `develop`
- `hotfix/*` → branch from production; merge into production AND back into `develop`
- If `develop` does not exist: stop and ask the owner whether to create it from production
- If branch naming does not match allowed patterns:
  - `standard`: warn
  - `strict` / `enterprise`: block

**All profiles:**
- Never overwrite, reset, clean, discard, or conceal user changes
- Inspect existing files before modifying them and preserve useful content
- Never rewrite history
- Never delete or rename branches automatically

**Mode: observe-only** — make zero file modifications; audit and report only.
**Mode: safe-bootstrap** — add missing workflow files only; skip existing files.
**Mode: strict-migration** — propose migration plan; require owner approval for each step.

---

## 5. Read project rules first

Before editing, read the files that exist in this order:

1. `AGENTS.md`
2. `CLAUDE.md`
3. `README.md`
4. `PROJECT-WORKING-GUIDE.md`
5. `PROGRESS.md`
6. `DECISIONS.md`
7. `specs/constitution.md`
8. Active files under `specs/`

**Source-of-truth hierarchy:**
1. Owner's latest explicit instruction
2. Repository instructions (`AGENTS.md`, `CLAUDE.md`)
3. `specs/constitution.md`
4. Active spec files
5. `PROGRESS.md` and `DECISIONS.md`
6. `README.md` and other docs
7. Implementation code

---

## 6. Identify the mode and handle existing projects

State the current operating mode before working:
**Planning, Implementation, Docs, Design, Debugging, Review, Release, or Bootstrap**

If the `.ai-workflow.yml` mode is `observe-only`:
- Perform audit only
- Run `scripts/audit-project-workflow.ps1` if available
- Produce a full report and handoff with zero file modifications

If the `.ai-workflow.yml` mode is `safe-bootstrap`:
- Add only missing workflow files
- Skip all files that already exist
- Ask before overwriting any existing file

If the `.ai-workflow.yml` mode is `strict-migration`:
- Produce a detailed migration proposal
- List each proposed change with rationale
- Wait for explicit owner approval before taking any action
- Never delete branches, rewrite history, or overwrite files without confirmation

---

## 7. Handle missing workflow files safely

If `AGENTS.md`, `PROJECT-WORKING-GUIDE.md`, `PROGRESS.md`, `DECISIONS.md`, or
`specs/constitution.md` is missing:
- Offer to create it (do not create without approval unless bootstrap was requested)
- Never overwrite an existing workflow file without first summarizing the proposed change

**Profile-specific requirements:**
- `minimal`: no required workflow files
- `standard`: `PROGRESS.md` and `DECISIONS.md` required
- `strict`: `PROGRESS.md`, `DECISIONS.md`, and `AGENTS.md` required
- `enterprise`: all of the above plus platform-specific governance files (CODEOWNERS, etc.)

---

## 8. Use Spec Kit when adopted

Detect Spec Kit by checking for `.specify/`, `specs/constitution.md`, spec commands, or existing spec workflow files.

- If Spec Kit is missing, ask before installing or initializing it
- If `specify` is unavailable, suggest installation; do not install silently
- Run `specify integration list` before assuming current integration identifiers
- Depending on supported identifiers, recommend:

```powershell
specify init . --integration claude
specify init . --integration codex
```

When Spec Kit exists, use: **specify / clarify → plan → tasks → implement → verify → handoff**

Do not force Spec Kit onto a tiny throwaway project where it adds no value.

---

## 9. Keep durable memory

- Keep long-term project state in repository files, not only chat
- Update `PROGRESS.md` after meaningful progress
- Update `DECISIONS.md` after durable owner or architecture decisions
- Do not promote temporary thoughts, guesses, or implementation notes into permanent decisions

---

## 10. Security and sensitive-file guardrails

**Stop and ask the owner before editing any of these file types:**

- `.env`, `.env.*`, `.env.local`, `.env.production`, `.env.staging`
- Files containing "secret", "credential", "password", "private_key" in the filename
- Private keys (`*.pem`, `*.key`, `*.p12`, `*.pfx`)
- Deployment credentials or production configuration
- CI/CD secrets or variable files (e.g. `secrets.yml`, `.vault_pass`)
- Database dumps (`*.sql`, `*.db`, `*.sqlite`)
- Backup files (`*.bak`, `*.backup`)
- Files outside the declared project scope

**Secrets in output — always:**
- Never print secret values in handoffs, logs, prompts, or documentation
- If a sensitive file or value is discovered, report the file path and nature only — never the value
- Never copy secret values into examples, templates, or comments

---

## 11. Generated and vendor file protection

**Warn before editing, and require explicit owner approval for:**

- `vendor/` — PHP/Composer dependencies
- `node_modules/` — JavaScript/npm dependencies
- `dist/`, `build/`, `out/` — compiled/bundled output
- `coverage/` — test coverage reports
- `.next/`, `.nuxt/`, `.svelte-kit/` — framework build caches
- `storage/cache/`, `storage/framework/` — Laravel framework caches
- `public/uploads/`, `wp-content/uploads/` — user-uploaded files
- `wp-content/cache/` — WordPress page/object cache

These directories are generated artifacts or external dependencies.
Changes to them are overwritten by builds or package installs.
Editing them directly is almost never the right action.

**Exception:** If the owner explicitly says "edit `dist/x.js` directly," proceed
but note the risk in the handoff (changes will be overwritten on next build).

---

## 12. Test and guard changes

Discover commands from `README` files, package manifests, Composer files, Makefiles,
CI configuration, and project docs.

When guard scripts are present in the project:
- Run `scripts/guard-before-edit.ps1` before editing
- Run `scripts/guard-git-flow.ps1` to validate branch state
- Run `scripts/guard-before-merge.ps1` before merging or releasing

Run the smallest relevant test first, then broader checks before declaring completion.
If a check cannot run, explain why and state the resulting risk.

See [docs/definition-of-done.md](../../docs/definition-of-done.md) for the full checklist
of what must be true before a task is considered complete.

---

## 13. Close the work

For real project work, end with this exact structure:

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

For advice-only answers with no file changes, end with:

```text
RECOMMENDED NEXT STEP

* Recommended:
* Why:
* Alternative:
* Decision needed:
```

---

## Stop conditions

Stop and ask the owner when:
- The real root is ambiguous or the checkout appears unintended
- A destructive operation would be required (reset, delete, force push)
- `develop` is missing and Git Flow is configured
- A required skill (wp-guard for WordPress in strict/enterprise) is missing and not bypassed
- Instructions conflict materially between config, project files, and owner request
- A missing decision would change project scope or branching strategy
- `observe-only` mode is active and someone is asking for file edits

Lack of a remote, optional tooling, optional CI, or Spec Kit is not a stop condition.
