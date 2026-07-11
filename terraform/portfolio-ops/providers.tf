provider "github" {
  owner = var.owner
  # GITHUB_TOKEN must be a personal access token of `nolte` (user mode) with
  # the `repo` scope so it can write the Actions variables and secrets on the
  # gh-portfolio-ops repository. `source scripts/portfolio-ops-env.sh` sets it
  # from `gh auth token` for convenience.
}
