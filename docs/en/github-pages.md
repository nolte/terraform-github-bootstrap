# GitHub Pages

GitHub Pages is an **opt-in feature** of the `terraform/repos` root module.
A repository gets Pages only when its entry in `terraform.tfvars` sets
`pages.enabled = true`; every other repository is left untouched.

## Configuration

```hcl
repositories = {
  my-repo = {
    pages = {
      enabled    = true
      build_type = "workflow" # default
    }
  }
}
```

| Field | Default | Meaning |
|---|---|---|
| `enabled` | `false` | Feature toggle. `false` or no `pages` block: Terraform does not manage Pages. |
| `build_type` | `"workflow"` | `workflow`: Pages source "GitHub Actions", the repo deploys with `actions/deploy-pages`. `legacy`: "Deploy from a branch". |
| `branch` | `"gh-pages"` | Publishing branch (`legacy` only). |
| `path` | `"/"` | Publishing directory, `/` or `/docs` (`legacy` only). |
| `cname` | none | Optional custom domain. |

## Branch guard for `legacy`

Terraform cannot create the orphan `gh-pages` branch, and the GitHub API rejects
a Pages source that points at a missing branch. For `build_type = "legacy"` the
module therefore looks the branch up first and creates the Pages resource
**only if the branch exists**. Until then:

- the plan contains no `github_repository_pages` resource for that repo, and
- the `pages_branch_exists` check prints a warning naming the repo.

Once the deploy workflow has pushed the branch, the next apply configures Pages.
The same applies to a repo that does not exist yet (or a mistyped key): it is
skipped with the warning, the rest of the plan is unaffected.

The guard only gates the **first** creation. Once Pages is live on GitHub, the
repo stays managed even when the branch is briefly missing — a deploy that
recreates the branch never plans a destroy. The lookup uses the provider's
deprecated `pages` attribute of `data.github_repository`, so plans with a
`legacy` repo print a deprecation warning.

## Lifecycle notes

- Setting `enabled = false` or removing the block destroys the resource, which
  **disables Pages on GitHub**. The plan shows a destroy for
  `github_repository_pages.managed["<name>"]`.
- `enabled = true` on an archived repository is rejected by variable validation.
- A repository that already serves Pages must be imported before the first
  apply, otherwise the create fails:

  ```sh
  terraform -chdir=terraform/repos import 'github_repository_pages.managed["<name>"]' <name>
  ```

- Terraform reconciles `build_type`, the source branch/path, and `cname`. Change
  those only through tfvars; a UI change is reverted by the next apply.
  `https_enforced` and the Pages visibility (`public`) are **not** managed —
  set them in the GitHub UI.
