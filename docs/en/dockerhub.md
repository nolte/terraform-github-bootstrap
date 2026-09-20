# Docker Hub pull credential — operator setup

The `terraform/dockerhub/` root module puts a **read-only** Docker Hub
credential onto the repositories whose CI pulls images, so those pulls stop
being anonymous. This page tells an operator (you) what to do *before*
`task tf:apply:dockerhub` and what the apply will actually do.

## Why this exists

An anonymous Docker Hub pull is rate-limited **per source IP**. On
GitHub-hosted runners that IP is shared with every other tenant of the runner
pool, so the budget can be exhausted by strangers — and the failure lands on
whichever pull request is unlucky, as a red required check that has nothing to
do with its diff.

[`nolte/kamerplanter#1311`](https://github.com/nolte/kamerplanter/issues/1311)
diagnosed that class of failure; [`#1321`](https://github.com/nolte/kamerplanter/issues/1321)
parked the prevention half on one missing piece — *"the credential is a
repository variable + secret the operator supplies."* This root is the operator
supplying it.

Authenticating changes the unit the quota is counted in: from an IP shared with
the internet to the account's own. The higher ceiling is the smaller half of
the benefit; not sharing the counter is the larger half. Docker has changed the
published limits more than once, so read the live values off the registry's own
response headers rather than trusting a number written down here.

## What Terraform owns vs. what stays manual

| Step | Where | Owner |
|---|---|---|
| 1. Create the Docker Hub personal access token | [Docker Hub UI](https://app.docker.com/settings/personal-access-tokens) | **manual (you)** |
| 2. Persist account name + token in gopass | local shell | **manual (you), one-time** |
| 3. Create the `DOCKERHUB_USERNAME` Actions variable | `github_actions_variable` | **Terraform** |
| 4. Create the `DOCKERHUB_TOKEN` Actions secret | `github_actions_secret` | **Terraform** |
| 5. Use the credential in CI | `reusable-pre-commit.yaml` | **already done** (gh-plumbing#417, v2.1.0) |

There is no Docker Hub Terraform provider in this stack, so step 1 cannot be
automated. Step 5 needs no work: the reusable workflow has accepted
`dockerhub-username` + `dockerhub-token` since v2.1.0, and every consumer
already passes them.

## The token — exact scope

Create it with the scope **`Public Repo Read-only`**.

Nothing this credential serves pushes an image, so anything wider only widens
what a leaked token reaches. Do **not** use the account password: a password
cannot be scoped down, cannot be revoked on its own, and unlocks the whole
account.

## One-time operator setup

```sh
# 1. Create the token in the Docker Hub UI (scope: Public Repo Read-only).

# 2. Persist it. The ACCOUNT NAME, not the e-mail address you sign in with —
#    the registry rejects an e-mail address at login.
gopass insert -f internet/hub.docker.com/nolte/username
gopass insert    internet/hub.docker.com/nolte/ci-pull-token
```

Override the store prefix with `DOCKERHUB_GOPASS_PREFIX` if your tree differs.

## Per-session workflow

```sh
source scripts/dockerhub-env.sh   # exports TF_VAR_* + GITHUB_TOKEN, reads gopass
task tf:plan:dockerhub
task tf:apply:dockerhub           # human-gated, as every apply in this repo
```

The script refuses to continue on a missing or empty gopass entry. That is
deliberate: an empty value would be written as a blank `DOCKERHUB_TOKEN`, and a
blank secret is worse than no secret — the login step would then run, fail, and
fall back on every single run.

## Verifying it took effect

Not in the Terraform output — in the run log. The reusable workflow prints the
mode it ran in on every run, precisely so it is stated rather than inferred:

```
Docker Hub login succeeded — pulls are authenticated
```

or, when the credential is absent or wrong, a warning naming anonymous mode.

## Who gets the credential

`consumer_repositories` defaults to `kamerplanter` alone. Measured 2026-09-20,
it is the only repository on this account that pulls from Docker Hub during CI
— its `.pre-commit-config.yaml` carries the two `language: docker_image` hooks
(actionlint, shellcheck), and its image builds and E2E stack read `node`,
`postgres`, `python`, `nginxinc/nginx-unprivileged` and `busybox` from Docker
Hub.

`gh-plumbing`, `claude-shared` and this repository were checked and have no
Docker Hub pulls, so they are deliberately absent. Add a repository when it
demonstrably pulls, not pre-emptively: every extra copy of a credential is an
extra place it can leak from, and a repository without the pair keeps pulling
anonymously — degraded, never broken.

## It never becomes a dependency

Every consumer degrades rather than breaks when the credential is absent,
wrong, or withheld:

- a repository not in `consumer_repositories` has no variable, so the login
  step is skipped
- a pull request **from a fork** receives no secrets at all; the login runs with
  an empty password, fails, and is `continue-on-error`
- a revoked or mistyped token fails the same way

In all three cases the lane continues with anonymous pulls. A setup that turned
a rate limit into a hard dependency on a registry credential would be the worse
trade.

## Rotation

1. Revoke the old token in Docker Hub.
2. Create a replacement with the same scope, `gopass insert` it at the same path.
3. `source scripts/dockerhub-env.sh && task tf:apply:dockerhub`.

The variable does not change; only the secret is replaced. There is no window
in which CI breaks — an invalid token just means anonymous pulls until the
apply lands.

## The token lives in Terraform state

`github_actions_secret` writes the value into state. This repository's state is
**local and git-ignored**, which is acceptable for a read-only token — and it
is the reason this concern must be revisited before any move to a remote
backend without encryption at rest. gopass is the source of truth; state is a
cache that happens to be readable.

## See also

- [`terraform/dockerhub/`](https://github.com/nolte/terraform-github-bootstrap/tree/develop/terraform/dockerhub) — the root module
- [`gh-plumbing//terraform/dockerhub-pull`](https://github.com/nolte/gh-plumbing/tree/develop/terraform/dockerhub-pull) — the shared module it wraps
- [`reusable-pre-commit.yaml`](https://github.com/nolte/gh-plumbing/blob/develop/.github/workflows/reusable-pre-commit.yaml) — the consuming workflow
