output "mode" {
  description = "Owner mode the gh-plumbing dockerhub-pull module ran in (`organization` or `user`)."
  value       = module.dockerhub_pull.mode
}

output "owner" {
  description = "Owner string the module resolved at plan time."
  value       = module.dockerhub_pull.owner
}

output "configured_repositories" {
  description = "Repository names now carrying DOCKERHUB_USERNAME and DOCKERHUB_TOKEN. A repository missing here still pulls anonymously."
  value       = module.dockerhub_pull.configured_repositories
}

output "variable_name" {
  description = "Name of the Actions variable that holds the Docker Hub account name."
  value       = module.dockerhub_pull.variable_name
}

output "secret_name" {
  description = "Name of the Actions secret that holds the Docker Hub pull token."
  value       = module.dockerhub_pull.secret_name
}
