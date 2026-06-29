# Decisions

## Decision log

### YYYY-MM-DD - Initial workflow defaults

- **Decision:** Use the selected project type, archetype, profile, branching strategy, platform, detected CI, skills policy, Spec Kit status, and owner-chosen defaults recorded in `.agent-workflow.lock.json`.
- **Reason:** Repo-local workflow defaults remove chat-history dependency and keep setup reproducible.
- **Impact:** Agents follow automatic startup instructions and preserve user-owned sections during workflow upgrades.
- **Revisit trigger:** Project type, branching model, CI provider, risk profile, or owner defaults change.
