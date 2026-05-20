# Most inputs default to sensible nolte values. The only thing you need
# to supply at apply time are the App credentials, and the recommended
# path for that is `source scripts/portfolio-app-env.sh` (reads from gopass
# under `internet/github.com/nolte/apps/<app>/{appid,slug,private_key}`).
#
# Manual equivalent:
#   export TF_VAR_app_id="$(gopass show -o internet/github.com/nolte/apps/nolte-portfolio-app/appid)"
#   export TF_VAR_app_slug="$(gopass show -o internet/github.com/nolte/apps/nolte-portfolio-app/slug)"
#   export TF_VAR_app_private_key="$(gopass show -o internet/github.com/nolte/apps/nolte-portfolio-app/private_key)"
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
