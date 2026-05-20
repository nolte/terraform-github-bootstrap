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
| 9. (Optional, Phase 2) Branch-protection bypass for the App | github_branch_protection | **Terraform** (after operator opts in) |

The permissions list, the exact webhook setting, and the rationale behind the App-token cascade are documented once at [`nolte/gh-plumbing/docs/en/portfolio-app/setup.md`](https://github.com/nolte/gh-plumbing/blob/develop/docs/en/portfolio-app/setup.md) — do not duplicate them here.

## One-time operator setup

After steps 1–5 above are done in the GitHub UI, persist the credentials in gopass so neither `terraform.tfvars` nor any shell history ever sees them in cleartext:

```sh
# Numeric App ID — visible on the App's settings page header.
gopass insert github/apps/nolte-portfolio-bot/app-id

# Private key — paste the entire PEM (BEGIN/END lines included).
gopass insert -m github/apps/nolte-portfolio-bot/private-key < downloaded.pem

# Wipe the local PEM file once gopass has it.
shred -u downloaded.pem
```

The default slug is `nolte-portfolio-bot`; if you pick a different one, set `var.app_slug` accordingly and replace the path under `github/apps/<slug>/` in gopass.

## Per-session workflow

`scripts/portfolio-app-env.sh` is the bridge between gopass and Terraform. It exports `TF_VAR_app_id`, `TF_VAR_app_private_key`, and `GITHUB_TOKEN` — all three are read fresh from gopass / `gh auth token` on every session:

```sh
source scripts/portfolio-app-env.sh
task tf:plan:portfolio-app          # review what Terraform will change
task tf:apply:portfolio-app         # human-gated apply
```

After the apply, the consumer repositories listed in `var.consumer_repositories` (defaults: `terraform-github-bootstrap`, `gh-plumbing`, `claude-shared`) have the variable and secret in place. The reusable workflows in `nolte/gh-plumbing` then auto-detect them via the `vars.PORTFOLIO_APP_ID != ''` switch and mint an App-installation token instead of falling back to `GITHUB_TOKEN`.

## Phase 0 → Phase 2

The wrapper module defaults to `enable_branch_bypass = false` (Phase 0): variable and secret only. Flipping to Phase 2 (`enable_branch_bypass = true`) declares the App as a branch-protection-bypass actor on `var.protected_branches`. Per the upstream module's rollout doc, do this **only after**:

- The App is installed in every consumer repository (step 5 of the manual checklist).
- A cross-repository security review of the App's permissions has happened.

When in doubt, leave Phase 2 off — the cascade gap closes already with Phase 0 for the workflows that actively read `vars.PORTFOLIO_APP_ID`.

## See also

- [Upstream module README](https://github.com/nolte/gh-plumbing/blob/develop/terraform/portfolio-app/README.md) — input reference, output reference, owner-mode matrix.
- [Upstream setup guide](https://github.com/nolte/gh-plumbing/blob/develop/docs/en/portfolio-app/setup.md) — required App permissions and the cascade rationale.
- Issue [`nolte/gh-plumbing#330`](https://github.com/nolte/gh-plumbing/issues/330) — the tracking issue that motivated the portfolio App.
