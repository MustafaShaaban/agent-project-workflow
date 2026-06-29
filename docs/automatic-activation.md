# Automatic Activation

Generated `AGENTS.md`, `CLAUDE.md`, and `PROJECT-WORKING-GUIDE.md` instruct supported agents to follow project-workflow automatically.

Agents must run the startup sequence before planning, editing, writing code, changing docs, running commands, committing, pushing, or merging, even when the user does not mention `project-workflow`.

The startup sequence resolves the real root, checks Git state, detects platform/CI/project type, reads workflow config and lock files, reads instruction/progress/decision/constitution files, then states the mode and recommended next step.

This removes chat-history dependency and makes the workflow repo-local.
