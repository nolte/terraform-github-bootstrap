# Copy to terraform.tfvars (git-ignored) and adjust before `task tf:apply`.
#
# `terraform.tfvars` is git-ignored. Keep secrets out of any committed file.

organization = "nolte"

teams = {
  # Example: a single maintainers team. Remove or extend as needed.
  # maintainers = {
  #   description = "Repository maintainers across the nolte org."
  #   privacy     = "closed"
  #   maintainers = ["nolte"]
  #   members     = []
  # }
}

rulesets = {
  # Example: enforce the gh-plumbing default protections for develop + master
  # across the listed repos.
  # default-branch-protection = {
  #   enforcement                     = "active"
  #   include_refs                    = ["refs/heads/develop", "refs/heads/main", "refs/heads/master"]
  #   include_repos                   = ["~ALL"]
  #   require_pull_request            = true
  #   required_approving_review_count = 0
  #   require_linear_history          = true
  #   block_force_pushes              = true
  #   block_deletions                 = true
  # }
}
