# Automatic activation

Automatic activation means future agents can follow the repository workflow
without the owner repeating "use project-workflow" in every prompt.

## What makes it durable

Initialization creates repository-local files:

- `AGENTS.md`: Codex and general agent startup and authority rules.
- `CLAUDE.md`: Claude Code entry point.
- `PROJECT-WORKING-GUIDE.md`: human-readable task and handoff process.
- `.ai-workflow.yml`: profile, authority, Spec Kit, branch, and safety policy.
- `.ai-skills.json`: machine-readable skill requirements and precedence.
- `.agent-workflow.lock.json`: detected and generated setup state.
- `PROGRESS.md`, `DECISIONS.md`, and Spec Kit files: durable work state.

A global project-workflow skill helps an agent discover the process, but global
installation alone is not enough. The repository-local files make the chosen
rules and planning authority travel with the project and survive new chats.

## What happens when Codex or Claude opens the repo later

The agent should read its entry-point file, resolve the real Git root, inspect
status/branch/remotes/worktrees, detect platform/CI/project type, read workflow
and skill policy, inspect Spec Kit and durable state, and report the mode and next
step before implementation.

For non-trivial work, the agent must use Spec Kit clarify/spec/plan/tasks before
implementation. Optional workflow or executor skills cannot replace that planning
authority. Conditional guards apply only when their project/risk condition matches.

## Managed blocks preserve owner content

Workflow-owned text is placed between exact markers:

```markdown
<!-- agent-project-workflow:start -->
<!-- agent-project-workflow:end -->
```

Upgrade changes only the valid managed block. Text before or after it is owner
content and remains unchanged. Files without one valid ordered marker pair receive
a `.suggested.md` proposal instead of being overwritten.
