# Testing

## Automated self-test

Run the test script from the repository root:

```powershell
.\scripts\test-workflow.ps1
```

This script validates:
1. **PowerShell syntax** — all `scripts/*.ps1` files parsed by the PowerShell AST
2. **JSON validity** — `templates/.ai-skills.json` and fixture `package.json` files
3. **YAML basic sanity** — `.ai-workflow.yml` templates contain expected keys
4. **Audit script on fixtures** — runs `audit-project-workflow.ps1 -OutputFormat Json`
5. **CLI smoke and safety tests** — verifies dry-run/apply, lock files, managed-block upgrades, `.suggested.md` conflicts, doctor JSON, required skills, archetype detection, and Spec Kit lifecycle
6. **Preset payload sanity** — verifies every generic/WordPress preset contains the complete template payload
   against each test fixture and verifies detected type and WordPress status
5. **Bootstrap observe-only** — runs `bootstrap-project.ps1 -Mode observe-only` against
   a fixture to confirm no files are written
6. **Template path sanity** — verifies all expected template files exist
7. **Doc file sanity** — verifies all expected documentation files exist

Exit codes:
- `0` = all passed (or only warnings)
- `1` = at least one failure

## Test fixtures

Located under `tests/fixtures/`:

| Fixture | Simulates | Expected type | Expected wp-guard |
|---------|-----------|--------------|-------------------|
| `generic-github-flow/` | React + GitHub Flow | `react` | Not required |
| `git-flow/` | Laravel + Git Flow | `laravel` | Not required |
| `wordpress/` | WordPress project | `wordpress` | Required (in `skills_missing`) |
| `non-git/` | Directory without Git | `unknown` | Not required |

Fixtures are not real applications and do not have real `.git` directories.
Guard scripts that check for `.git` will report "Not a Git repository" for fixtures — this is expected.

## Manual verification checklist

If the automated test cannot run (e.g. no PowerShell available), use this manual checklist:

1. **Syntax check**: Open each `.ps1` file and verify no obvious syntax errors (missing braces, unclosed strings)
2. **Install test**:
   ```powershell
   .\scripts\install-global.ps1
   .\scripts\verify-install.ps1
   ```
   Confirm `project-workflow` appears in the global skills list for `claude-code` and `codex`.
3. **Audit test**:
   ```powershell
   .\scripts\audit-project-workflow.ps1 -TargetPath tests\fixtures\wordpress
   ```
   Confirm WordPress is detected and `wp-guard` is mentioned as required.
4. **Guard test**:
   ```powershell
   .\scripts\guard-git-flow.ps1
   ```
   On `feature/v2-workflow-system`, should show `[RESULT] PASS`.
5. **Bootstrap observe-only**:
   ```powershell
   .\scripts\bootstrap-project.ps1 -TargetPath tests\fixtures\generic-github-flow -Mode observe-only
   ```
   Should show which files would be created without creating them.
6. **JSON output**:
   ```powershell
   .\scripts\audit-project-workflow.ps1 -TargetPath tests\fixtures\wordpress -OutputFormat Json
   ```
   Confirm valid JSON with `project_type: wordpress` and `skills_missing` containing `wp-guard`.

## CI integration

See `templates/github/ci-guards.yml` and `templates/azure-devops/ci-guards.yml`
for examples of running guard scripts in CI pipelines.

## Adding new tests

To add a new fixture:
1. Create `tests/fixtures/<name>/` with indicator files
2. Add an `AGENTS.md` explaining what the fixture simulates
3. Add `.ai-workflow.yml` if testing config detection
4. Add a row to the fixtures table in `scripts/test-workflow.ps1`
