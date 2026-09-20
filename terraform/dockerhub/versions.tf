terraform {
  required_version = ">= 1.9.0"

  required_providers {
    github = {
      source = "integrations/github"
      # Floor raised from the `~> 6.4` the other roots declare: the upstream
      # module writes the Actions secret through `value`, which 6.12.0
      # introduced while deprecating `plaintext_value`. Below 6.12 the plan
      # fails outright rather than degrading, so the constraint states it.
      version = "~> 6.12"
    }
  }
}
