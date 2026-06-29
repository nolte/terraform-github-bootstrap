# Concern: PR merge-queue board.
#
# Wire the merge-queue sync workflow's two inputs onto the gh-portfolio-ops repo:
#   - PROJECT_NUMBER  (Actions variable) — which board to reconcile
#   - MERGE_QUEUE_TOKEN (Actions secret) — PAT with repo + project scopes
#
# What is intentionally NOT here, because it cannot be Terraform-managed:
#   - Minting the PAT            -> GitHub UI only (value lands in gopass)
#   - The Projects V2 board      -> the integrations/github provider has no
#                                   resource for Projects V2 (user boards)
#   - The board's "grouped by Status" kanban view -> UI only
#   - The `automerge` label on target repos -> owned by gh-plumbing's Probot
#                                   settings.yml; never duplicated here
#
# Future portfolio-ops concerns get their own <concern>.tf file beside this one.
resource "github_actions_variable" "project_number" {
  repository    = var.repository
  variable_name = "PROJECT_NUMBER"
  value         = tostring(var.project_number)
}

resource "github_actions_secret" "merge_queue_token" {
  repository      = var.repository
  secret_name     = "MERGE_QUEUE_TOKEN"
  plaintext_value = var.merge_queue_token
}
