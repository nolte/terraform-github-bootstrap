# Copy to terraform.tfvars (git-ignored) and adjust before `task tf:apply`.
#
# `terraform.tfvars` is git-ignored. Keep secrets out of any committed file.

owner = "nolte"

repositories = {
  # Dogfood: the bootstrap repo manages itself. Adopt existing state with
  #   terraform import github_repository.managed[\"terraform-github-bootstrap\"] terraform-github-bootstrap
  # before the first apply, otherwise Terraform tries to create it.
  terraform-github-bootstrap = {
    description  = "Bootstrap the nolte GitHub org via Terraform: org settings, teams, branch protection rulesets."
    homepage_url = "https://github.com/nolte/terraform-github-bootstrap"
    visibility   = "public"
    has_issues   = true
    has_projects = false
    has_wiki     = false
    topics       = ["terraform", "github", "iac", "bootstrap", "nolte"]

    ruleset = {
      enforcement                     = "active"
      include_refs                    = ["refs/heads/develop", "refs/heads/main"]
      require_pull_request            = true
      required_approving_review_count = 0
      require_linear_history          = true
      block_force_pushes              = true
      block_deletions                 = true
    }
  }

  # Add further repos one at a time. Adopt each existing repo via
  # `terraform import github_repository.managed["<name>"] <name>` before apply.
  # Example skeleton:
  # claude-shared = {
  #   description  = "Shared Claude Code skills and agents …"
  #   visibility   = "public"
  #   topics       = ["claude-code", "skills", "agents"]
  #   ruleset = {
  #     enforcement          = "active"
  #     include_refs         = ["refs/heads/develop", "refs/heads/main"]
  #     require_pull_request = true
  #   }
  # }
}
