# Shared Sigstore signing key for bootable system images.
#
# bootc appliances verify updates against a key-based signature: the
# containers-policy.json `sigstoreSigned` requirement cannot verify keyless
# (Fulcio/GitHub-workflow identity) signatures yet, so CI signs with one shared
# key pair instead. Repos opting in via `system_image_signing = true` get
#   - SYSTEM_IMAGE_SIGNING_KEY        (Actions secret)   — encrypted private key PEM
#   - SYSTEM_IMAGE_SIGNING_PASSPHRASE (Actions secret)   — passphrase of that key
#   - SYSTEM_IMAGE_SIGNING_PUBLIC_KEY (Actions variable) — public key PEM, not a secret
# in the same apply that configures the repository.
#
# The key pair is created once, outside Terraform, with
# `skopeo generate-sigstore-key` and stored in gopass. Load it with
# `source scripts/system-image-signing-env.sh`. The values land in the
# Terraform state (like DOCKERHUB_TOKEN) — treat the state file as sensitive.
# Key creation and the rotation runbook: docs/en/system-image-signing.md.
locals {
  system_image_signing_repositories = toset([
    for name, repo in var.repositories : name if repo.system_image_signing
  ])
}

resource "github_actions_secret" "system_image_signing_key" {
  for_each = local.system_image_signing_repositories

  repository  = github_repository.managed[each.key].name
  secret_name = "SYSTEM_IMAGE_SIGNING_KEY"
  value       = var.system_image_signing_key

  lifecycle {
    precondition {
      condition     = var.system_image_signing_key != null && var.system_image_signing_key != ""
      error_message = "system_image_signing_key is required when a repository sets system_image_signing = true (run: source scripts/system-image-signing-env.sh)."
    }
  }
}

resource "github_actions_secret" "system_image_signing_passphrase" {
  for_each = local.system_image_signing_repositories

  repository  = github_repository.managed[each.key].name
  secret_name = "SYSTEM_IMAGE_SIGNING_PASSPHRASE"
  value       = var.system_image_signing_passphrase

  lifecycle {
    precondition {
      condition     = var.system_image_signing_passphrase != null && var.system_image_signing_passphrase != ""
      error_message = "system_image_signing_passphrase is required when a repository sets system_image_signing = true (run: source scripts/system-image-signing-env.sh)."
    }
  }
}

resource "github_actions_variable" "system_image_signing_public_key" {
  for_each = local.system_image_signing_repositories

  repository    = github_repository.managed[each.key].name
  variable_name = "SYSTEM_IMAGE_SIGNING_PUBLIC_KEY"
  value         = var.system_image_signing_public_key

  lifecycle {
    precondition {
      condition     = var.system_image_signing_public_key != null && var.system_image_signing_public_key != ""
      error_message = "system_image_signing_public_key is required when a repository sets system_image_signing = true (run: source scripts/system-image-signing-env.sh)."
    }
  }
}
