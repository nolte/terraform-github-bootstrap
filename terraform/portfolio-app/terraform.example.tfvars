# Most inputs default to sensible nolte values. The only thing you need
# to supply at apply time are the App credentials, and the recommended
# path for that is environment variables sourced from gopass:
#
#   export TF_VAR_app_id="$(gopass show -o github/apps/nolte-portfolio-bot/app-id)"
#   export TF_VAR_app_private_key="$(gopass show -o github/apps/nolte-portfolio-bot/private-key)"
#   task tf:plan:portfolio-app
#
# A local terraform.tfvars is only needed when you want to override a
# default value (e.g. expand consumer_repositories or flip Phase 2):

# consumer_repositories = [
#   "terraform-github-bootstrap",
#   "gh-plumbing",
#   "claude-shared",
#   "cookiecutter-gh-project",
# ]

# enable_branch_bypass = true
