# terraform-github-bootstrap

Bootstrap of the [`nolte`](https://github.com/nolte) GitHub organisation as Terraform code.

## Scope

This repository owns:

- **Organisation settings** — member permissions, 2FA enforcement, default repository permissions.
- **Teams and memberships** — every nolte-internal team plus its repository permissions.
- **Branch protection / rulesets** — org-wide rulesets enforced through the GitHub API.

Per-repository configuration (settings, labels, merge strategy, per-repo branch protection) stays in [`nolte/gh-plumbing`](https://github.com/nolte/gh-plumbing) via the Probot Settings app.

## Layout

```text
terraform/
  org/                  # organisation root module
```

See the repository [`README.md`](https://github.com/nolte/terraform-github-bootstrap#readme) for command entry points.
