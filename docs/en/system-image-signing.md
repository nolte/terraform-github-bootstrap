# System Image Signing

System image signing is an **opt-in feature** of the `terraform/repos` root
module. A repository receives the shared Sigstore signing key only when its
entry in `terraform.tfvars` sets `system_image_signing = true`; every other
repository is left untouched.

Every repository that publishes a bootable system image signs it with the
**same** key. The key is created once by the operator, stored in gopass, and
distributed from here. Terraform never creates the key and never reads it
from a file in this repository.

## Why a key and not keyless signing

Installed bootc appliances verify every update against a public key built into
the image. Keyless (Fulcio) signatures can't serve that check yet:

- The `containers-policy.json` that bootc applies accepts Fulcio identities
  only as **e-mail addresses**, not as the URI identity of a GitHub workflow.
- It doesn't read the **bundle format** that cosign v3 writes by default.

Both limits live in `image/signature/fulcio_cert.go` of
[`containers/container-libs`](https://github.com/containers/container-libs);
the fixes are open as PRs
[#625](https://github.com/containers/container-libs/pull/625) and
[#1153](https://github.com/containers/container-libs/pull/1153).

Keyless signing **stays in place in addition**, for checks from outside the
appliance. The key-based signature only serves the appliance's update policy.

## What Terraform owns vs. what stays manual

| Step | Where | Owner |
|---|---|---|
| 1. Create the key pair | local shell (`skopeo generate-sigstore-key`) | **manual (you), one-time** |
| 2. Store private key, passphrase, public key in gopass | local shell | **manual (you), one-time** |
| 3. Publish the public key in `nolte/gh-plumbing` (`keys/system-image.pub`) and cut a gh-plumbing release | `nolte/gh-plumbing`, separate pull request there | **manual (you)** |
| 4. Opt the repository in | `terraform/repos/terraform.tfvars` | **manual (you)** |
| 5. `SYSTEM_IMAGE_SIGNING_KEY` Actions secret | `github_actions_secret` | **Terraform** |
| 6. `SYSTEM_IMAGE_SIGNING_PASSPHRASE` Actions secret | `github_actions_secret` | **Terraform** |
| 7. `SYSTEM_IMAGE_SIGNING_PUBLIC_KEY` Actions variable | `github_actions_variable` | **Terraform** |

Terraform can't produce this key format, so steps 1–3 stay outside it.

| Name | Kind | Content |
|---|---|---|
| `SYSTEM_IMAGE_SIGNING_KEY` | Actions secret | Encrypted Sigstore private key (PEM, `ENCRYPTED SIGSTORE PRIVATE KEY`) |
| `SYSTEM_IMAGE_SIGNING_PASSPHRASE` | Actions secret | Passphrase of that private key |
| `SYSTEM_IMAGE_SIGNING_PUBLIC_KEY` | Actions variable | Matching public key (PEM), so a workflow can check that the secret matches the key published in `nolte/gh-plumbing` |

All three values are **required** on opt-in. With an empty value the plan
fails with a precondition that names `scripts/system-image-signing-env.sh`.

## One-time key creation

Create the key pair once, outside Terraform. The passphrase lives only in
gopass and in a short-lived file that `skopeo` reads.

```sh
GP=internet/github.com/nolte/signing/system-image

# 1. Generate a single-line passphrase and store it in gopass.
openssl rand -base64 32 | gopass insert -f "$GP/passphrase"

# 2. Write it to a private, short-lived passphrase file.
umask 077
PASSFILE=$(mktemp)
gopass show -o "$GP/passphrase" > "$PASSFILE"

# 3. Create the key pair: system-image.private and system-image.pub.
skopeo generate-sigstore-key --output-prefix system-image --passphrase-file "$PASSFILE"

# 4. Store both PEM files in gopass (multi-line).
gopass insert -m "$GP/private_key" < system-image.private
gopass insert -m "$GP/public_key"  < system-image.pub

# 5. Wipe the passphrase file and the private key file.
shred -u "$PASSFILE" system-image.private
```

Step 3 of the table publishes `system-image.pub` in `nolte/gh-plumbing`.
Copy it into a gh-plumbing checkout as `keys/system-image.pub`, open a pull
request there, and cut a gh-plumbing release once it's merged. Then delete
the local copy too:

```sh
rm system-image.pub
```

Consumer repositories don't carry a copy of the public key; see
[Public key distribution](#public-key-distribution).

The default gopass prefix is `internet/github.com/nolte/signing/system-image`
with the entries `private_key`, `passphrase`, and `public_key`. If the key
lives elsewhere, set `SYSTEM_IMAGE_SIGNING_GOPASS_PREFIX` before sourcing the
loader.

## Public key distribution

The canonical public key lives in `nolte/gh-plumbing` at
`keys/system-image.pub`. gh-plumbing documents it in
`docs/<lang>/signing/system-image-key.md`.

| Use | URL |
|---|---|
| Builds (pinned) | `https://raw.githubusercontent.com/nolte/gh-plumbing/<tag>/keys/system-image.pub` |
| Human reference (after the next gh-plumbing release) | `https://nolte.github.io/gh-plumbing/keys/system-image.pub` |

SHA-256 fingerprint of the current key file:

```text
35eab2c5b1a413e82ebd8919f2158e68af7c165da4535533ebf15a9f9a8bd084
```

Consumer builds fetch the key at build time and bake it into the image. Every
build **pins a gh-plumbing release tag** in the URL and **verifies the
SHA-256** of the downloaded file before it uses the key. A build never fetches
from a moving branch, and a fingerprint mismatch fails the build.

## Distribution

Opt a repository in through its entry in the git-ignored
`terraform/repos/terraform.tfvars`:

```hcl
repositories = {
  kamerplanter-appliance = {
    # ...
    system_image_signing = true
  }
}
```

`scripts/system-image-signing-env.sh` bridges gopass and Terraform. It exports
`TF_VAR_system_image_signing_key`, `TF_VAR_system_image_signing_passphrase`,
and `TF_VAR_system_image_signing_public_key`. The environment variables
`SYSTEM_IMAGE_SIGNING_KEY`, `SYSTEM_IMAGE_SIGNING_PASSPHRASE`, and
`SYSTEM_IMAGE_SIGNING_PUBLIC_KEY` win when set; otherwise the loader reads
gopass.

```sh
source scripts/system-image-signing-env.sh
task tf:plan     # review: 2 secrets + 1 variable per opted-in repo
task tf:apply    # human-gated apply
```

Once any repository opts in, **every** `task tf:plan` for `terraform/repos`
needs the loader sourced first; otherwise the precondition fails. Source the
other loaders too when their features are in use (for example
`scripts/dockerhub-env.sh`). Apply stays a local, human-gated step; CI never
applies.

## Verification

After the apply, check that the names are in place (GitHub never returns
secret values):

```sh
gh secret list   -R nolte/<repo>    # SYSTEM_IMAGE_SIGNING_KEY, SYSTEM_IMAGE_SIGNING_PASSPHRASE
gh variable list -R nolte/<repo>    # SYSTEM_IMAGE_SIGNING_PUBLIC_KEY
```

Compare the variable against the public key published in `nolte/gh-plumbing`:

```sh
diff <(gh variable get SYSTEM_IMAGE_SIGNING_PUBLIC_KEY -R nolte/<repo>) \
  <(curl -fsSL https://raw.githubusercontent.com/nolte/gh-plumbing/develop/keys/system-image.pub)
```

No output means the Actions variable matches the published key.

## First consumer

`nolte/kamerplanter-appliance` is the first consumer. Its reusable workflow
`.github/workflows/disk-image.yml` signs the published image when the input
`publish-image` is set. `release-publish.yml` passes the two secrets into it as
`system-image-signing-key` and `system-image-signing-passphrase`. The workflow
changes live in that repository, not here.

The appliance build fetches the public key from a pinned gh-plumbing tag,
verifies its SHA-256, and bakes it into the image's update policy, as
[Public key distribution](#public-key-distribution) describes. The repository
holds no copy of the key.

## State sensitivity

The secret values end up in the local Terraform state
(`terraform/repos/terraform.tfstate`), exactly as `DOCKERHUB_TOKEN` does. The
private key stays encrypted with the passphrase, but the passphrase sits in
the same state file. Treat the state like the gopass entries: keep it
git-ignored, never copy it into a shared location, and wipe stale copies.

## Rotation

Appliances accept only updates signed with the key they carry. A new public key
therefore has to reach them in a release that is **still signed with the old
key**. Rotate in this order:

1. **Create a new key pair** as in [One-time key creation](#one-time-key-creation),
   but keep it under a separate gopass prefix for now, so the current entries
   stay intact.
2. **Ship the new public key with the old key.** Publish the new public key
   in a new gh-plumbing release (`keys/system-image.pub`, with its new
   SHA-256). Each consumer then bumps its pinned gh-plumbing tag and expected
   fingerprint and ships a release that bundles the **new** public key but is
   still signed with the **old** key. Appliances accept that release and pick
   up the new key.
3. **Wait** until the appliances have taken that release.
4. **Swap the gopass values**: move the new private key, passphrase, and
   public key into the default prefix (or point
   `SYSTEM_IMAGE_SIGNING_GOPASS_PREFIX` at the new one), then
   `source scripts/system-image-signing-env.sh`, `task tf:plan`, and
   `task tf:apply`.
5. **Sign the next release with the new key.**

!!! warning "Public-key check in the consumer workflow"
    During step 2 the public key bundled into the image is already the new one
    (fetched from the new gh-plumbing tag) while
    `SYSTEM_IMAGE_SIGNING_PUBLIC_KEY` still holds the old one, because the
    secret and the variable change only in step 4. A workflow that compares the
    bundled key with the variable before signing fails for exactly that
    transition release.
    Such a check has to allow the transition, for example by comparing against
    the key the image currently trusts.

Never remove or overwrite the old key before step 3 is complete. An appliance
that still carries only the old public key rejects every update signed with the
new key and can't recover through the update channel.

## Lifecycle notes

- Setting `system_image_signing = false` or removing the flag **deletes** both
  secrets and the variable from the repository. The next signing run in that
  repository then fails.
- The secrets and the variable are Terraform-owned. Don't edit them through the
  GitHub UI; the next apply overwrites the change.
