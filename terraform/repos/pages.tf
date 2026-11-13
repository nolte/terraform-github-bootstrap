# GitHub Pages per repository — an opt-in feature toggle.
#
# A repo gets Pages only when its tfvars entry sets `pages = { enabled = true }`.
#   - build_type = "workflow" (default): Pages source "GitHub Actions"; the
#     repo's own workflow deploys via actions/deploy-pages. No branch needed.
#   - build_type = "legacy": "Deploy from a branch". The branch guard below only
#     gates the FIRST creation: Terraform sets Pages once `branch` (default
#     gh-pages) exists — the deploy workflow creates it as an orphan branch,
#     which Terraform cannot do. Until then the repo is skipped and the
#     `pages_branch_exists` check warns in every plan.
#
# Once Pages is live on GitHub it stays managed even if the branch is briefly
# missing (e.g. a deploy force-recreating it), so a transient branch gap never
# plans a destroy. Only turning `enabled` off (or removing the block) destroys
# the resource and thereby DISABLES Pages on GitHub.
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

# Both lookups use `each.key`, not a reference to github_repository.managed: such
# a reference would defer the read whenever that resource has pending changes,
# leaving the for_each keys of github_repository_pages unknown. Both data sources
# tolerate a missing repo or branch (empty result, no error), so a repo that does
# not exist yet is simply skipped with the check warning — the plan never aborts.

# One call per legacy repo: null `id` when the branch (or the repo) is missing.
data "github_branch" "pages" {
  for_each = local.pages_legacy

  repository = each.key
  branch     = each.value.branch
}

# Is Pages already live? Uses the provider's deprecated `pages` attribute (plan
# prints a deprecation warning) because the `github_repository_pages` data
# source errors on a repo without Pages instead of returning empty.
data "github_repository" "pages" {
  for_each = local.pages_legacy

  name = each.key
}

locals {
  # workflow: always. legacy: branch exists, or Pages is already live.
  pages_ready = {
    for name, pages in local.pages_enabled : name => pages
    if pages.build_type != "legacy" ||
    try(length(data.github_branch.pages[name].id) > 0, false) ||
    try(length(data.github_repository.pages[name].pages) > 0, false)
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
    condition     = length(setsubtract(keys(local.pages_enabled), keys(local.pages_ready))) == 0
    error_message = "GitHub Pages enabled but the publishing branch does not exist yet, so Pages is NOT configured for: ${join(", ", setsubtract(keys(local.pages_enabled), keys(local.pages_ready)))}. Push the branch, then re-apply."
  }
}
