# Concern: the Docker Hub read credential for repositories whose CI pulls
# images.
#
# WHY IT IS HERE AND NOT IN A ROOT OF ITS OWN. `var.repositories` is the one
# place that says what is true about each repository, and "this repo's CI pulls
# from Docker Hub" is such a fact. A second root would have carried a second
# list of repository names beside this map, free to drift from it.
#
# WHY A CREDENTIAL AT ALL. An anonymous Docker Hub pull is rate-limited per
# source IP, and on GitHub-hosted runners that IP is shared with every other
# tenant of the pool — so the budget can be spent by strangers and the failure
# lands on whichever pull request is unlucky, as a red required check unrelated
# to its diff (nolte/kamerplanter#1311, measured `ratelimit-limit: 100;w=3600`).
# Authenticating changes the unit the quota is counted in, from a shared IP to
# the account's own.
#
# WHAT IS NOT HERE, because Terraform cannot do it:
#   - minting the token     -> Docker Hub UI only; no provider in this stack
#   - using it in CI        -> already done: gh-plumbing#417 (v2.1.0) taught
#                              reusable-pre-commit.yaml to take the pair, and
#                              every consumer already passes it
#
# FAIL-OPEN IS THE CONTRACT. A repository without `dockerhub_pull` has no
# variable, so the consuming workflow skips its login step; a fork pull request
# gets no secrets and its login fails under `continue-on-error`. Both end in
# anonymous pulls plus a warning naming the mode. Nothing here turns a rate
# limit into a dependency on a registry being reachable.

locals {
  # Repositories that opted in. Empty set => this whole concern is inert and
  # the credential variables may stay unset.
  dockerhub_repositories = toset([
    for name, repo in var.repositories : name if repo.dockerhub_pull
  ])
}

# The ACCOUNT NAME as an Actions *variable*, not a secret. It is not
# confidential — it appears in every image reference the account publishes —
# and the consuming workflow gates its login step on it in a job-level `if:`,
# where the `secrets` context is not readable.
resource "github_actions_variable" "dockerhub_username" {
  for_each = local.dockerhub_repositories

  # Through the resource, not the bare name, so the repository is created (or
  # adopted) before Terraform tries to write a variable onto it.
  repository    = github_repository.managed[each.value].name
  variable_name = "DOCKERHUB_USERNAME"
  value         = var.dockerhub_username

  lifecycle {
    precondition {
      condition     = var.dockerhub_username != null && var.dockerhub_username != ""
      error_message = "repository '${each.value}' sets dockerhub_pull = true, so var.dockerhub_username must be set (`source scripts/dockerhub-env.sh` to export TF_VAR_dockerhub_username)."
    }
  }
}

# The token as a secret. `value`, not `plaintext_value`: measured against the
# provider schema, `value` first appears in integrations/github 6.12.0 and the
# same release deprecates `plaintext_value` and `encrypted_value`. That is why
# versions.tf requires `~> 6.12`.
resource "github_actions_secret" "dockerhub_token" {
  for_each = local.dockerhub_repositories

  repository  = github_repository.managed[each.value].name
  secret_name = "DOCKERHUB_TOKEN"
  value       = var.dockerhub_token

  lifecycle {
    # Mirrors the `bypass_portfolio_app` / `portfolio_app_id` precondition in
    # rulesets.tf. A plan run without the credential loaded must FAIL here
    # rather than write an empty secret: a blank DOCKERHUB_TOKEN is worse than
    # no secret at all, because the login step would then run, fail, and fall
    # back on every single run while the configuration claims authentication.
    precondition {
      condition     = var.dockerhub_token != null && var.dockerhub_token != ""
      error_message = "repository '${each.value}' sets dockerhub_pull = true, so var.dockerhub_token must be set (`source scripts/dockerhub-env.sh` to export TF_VAR_dockerhub_token)."
    }
  }
}
