---
id: F-1
title: Reconciled GitHub configuration
status: done
roadmap_item: R-1
sprint: 1
created: 2026-07-02
ended: 2026-07-02
verifies_sprint_value: acceptance-1
consistency_check:
  performed_at: 2026-07-02
  agent_version: manual-fallback (retroactive; feature-consistency-reviewer not run cross-repo)
  findings:
    - kind: clean
      target: project/features/
      resolution: proceed
      evidence: "project/features/ empty (first decomposition); no feature-to-feature overlap possible."
    - kind: prior-art
      target: the applied Terraform configuration
      resolution: proceed
      evidence: "The Terraform github-config-as-code already manages the account inventory and rulesets; F-1 documents the reconciliation contract, it does not build new configuration."
---

## Description

F-1 is the mission-verifying feature for the shipped `github-config-as-code`
capability. The Terraform configuration declares the nolte GitHub account's
repository inventory and per-repo rulesets. The contract is met when
`terraform apply` reconciles that declaration with the account and reports no
drift. This holds against the applied configuration, so the feature is recorded
`done` as part of the retroactive MVP reconciliation (issue
nolte/claude-shared#262).

## Acceptance criteria

- [x] **acceptance-1** `terraform apply` reconciles the declared repository
  inventory and rulesets with the nolte GitHub account and reports no drift.
  _(This is the sprint value verifier.)_
- [x] **acceptance-2** Every pull request runs `terraform plan`, so configuration
  changes are reviewable before apply.
- [x] **acceptance-3** Repository rulesets (modern branch protection) are managed
  per repo as code, complementing gh-plumbing's Probot-managed settings.

## Test hooks

- **acceptance-1** — `terraform plan` shows no diff against the applied state — passing.
- **acceptance-2** — the plan-on-pull-request CI job — passing.
- **acceptance-3** — inspect the managed `github_repository_ruleset` resources — passing.

## Consistency notes

Retroactive documentation feature: the Terraform configuration predates the
planning suite. No new implementation is introduced; the feature exists so the
mission's `verifies_via: F-1:acceptance-1` and sprint 1's `value_statement`
resolve to a real acceptance criterion.

## References

- `project/portfolio.yml` capability `github-config-as-code`
- `AUDIENCES.md` audience "Terraform operator / maintainer (nolte)"
- `README.md` source-of-truth table (Terraform vs Probot split)
