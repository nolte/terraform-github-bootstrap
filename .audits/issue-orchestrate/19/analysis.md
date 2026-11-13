# Pre-analysis — issue #19

- **Issue:** https://github.com/nolte/terraform-github-bootstrap/issues/19 — "feat: distribute a shared Sigstore key for signing bootable system images"
- **Author:** `nolte` (repository owner → trusted)
- **Classification:** `feature-request` — adds a new opt-in per-repo provisioning concern; no defect, no security fix of existing code.
- **Route:** implement directly (one outcome, one PR strand, no roadmap item) — operator-confirmed 2026-11-13.
- **Requirements gate:** no `project/requirements/` artefact; **operator override** recorded 2026-11-13 — the issue body carries four testable acceptance criteria and a concrete reference pattern (`terraform/repos/dockerhub.tf`).
- **Working copy:** `~/repos/.worktrees/terraform-github-bootstrap/system-image-signing`, branch `feat/system-image-signing` off `origin/develop` (22826a7). `task worktree:add` is absent from this repo's Taskfile (established: `Taskfile.yml` has no `worktree` task) → plain `git worktree add -b … origin/develop`.

## Operator decisions

1. `SYSTEM_IMAGE_SIGNING_PUBLIC_KEY` is **required** on opt-in (precondition like the secrets).
2. gopass default prefix: `internet/github.com/nolte/signing/system-image/{private_key,passphrase,public_key}`, override via env.
3. Opt-in of `kamerplanter-appliance` is applied locally to the git-ignored `terraform/repos/terraform.tfvars` (no apply).

## Established facts

- Reference pattern: `terraform/repos/dockerhub.tf` (locals set from `var.repositories`, `github_actions_variable` + `github_actions_secret`, `lifecycle.precondition` naming the loader script).
- `kamerplanter-appliance` is already managed and imported (`terraform/repos/terraform.tfvars:536`, state entries for `github_repository.managed["kamerplanter-appliance"]`).
- Multi-line PEM from gopass must be read with `gopass show -n`; `-o` truncates to the first line (`scripts/portfolio-app-env.sh` comment).
- `image/keys/system-image.pub` is not yet on `develop` of `nolte/kamerplanter-appliance` (`gh api …/contents/image/keys` → 404) — consumer-side, out of scope.

## Scope

- **In:** opt-in flag, three input variables, resources + preconditions, loader script, runbook (creation, distribution, rotation, state sensitivity), index/nav/Taskfile/CLAUDE.md pointers, local tfvars opt-in.
- **Out:** running `terraform apply` (human-gated); creating the key; consumer-repo workflow changes and committing the public key in `kamerplanter-appliance`.

## Work packages

| ID | Problem | Acceptance | Files | Specialist | Depends |
|---|---|---|---|---|---|
| WP1 | Terraform opt-in + resources | `system_image_signing = true` yields 2 secrets + 1 variable; empty value → plan fails naming `scripts/system-image-signing-env.sh`; `task test` green | `terraform/repos/variables.tf`, `terraform/repos/system-image-signing.tf` | `nolte-engineering:fullstack-developer` | — |
| WP2 | Loader script | env wins over gopass; PEM read with `-n`; exports `TF_VAR_system_image_signing_{key,passphrase,public_key}` + `GITHUB_TOKEN`; sourced-safe (no `set -e`) | `scripts/system-image-signing-env.sh` | `nolte-engineering:fullstack-developer` | — |
| WP3 | Runbook + pointers | key creation, distribution, rotation documented; `task docs` strict green | `docs/en/system-image-signing.md`, `docs/en/index.md`, `mkdocs.yml`, `Taskfile.yml`, `CLAUDE.md` | `nolte-shared:audience-doc-author` | WP1/WP2 contract |
| WP4 | Opt in `kamerplanter-appliance` | `system_image_signing = true` in local tfvars | `terraform/repos/terraform.tfvars` (git-ignored) | generalist (one-line local edit, no specialist owns it) | WP1 |

## Risks

- Secret values land in the local Terraform state (as `DOCKERHUB_TOKEN` does) — documented in the runbook.
- Rotation needs a release signed with the old key that ships the new public key first — documented.
- After WP4, every `task tf:plan` needs the loader sourced, otherwise the precondition fails (intended).
