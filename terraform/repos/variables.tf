variable "owner" {
  description = "GitHub account login (user) this module manages."
  type        = string
  default     = "nolte"
}

variable "repositories" {
  description = <<-EOT
    Repositories managed by Terraform. Each entry produces a github_repository
    plus a default github_repository_ruleset (when `ruleset` is non-null).

    Per-repo settings (labels, merge strategies, branch protections, …) remain
    owned by nolte/gh-plumbing via the Probot Settings App's `_extends`. The
    keys exposed here intentionally stay slim and only cover what the GitHub
    Terraform provider does better than Probot — repository inventory itself
    plus modern repository rulesets.
  EOT

  type = map(object({
    description   = optional(string)
    homepage_url  = optional(string)
    visibility    = optional(string, "public") # public | private
    is_template   = optional(bool, false)
    archived      = optional(bool, false)
    has_issues    = optional(bool, true)
    has_projects  = optional(bool, true)
    has_wiki      = optional(bool, false)
    has_downloads = optional(bool, false)
    topics        = optional(list(string), [])
    auto_init     = optional(bool, false)

    # Default branch — the Probot Settings App also writes this; Terraform
    # only sets it when explicitly given here, otherwise the field is left
    # to the existing repo state.
    default_branch = optional(string)

    # Per-repo ruleset. Set to null to opt out (e.g. for archived repos).
    ruleset = optional(object({
      enforcement                     = optional(string, "active") # active | evaluate | disabled
      target                          = optional(string, "branch") # branch | tag | push
      include_refs                    = optional(list(string), ["refs/heads/develop", "refs/heads/main", "refs/heads/master"])
      require_pull_request            = optional(bool, true)
      required_approving_review_count = optional(number, 0)
      require_status_checks_to_pass   = optional(bool, false)
      required_status_checks          = optional(list(string), [])
      require_linear_history          = optional(bool, true)
      require_signed_commits          = optional(bool, false)
      block_force_pushes              = optional(bool, true)
      block_deletions                 = optional(bool, true)
    }))
  }))

  default = {}
}
