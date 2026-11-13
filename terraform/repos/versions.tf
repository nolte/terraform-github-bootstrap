terraform {
  required_version = ">= 1.9.0"

  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.12" # github_repository_pages landed in 6.12.0
    }
  }
}
