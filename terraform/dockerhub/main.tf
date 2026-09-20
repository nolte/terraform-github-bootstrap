# Provision the per-repository DOCKERHUB_USERNAME variable and DOCKERHUB_TOKEN
# secret on every repository whose CI pulls images from Docker Hub, using the
# shared module from nolte/gh-plumbing.
#
# WHY THIS ROOT EXISTS. An anonymous Docker Hub pull is rate-limited per source
# IP, and on GitHub-hosted runners that IP is shared with every other tenant of
# the pool — so the budget can be spent by strangers and the failure lands on
# whichever pull request is unlucky, as a red required check unrelated to its
# diff. nolte/kamerplanter#1311 diagnosed that, #1321 parked the prevention
# half on exactly one missing piece: "the credential is a repository variable +
# secret the operator supplies". This is the operator supplying it.
#
# The consuming side has been ready since gh-plumbing#417 (v2.1.0):
# `reusable-pre-commit.yaml` takes the pair, skips the login when the variable
# is empty, and treats a failed login as "pull anonymously". Nothing in any
# workflow needs to change when this root is applied.
#
# The module is pinned to `?ref=develop` because it landed after gh-plumbing's
# newest release tag. Repin to the first tagged release that carries
# `terraform/dockerhub-pull` (search for the ref string below); the
# corresponding tflint rule is disabled in `.tflint.hcl` until then, exactly as
# in the portfolio-app root.
module "dockerhub_pull" {
  source = "github.com/nolte/gh-plumbing//terraform/dockerhub-pull?ref=develop"

  # User mode — `nolte` is a personal user account, not an org.
  user = var.owner

  dockerhub_username = var.dockerhub_username
  dockerhub_token    = var.dockerhub_token

  consumer_repositories = var.consumer_repositories
}
