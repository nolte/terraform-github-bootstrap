# Provision the per-repository PORTFOLIO_APP_ID variable and
# PORTFOLIO_APP_PRIVATE_KEY secret on every consumer repository,
# using the shared module from nolte/gh-plumbing.
#
# The module is pinned to `?ref=develop` because the module itself
# only landed after the v1.1.18 release tag. Repin to the next tagged
# release once it ships (search for the ref string below).
# Conscious develop-pin until the first tagged gh-plumbing release that ships
# the portfolio-app module (v1.1.18 does not). Repin to that release tag.
# tflint-ignore: terraform_module_pinned_source
module "portfolio_app" {
  source = "github.com/nolte/gh-plumbing//terraform/portfolio-app?ref=develop"

  # User mode — `nolte` is a personal user account, not an org.
  user = var.owner

  app_id          = var.app_id
  app_slug        = var.app_slug
  app_private_key = var.app_private_key

  consumer_repositories = var.consumer_repositories

  # Phase 0: variable + secret only. Flip to Phase 2 once every
  # consumer repo has the App installed and the security review is done.
  enable_branch_bypass = var.enable_branch_bypass
}
