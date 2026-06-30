# Agent Instructions

<!-- agent-project-workflow:start -->
For every project request, even if the user does not mention project-workflow, automatically follow the startup sequence in PROJECT-WORKING-GUIDE.md before planning, editing, running commands, committing, pushing, or merging.

Use one real Git root, preserve user work, protect generated/vendor/build/cache/upload paths, use Spec Kit for non-trivial work, update progress/decisions, run guards, and end with mandatory NEXT STEP.

Project-workflow owns startup and verification. Spec Kit owns clarify/spec/plan/tasks. Guard skills own conditional safety. Optional executor, build, debug, Superpowers, or similar skills must not replace Spec Kit planning unless the owner explicitly overrides this policy. Do not implement non-trivial work before active Spec Kit tasks exist.
<!-- agent-project-workflow:end -->

## Project-specific notes
