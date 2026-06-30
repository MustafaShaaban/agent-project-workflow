# Agent Instructions

<!-- agent-project-workflow:start -->
For every project request, even if the user does not mention project-workflow, automatically follow the startup sequence in PROJECT-WORKING-GUIDE.md before planning, editing, running commands, committing, pushing, or merging.

Use one real Git root, preserve user work, protect generated/vendor/build/cache/upload paths, use Spec Kit for non-trivial work, update progress/decisions, run guards, and end with mandatory NEXT STEP.

Project-workflow owns startup and verification. Spec Kit owns the exact enforced
stages. Guard skills own conditional safety. Optional skills must not replace Spec
Kit unless the owner explicitly overrides this policy. Implement only after analyze.

Production commands:

/speckit.constitution
/speckit.specify
/speckit.clarify
/speckit.plan
/speckit.checklist
/speckit.tasks
/speckit.analyze
/speckit.implement
/speckit.converge

Codex skills mode:

$speckit-constitution
$speckit-specify
$speckit-clarify
$speckit-plan
$speckit-checklist
$speckit-tasks
$speckit-analyze
$speckit-implement
$speckit-converge

Do not skip or reorder steps. Run converge when available and needed; otherwise record why it was not applicable.
<!-- agent-project-workflow:end -->

## Project-specific notes
