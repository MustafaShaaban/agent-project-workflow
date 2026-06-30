# Claude Code Entry Point

<!-- agent-project-workflow:start -->
Read and follow `AGENTS.md`, `.ai-workflow.yml`, `.ai-skills.json`, `.agent-workflow.lock.json`, and `PROJECT-WORKING-GUIDE.md` before project work.

For every project request, even if the user does not mention `project-workflow`, automatically follow the project-workflow startup sequence before planning, editing, writing code, changing docs, running commands, committing, pushing, or merging.

Repository instructions and active specs override generic global routines. Work from the real Git root, preserve user changes, ask before initializing Spec Kit when not already requested/configured, and finish with the required handoff and `NEXT STEP`.

Workflow authority: project-workflow owns startup and verification. Spec Kit owns
the exact enforced stages below. Conditional guards own safety checks. Optional
skills must not replace Spec Kit unless the owner explicitly overrides the policy.
Implementation starts only after checklist, tasks, and analyze complete.

Exact command order:

```text
/speckit.constitution
/speckit.specify
/speckit.clarify
/speckit.plan
/speckit.checklist
/speckit.tasks
/speckit.analyze
/speckit.implement
/speckit.converge
```

Codex skills-mode equivalent:

```text
$speckit-constitution
$speckit-specify
$speckit-clarify
$speckit-plan
$speckit-checklist
$speckit-tasks
$speckit-analyze
$speckit-implement
$speckit-converge
```

Do not skip or reorder steps. `converge` is conditional on availability and need.

For an empty directory or missing Git root, do not implement. Detect state, ask about Git when approval is missing, ask for project type only if unknown, apply approved workflow files, run doctor/audit, and stop with a recommended next step.
<!-- agent-project-workflow:end -->

## Project-specific notes

Add Claude-specific project notes here. This section is preserved during workflow upgrades.
