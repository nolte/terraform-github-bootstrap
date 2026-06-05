# Audiences — Terraform GitHub Bootstrap

<!--
Produced following spec/project/audience-identification/. Audiences are derived
from the repository's README and purpose, not invented. Do not add audiences
without first declaring the bounded context.
-->

## Bounded context

Terraform (integrations/github provider) that manages the nolte GitHub
account's repository inventory and per-repo repository rulesets (modern branch
protection) as code — the deliberate complement to gh-plumbing's Probot-
managed per-repo settings.

**Inside the boundary**

- The Terraform root module under `terraform/` (`github_repository`, `github_repository_ruleset`)

**Outside the boundary**

- The GitHub account and repositories being managed
- The `integrations/github` Terraform provider
- `nolte/gh-plumbing` (Probot-managed per-repo settings, the complementary source of truth)

## Audiences

Each entry: label, relationship category, interaction surface, expectation,
documentation `track` (per spec/project/docs-audience-tracks/), status, criticality.

### Operators

- **Terraform operator / maintainer (`nolte`)** — _category_: operator ·
  _surface_: `terraform plan`/`apply`, the root module, the state ·
  _expects_: a reproducible plan, safe rulesets, and a clear split versus gh-plumbing ·
  _track_: `developer-docs` · _status_: `assumed` · _criticality_: primary
- **GitHub Actions CI (plan on pull request)** — _category_: operator ·
  _surface_: the CI workflow running `terraform plan` ·
  _expects_: a deterministic plan diff on each pull request ·
  _track_: `developer-docs` · _status_: `assumed` · _criticality_: secondary

### Contributors / maintainers

- **Claude Code as co-author** — _category_: contributor ·
  _surface_: `CLAUDE.md`, `.claude/`, the Taskfile ·
  _expects_: deterministic conventions ·
  _track_: `developer-docs` · _status_: `assumed` · _criticality_: secondary

### Governing parties

- **The nolte GitHub account and its repositories** — _category_: governing ·
  _surface_: the repository inventory and rulesets applied by this module ·
  _expects_: consistent repository metadata and modern branch-protection rulesets ·
  _track_: `developer-docs` · _status_: `assumed` · _criticality_: primary

## Revisit triggers

Re-run `audience-identify revisit` when any of the following changes:

- `nolte` migrates from a user account to an organisation (org-only concerns enter scope).
- The split of source-of-truth versus gh-plumbing changes.
