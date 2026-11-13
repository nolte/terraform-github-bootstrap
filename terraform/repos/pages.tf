# GitHub Pages per repository — an opt-in feature toggle.
#
# A repo gets Pages only when its tfvars entry sets `pages = { enabled = true }`.
#   - build_type = "workflow" (default): Pages source "GitHub Actions"; the
#     repo's own workflow deploys via actions/deploy-pages. No branch needed.
#   - build_type = "legacy": "Deploy from a branch". Terraform sets it only once
#     `branch` (default gh-pages) exists — the deploy workflow creates it as an
#     orphan branch, which Terraform cannot do. Until then the repo is skipped
#     and the `pages_branch_exists` check warns in every plan; the next apply
#     after the first push picks it up.
#
# Turning `enabled` off, or a legacy branch disappearing, removes the resource
# and thereby DISABLES Pages on GitHub — the plan shows it as a destroy.
#
# Adopt a repo that already has Pages before the first apply:
#   terraform -chdir=terraform/repos import 'github_repository_pages.managed["<name>"]' <name>
#
# Source of truth:
#   https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_pages

locals {
  pages_enabled = {
    for name, repo in var.repositories :
    name => repo.pages
    if try(repo.pages.enabled, false)
  }

  pages_legacy = {
    for name, pages in local.pages_enabled : name => pages if pages.build_type == "legacy"
  }
}

# Branch lookup for legacy repos only. `repository = each.key` on purpose: a
# reference to github_repository.managed would defer the read whenever that
# resource has pending changes, leaving the for_each keys below unknown. The
# repo must therefore already exist before legacy Pages is enabled — which it
# does by definition once its publishing branch has been pushed.
data "github_repository_branches" "pages" {
  for_each = local.pages_legacy

  repository = each.key
}

locals {
  pages_missing_branch = [
    for name, pages in local.pages_legacy : name
    if !contains(data.github_repository_branches.pages[name].branches[*].name, pages.branch)
  ]

  pages_ready = {
    for name, pages in local.pages_enabled : name => pages
    if !contains(local.pages_missing_branch, name)
  }
}

resource "github_repository_pages" "managed" {
  for_each = local.pages_ready

  repository = github_repository.managed[each.key].name
  build_type = each.value.build_type
  cname      = each.value.cname

  dynamic "source" {
    for_each = each.value.build_type == "legacy" ? [1] : []
    content {
      branch = each.value.branch
      path   = each.value.path
    }
  }
}

# Skipping a repo must never be silent.
check "pages_branch_exists" {
  assert {
    condition     = length(local.pages_missing_branch) == 0
    error_message = "GitHub Pages enabled but the publishing branch does not exist yet, so Pages is NOT configured for: ${join(", ", local.pages_missing_branch)}. Push the branch, then re-apply."
  }
}
