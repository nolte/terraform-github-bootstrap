# Secrets are read from gopass at apply time — the recommended path is
#   source scripts/portfolio-ops-env.sh
# which exports the TF_VAR_* secrets and GITHUB_TOKEN (from `gh auth token`).
#
# --- Concern: PR merge-queue board ---
# The merge-queue PAT must be minted in the GitHub UI (Settings -> Developer
# settings -> Personal access tokens) with the `repo` + `project` scopes, then:
#   gopass insert internet/github.com/nolte/tokens/gh-portfolio-ops/merge-queue-pat
#
# project_number is NOT a secret but is only known once the board exists.
# Set it here (a local terraform.tfvars is git-ignored):

# project_number = 7

# Override only if the repo name differs from the default:
# repository = "gh-portfolio-ops"
