# CLAUDE.md

## Purpose

This repository owns the **organisation-level** GitHub configuration for the [`nolte`](https://github.com/nolte) org as Terraform, complementing the per-repo Probot Settings configuration that lives in [`nolte/gh-plumbing`](https://github.com/nolte/gh-plumbing).

## Architecture hints

- Terraform provider: [`integrations/github`](https://registry.terraform.io/providers/integrations/github/latest/docs).
- State: **local** (`terraform/<root>/terraform.tfstate`) until a remote backend is chosen. State files are git-ignored.
- Module layout: one root module per concern under `terraform/<root>/` (start: `terraform/org/`). Each root module is independently `terraform init`-able.
- Provider authentication: `GITHUB_TOKEN` with scope `admin:org` for org/team management and `repo` for branch-protection writes. The bootstrap operator runs locally; CI does **not** apply.
- Do **not** duplicate concerns owned by `gh-plumbing` (per-repo `settings.yml`, labels, merge strategy, repo-level branch protection driven by the Probot Settings app). Terraform here manages org-wide policy and team membership only.

## Command entry points

All developer commands go through `Taskfile.yml`:

| Task | What it does |
|---|---|
| `task lint` | pre-commit (terraform_fmt, terraform_validate, tflint, yamllint) |
| `task test` | `terraform validate` across every root module |
| `task docs` | `mkdocs build --strict` |
| `task tf:fmt` | `terraform fmt -recursive terraform/` |
| `task tf:validate` | Iterates over every `terraform/<root>/` and runs `terraform init -backend=false && terraform validate` |
| `task tf:plan` | `terraform -chdir=terraform/org plan` (requires `GITHUB_TOKEN`) |
| `task tf:apply` | `terraform -chdir=terraform/org apply` (requires `GITHUB_TOKEN`) |

## Working conventions

- **Never** run `terraform apply` from CI on this repo. Apply is a deliberate, human-gated step performed locally by the org owner.
- **Never** commit a real `terraform.tfvars` containing secrets. Use `*.example.tfvars` for fixtures.
- **Never** edit org settings, teams, or org-wide rulesets through the GitHub UI once Terraform manages them — any UI change is drift that must be reconciled back into Terraform.
- Pin every `nolte/gh-plumbing` workflow reference in `.github/workflows/` to a release tag (currently `v1.1.18`), never to a moving branch.
