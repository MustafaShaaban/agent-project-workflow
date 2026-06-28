# WordPress Support and wp-guard

`project-workflow` is a universal workflow system. It does not contain
WordPress-specific rules. WordPress-specific safety is handled by a companion
skill: **wp-guard**.

## Why wp-guard is separate

WordPress projects have unique risks that do not apply to other project types:
- Modifications to `wp-core` files are wiped on WordPress updates
- Plugin/theme structures follow strict conventions that agents can accidentally break
- Child themes, mu-plugins, and drop-ins have subtle override rules
- Direct database access via WP-CLI must be handled carefully

Keeping wp-guard separate means `project-workflow` stays a clean, generic
orchestrator, and wp-guard can evolve its WordPress-specific rules independently.

## Detection

The agent and audit script detect WordPress using these indicators:

| Indicator | Description |
|-----------|-------------|
| `wp-config.php` | Core WordPress config |
| `wp-config-sample.php` | WordPress installer artifact |
| `wp-content/` directory | WordPress content directory |
| `wp-content/plugins/` | Plugin directory |
| `wp-content/themes/` | Themes directory |
| `wp-login.php` | WordPress login page |
| `wp-blog-header.php` | WordPress bootstrap file |
| `composer.json` with `johnpbloch/wordpress` | Composer-managed WP |
| `composer.json` with `roots/bedrock` | Bedrock WP stack |
| `package.json` with `@wordpress/*` | Gutenberg/block development |

Detection is also configurable via `.ai-skills.json` under `detection.project_types.wordpress`.

## What happens when WordPress is detected

| Profile | Missing wp-guard behavior |
|---------|--------------------------|
| minimal | Warn only, continue |
| standard | Warn and ask before continuing |
| strict | Stop until wp-guard is installed or explicitly bypassed |
| enterprise | Stop until wp-guard is installed or explicitly bypassed |

The agent will **never** silently install wp-guard unless an approved
`install_command` is present in `.ai-skills.json` and `install_mode` is
`auto-approved-only`.

## Configuring wp-guard behavior

In `.ai-workflow.yml`:

```yaml
wordpress:
  guard_required: true

skills:
  install_mode: ask
  conditional_required:
    - name: wp-guard
      condition: wordpress_detected
```

In `.ai-skills.json`, set `install_approved: true` and provide the install command
only if you have a verified, approved installation procedure for wp-guard.

## What to do if wp-guard is not installed

1. Find the wp-guard installation procedure from its documentation
2. Add the verified install command to `.ai-skills.json` with `install_approved: true`
3. Or install it manually and then continue with the project workflow

If you want to proceed without wp-guard in a one-off session, explicitly tell
the agent:

```text
I acknowledge wp-guard is missing. Proceed without it for this session only.
```

The agent will note this as a risk in its handoff.

## Non-WordPress projects

If your project is not WordPress, `wp-guard` is never required.
The detection checks run once at session start and do not block non-WordPress work.
