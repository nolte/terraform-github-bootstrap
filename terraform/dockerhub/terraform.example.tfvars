# Both credentials come from the environment, never from this file:
#
#   source scripts/dockerhub-env.sh   # reads gopass, exports TF_VAR_*
#   task tf:plan:dockerhub
#
# Manual equivalent:
#   export TF_VAR_dockerhub_username="$(gopass show -o internet/hub.docker.com/nolte/username)"
#   export TF_VAR_dockerhub_token="$(gopass show -o internet/hub.docker.com/nolte/ci-pull-token)"
#
# NEVER put dockerhub_token in a tfvars file. `terraform.tfvars` is git-ignored,
# but a token in a file is a token that outlives the shell that needed it.
#
# A local terraform.tfvars is only needed to override a default — in practice
# that means admitting another repository to the credential:

# consumer_repositories = [
#   "kamerplanter",
#   "some-other-repo-that-actually-pulls-from-docker-hub",
# ]
