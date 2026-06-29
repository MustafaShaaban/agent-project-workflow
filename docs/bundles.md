# Bundles

Bundles combine a preset and profile into a shorter command.

Supported/documented bundles:

- `generic-standard`
- `generic-strict`
- `wordpress-standard`
- `wordpress-strict`
- `wordpress-site-standard`
- `wordpress-plugin-standard`
- `wordpress-theme-standard`
- `wordpress-woocommerce-strict`

Examples:

```powershell
.\scripts\project-workflow.ps1 init -Bundle wordpress-standard -Apply
.\scripts\project-workflow.ps1 init -Bundle wordpress-strict -Apply
.\scripts\project-workflow.ps1 init -Bundle generic-standard -Apply
```

The MVP maps bundle names to the closest archetype/profile and records the selection in `.agent-workflow.lock.json`.
