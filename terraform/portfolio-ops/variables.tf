variable "owner" {
  description = "GitHub user account that owns the gh-portfolio-ops repository (user mode)."
  type        = string
  default     = "nolte"
}

variable "repository" {
  description = "Repository that hosts the portfolio-ops automations (merge-queue sync and future jobs). Receives the per-concern Actions variables and secrets. Must already exist (created by the board bootstrap, then adopted into terraform/repos)."
  type        = string
  default     = "gh-portfolio-ops"
}

# --- Concern: PR merge-queue board ---

variable "project_number" {
  description = "Number of the Projects V2 board the merge-queue sync workflow reconciles (the trailing path segment of https://github.com/users/nolte/projects/<N>). Known only after the board is created — supply via terraform.tfvars."
  type        = number
}

variable "merge_queue_token" {
  description = "Classic PAT with `repo` + `project` scopes used by the merge-queue sync workflow to manage the user-level board and label PRs across nolte/*. Set via TF_VAR_merge_queue_token (typically `gopass show -o internet/github.com/nolte/tokens/gh-portfolio-ops/merge-queue-pat`). The PAT itself can only be minted in the GitHub UI. Marked sensitive."
  type        = string
  sensitive   = true
}
