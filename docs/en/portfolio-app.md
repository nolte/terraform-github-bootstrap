# Portfolio App — operator setup

The `terraform/portfolio-app/` root module wires up the [portfolio GitHub App](https://github.com/nolte/gh-plumbing/blob/develop/docs/en/portfolio-app/setup.md) on every consumer repository under the `nolte` user account. This page tells an operator (you) what to do *before* `task tf:apply:portfolio-app` and what the apply will actually do.

## What Terraform owns vs. what stays manual

Terraform can only manage the App's **footprint** in consumer repositories. The App's identity itself (registration, private key) is created via the GitHub UI — there is no GitHub REST or GraphQL endpoint to create a GitHub App or rotate its private key. Same goes for installing the App into individual repositories.

| Step | Where | Owner |
|---|---|---|
| 1. Register the App | `https://github.com/settings/apps/new` | **manual (you)** |
| 2. Grant the four required permissions | App settings UI | **manual (you)** |
| 3. Generate a private key | App settings UI ("Generate a private key") | **manual (you)** |
| 4. Note the numeric App ID | App settings UI header | **manual (you)** |
| 5. Install the App in every consumer repo | App's "Install" page | **manual (you)** |
| 6. Persist App ID + private key in gopass | local shell | **manual (you), one-time** |
| 7. Create per-repo `PORTFOLIO_APP_ID` Actions variable | github_actions_variable | **Terraform** |
| 8. Create per-repo `PORTFOLIO_APP_PRIVATE_KEY` Actions secret | github_actions_secret | **Terraform** |
| 9. (Optional, per repo) Ruleset bypass for the App on protected release branches | `github_repository_ruleset` `bypass_actors` in `terraform/repos` | **Terraform** (after operator opts in) |

The permissions list, the exact webhook setting, and the rationale behind the App-token cascade are documented once at [`nolte/gh-plumbing/docs/en/portfolio-app/setup.md`](https://github.com/nolte/gh-plumbing/blob/develop/docs/en/portfolio-app/setup.md) — do not duplicate them here.

## One-time operator setup

After steps 1–5 above are done in the GitHub UI, persist the credentials in gopass so neither `terraform.tfvars` nor any shell history ever sees them in cleartext. The canonical store path follows the URL-based gopass convention `internet/github.com/<owner>/apps/<app-slug>/`:

```sh
GP=internet/github.com/nolte/apps/nolte-portfolio-app

# Numeric App ID — visible on the App's settings page header.
gopass insert "$GP/appid"

# App slug — the path segment after /apps/ on the App's settings page.
gopass insert "$GP/slug"

# Private key — paste the entire PEM (BEGIN/END lines included).
gopass insert -m "$GP/private_key" < downloaded.pem

# Wipe the local PEM file once gopass has it.
shred -u downloaded.pem
```

The default slug is `nolte-portfolio-app`. If you pick a different one, override the gopass prefix via the `PORTFOLIO_APP_GOPASS_PATH` env var before sourcing `scripts/portfolio-app-env.sh`, and set `var.app_slug` accordingly in your tfvars (or leave it to the env loader, which pulls the slug from gopass).

## Per-session workflow

`scripts/portfolio-app-env.sh` is the bridge between gopass and Terraform. It exports `TF_VAR_app_id`, `TF_VAR_app_private_key`, `TF_VAR_portfolio_app_id` (the same App ID under the variable name the `terraform/repos` ruleset-bypass uses), and `GITHUB_TOKEN` — all read fresh from gopass / `gh auth token` on every session:

```sh
source scripts/portfolio-app-env.sh
task tf:plan:portfolio-app          # review what Terraform will change
task tf:apply:portfolio-app         # human-gated apply
```

After the apply, the consumer repositories listed in `var.consumer_repositories` (defaults: `terraform-github-bootstrap`, `gh-plumbing`, `claude-shared`) have the variable and secret in place. The reusable workflows in `nolte/gh-plumbing` then auto-detect them via the `vars.PORTFOLIO_APP_ID != ''` switch and mint an App-installation token instead of falling back to `GITHUB_TOKEN`.

## Protected-branch bypass (ruleset-based)

The bypass the App needs on protected release branches is **not** managed through this wrapper module (the upstream `enable_branch_bypass` / `github_branch_protection` Phase-2 path is unused here — classic branch protection stays owned by Probot Settings). Instead, `terraform/repos` declares the App as an `always` `Integration` bypass actor directly on a repo's ruleset via the per-repo `bypass_portfolio_app = true` flag, with the App ID supplied as `var.portfolio_app_id` (exported by this page's env loader as `TF_VAR_portfolio_app_id`).

Opt a repo in **only** when its ruleset protects a branch the release automation writes with the App token — see the bypass-actors section in `CLAUDE.md` for the exact criterion and the caveat that `bypass_mode = "always"` waives every rule of that ruleset for the App. When in doubt, leave the flag off — the variable/secret footprint (steps 7–8) alone already closes the cascade gap for workflows that read `vars.PORTFOLIO_APP_ID`.

## See also

- [Upstream module README](https://github.com/nolte/gh-plumbing/blob/develop/terraform/portfolio-app/README.md) — input reference, output reference, owner-mode matrix.
- [Upstream setup guide](https://github.com/nolte/gh-plumbing/blob/develop/docs/en/portfolio-app/setup.md) — required App permissions and the cascade rationale.
- Issue [`nolte/gh-plumbing#330`](https://github.com/nolte/gh-plumbing/issues/330) — the tracking issue that motivated the portfolio App.
