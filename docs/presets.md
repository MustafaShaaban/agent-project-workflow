# Presets

Presets describe the workflow files, skills, constitution rules, and defaults for a project archetype.

Current preset families:

- `generic`
- `wordpress`
- `wordpress-site`
- `wordpress-plugin`
- `wordpress-theme`
- `wordpress-block`
- `wordpress-woocommerce`
- `wordpress-bedrock`

The PowerShell MVP can select an archetype with `-Type`:

```powershell
.\scripts\project-workflow.ps1 init -Type wordpress-plugin -Profile standard -Apply
```

Presets produce `.ai-workflow.yml`, `.ai-skills.json`, `AGENTS.md`, `CLAUDE.md`, `PROJECT-WORKING-GUIDE.md`, `PROGRESS.md`, `DECISIONS.md`, `specs/constitution.md`, and `.agent-workflow.lock.json`.

WordPress presets require `wp-guard`; WooCommerce requires `woo-guard`.

Each preset directory contains `.ai-workflow.yml`, `.ai-skills.json`, `AGENTS.md`, `CLAUDE.md`, `PROJECT-WORKING-GUIDE.md`, `PROGRESS.md`, `DECISIONS.md`, `specs/constitution.md`, and a README.

Regenerate deterministic preset payloads after changing preset rules:

```powershell
.\scripts\generate-presets.ps1
```
