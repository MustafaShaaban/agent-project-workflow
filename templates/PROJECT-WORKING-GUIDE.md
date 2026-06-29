# Project Working Guide

<!-- agent-project-workflow:start -->
## Start a session

Run the startup sequence from `AGENTS.md` before planning, editing, writing code, changing docs, running commands, committing, pushing, or merging. State the detected mode: Planning, Implementation, Docs, Design, Debugging, Review, Release, or Bootstrap.

## Task intake

Classify the task:

- Tiny: typo, small docs edit, obvious comment update, simple config cleanup. Proceed with a documented safe assumption.
- Normal: feature, UI behavior, plugin/theme/block feature, API endpoint, data model, integration, tests, docs plus code. Ask only missing implementation questions.
- High-risk: authentication, authorization, payments, user data, PII, security, database migration, deployment, CI/CD, production configuration, WooCommerce checkout/orders/payments/shipping/tax. Require Spec Kit and clarifying questions before implementation.

Question format:

```text
Detected:
Recommended:
Why:
Alternatives:
Impact:
Question:
Default if you approve:
```

## Handoff

For real project work, end with SUMMARY, WORKSPACE, MODE, SPEC KIT STATUS, VERIFICATION, BLOCKERS / DECISIONS NEEDED, RECOMMENDED OPTIONS, and NEXT STEP.
<!-- agent-project-workflow:end -->

## Project-specific notes

Add local process details here. This section is preserved during workflow upgrades.
