# Git Flow Support

Git Flow is supported as an optional branching strategy. It is **not** enforced
by default. Enable it by setting `branching.strategy: git-flow` in `.ai-workflow.yml`.

## Branch structure

| Branch | Source | Merges into | Purpose |
|--------|--------|-------------|---------|
| `main` / `master` | — | — | Production/release |
| `develop` | `main` | — | Integration |
| `feature/<name>` | `develop` | `develop` | New features |
| `fix/<name>` | `develop` | `develop` | Bug fixes |
| `chore/<name>` | `develop` | `develop` | Maintenance, docs, tooling |
| `release/<version>` | `develop` | `main` + `develop` | Release preparation |
| `hotfix/<name>` | `main` | `main` + `develop` | Urgent production fixes |

## Rules

- **Never** implement directly on `main` / `master`.
- **Never** implement directly on `develop` (except owner-approved tiny docs/workflow changes).
- `feature/*`, `fix/*`, `chore/*` must start from `develop`.
- `release/*` must start from `develop` and merge into both `main` and back into `develop`.
- `hotfix/*` must start from `main` and merge into both `main` and back into `develop`.
- **Never** rewrite history (`git push --force` is blocked).
- **Never** delete or rename branches automatically.

## Enabling Git Flow

In `.ai-workflow.yml`:

```yaml
branching:
  strategy: git-flow
  production_branch: main
  integration_branch: develop
```

If `develop` does not exist, the agent will stop and ask whether to create it from `main`.
If the project already uses a different branching model, the agent will stop and ask before changing.

## Guards

Run these before editing or merging:

```powershell
.\scripts\guard-git-flow.ps1
.\scripts\guard-before-edit.ps1
.\scripts\guard-before-merge.ps1
```

## Creating `develop` from scratch

```powershell
git checkout main
git pull
git checkout -b develop
git push -u origin develop
```

Then update `.ai-workflow.yml` and commit.

## Git Flow and profiles

| Profile | Git Flow enforcement |
|---------|---------------------|
| minimal | Not enforced |
| standard | Warns on violations |
| strict | Blocks on violations |
| enterprise | Blocks + requires PR reviews |

## When NOT to use Git Flow

- Single-developer projects → GitHub Flow is simpler
- Continuous deployment pipelines → Trunk-based development is more appropriate
- Short-lived prototypes → `minimal` profile with no enforced strategy
