# Skills Policy

Skills are separated into build skills and guard skills.

Required for every managed project:

- `project-workflow`

Required for standard, strict, and enterprise profiles:

- `clean-code-guard`
- `test-guard`
- `docs-guard`

Required for WordPress:

- `wp-guard`

Required for WooCommerce:

- `woo-guard`

Optional WordPress build skills include plugin development, block development, block themes, REST API, WP-CLI/ops, performance, PHPStan, and Playground skills.

`install-skills -ApprovedOnly` executes documented commands only when `install_approved` is true and the command matches the `npx -y skills add ...` allowlist. Shell operators, redirects, and unsupported commands are rejected. Unknown or unapproved skills remain manual.

## Verified companion package

All five required guard names are real installable skills in
`amElnagdy/guard-skills`. This was verified with:

```powershell
npx -y skills add amElnagdy/guard-skills --list
```

The package reports `clean-code-guard`, `test-guard`, `docs-guard`, `wp-guard`,
and `woo-guard`. Install an individual guard globally for Codex and Claude Code
with this pattern:

```powershell
npx -y skills add amElnagdy/guard-skills --skill wp-guard --global --agent claude-code --agent codex --copy
```

Generated `.ai-skills.json` files include the corresponding command for each
guard, but default to `install_approved: false`. The commands are therefore
documented manual companion installs, not automatic installs. Review the remote
repository and change that field only when the project owner approves the
third-party source.
