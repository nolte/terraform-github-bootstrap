# terraform-github-bootstrap

Manage parts of the [`nolte`](https://github.com/nolte) GitHub user account as Terraform code.

## Scope

This repository owns:

- **Repository inventory** — which repositories exist on `nolte`, their description, topics, visibility, `has_issues` / `has_wiki` / `has_projects` flags.
- **Per-repository rulesets** — modern branch-protection via `github_repository_ruleset`.

Per-repository configuration that Probot already handles well (labels, merge strategy, classic branch protection, release-drafter, boring-cyborg) stays in [`nolte/gh-plumbing`](https://github.com/nolte/gh-plumbing) via the Probot Settings app.

`nolte` is a personal user account, not an organisation. Org-only concerns (teams, org settings, organisation-wide rulesets) are out of scope.

## Layout

```text
terraform/
  repos/                # repository inventory + per-repo rulesets
```

See the repository [`README.md`](https://github.com/nolte/terraform-github-bootstrap#readme) for command entry points.
