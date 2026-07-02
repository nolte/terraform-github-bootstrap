---
number: 1
status: closed
started: 2026-07-02
ended: 2026-07-02
value_statement: The nolte GitHub account's repository inventory and per-repo rulesets are managed as reviewable Terraform code, reconciled by terraform apply with no drift.
artifact_ref: develop (shipped capability, pre-planning-suite)
roadmap_items: [R-1]
features: [F-1]
---

## Goal

The nolte GitHub account's repository inventory and per-repo rulesets exist as
Terraform code that `terraform apply` reconciles with the account. Success is
verified by F-1 `acceptance-1`: an apply reconciles the declared inventory and
rulesets and reports no drift.

## Features

- [F-1](../features/reconciled-github-configuration.md) — Reconciled GitHub configuration — status: done

## Out of scope

- gh-plumbing's Probot-managed per-repo settings (the deliberate complement, a
  separate source of truth).
- Secrets, environments, and organisation-level policy outside the declared
  repository inventory and rulesets.

## Review notes

Retroactive reconciliation (2026-07-02): the `github-config-as-code` capability
was already `status: active` before this repository adopted the planning suite
(issue nolte/claude-shared#262 mission-authoring backfill). This sprint records
roadmap item R-1 and feature F-1 as `done`, and itself as `closed`, to document
the delivered MVP rather than to plan new work.
