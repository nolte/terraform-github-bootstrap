# Roadmap

This file is the work queue governed by `spec/project/roadmap/`. Each entry is a
level-3 heading followed by a `yaml` code block (`id`, `title`, `detail`,
`outcomes`, `target_sprint`, `mvp`, `status`, in that order) and a free-text
body. `roadmap-plan` and `roadmap-refine` own the detail level and the status
lifecycle; do not hand-edit those fields here.

Entries carry monotonically increasing IDs starting at `R-1`, never reused.
Outcome IDs (`O-n` in `goals.md`) are an independent counter.

`terraform-github-bootstrap` shipped the MVP item below before adopting the
planning suite. This roadmap records it retroactively as `status: done`, mapped
to sprint 1, so the mission's minimum viable product resolves.

## Phase 1 — GitHub configuration as code

### R-1 — Terraform-managed repository inventory and rulesets

```yaml
id: R-1
title: Terraform-managed repository inventory and rulesets
detail: fine
outcomes: [O-1, O-2]
target_sprint: 1
mvp: true
status: done
```

The Terraform configuration (`integrations/github` provider) that manages the
nolte account's repository inventory (existence, description, topics, visibility,
feature flags) and per-repo repository rulesets. Capability
`github-config-as-code` in `project/portfolio.yml`.
