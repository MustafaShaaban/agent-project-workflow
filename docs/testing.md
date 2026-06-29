# Testing

## Automated self-test

Run from the repository root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\test-workflow.ps1
```

The self-test validates:

1. **PowerShell syntax** - every `scripts/*.ps1` file is parsed by the PowerShell AST.
2. **JSON validity and skill policy** - JSON parses and companion guard commands remain manual by default.
3. **YAML validity** - a real parser is used when installed; otherwise structural checks produce warnings, never false passes.
4. **Fixture audits** - archetype and required-guard detection match each fixture.
5. **Bootstrap safety** - observe-only mode writes nothing.
6. **CLI smoke behavior** - dry-run/apply, lock files, automatic activation, and doctor output work.
7. **Managed-block safety** - constants are non-empty, generated files contain exact marker pairs, unmanaged files produce suggestions, incomplete pairs are rejected, and owner text survives upgrade.
8. **Preset and documentation payloads** - required files exist for every supported archetype.
9. **Formatting** - README, templates, all docs, presets, and scripts retain sane line counts and line lengths.
10. **Repository policy** - `.gitattributes` and `.github/workflows/verify.yml` exist.

Exit codes:

- `0` = all checks passed or only explicit YAML-parser warnings remain.
- `1` = at least one failure.

## Test fixtures

Fixtures are under `tests/fixtures/`:

| Fixture | Simulates | Expected type | Expected wp-guard |
|---------|-----------|---------------|-------------------|
| `generic-github-flow/` | React + GitHub Flow | `react` | Not required |
| `git-flow/` | Laravel + Git Flow | `laravel` | Not required |
| `wordpress/` | WordPress project | `wordpress` | Required in `skills_missing` |
| `non-git/` | Directory without Git | `unknown` | Not required |

Fixtures are not complete applications and do not contain real `.git`
directories. Git guards can report that a fixture is not a repository; that is
expected for fixture-only checks.

## Required manual smoke test

Run the release smoke commands in an isolated copy or disposable target so
`init -Apply` does not add workflow files to this repository:

```powershell
.\scripts\project-workflow.ps1 init -Type wordpress-site -Profile standard -SpecKit -Agents codex,claude-code -DryRun
.\scripts\project-workflow.ps1 init -Type wordpress-site -Profile standard -SpecKit -Agents codex,claude-code -Apply
.\scripts\project-workflow.ps1 doctor -Json
```

Confirm the dry run writes nothing, apply creates the lock and workflow files,
and doctor returns parseable JSON. When `specify` is unavailable, the lock must
record that status rather than failing initialization.

## Additional manual checks

```powershell
.\scripts\install-global.ps1
.\scripts\verify-install.ps1
.\scripts\audit-project-workflow.ps1 -TargetPath tests\fixtures\wordpress -OutputFormat Json
.\scripts\bootstrap-project.ps1 -TargetPath tests\fixtures\generic-github-flow -Mode observe-only
git diff --check
```

The WordPress audit should report `project_type: wordpress` and include
`wp-guard` in `skills_missing`. Observe-only bootstrap must not write files.

## CI integration

`.github/workflows/verify.yml` validates this repository on pushes and pull
requests targeting `master`. See `templates/github/ci-guards.yml` and
`templates/azure-devops/ci-guards.yml` for downstream project examples.

## Adding a fixture

1. Create `tests/fixtures/<name>/` with the smallest required indicator files.
2. Add an `AGENTS.md` describing what the fixture represents.
3. Add `.ai-workflow.yml` only when configuration detection is under test.
4. Add the fixture expectation to `scripts/test-workflow.ps1`.
