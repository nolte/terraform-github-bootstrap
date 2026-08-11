# terraform-github-bootstrap

Manage parts of the [`nolte`](https://github.com/nolte) GitHub user account as Terraform code.

## Scope

This repository owns:

- **Repository inventory** — which repositories exist on `nolte`, their description, topics, visibility, `has_issues` / `has_wiki` / `has_projects` flags.
- **Per-repository rulesets** — modern branch-protection via `github_repository_ruleset`, including the bypass actor a repo's release automation needs when its ruleset protects the branch the portfolio App pushes to.
- **Portfolio App footprint** — per-repo `PORTFOLIO_APP_ID` variable and `PORTFOLIO_APP_PRIVATE_KEY` secret on consumer repos (see [Portfolio App](portfolio-app.md)).
- **Portfolio Ops wiring** — Actions variables and secrets for the `gh-portfolio-ops` automation repo, starting with the PR merge-queue board (see [Portfolio Ops](portfolio-ops.md)).

Per-repository configuration that Probot already handles well (labels, merge strategy, classic branch protection, release-drafter, boring-cyborg) stays in [`nolte/gh-plumbing`](https://github.com/nolte/gh-plumbing) via the Probot Settings app.

`nolte` is a personal user account, not an organisation. Org-only concerns (teams, org settings, organisation-wide rulesets) are out of scope.

## Layout

```text
terraform/
  repos/                # repository inventory + per-repo rulesets
  portfolio-app/        # per-repo Portfolio App credentials (variable + secret)
  portfolio-ops/        # gh-portfolio-ops automation wiring (merge-queue board)
```

See the repository [`README.md`](https://github.com/nolte/terraform-github-bootstrap#readme) for command entry points.
