# Organisation-wide repository rulesets.
#
# Each ruleset targets a set of refs (branches or tags) across an explicit
# repository list and codifies the protection policy declared per repo in
# `nolte/gh-plumbing:.github/commons-settings.yml` (`develop` and `master`).
#
# Source of truth:
#   https://registry.terraform.io/providers/integrations/github/latest/docs/resources/organization_ruleset

resource "github_organization_ruleset" "managed" {
  for_each = var.rulesets

  name        = each.key
  target      = each.value.target
  enforcement = each.value.enforcement

  conditions {
    ref_name {
      include = each.value.include_refs
      exclude = []
    }
    repository_name {
      include = each.value.include_repos
      exclude = []
    }
  }

  rules {
    deletion                = each.value.block_deletions
    non_fast_forward        = each.value.block_force_pushes
    required_linear_history = each.value.require_linear_history
    required_signatures     = each.value.require_signed_commits

    dynamic "pull_request" {
      for_each = each.value.require_pull_request ? [1] : []
      content {
        required_approving_review_count   = each.value.required_approving_review_count
        dismiss_stale_reviews_on_push     = true
        require_code_owner_review         = false
        require_last_push_approval        = false
        required_review_thread_resolution = true
      }
    }

    dynamic "required_status_checks" {
      for_each = each.value.require_status_checks_to_pass ? [1] : []
      content {
        strict_required_status_checks_policy = true
        dynamic "required_check" {
          for_each = toset(each.value.required_status_checks)
          content {
            context = required_check.value
          }
        }
      }
    }
  }
}
