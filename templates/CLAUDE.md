# Claude Code Entry Point

<!-- agent-project-workflow:start -->
Read and follow `AGENTS.md`, `.ai-workflow.yml`, `.ai-skills.json`, `.agent-workflow.lock.json`, and `PROJECT-WORKING-GUIDE.md` before project work.

For every project request, even if the user does not mention `project-workflow`, automatically follow the project-workflow startup sequence before planning, editing, writing code, changing docs, running commands, committing, pushing, or merging.

Repository instructions and active specs override generic global routines. Work from the real Git root, preserve user changes, ask before initializing Spec Kit when not already requested/configured, and finish with the required handoff and `NEXT STEP`.

Workflow authority: project-workflow owns startup and verification; Spec Kit owns clarify/spec/plan/tasks; conditional guards own safety checks. Optional executor, build, debug, Superpowers, or similar skills must not replace Spec Kit planning unless the owner explicitly overrides the policy. For non-trivial work, implementation starts only after active Spec Kit tasks exist.

For an empty directory or missing Git root, do not implement. Detect state, ask about Git when approval is missing, ask for project type only if unknown, apply approved workflow files, run doctor/audit, and stop with a recommended next step.
<!-- agent-project-workflow:end -->

## Project-specific notes

Add Claude-specific project notes here. This section is preserved during workflow upgrades.
