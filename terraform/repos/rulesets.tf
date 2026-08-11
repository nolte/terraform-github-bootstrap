# Per-repo repository rulesets (modern alternative to classic branch protection).
#
# Source of truth:
#   https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_ruleset

locals {
  rulesets = {
    for name, cfg in var.repositories :
    name => cfg.ruleset
    if cfg.ruleset != null
  }
}

resource "github_repository_ruleset" "default_protection" {
  for_each = local.rulesets

  repository  = github_repository.managed[each.key].name
  name        = "default-branch-protection"
  target      = each.value.target
  enforcement = each.value.enforcement

  # Bypass actors are NOT inheritable from anywhere else: a ruleset bypass set
  # through the GitHub UI shows up here as drift Terraform wants to delete, so
  # every bypass a repo genuinely needs has to be declared in tfvars. See the
  # `bypass_portfolio_app` note in variables.tf for when that is the case.
  dynamic "bypass_actors" {
    for_each = each.value.bypass_portfolio_app ? [1] : []
    content {
      actor_id   = var.portfolio_app_id
      actor_type = "Integration"
      # `always`, not `pull_request`: the App pushes directly to the protected
      # branch, it does not open a PR that a `pull_request` bypass would cover.
      # Scope caveat: `always` waives EVERY rule in this ruleset for the App —
      # force-pushes, deletions, required checks, signatures — not just the PR
      # requirement, and anything holding the App's installation token (e.g. a
      # workflow in a repo carrying PORTFOLIO_APP_PRIVATE_KEY) inherits that
      # waiver. Opt in per repo only where the release cascade needs it.
      bypass_mode = "always"
    }
  }

  conditions {
    ref_name {
      include = each.value.include_refs
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

  lifecycle {
    precondition {
      # `type = number` already rejects non-numeric input at variable decode
      # (with the variable's own name in the error). This guard closes the
      # remaining hole — the flag set while the variable stayed null (missing
      # tfvars entry / forgotten env export) — which would otherwise surface
      # as a raw provider error naming neither the repo nor the variable.
      condition     = !each.value.bypass_portfolio_app || var.portfolio_app_id != null
      error_message = "ruleset for '${each.key}' sets bypass_portfolio_app = true, so var.portfolio_app_id must be set (git-ignored terraform.tfvars, or `source scripts/portfolio-app-env.sh` to export TF_VAR_portfolio_app_id)."
    }
  }
}
