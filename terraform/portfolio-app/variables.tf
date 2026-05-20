variable "owner" {
  description = "GitHub user account that owns the consumer repositories. Passed through to the gh-plumbing portfolio-app module as `user` (user mode)."
  type        = string
  default     = "nolte"
}

variable "app_id" {
  description = "Numeric ID of the portfolio GitHub App. Set via TF_VAR_app_id (typically `gopass show -o github/apps/<slug>/app-id`)."
  type        = string
}

variable "app_slug" {
  description = "Slug of the portfolio GitHub App (the path segment after `/apps/`)."
  type        = string
  default     = "nolte-portfolio-bot"
}

variable "app_private_key" {
  description = "PEM-encoded private key for the portfolio GitHub App. Set via TF_VAR_app_private_key (typically `gopass show -o github/apps/<slug>/private-key`). Marked sensitive."
  type        = string
  sensitive   = true
}

variable "consumer_repositories" {
  description = "Repositories on the nolte account that consume the portfolio App. Each entry receives a repo-scoped PORTFOLIO_APP_ID variable and a PORTFOLIO_APP_PRIVATE_KEY secret."
  type        = list(string)
  default = [
    "terraform-github-bootstrap",
    "gh-plumbing",
    "claude-shared",
  ]
}

variable "enable_branch_bypass" {
  description = "Phase 2 toggle. Flip to `true` only after the App lives in every consumer repository and a cross-repo security review is done."
  type        = bool
  default     = false
}
