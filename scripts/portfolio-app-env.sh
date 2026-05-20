#!/usr/bin/env bash
# Source this file before `task tf:plan:portfolio-app` / `tf:apply:portfolio-app`.
#
# Usage:
#   source scripts/portfolio-app-env.sh
#   task tf:plan:portfolio-app
#
# The script reads the portfolio-App credentials from gopass and exports
# them as TF_VAR_* so Terraform picks them up without writing them to
# disk. GITHUB_TOKEN is read from `gh auth token` for convenience.
#
# Prerequisites:
#   - gopass entries:
#       github/apps/nolte-portfolio-bot/app-id        (numeric App ID)
#       github/apps/nolte-portfolio-bot/private-key   (PEM, generated in
#                                                      the App's UI and
#                                                      piped into gopass)
#   - gh CLI authenticated as the account that owns var.consumer_repositories.
set -euo pipefail

APP_SLUG="${PORTFOLIO_APP_SLUG:-nolte-portfolio-bot}"

if ! command -v gopass >/dev/null 2>&1; then
  echo "error: gopass not in PATH" >&2
  return 1 2>/dev/null || exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "error: gh CLI not in PATH" >&2
  return 1 2>/dev/null || exit 1
fi

TF_VAR_app_id="$(gopass show -o "github/apps/${APP_SLUG}/app-id")"
TF_VAR_app_private_key="$(gopass show -o "github/apps/${APP_SLUG}/private-key")"
GITHUB_TOKEN="$(gh auth token)"

export TF_VAR_app_id TF_VAR_app_private_key GITHUB_TOKEN

echo "portfolio-app env loaded:"
echo "  TF_VAR_app_id          = (${#TF_VAR_app_id} chars)"
echo "  TF_VAR_app_private_key = (${#TF_VAR_app_private_key} chars, sensitive)"
echo "  GITHUB_TOKEN           = (${#GITHUB_TOKEN} chars, sensitive)"
