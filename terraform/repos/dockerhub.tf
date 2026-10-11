# Docker Hub pull credentials for CI.
#
# Anonymous pulls are rate limited per runner IP; authenticated pulls use the
# account's quota. Repos opting in via `dockerhub_pull_credentials = true` get
#   - DOCKERHUB_USERNAME (Actions variable) — not a secret
#   - DOCKERHUB_TOKEN    (Actions secret)
# in the same apply that configures the repository. Minting the access token is
# UI-only (Docker Hub -> Account settings -> Personal access tokens; "Public
# Repo Read-only" suffices). Load credentials with `source scripts/dockerhub-env.sh`.
locals {
  dockerhub_repositories = toset([
    for name, repo in var.repositories : name if repo.dockerhub_pull_credentials
  ])
}

resource "github_actions_variable" "dockerhub_username" {
  for_each = local.dockerhub_repositories

  repository    = github_repository.managed[each.key].name
  variable_name = "DOCKERHUB_USERNAME"
  value         = var.dockerhub_username

  lifecycle {
    precondition {
      condition     = var.dockerhub_username != null && var.dockerhub_username != ""
      error_message = "dockerhub_username is required when a repository sets dockerhub_pull_credentials = true (run: source scripts/dockerhub-env.sh)."
    }
  }
}

resource "github_actions_secret" "dockerhub_token" {
  for_each = local.dockerhub_repositories

  repository  = github_repository.managed[each.key].name
  secret_name = "DOCKERHUB_TOKEN"
  value       = var.dockerhub_token

  lifecycle {
    precondition {
      condition     = var.dockerhub_token != null && var.dockerhub_token != ""
      error_message = "dockerhub_token is required when a repository sets dockerhub_pull_credentials = true (run: source scripts/dockerhub-env.sh)."
    }
  }
}
