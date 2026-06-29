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
