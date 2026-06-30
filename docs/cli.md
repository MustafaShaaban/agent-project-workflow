# CLI reference

The PowerShell CLI works on Windows PowerShell 5.1 and newer PowerShell hosts.
Run it from this repository or provide `-TargetPath`.

## Safest first command

Always preview before applying:

```powershell
.\scripts\project-workflow.ps1 init -Type auto -Profile standard -SpecKit -Agents codex,claude-code -DryRun
```

`-DryRun` detects state and proposed files without writing. `-SpecKit` is explicit
approval to attempt setup during apply; omit it when you want the agent to ask.

After reviewing the preview:

```powershell
.\scripts\project-workflow.ps1 init -Type auto -Profile standard -SpecKit -Agents codex,claude-code -Apply
.\scripts\project-workflow.ps1 doctor
```

If auto-detection is uncertain, `init` stops and prints the explicit type command
to run next.

## Commands

- `init`: add or update workflow files in an existing target. Dry-run by default.
- `new`: create a named directory and initialize Git; with an explicit type it applies workflow files.
- `audit`: read-only repository and workflow inspection.
- `doctor`: validate workflow readiness and report the recommended next action.
- `upgrade`: refresh valid managed blocks; dry-run by default.
- `install-skills`: show approval questions or execute only allowlisted, approved commands.

Use `new` when you want a new named starter directory. Use `init` when the target
folder already exists, including an empty folder.

## Greenfield examples

```powershell
# Existing empty folder: detect Git and type decisions first.
.\scripts\project-workflow.ps1 init -Type auto -Profile standard -DryRun

# After Git and type decisions are approved.
.\scripts\project-workflow.ps1 init -Type generic -Profile standard -Apply

# New named React starter directory.
.\scripts\project-workflow.ps1 new -ProjectName my-app -Type react -Profile standard
```

## Existing repository examples

```powershell
.\scripts\project-workflow.ps1 audit
.\scripts\project-workflow.ps1 init -Type auto -Profile standard -DryRun
.\scripts\project-workflow.ps1 init -Type auto -Profile standard -Apply
.\scripts\project-workflow.ps1 doctor -Json
```

## Explicit project types

Use an explicit type only when detection cannot infer it or you are choosing a
greenfield archetype:

```powershell
.\scripts\project-workflow.ps1 init -Type generic -DryRun
.\scripts\project-workflow.ps1 init -Type php -DryRun
.\scripts\project-workflow.ps1 init -Type 'js/ts' -DryRun
.\scripts\project-workflow.ps1 init -Type react -DryRun
.\scripts\project-workflow.ps1 init -Type laravel -DryRun
.\scripts\project-workflow.ps1 init -Type python -DryRun
.\scripts\project-workflow.ps1 init -Type wordpress-site -DryRun
.\scripts\project-workflow.ps1 init -Type wordpress-plugin -DryRun
.\scripts\project-workflow.ps1 init -Type wordpress-theme -DryRun
.\scripts\project-workflow.ps1 init -Type wordpress-block -DryRun
```

Both `js/ts` and `js-ts` select JavaScript/TypeScript projects. Additional types
include `vue`, `nextjs`, `dotnet`, `wordpress-bedrock`, and
`wordpress-woocommerce`.

## File safety

Existing unmanaged files are never overwritten. The CLI writes a
`.suggested.md` proposal. A managed file must contain exactly one ordered marker
pair:

```markdown
<!-- agent-project-workflow:start -->
<!-- agent-project-workflow:end -->
```

Upgrade replaces only that inclusive block and preserves owner content around it.

## Skill installation

`install-skills` asks by default. `-ApprovedOnly` executes only entries with
`install_approved: true` whose commands match the safe
`npx -y skills add ...` allowlist. Unknown, unapproved, redirected, or chained
commands remain manual.
