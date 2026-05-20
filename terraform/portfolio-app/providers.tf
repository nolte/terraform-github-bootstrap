provider "github" {
  owner = var.owner
  # GITHUB_TOKEN must be a personal access token of `nolte` (user mode) with
  # the `repo` scope. `admin:org` is NOT required because we operate in
  # user mode: the gh-plumbing portfolio-app module then provisions
  # repository-level Actions variables and secrets per consumer repo.
}
