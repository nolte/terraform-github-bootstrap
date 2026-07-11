output "repository" {
  description = "Repository that received the merge-queue variable and secret."
  value       = var.repository
}

output "project_number" {
  description = "Projects V2 board number the sync workflow reconciles."
  value       = var.project_number
}

output "variable_name" {
  description = "Name of the Actions variable that holds the board number."
  value       = github_actions_variable.project_number.variable_name
}

output "secret_name" {
  description = "Name of the Actions secret that holds the merge-queue PAT."
  value       = github_actions_secret.merge_queue_token.secret_name
}
