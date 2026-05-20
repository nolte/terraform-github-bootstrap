output "organization" {
  description = "GitHub organisation login this module manages."
  value       = var.organization
}

output "team_ids" {
  description = "Map of team slug to numeric team ID for downstream wiring."
  value       = { for k, t in github_team.managed : k => t.id }
}

output "ruleset_ids" {
  description = "Map of ruleset name to numeric ruleset ID."
  value       = { for k, r in github_organization_ruleset.managed : k => r.id }
}
