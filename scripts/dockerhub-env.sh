#!/usr/bin/env bash
# Source this file before `task tf:plan` / `task tf:apply`.
#
# Usage:
#   source scripts/dockerhub-env.sh
#   task tf:plan
#
# Docker Hub credentials come from ONE of two sources, per value:
#   1. the environment: DOCKERHUB_USERNAME / DOCKERHUB_TOKEN (wins if set)
#   2. gopass: internet/hub.docker.com/{username,token/github-read-only}
#      (override via DOCKERHUB_USERNAME_GOPASS_PATH / DOCKERHUB_TOKEN_GOPASS_PATH)
#
# Prerequisite (one-time, UI-only): mint a Docker Hub access token
# (Account settings -> Personal access tokens, "Public Repo Read-only" suffices),
# then either export DOCKERHUB_TOKEN or store it:
#   gopass insert internet/hub.docker.com/token/github-read-only
#   gopass insert internet/hub.docker.com/username
#
# Meant to be *sourced*: no `set -e`, failures use `return 1 || exit 1`.

GOPASS_USERNAME_PATH="${DOCKERHUB_USERNAME_GOPASS_PATH:-internet/hub.docker.com/username}"
GOPASS_TOKEN_PATH="${DOCKERHUB_TOKEN_GOPASS_PATH:-internet/hub.docker.com/token/github-read-only}"

# _dockerhub_resolve <env value> <gopass path> -> prints the value, empty on failure
_dockerhub_resolve() {
  if [ -n "$1" ]; then
    printf '%s' "$1"
  elif command -v gopass >/dev/null 2>&1; then
    gopass show -o "$2" 2>/dev/null
  fi
}

if ! TF_VAR_dockerhub_username="$(_dockerhub_resolve "${DOCKERHUB_USERNAME:-}" "${GOPASS_USERNAME_PATH}")" \
  || [ -z "${TF_VAR_dockerhub_username}" ]; then
  echo "error: Docker Hub username missing — export DOCKERHUB_USERNAME or 'gopass insert ${GOPASS_USERNAME_PATH}'" >&2
  unset -f _dockerhub_resolve
  return 1 2>/dev/null || exit 1
fi

if ! TF_VAR_dockerhub_token="$(_dockerhub_resolve "${DOCKERHUB_TOKEN:-}" "${GOPASS_TOKEN_PATH}")" \
  || [ -z "${TF_VAR_dockerhub_token}" ]; then
  echo "error: Docker Hub token missing — export DOCKERHUB_TOKEN or 'gopass insert ${GOPASS_TOKEN_PATH}'" >&2
  unset -f _dockerhub_resolve
  return 1 2>/dev/null || exit 1
fi
unset -f _dockerhub_resolve

if ! GITHUB_TOKEN="$(gh auth token)" || [ -z "${GITHUB_TOKEN}" ]; then
  echo "error: could not read a GitHub token from 'gh auth token' — run 'gh auth login'" >&2
  return 1 2>/dev/null || exit 1
fi

export TF_VAR_dockerhub_username TF_VAR_dockerhub_token GITHUB_TOKEN

echo "dockerhub env loaded:"
echo "  TF_VAR_dockerhub_username = ${TF_VAR_dockerhub_username}"
echo "  TF_VAR_dockerhub_token    = (${#TF_VAR_dockerhub_token} chars, sensitive)"
