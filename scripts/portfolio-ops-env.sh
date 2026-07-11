#!/usr/bin/env bash
# Source this file before `task tf:plan:portfolio-ops` / `tf:apply:portfolio-ops`.
#
# Usage:
#   source scripts/portfolio-ops-env.sh
#   task tf:plan:portfolio-ops
#
# Reads the portfolio-ops automation secrets from gopass and exports them as
# TF_VAR_* so Terraform picks them up without writing them to disk. GITHUB_TOKEN
# is read from `gh auth token` for convenience. Future concerns add their own
# TF_VAR_* export below.
#
# Prerequisites (one-time, all manual — no GitHub API for any of these):
#   1. Mint the merge-queue PAT in the GitHub UI (Settings -> Developer
#      settings -> Personal access tokens) with the `repo` + `project` scopes.
#   2. Persist it into gopass under the canonical store path:
#        gopass insert internet/github.com/nolte/tokens/gh-portfolio-ops/merge-queue-pat
#   3. Create the Projects V2 board + the gh-portfolio-ops repo (bootstrap.sh),
#      then set project_number in terraform/portfolio-ops/terraform.tfvars.
#
# Per-session prerequisites:
#   - gh CLI authenticated as the account that owns the repository
#   - gopass unlocked
#
# This file is meant to be *sourced*, so it deliberately does NOT `set -euo
# pipefail`: those options would persist in the caller's interactive shell and
# turn the next failing command into a shell exit. Every failure path below is
# handled explicitly with `return 1 2>/dev/null || exit 1` instead.

# gopass store prefix for portfolio-ops secrets. Override via
# PORTFOLIO_OPS_GOPASS_PREFIX if the secrets live under a different path; the
# default matches the nolte-managed gopass tree.
GOPASS_PREFIX="${PORTFOLIO_OPS_GOPASS_PREFIX:-internet/github.com/nolte/tokens/gh-portfolio-ops}"

if ! command -v gopass >/dev/null 2>&1; then
  echo "error: gopass not in PATH" >&2
  return 1 2>/dev/null || exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "error: gh CLI not in PATH" >&2
  return 1 2>/dev/null || exit 1
fi

# --- Concern: PR merge-queue board ---
# Fail fast: a missing gopass entry must abort here, never silently leave an
# empty token that Terraform would write as a blank MERGE_QUEUE_TOKEN secret.
if ! TF_VAR_merge_queue_token="$(gopass show -o "${GOPASS_PREFIX}/merge-queue-pat")" \
  || [ -z "${TF_VAR_merge_queue_token}" ]; then
  echo "error: merge-queue PAT missing or empty at ${GOPASS_PREFIX}/merge-queue-pat" >&2
  echo "       mint a classic PAT with the 'repo' + 'project' scopes, then store it:" >&2
  echo "         gopass insert ${GOPASS_PREFIX}/merge-queue-pat" >&2
  return 1 2>/dev/null || exit 1
fi

if ! GITHUB_TOKEN="$(gh auth token)" || [ -z "${GITHUB_TOKEN}" ]; then
  echo "error: could not read a GitHub token from 'gh auth token' — run 'gh auth login'" >&2
  return 1 2>/dev/null || exit 1
fi

export TF_VAR_merge_queue_token GITHUB_TOKEN

echo "portfolio-ops env loaded:"
echo "  TF_VAR_merge_queue_token = (${#TF_VAR_merge_queue_token} chars, sensitive)"
echo "  GITHUB_TOKEN             = (${#GITHUB_TOKEN} chars, sensitive)"
echo "  (set project_number in terraform/portfolio-ops/terraform.tfvars)"
