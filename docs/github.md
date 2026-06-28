# GitHub Platform Support

When `project-workflow` detects a GitHub project, it applies GitHub-specific
guidance for PRs, branch protection, CODEOWNERS, and Actions.

## Detection

GitHub is detected when:
- Remote URL contains `github.com`
- `.github/` directory exists

## Templates available

| Template | Path | Usage |
|----------|------|-------|
| PR template | `templates/github/pull_request_template.md` | Copy to `.github/pull_request_template.md` |
| CODEOWNERS | `templates/github/CODEOWNERS` | Copy to `.github/CODEOWNERS` or repo root |
| Branch protection guide | `templates/github/branch-protection-guide.md` | Reference for Settings → Branches |

## Recommended setup

### PR template

Copy to your project:

```powershell
Copy-Item templates\github\pull_request_template.md .github\pull_request_template.md
```

GitHub automatically populates this template in all new PRs.

### CODEOWNERS

Copy and edit:

```powershell
Copy-Item templates\github\CODEOWNERS .github\CODEOWNERS
```

Replace `@org/leads` with your actual GitHub team or user handles.

### Branch protection

Follow `templates/github/branch-protection-guide.md` to configure:
- Required reviewers on `main` and `develop`
- Required status checks
- No force pushes
- No branch deletions

### GitHub Actions

Add a CI workflow at `.github/workflows/ci.yml`. A minimal placeholder is
included in `templates/github/branch-protection-guide.md`.

## Agent behavior on GitHub projects

- Handoff includes `DETECTED PLATFORM: GitHub`
- PR descriptions use the GitHub PR template format
- CODEOWNERS is mentioned when enterprise profile is active
- Branch protection guidance is included in bootstrap output

## What this system does NOT do

- It does not create GitHub Actions workflows automatically
- It does not manage GitHub secrets or environments
- It does not push to GitHub
- It does not open or close GitHub issues or PRs on your behalf without explicit instruction
