# Automatic Activation

Generated `AGENTS.md`, `CLAUDE.md`, `PROJECT-WORKING-GUIDE.md`, and
`specs/constitution.md` contain the workflow-owned block between these exact
markers:

```markdown
<!-- agent-project-workflow:start -->
<!-- agent-project-workflow:end -->
```

The three agent entry-point files instruct supported agents to follow
project-workflow automatically.

Agents must run the startup sequence before planning, editing, writing code, changing docs, running commands, committing, pushing, or merging, even when the user does not mention `project-workflow`.

The startup sequence resolves the real root, checks Git state, detects platform/CI/project type, reads workflow config and lock files, reads instruction/progress/decision/constitution files, then states the mode and recommended next step.

This removes chat-history dependency and makes the workflow repo-local.

Upgrade replaces only the inclusive managed block. Owner content before and
after the block is preserved. An existing file without exactly one ordered
marker pair is treated as owner-managed and receives a `.suggested.md` proposal
instead of being overwritten.
