terraform {
  required_version = ">= 1.9.0"

  required_providers {
    github = {
      source = "integrations/github"
      # Raised from `~> 6.4` by dockerhub.tf: it writes the Actions secret
      # through `value`, which 6.12.0 introduced while deprecating
      # `plaintext_value` and `encrypted_value`. Below 6.12 the plan fails
      # outright ("An argument named `value` is not expected here") rather
      # than degrading quietly, so the constraint states it.
      version = "~> 6.12"
    }
  }
}
