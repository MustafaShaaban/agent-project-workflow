# Project Constitution

<!-- agent-project-workflow:start -->
Use the source-of-truth hierarchy, durable progress/decisions, Spec Kit before non-trivial code, tests/guards before completion, docs with code, CI awareness, branch safety, one real root, recommendation-first questions, and mandatory handoff/NEXT STEP.

## WordPress rules

Never edit WordPress core. Use WordPress APIs, sanitize input, escape output, use nonces and capabilities, prepare queries, keep strings translation-ready, load assets conditionally, and keep business logic in the correct plugin/theme/block mode.
## WooCommerce rules

Checkout, orders, payments, shipping, tax, customer data, and PII are high-risk. Require WooCommerce mode, woo-guard, and Spec Kit.
<!-- agent-project-workflow:end -->

## Project-specific notes
