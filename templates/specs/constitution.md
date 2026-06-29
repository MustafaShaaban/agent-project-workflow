# Project Constitution

<!-- agent-project-workflow:start -->
## Generic workflow principles

- Source-of-truth hierarchy: latest owner instruction, repository instructions, constitution, active specs, progress/decisions, docs, implementation code.
- Use one real Git root.
- Preserve user work.
- Use Spec Kit before code for non-trivial work.
- Run tests and guards before completion.
- Keep docs synchronized with code.
- Protect secrets and never expose credentials.
- Do not edit generated/vendor/build/cache/upload outputs as source.
- End with verification, recommended options, and mandatory `NEXT STEP`.
- Ask recommendation-first questions only when detection cannot answer safely.

## WordPress principles

- Never edit WordPress core.
- Never treat uploads, cache, vendor, or build output as source.
- Use WordPress APIs.
- Sanitize input and escape output.
- Use nonces for state-changing requests.
- Use capabilities for authorization.
- Prepare database queries.
- Keep strings translation-ready.
- Keep business logic out of themes unless the selected project is theme-only and presentation-only.
- Plugin work belongs in plugin mode; theme work belongs in theme mode; block work belongs in block mode.
- WooCommerce checkout, order, payment, shipping, and tax work requires WooCommerce mode and `woo-guard`.
- Load frontend, admin, and block assets conditionally.
- Avoid global asset bloat and prefer progressive enhancement.
- Respect WordPress coding standards where applicable.
- Add tests where the repository supports tests.
- Use Spec Kit for non-trivial WordPress work.
<!-- agent-project-workflow:end -->

## Project-specific notes

Add project-specific constitutional constraints here. This section is preserved during workflow upgrades.
