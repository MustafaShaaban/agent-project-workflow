# Azure DevOps Platform Support

When `project-workflow` detects an Azure DevOps project, it applies
Azure-specific guidance for PRs, branch policies, required reviewers,
and pipelines.

## Detection

Azure DevOps is detected when:
- Remote URL contains `dev.azure.com` or `visualstudio.com`
- `azure-pipelines.yml` exists in the project root
- `.azure/` directory exists

## Templates available

| Template | Path | Usage |
|----------|------|-------|
| PR template | `templates/azure-devops/pull_request_template.md` | Add to repo or PR description |
| Branch policy guide | `templates/azure-devops/branch-policy-guide.md` | Reference for branch policy setup |

## PR template for Azure DevOps

Azure DevOps supports PR templates via a file at:
- `pull_request_template.md` in the repo root, or
- `.azuredevops/pull_request_template.md`

Copy the template:

```powershell
New-Item -ItemType Directory -Force .azuredevops
Copy-Item templates\azure-devops\pull_request_template.md .azuredevops\pull_request_template.md
```

## Branch policies

Follow `templates/azure-devops/branch-policy-guide.md` to configure:
- Minimum number of reviewers on `main` and `develop`
- Build validation (link your pipeline)
- Required linked work items
- Comment resolution policy
- Merge strategy

## Linking work items

Use `AB#<id>` syntax in PR descriptions and commit messages to auto-link
Azure Boards work items. Enforce this via branch policies when using
`strict` or `enterprise` profiles.

## Azure Pipelines

A placeholder pipeline file is included in `templates/azure-devops/branch-policy-guide.md`.
Copy it to `azure-pipelines.yml` and add your build/test steps.

## Agent behavior on Azure DevOps projects

- Handoff includes `DETECTED PLATFORM: Azure DevOps`
- PR descriptions reference `AB#<id>` work item syntax
- Build validation guidance is included
- Required reviewers guidance is included when `enterprise` profile is active

## What this system does NOT do

- It does not configure Azure DevOps branch policies automatically
- It does not manage Azure DevOps secrets or variable groups
- It does not push to Azure DevOps repos
- It does not create or modify pipelines without explicit instruction
