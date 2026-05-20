variable "organization" {
  description = "GitHub organisation login this module manages."
  type        = string
  default     = "nolte"
}

variable "teams" {
  description = <<-EOT
    Teams managed by Terraform. Each entry creates a github_team and an associated
    github_team_membership set. Privacy is `closed` by default (visible inside the org).
  EOT
  type = map(object({
    description = string
    privacy     = optional(string, "closed")
    parent_team = optional(string)
    members     = optional(list(string), [])
    maintainers = optional(list(string), [])
  }))
  default = {}
}

variable "rulesets" {
  description = <<-EOT
    Organisation-wide repository rulesets. Each entry produces one github_organization_ruleset
    targeting the named refs and applied to the listed repositories (by name).
  EOT
  type = map(object({
    enforcement                     = optional(string, "active") # active | evaluate | disabled
    target                          = optional(string, "branch") # branch | tag | push
    include_refs                    = optional(list(string), ["refs/heads/develop", "refs/heads/main"])
    include_repos                   = optional(list(string), [])
    require_pull_request            = optional(bool, true)
    required_approving_review_count = optional(number, 0)
    require_status_checks_to_pass   = optional(bool, false)
    required_status_checks          = optional(list(string), [])
    require_linear_history          = optional(bool, true)
    require_signed_commits          = optional(bool, false)
    block_force_pushes              = optional(bool, true)
    block_deletions                 = optional(bool, true)
  }))
  default = {}
}
