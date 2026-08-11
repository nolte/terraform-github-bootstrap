variable "owner" {
  description = "GitHub account login (user) this module manages."
  type        = string
  default     = "nolte"
}

variable "portfolio_app_id" {
  description = <<-EOT
    Numeric ID of the portfolio GitHub App, used as the `Integration` bypass
    actor for every ruleset that sets `bypass_portfolio_app = true`.

    Required only when at least one ruleset opts into the bypass — otherwise
    leave it null. The App ID is a non-secret identifier (unlike the App's
    private key, which never leaves gopass), but keep it out of committed
    files anyway: put it in the git-ignored `terraform.tfvars`, or source it
    per session from gopass via the shared env loader, which exports it
    alongside the portfolio-app credentials:

      source scripts/portfolio-app-env.sh   # exports TF_VAR_portfolio_app_id
  EOT

  type    = number
  default = null
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
    # NOTE: `homepage_url` and `topics` are deliberately absent — `.github/settings.yml`
    # (Probot Settings) is the leading system for those. The github_repository
    # resource ignore_changes them so Terraform never reconciles them.
    description  = optional(string)
    visibility   = optional(string, "public") # public | private
    is_template  = optional(bool, false)
    archived     = optional(bool, false)
    has_issues   = optional(bool, true)
    has_projects = optional(bool, true)
    has_wiki     = optional(bool, false)
    auto_init    = optional(bool, false)

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

      # Grant the portfolio GitHub App an `always` bypass on this ruleset.
      #
      # Required for every repo whose release automation pushes the
      # `chore(release): <tag>` commit straight to a PROTECTED branch with the
      # App token, or cascades the release tag into master/main
      # (reusable-release-publish + reusable-release-cd-refresh-master). Without
      # the bypass, a ruleset that carries `require_pull_request = true` or
      # required status checks on that branch blocks the App push and the release
      # fails. The alternative shape — protect `develop` only and keep
      # `require_pull_request = false` (gh-plumbing, kamerplanter) — needs no
      # bypass because the ruleset never stands in the App's way.
      #
      # The App ID itself comes from `var.portfolio_app_id`, never from here.
      bypass_portfolio_app = optional(bool, false)
    }))
  }))

  default = {}
}
