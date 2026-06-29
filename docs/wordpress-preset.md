# WordPress Preset

WordPress is the first-class priority for this workflow.

## Detection

The workflow treats a project as WordPress when it finds WordPress core files, `wp-content/`, Bedrock or WordPress Composer packages, `@wordpress/` packages, plugin headers, theme headers, block metadata, or WooCommerce indicators.

## Required rules

- Never edit WordPress core.
- Never treat uploads, cache, vendor, or build output as source.
- Use WordPress APIs.
- Sanitize input and escape output.
- Use nonces for state-changing requests.
- Use capabilities for authorization.
- Prepare database queries.
- Keep strings translation-ready.
- Do not put business logic in themes unless the selected project is theme-only and presentation-only.
- Load assets conditionally.
- Use Spec Kit for non-trivial WordPress work.

## Skills

WordPress presets require `project-workflow`, `clean-code-guard`, `test-guard`, `docs-guard`, and `wp-guard` for standard/strict profiles. WooCommerce presets also require `woo-guard`.
