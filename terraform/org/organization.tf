# Organisation-level settings.
#
# Note: github_organization_settings manages the *settings* of an existing
# organisation. Creating an organisation itself is a manual operation and is
# explicitly out of scope for this bootstrap.
#
# Source of truth: https://registry.terraform.io/providers/integrations/github/latest/docs/resources/organization_settings
resource "github_organization_settings" "this" {
  billing_email = "nolte07@gmail.com"

  # Member privileges
  members_can_create_repositories          = false
  members_can_create_public_repositories   = false
  members_can_create_private_repositories  = false
  members_can_create_internal_repositories = false
  members_can_fork_private_repositories    = false

  # Default repository permission for members across the org.
  default_repository_permission = "read"

  # Project boards / wikis at org level.
  has_organization_projects = true
  has_repository_projects   = true

  # Issue / PR hygiene defaults.
  members_can_create_pages = false

  # Two-factor enforcement is set on the *organisation* via the
  # `advanced_security_enabled_for_new_repositories` toggle line of resources;
  # for personal-tier orgs, 2FA enforcement is enabled via the org UI and
  # captured here as a comment-only invariant for the operator to verify.
  # NOTE: confirm in https://github.com/organizations/nolte/settings/security
  #       that "Require two-factor authentication" is enabled.
}
