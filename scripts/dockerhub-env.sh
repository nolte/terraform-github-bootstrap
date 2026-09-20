#!/usr/bin/env bash
# Source this file before `task tf:plan:dockerhub` / `tf:apply:dockerhub`.
#
# Usage:
#   source scripts/dockerhub-env.sh
#   task tf:plan:dockerhub
#
# Reads the Docker Hub pull credential from gopass and exports it as TF_VAR_*
# so Terraform picks it up without it ever reaching a file in this checkout.
# GITHUB_TOKEN is read from `gh auth token` for convenience.
#
# Prerequisites (one-time, both manual — Terraform cannot mint a Docker Hub
# token and this portfolio has no Docker Hub provider):
#   1. Create a personal access token at
#        https://app.docker.com/settings/personal-access-tokens
#      scoped "Public Repo Read-only". Nothing this credential serves pushes an
#      image, so a wider scope only widens what a leaked token reaches.
#   2. Persist the account name and the token under the canonical store paths:
#        gopass insert -f internet/hub.docker.com/nolte/username
#        gopass insert    internet/hub.docker.com/nolte/ci-pull-token
#
# Per-session prerequisites:
#   - gh CLI authenticated as the account that owns the repositories
#   - gopass unlocked
#
# This file is meant to be *sourced*, so it deliberately does NOT `set -euo
# pipefail`: those options would persist in the caller's interactive shell and
# turn the next failing command into a shell exit. Every failure path below is
# handled explicitly with `return 1 2>/dev/null || exit 1` instead.

# gopass store prefix for the Docker Hub credential. Override via
# DOCKERHUB_GOPASS_PREFIX if it lives under a different path; the default
# matches the nolte-managed gopass tree.
GOPASS_PREFIX="${DOCKERHUB_GOPASS_PREFIX:-internet/hub.docker.com/nolte}"

if ! command -v gopass >/dev/null 2>&1; then
  echo "error: gopass not in PATH" >&2
  return 1 2>/dev/null || exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "error: gh CLI not in PATH" >&2
  return 1 2>/dev/null || exit 1
fi

# Fail fast on a missing entry: an empty value would otherwise be written as a
# blank DOCKERHUB_TOKEN secret, and a blank secret is worse than none — the
# login step would run, fail, and rely on its fallback on every single run.
if ! TF_VAR_dockerhub_username="$(gopass show -o "${GOPASS_PREFIX}/username")" \
  || [ -z "${TF_VAR_dockerhub_username}" ]; then
  echo "error: Docker Hub username missing or empty at ${GOPASS_PREFIX}/username" >&2
  echo "       store the ACCOUNT NAME (not the e-mail address used to sign in):" >&2
  echo "         gopass insert -f ${GOPASS_PREFIX}/username" >&2
  return 1 2>/dev/null || exit 1
fi

if ! TF_VAR_dockerhub_token="$(gopass show -o "${GOPASS_PREFIX}/ci-pull-token")" \
  || [ -z "${TF_VAR_dockerhub_token}" ]; then
  echo "error: Docker Hub pull token missing or empty at ${GOPASS_PREFIX}/ci-pull-token" >&2
  echo "       create one scoped 'Public Repo Read-only' at" >&2
  echo "         https://app.docker.com/settings/personal-access-tokens" >&2
  echo "       then store it:" >&2
  echo "         gopass insert ${GOPASS_PREFIX}/ci-pull-token" >&2
  return 1 2>/dev/null || exit 1
fi

if ! GITHUB_TOKEN="$(gh auth token)" || [ -z "${GITHUB_TOKEN}" ]; then
  echo "error: could not read a GitHub token from 'gh auth token' — run 'gh auth login'" >&2
  return 1 2>/dev/null || exit 1
fi

export TF_VAR_dockerhub_username TF_VAR_dockerhub_token GITHUB_TOKEN

echo "dockerhub env loaded:"
echo "  TF_VAR_dockerhub_username = ${TF_VAR_dockerhub_username}"
echo "  TF_VAR_dockerhub_token    = (${#TF_VAR_dockerhub_token} chars, sensitive)"
echo "  GITHUB_TOKEN              = (${#GITHUB_TOKEN} chars, sensitive)"
