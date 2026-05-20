output "mode" {
  description = "Owner mode the gh-plumbing portfolio-app module ran in (`organization` or `user`)."
  value       = module.portfolio_app.mode
}

output "owner" {
  description = "Owner string the module resolved at plan time."
  value       = module.portfolio_app.owner
}

output "configured_repositories" {
  description = "Repository names now seeing PORTFOLIO_APP_ID and PORTFOLIO_APP_PRIVATE_KEY."
  value       = module.portfolio_app.configured_repositories
}

output "variable_name" {
  description = "Name of the Actions variable that holds the App ID."
  value       = module.portfolio_app.variable_name
}

output "secret_name" {
  description = "Name of the Actions secret that holds the App private key."
  value       = module.portfolio_app.secret_name
}

output "branch_bypass_enabled" {
  description = "Whether Phase 2 branch-protection bypass is active."
  value       = module.portfolio_app.branch_bypass_enabled
}

output "branch_bypass_pairs" {
  description = "`repo::branch` pairs that received the bypass entry. Empty in Phase 0."
  value       = module.portfolio_app.branch_bypass_pairs
}
