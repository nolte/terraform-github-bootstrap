# Portfolio Ops — operator setup

The `terraform/portfolio-ops/` root module wires the Actions variables and secrets for [`nolte/gh-portfolio-ops`](https://github.com/nolte/gh-portfolio-ops), the repository that hosts scheduled and dispatch automations over the `nolte` portfolio (sibling to `gh-plumbing`). This page tells an operator (you) what to do *before* `task tf:apply:portfolio-ops` and what the apply will actually do.

One `<concern>.tf` file exists per automation. The first concern is the **PR merge-queue board**.

## What Terraform owns vs. what stays manual

Terraform can only manage the **wiring** on the `gh-portfolio-ops` repo — the Actions variable and secret that the automation reads. The board itself, its kanban view, and the PAT value are UI-only: the `integrations/github` provider has no Projects V2 resource, and a PAT can only be minted in the GitHub UI.

| Step | Where | Owner |
|---|---|---|
| 1. Create the `gh-portfolio-ops` repo (its `bootstrap.sh`) | local shell | **manual (you)** |
| 2. Adopt the repo into `terraform/repos` via `terraform import` | local shell | **manual (you), one-time** |
| 3. Create the Projects V2 board ("PR Merge Queue") | `https://github.com/users/nolte/projects/new` | **manual (you)** |
| 4. Configure the board's "grouped by Status" kanban view | board UI | **manual (you)** |
| 5. Mint the merge-queue PAT | GitHub UI (Developer settings) | **manual (you)** |
| 6. Persist the PAT in gopass | local shell | **manual (you), one-time** |
| 7. Set `project_number` in `terraform.tfvars` | local file (git-ignored) | **manual (you)** |
| 8. Create the `PROJECT_NUMBER` Actions variable | github_actions_variable | **Terraform** |
| 9. Create the `MERGE_QUEUE_TOKEN` Actions secret | github_actions_secret | **Terraform** |

The `automerge` label on target repositories is **not** managed here — it is owned by `gh-plumbing`'s Probot `settings.yml`, and must never be duplicated into this module.

## The merge-queue PAT — exact permissions

It is a **classic** Personal Access Token (not fine-grained), owned by `nolte`, with exactly two scopes:

| Scope | Why the merge-queue sync workflow needs it |
|---|---|
| `repo` | Read PRs across `nolte/*` (including private repos), set/remove the merge-queue labels on PRs, and read PR/check status. |
| `project` | Add, update, and reorder items on the user-level Projects V2 board. Because the workflow **writes** to the board, the read-only `read:project` sub-scope is not enough — the full `project` scope (read + write) is required. |

Notes:

- The classic `repo` scope does **not** include project access — `project` must be granted separately.
- `workflow` is **not** needed: the token never edits files under `.github/workflows/`.
- Keep the scope set minimal. Anything beyond `repo` + `project` is over-privileged for this automation.

## One-time operator setup

After the board exists and the PAT is minted (steps 3–5 above), persist the PAT in gopass so neither `terraform.tfvars` nor any shell history ever sees it in cleartext. The canonical store path follows the URL-based gopass convention:

```sh
# Paste the classic PAT value when prompted.
gopass insert internet/github.com/nolte/tokens/gh-portfolio-ops/merge-queue-pat
```

If you keep the secret under a different store path, override the prefix via the `PORTFOLIO_OPS_GOPASS_PREFIX` env var before sourcing `scripts/portfolio-ops-env.sh`.

Then record the board number in the git-ignored tfvars (the trailing path segment of `https://github.com/users/nolte/projects/<N>`):

```hcl
# terraform/portfolio-ops/terraform.tfvars
project_number = 5
```

## Per-session workflow

`scripts/portfolio-ops-env.sh` is the bridge between gopass and Terraform. It exports `TF_VAR_merge_queue_token` (read fresh from gopass) and `GITHUB_TOKEN` (from `gh auth token`), and **fails fast** if the PAT is missing or empty — so a forgotten gopass entry can never end up as a blank `MERGE_QUEUE_TOKEN` secret:

```sh
source scripts/portfolio-ops-env.sh
task tf:plan:portfolio-ops          # review what Terraform will change
task tf:apply:portfolio-ops         # human-gated apply
```

After the apply, `gh-portfolio-ops` carries the `PROJECT_NUMBER` Actions variable and the `MERGE_QUEUE_TOKEN` Actions secret. Verify with:

```sh
gh variable list -R nolte/gh-portfolio-ops
gh secret list   -R nolte/gh-portfolio-ops
```

## Adding a future concern

Each new automation gets its own `<concern>.tf` beside `merge-queue.tf`, its own `variable`/`output` entries, and — if it needs a secret — its own `TF_VAR_*` export appended to `scripts/portfolio-ops-env.sh`. Keep the manual-vs-Terraform split above in mind: board structure, views, and PAT values stay UI-only.

## See also

- [`nolte/gh-portfolio-ops`](https://github.com/nolte/gh-portfolio-ops) — the repository whose automations consume the variable and secret.
- [Portfolio App — operator setup](portfolio-app.md) — the sibling runbook for the per-repo App credentials.
