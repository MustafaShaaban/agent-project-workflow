# CI Enforcement

CI should run read-only workflow checks first:

```powershell
.\scripts\project-workflow.ps1 audit -Ci
.\scripts\project-workflow.ps1 doctor -Ci
```

GitHub Actions and Azure DevOps templates can call the PowerShell MVP before
project-specific tests. CI must fail on doctor blocking items, invalid workflow
YAML, or a missing YAML parser. Missing optional skills may remain warnings when
the active profile permits them.

Minimum CI expectations:

- Validate workflow files exist.
- Validate lock file is parseable.
- Validate required skills are documented.
- Validate automatic activation and NEXT STEP rules exist.
- Run repository-specific tests after workflow checks.

This repository uses `.github/workflows/verify.yml` to run the complete
`scripts/test-workflow.ps1` suite and `git diff --check` on Windows for pushes
and pull requests targeting `master`. Downstream repositories can start from
`templates/github/ci-guards.yml` or `templates/azure-devops/ci-guards.yml`.
