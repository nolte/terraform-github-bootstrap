plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

# `terraform_module_pinned_source` is intentionally disabled in this module
# only. `main.tf` pins the upstream gh-plumbing module to `?ref=develop`
# because the portfolio-app module landed after gh-plumbing's `v1.1.18`
# release tag and no later tag carries the module yet. The pin is documented
# at the source line and the comment names the re-pin trigger. Re-enable
# this rule (delete this file) once we repin to a tagged gh-plumbing release.
#
# The file lives next to the module — not at the repo root — because the
# pre-commit-terraform `terraform_tflint` hook invokes tflint per
# terraform-module directory and only reads a `.tflint.hcl` from that cwd.
rule "terraform_module_pinned_source" {
  enabled = false
}
