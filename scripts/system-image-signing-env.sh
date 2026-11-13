#!/usr/bin/env bash
# Source this file before `task tf:plan` / `task tf:apply` whenever a repo in
# terraform/repos sets `system_image_signing = true`.
#
# Usage:
#   source scripts/system-image-signing-env.sh
#   task tf:plan
#
# The shared signing key comes from ONE of two sources, per value:
#   1. the environment (wins if set):
#        SYSTEM_IMAGE_SIGNING_KEY         encrypted Sigstore/cosign private key PEM
#                                         (`ENCRYPTED SIGSTORE PRIVATE KEY` from skopeo,
#                                         or `ENCRYPTED COSIGN PRIVATE KEY` from cosign)
#        SYSTEM_IMAGE_SIGNING_PASSPHRASE  passphrase of that key
#        SYSTEM_IMAGE_SIGNING_PUBLIC_KEY  public key PEM
#   2. gopass under ${SYSTEM_IMAGE_SIGNING_GOPASS_PREFIX:-internet/github.com/nolte/signing/system-image}:
#        <prefix>/private_key, <prefix>/passphrase, <prefix>/public_key
#
# Prerequisite (one-time, outside Terraform): create the key pair in a temp dir
# (never inside a checkout) and store it in gopass under the prefix above:
#   skopeo generate-sigstore-key --output-prefix system-image --passphrase-file <file>
#   # -> system-image.private (encrypted) + system-image.pub
#   # (alternative: `cosign generate-key-pair`, rename cosign.key/.pub to system-image.*)
#   gopass insert -m "$GP/private_key" < system-image.private
#   gopass insert -m "$GP/public_key"  < system-image.pub
# Publish system-image.pub in nolte/gh-plumbing (keys/system-image.pub), then
# delete the local key files. Runbook incl. rotation: docs/en/system-image-signing.md.
#
# PEM values get exactly one trailing newline re-appended (command substitution
# strips it), so they are byte-identical to the PEM files and their SHA-256
# matches the published fingerprint. The passphrase is left as-is.
#
# Meant to be *sourced*: no `set -e`, failures use `return 1 || exit 1`.

GOPASS_SIGNING_PREFIX="${SYSTEM_IMAGE_SIGNING_GOPASS_PREFIX:-internet/github.com/nolte/signing/system-image}"

# _signing_resolve <env value> <gopass path> <gopass mode flag> -> prints the value,
# empty on failure. PEM entries need `-n` (no-parsing) to keep the full multi-line
# body; `-o` (oneline) would truncate the key to its `-----BEGIN ...-----` line.
_signing_resolve() {
  if [ -n "$1" ]; then
    printf '%s' "$1"
  elif command -v gopass >/dev/null 2>&1; then
    gopass show "$3" "$2" 2>/dev/null
  fi
}

# _signing_fail <what> <env name> <gopass path>
_signing_fail() {
  if command -v gopass >/dev/null 2>&1; then
    echo "error: system image signing $1 missing — export $2 or 'gopass insert -m $3'" >&2
  else
    echo "error: system image signing $1 missing and gopass is not installed — export $2" >&2
  fi
  unset -f _signing_resolve _signing_fail
}

if ! TF_VAR_system_image_signing_key="$(_signing_resolve "${SYSTEM_IMAGE_SIGNING_KEY:-}" "${GOPASS_SIGNING_PREFIX}/private_key" -n)" \
  || [ -z "${TF_VAR_system_image_signing_key}" ]; then
  _signing_fail "private key" SYSTEM_IMAGE_SIGNING_KEY "${GOPASS_SIGNING_PREFIX}/private_key"
  return 1 2>/dev/null || exit 1
fi
# $(...) stripped every trailing newline (env and gopass path alike): re-add one.
TF_VAR_system_image_signing_key+=$'\n'

if ! TF_VAR_system_image_signing_passphrase="$(_signing_resolve "${SYSTEM_IMAGE_SIGNING_PASSPHRASE:-}" "${GOPASS_SIGNING_PREFIX}/passphrase" -o)" \
  || [ -z "${TF_VAR_system_image_signing_passphrase}" ]; then
  _signing_fail "passphrase" SYSTEM_IMAGE_SIGNING_PASSPHRASE "${GOPASS_SIGNING_PREFIX}/passphrase"
  return 1 2>/dev/null || exit 1
fi

if ! TF_VAR_system_image_signing_public_key="$(_signing_resolve "${SYSTEM_IMAGE_SIGNING_PUBLIC_KEY:-}" "${GOPASS_SIGNING_PREFIX}/public_key" -n)" \
  || [ -z "${TF_VAR_system_image_signing_public_key}" ]; then
  _signing_fail "public key" SYSTEM_IMAGE_SIGNING_PUBLIC_KEY "${GOPASS_SIGNING_PREFIX}/public_key"
  return 1 2>/dev/null || exit 1
fi
TF_VAR_system_image_signing_public_key+=$'\n'
unset -f _signing_resolve _signing_fail

if ! GITHUB_TOKEN="$(gh auth token)" || [ -z "${GITHUB_TOKEN}" ]; then
  echo "error: could not read a GitHub token from 'gh auth token' — run 'gh auth login'" >&2
  return 1 2>/dev/null || exit 1
fi

export TF_VAR_system_image_signing_key TF_VAR_system_image_signing_passphrase \
  TF_VAR_system_image_signing_public_key GITHUB_TOKEN

echo "system-image-signing env loaded:"
echo "  TF_VAR_system_image_signing_key        = (${#TF_VAR_system_image_signing_key} chars, sensitive)"
echo "  TF_VAR_system_image_signing_passphrase = (${#TF_VAR_system_image_signing_passphrase} chars, sensitive)"
echo "  TF_VAR_system_image_signing_public_key = ${TF_VAR_system_image_signing_public_key%%$'\n'*} (${#TF_VAR_system_image_signing_public_key} chars)"
echo "  GITHUB_TOKEN                           = (${#GITHUB_TOKEN} chars, sensitive)"
