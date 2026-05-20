provider "github" {
  owner = var.owner
  # GITHUB_TOKEN must be a personal access token of the account named in
  # var.owner with the `repo` and `delete_repo` scopes for the resources
  # this module manages.
}
