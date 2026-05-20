plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

# `terraform_module_pinned_source` is intentionally disabled.
#
# `terraform/portfolio-app/main.tf` pins the upstream gh-plumbing module to
# `?ref=develop` because the portfolio-app module landed after gh-plumbing's
# `v1.1.18` release tag and no later tag carries the module yet. The pin is
# documented at the source line and the comment names the re-pin trigger.
# Re-enable this rule once we repin to a tagged gh-plumbing release.
rule "terraform_module_pinned_source" {
  enabled = false
}
