# CI Enforcement

CI should run read-only workflow checks first:

```powershell
.\scripts\project-workflow.ps1 audit -Ci
.\scripts\project-workflow.ps1 doctor -Ci
```

GitHub Actions and Azure DevOps templates can call the PowerShell MVP before project-specific tests. CI should fail on doctor blocking items and surface warnings for missing optional skills or missing YAML parser validation.

Minimum CI expectations:

- Validate workflow files exist.
- Validate lock file is parseable.
- Validate required skills are documented.
- Validate automatic activation and NEXT STEP rules exist.
- Run repository-specific tests after workflow checks.
