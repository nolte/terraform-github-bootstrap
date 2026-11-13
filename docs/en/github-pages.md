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
module therefore lists the repository's branches first and creates the Pages
resource **only if the branch exists**. Until then:

- the plan contains no `github_repository_pages` resource for that repo, and
- the `pages_branch_exists` check prints a warning naming the repo.

Once the deploy workflow has pushed the branch, the next apply configures Pages.
The repository must already exist before `legacy` Pages is enabled.

## Lifecycle notes

- Setting `enabled = false`, removing the block, or deleting the `legacy` branch
  removes the resource, which **disables Pages on GitHub**. The plan shows a
  destroy for `github_repository_pages.managed["<name>"]`.
- A repository that already serves Pages must be imported before the first
  apply, otherwise the create fails:

  ```sh
  terraform -chdir=terraform/repos import 'github_repository_pages.managed["<name>"]' <name>
  ```

- Do not change the Pages settings in the GitHub UI for a managed repository;
  the next apply reverts it.
