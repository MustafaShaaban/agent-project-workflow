# Question Engine

The workflow asks only useful questions that cannot be safely answered by inspecting the repository.

Every setup or task-intake question must use this structure:

```text
Detected:
Recommended:
Why:
Alternatives:
Impact:
Question:
Default if you approve:
```

## Task classes

- Tiny: typo, small docs edit, obvious comment update, simple config cleanup. Proceed with a documented safe assumption.
- Normal: feature, UI behavior, plugin/theme/block feature, API endpoint, data model, integration, tests, docs plus code. Ask only missing questions that affect implementation.
- High-risk: authentication, authorization, payments, user data, PII, security, database migration, deployment, CI/CD, production configuration, WooCommerce checkout/orders/payments/shipping/tax. Require Spec Kit and clarifying questions before implementation.

Do not ask about facts the repo can answer.
