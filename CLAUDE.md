# CLAUDE.md

## Purpose

This repository owns the **per-repository** GitHub configuration for the [`nolte`](https://github.com/nolte) **user account** as Terraform, complementing the per-repo Probot Settings configuration that lives in [`nolte/gh-plumbing`](https://github.com/nolte/gh-plumbing).

`nolte` is a personal user account, not an organisation — so org-only concerns (teams, org settings, organisation-wide rulesets) are deliberately out of scope.

## Architecture hints

- Terraform provider: [`integrations/github`](https://registry.terraform.io/providers/integrations/github/latest/docs).
- State: **local** (`terraform/repos/terraform.tfstate`) until a remote backend is chosen. State files and `terraform.tfvars` are git-ignored.
- Module layout: one root module per concern under `terraform/<root>/`. Current roots:
  - `terraform/repos/` — repository inventory plus per-repo rulesets.
  - `terraform/portfolio-app/` — thin wrapper around `github.com/nolte/gh-plumbing//terraform/portfolio-app?ref=develop` that provisions per-repo `PORTFOLIO_APP_ID` variable and `PORTFOLIO_APP_PRIVATE_KEY` secret on consumer repositories. App-credentials are read from gopass via `scripts/portfolio-app-env.sh` and exported as `TF_VAR_*` — they never land in tfvars or the repo.
- Provider authentication: `GITHUB_TOKEN` (PAT belonging to `nolte`) with at minimum the `repo` and `delete_repo` scopes for the resources this module manages. CI does **not** apply.
- **Do not** duplicate concerns owned by `gh-plumbing` (per-repo `settings.yml`, labels, merge strategy, classic branch protection driven by the Probot Settings app). The `github_repository` resource here intentionally `ignore_changes` on `allow_*_merge`, `delete_branch_on_merge`, and `allow_auto_merge` so Probot remains authoritative for those fields.
- **Adopt** existing repositories with `terraform import github_repository.managed["<name>"] <name>` before the first apply for that key. Forgetting this will make Terraform try to recreate the repo, which fails (name collision) or — in the worst case — could destroy and recreate. The example tfvars carries inline import instructions.

## Command entry points

All developer commands go through `Taskfile.yml`:

| Task | What it does |
|---|---|
| `task lint` | pre-commit (terraform_fmt, terraform_validate, tflint, yamllint) |
| `task test` | `terraform validate` across every root module |
| `task docs` | `mkdocs build --strict` |
| `task tf:fmt` | `terraform fmt -recursive terraform/` |
| `task tf:validate` | Iterates over every `terraform/<root>/` and runs `terraform init -backend=false && terraform validate` |
| `task tf:plan` | `terraform -chdir=terraform/repos plan` (requires `GITHUB_TOKEN`) |
| `task tf:apply` | `terraform -chdir=terraform/repos apply` (requires `GITHUB_TOKEN`) |
| `task tf:plan:portfolio-app` | plan of the portfolio-app root module (needs `source scripts/portfolio-app-env.sh` first) |
| `task tf:apply:portfolio-app` | apply of the portfolio-app root module (human-gated) |

## Working conventions

- **Never** run `terraform apply` from CI on this repo. Apply is a deliberate, human-gated step performed locally by the account owner.
- **Never** commit a real `terraform.tfvars` containing secrets. Use `*.example.tfvars` for fixtures.
- **Never** edit repository inventory or rulesets through the GitHub UI once Terraform manages them — any UI change is drift that must be reconciled back into Terraform.
- **Always** `terraform import` existing repos before the first apply targets them.
- Pin every `nolte/gh-plumbing` workflow reference in `.github/workflows/` to a release tag (currently `v1.1.18`), never to a moving branch. **Exception:** the `portfolio-app` Terraform module is pinned to `?ref=develop` because it landed after `v1.1.18`; repin to the first tagged release that contains the module.
- **Never** commit the App ID, App slug, or App private key. They live in gopass under `github/apps/<app-slug>/{app-id,private-key}` and are exported as `TF_VAR_*` by `scripts/portfolio-app-env.sh` at apply time.
- The GitHub App itself — registration, private-key generation, and per-repository installation — cannot be created by Terraform. All three are UI-only operations at `https://github.com/settings/apps/new`, the App's settings page, and the App's "Install" page. This repo only manages what happens **after** the App is registered and installed: per-repo Actions variable, secret, and (Phase 2) branch-protection bypass.
- Operator runbook for the portfolio App lives at `docs/en/portfolio-app.md`. Keep it in sync whenever the wrapper module's inputs change.
