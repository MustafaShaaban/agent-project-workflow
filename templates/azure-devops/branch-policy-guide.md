# Azure DevOps Branch Policy Guide

Configure these via **Project Settings → Repositories → Policies**
or per-branch under **Repos → Branches → Branch policies**.

## Recommended policies for `main` / `master`

| Policy | Setting |
|--------|---------|
| Require a minimum number of reviewers | 1–2 |
| Allow requestors to approve their own changes | No |
| Reset reviewer votes on new pushes | Yes |
| Require linked work items | Yes (for traceability) |
| Require comment resolution | Yes |
| Build validation | Add your CI pipeline |
| Limit merge types | Squash merge or merge commit (choose one convention) |

## Recommended policies for `develop`

| Policy | Setting |
|--------|---------|
| Require a minimum number of reviewers | 1 |
| Build validation | Yes |
| Require linked work items | Optional |

## Build validation pipeline placeholder

Create `azure-pipelines.yml`:

```yaml
trigger: none
pr:
  branches:
    include:
      - main
      - develop

pool:
  vmImage: ubuntu-latest

steps:
  - script: echo "No tests configured yet"
    displayName: "Run tests"
```

## Required reviewers

Add required reviewers under **Branch policies → Automatically included reviewers**.
Set teams rather than individuals where possible to avoid single points of failure.

## Linked work items

Enforce linked work items on `main` to ensure every merge is traceable to a backlog item.
Use `AB#<id>` syntax in PR descriptions to auto-link Azure Boards items.
