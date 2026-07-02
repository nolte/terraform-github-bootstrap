# Vision

`terraform-github-bootstrap` is the nolte portfolio's source of GitHub
configuration as code. Using the Terraform `integrations/github` provider, it
manages the nolte GitHub account's repository inventory (existence, description,
topics, visibility, feature flags) and per-repo repository rulesets (modern
branch protection) as code. It is the deliberate complement to gh-plumbing's
Probot-managed per-repo settings: this repository owns the Terraform-managed half
of GitHub configuration, split cleanly per its README's source-of-truth table.

## Outcomes

- **O-1** — the nolte GitHub account's repository inventory and per-repo rulesets
  exist as reviewable Terraform code rather than click-ops, so the account's
  configuration is reproducible and auditable. _(audience: The nolte GitHub account and its repositories)_
- **O-2** — the Terraform operator applies GitHub configuration changes
  reproducibly, with a plan reviewed on every pull request before apply.
  _(audience: Terraform operator / maintainer (nolte))_
