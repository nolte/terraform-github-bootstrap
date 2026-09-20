variable "owner" {
  description = "GitHub user account that owns the consumer repositories. Passed through to the gh-plumbing dockerhub-pull module as `user` (user mode)."
  type        = string
  default     = "nolte"
}

variable "dockerhub_username" {
  description = "Docker Hub account name the pull token belongs to. Set via TF_VAR_dockerhub_username — `source scripts/dockerhub-env.sh` reads it from gopass. Not secret: it appears in every image reference the account publishes, and the consuming workflows need it in a job-level `if:`, where the secrets context is not readable."
  type        = string
}

variable "dockerhub_token" {
  description = "Docker Hub personal access token scoped `Public Repo Read-only`. Set via TF_VAR_dockerhub_token — `source scripts/dockerhub-env.sh` reads it from gopass. Never place this in tfvars. Marked sensitive."
  type        = string
  sensitive   = true
}

variable "consumer_repositories" {
  description = "Repositories on the nolte account whose CI pulls images from Docker Hub. Each receives a repo-scoped DOCKERHUB_USERNAME variable and a DOCKERHUB_TOKEN secret. A repository joins this list when it demonstrably pulls — not pre-emptively: every extra copy of a credential is an extra place it can leak from, and a repository without the pair keeps pulling anonymously, which is degraded rather than broken."
  type        = list(string)
  default = [
    # Measured 2026-09-20. kamerplanter is the only repository on this account
    # that pulls from Docker Hub during CI: its `.pre-commit-config.yaml`
    # carries the two `language: docker_image` hooks (actionlint, shellcheck)
    # whose pulls #1321 is about, and its image builds and E2E stack read
    # `node`, `postgres`, `python`, `nginxinc/nginx-unprivileged` and
    # `busybox` from Docker Hub as well.
    #
    # Checked and deliberately absent: `gh-plumbing`, `claude-shared` and this
    # repository have no docker-based pre-commit hooks and no Docker Hub pulls
    # in their workflows, so the pair would sit there unused.
    "kamerplanter",
  ]
}
