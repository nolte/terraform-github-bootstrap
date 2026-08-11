# Copy to terraform.tfvars (git-ignored) and adjust before `task tf:apply`.
#
# `terraform.tfvars` is git-ignored. Keep secrets out of any committed file.

owner = "nolte"

# Numeric ID of the portfolio GitHub App (a non-secret identifier — the App's
# private key is the secret and never leaves gopass). Only needed when a
# ruleset below sets `bypass_portfolio_app = true`. Keep it out of committed
# files: put it in the git-ignored `terraform.tfvars`, or export it per
# session via the shared env loader (honours PORTFOLIO_APP_GOPASS_PATH):
#   source scripts/portfolio-app-env.sh   # exports TF_VAR_portfolio_app_id
# portfolio_app_id = 123456

repositories = {
  # Dogfood: the bootstrap repo manages itself. Adopt existing state with
  #   terraform import github_repository.managed[\"terraform-github-bootstrap\"] terraform-github-bootstrap
  # before the first apply, otherwise Terraform tries to create it.
  terraform-github-bootstrap = {
    description  = "Bootstrap the nolte GitHub org via Terraform: org settings, teams, branch protection rulesets."
    visibility   = "public"
    has_issues   = true
    has_projects = false
    has_wiki     = false

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

  # gh-plumbing — example of enforcing required status checks via the ruleset
  # instead of giving the Probot Settings App `administration: write`. Adopt
  # existing state before the first apply:
  #   terraform import github_repository.managed[\"gh-plumbing\"] gh-plumbing
  # Notes: only `develop` is included (master is refreshed by an App-token
  # cascade and this ruleset has no bypass_actors), and require_pull_request
  # is false so the release-automation App-token direct push to develop is
  # not blocked — the ruleset only adds the required checks.
  gh-plumbing = {
    description = "Github Project plumbing"
    visibility  = "public"

    ruleset = {
      enforcement                   = "active"
      include_refs                  = ["refs/heads/develop"]
      require_pull_request          = false
      require_status_checks_to_pass = true
      # Each context MUST equal the check-run name GitHub actually reports, or the
      # ruleset shows it forever as "Expected — Waiting for status to be reported"
      # and BLOCKS every PR:
      #   - Reusable-workflow checks report as `caller-job / job`  -> keep the
      #     prefix, e.g. "static / Static CI Tests", "docs / MkDocs Build".
      #   - DIRECT-job checks report the BARE job name (no `workflow /` prefix),
      #     e.g. "Static CI Tests" or "lint". Using the prefixed form for a
      #     direct-job repo never matches.
      # Verify with: gh api repos/<owner>/<repo>/commits/<sha>/check-runs --jq '.check_runs[].name'
      required_status_checks = ["static / Static CI Tests", "docs / MkDocs Build"]
      require_linear_history = false
      block_force_pushes     = true
      block_deletions        = true
      # Not needed here: this ruleset never blocks the portfolio App, because it
      # protects `develop` only and keeps require_pull_request = false. Set
      # `bypass_portfolio_app = true` (and `portfolio_app_id` above) instead when
      # a ruleset DOES stand in the App's way — e.g. it protects the branch that
      # reusable-release-cd-refresh-master merges the tag into, or it requires a
      # PR on the branch release-publish pushes the `chore(release)` commit to.
      # A ruleset cannot inherit a bypass: one set through the GitHub UI reads as
      # drift and gets deleted on the next apply.
      # bypass_portfolio_app = true
    }
  }

  # Add further repos one at a time. Adopt each existing repo via
  # `terraform import github_repository.managed["<name>"] <name>` before apply.
}
