output "owner" {
  description = "GitHub account login this module manages."
  value       = var.owner
}

output "repository_full_names" {
  description = "Map of repo key to its <owner>/<name> identifier on github.com."
  value       = { for k, r in github_repository.managed : k => r.full_name }
}

output "ruleset_ids" {
  description = "Map of repo key to the numeric default-protection ruleset ID."
  value       = { for k, r in github_repository_ruleset.default_protection : k => r.ruleset_id }
}
