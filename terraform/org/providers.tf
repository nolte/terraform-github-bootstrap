provider "github" {
  owner = var.organization
  # GITHUB_TOKEN must be exported with `admin:org` and `repo` scopes
  # for the operator running plan/apply.
}
