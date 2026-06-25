# Repositories managed by Terraform.
#
# Adopt an existing repo with:
#   terraform -chdir=terraform/repos import github_repository.managed[\"<name>\"] <name>
#
# Source of truth:
#   https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository

resource "github_repository" "managed" {
  for_each = var.repositories

  name        = each.key
  description = each.value.description

  visibility  = each.value.visibility
  is_template = each.value.is_template
  archived    = each.value.archived

  has_issues   = each.value.has_issues
  has_projects = each.value.has_projects
  has_wiki     = each.value.has_wiki

  auto_init = each.value.auto_init

  # Per-repo settings (merge strategies, labels, branch lists, homepage URL,
  # topics) remain owned by Probot Settings via
  # `_extends: nolte/gh-plumbing:.github/commons-settings.yml` and each repo's
  # `.github/settings.yml`. We deliberately do NOT let Terraform reconcile
  # allow_*_merge, delete_branch_on_merge, labels, homepage_url, or topics so
  # the two systems do not fight over the same fields.

  lifecycle {
    ignore_changes = [
      # Probot Settings owns these; ignore drift caused by Probot syncs.
      allow_squash_merge,
      allow_merge_commit,
      allow_rebase_merge,
      delete_branch_on_merge,
      allow_auto_merge,
      squash_merge_commit_title,
      squash_merge_commit_message,
      # `.github/settings.yml` (Probot) is the leading system for these.
      homepage_url,
      topics,
    ]
  }
}
