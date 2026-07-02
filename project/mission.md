---
mission_statement: "terraform-github-bootstrap manages the nolte GitHub account's repository inventory and per-repo rulesets as reviewable Terraform code, so the account's configuration is reproducible and auditable instead of click-ops, complementing gh-plumbing's Probot-managed settings."
relevant_outcomes: [O-1, O-2]
audiences:
  - The nolte GitHub account and its repositories
  - Terraform operator / maintainer (nolte)
verifies_via: F-1:acceptance-1
time_bound:
  kind: mvp_completion
mvp_status: achieved
created: 2026-07-02
revised_at: null
---

## Statement

`terraform-github-bootstrap` manages the nolte GitHub account's repository
inventory and per-repo rulesets as reviewable Terraform code, so the account's
configuration is reproducible and auditable instead of click-ops. It complements
gh-plumbing's Probot-managed settings.

- **Specific** — the statement names *what* (Terraform-managed GitHub repository
  inventory and rulesets) and *for whom* (the nolte GitHub account and the
  Terraform operator, resolved in `audiences`).
- **Measurable** — `verifies_via: F-1:acceptance-1`: `terraform apply` reconciles
  the declared repository inventory and rulesets with the account, reporting no
  drift.
- **Achievable** — the minimum viable product is the shipped `github-config-as-code`
  capability; roadmap item R-1 is `mvp: true`, `detail: fine`, `target_sprint: 1`.
- **Relevant** — `relevant_outcomes: [O-1, O-2]`, each resolving to an outcome in
  `project/goals.md`.
- **Time-bound** — `time_bound: { kind: mvp_completion }`; the bound is the moment
  the shipped MVP is recorded as achieved.

## Audiences

- **The nolte GitHub account and its repositories** — the MVP delivers the
  account's repository inventory (existence, description, topics, visibility,
  feature flags) and per-repo rulesets as Terraform code, so the account's
  configuration is reconcilable from one source rather than hand-edited per repo.
- **Terraform operator / maintainer (nolte)** — the MVP delivers a Terraform
  configuration the operator plans on every pull request and applies to
  reconcile GitHub state, so configuration changes are reviewable before they
  land.

## Verification

The mission is verified by feature **F-1 — Reconciled GitHub configuration**,
acceptance criterion 1: *"`terraform apply` reconciles the declared repository
inventory and rulesets with the nolte GitHub account and reports no drift."*
This is the `verifies_sprint_value` criterion for sprint 0001 and holds against
the applied configuration, so the MVP is recorded as `achieved`.

## Source

- **Audience artefact**: `AUDIENCES.md` at the `terraform-github-bootstrap`
  repository root (consulted at its current develop tip); the two `audiences`
  entries are the operator and the managed GitHub account.
- **Outcomes referenced**: O-1, O-2 from `project/goals.md`.
- **Authored by**: the `mission-define` cascade (issue nolte/claude-shared#262
  mission-authoring backfill), 2026-07-02. The MVP is modelled retroactively: the
  `github-config-as-code` capability was already `status: active` when the
  repository adopted the planning suite, so R-1 is recorded `status: done` and
  `mvp_status` opens at `achieved`.
