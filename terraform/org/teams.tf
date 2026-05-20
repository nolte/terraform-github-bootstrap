# Teams managed by Terraform.
#
# Membership is *authoritative* per team: the operator declares the full
# member set here, and Terraform reconciles. Manual UI changes will be
# reverted on the next apply.
#
# Source of truth:
#   - https://registry.terraform.io/providers/integrations/github/latest/docs/resources/team
#   - https://registry.terraform.io/providers/integrations/github/latest/docs/resources/team_members

resource "github_team" "managed" {
  for_each = var.teams

  name        = each.key
  description = each.value.description
  privacy     = each.value.privacy

  # parent_team_id is resolved via the data source when set.
  parent_team_id = each.value.parent_team != null ? data.github_team.parents[each.value.parent_team].id : null

  lifecycle {
    create_before_destroy = false
  }
}

resource "github_team_members" "managed" {
  for_each = var.teams

  team_id = github_team.managed[each.key].id

  dynamic "members" {
    for_each = toset(each.value.members)
    content {
      username = members.value
      role     = "member"
    }
  }

  dynamic "members" {
    for_each = toset(each.value.maintainers)
    content {
      username = members.value
      role     = "maintainer"
    }
  }
}

# Resolve parent-team IDs by slug.
data "github_team" "parents" {
  for_each = toset([
    for cfg in values(var.teams) : cfg.parent_team if cfg.parent_team != null
  ])

  slug = each.key
}
