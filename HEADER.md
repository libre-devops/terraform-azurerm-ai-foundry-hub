<!--
  Keep the title and badges OUTSIDE the centered <div>: the Terraform Registry's markdown renderer
  does not parse markdown inside an HTML block, so a # heading or [![badge]] in the div renders as
  literal text on the registry. Only the logo (HTML) goes in the div.
-->
<div align="center">
  <a href="https://libredevops.org">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://libredevops.org/assets/libre-devops-white.png">
      <img alt="Libre DevOps" src="https://libredevops.org/assets/libre-devops-black.png" width="300">
    </picture>
  </a>
</div>

# Terraform Azure AI Foundry Hub (legacy)

The legacy, hub-based Azure AI Foundry (Machine Learning workspace hub + projects). Most users want
the modern project-based Foundry instead: see the note below.

[![CI](https://github.com/libre-devops/terraform-azurerm-ai-foundry-hub/actions/workflows/ci.yml/badge.svg)](https://github.com/libre-devops/terraform-azurerm-ai-foundry-hub/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/libre-devops/terraform-azurerm-ai-foundry-hub?sort=semver&label=release)](https://github.com/libre-devops/terraform-azurerm-ai-foundry-hub/releases/latest)
[![Terraform Registry](https://img.shields.io/badge/registry-libre--devops-7B42BC?logo=terraform&logoColor=white)](https://registry.terraform.io/namespaces/libre-devops)
[![License](https://img.shields.io/github/license/libre-devops/terraform-azurerm-ai-foundry-hub)](./LICENSE)

---

> ### ⚠️ This is the legacy hub-based Foundry
>
> Azure has two "AI Foundry" architectures. This module builds the **legacy** one:
> `azurerm_ai_foundry` and `azurerm_ai_foundry_project`, which are **Azure Machine Learning
> workspaces** (kind Hub and kind Project) and require a **Key Vault and a Storage account** per hub.
>
> For most new work, use the **modern, project-based Foundry** instead, which needs no Key Vault or
> Storage and is the Azure AI Foundry portal default:
> [`cognitive-account`](https://registry.terraform.io/modules/libre-devops/cognitive-account/azurerm/latest)
> (an AIServices account) plus
> [`ai-foundry-project`](https://registry.terraform.io/modules/libre-devops/ai-foundry-project/azurerm/latest).
>
> Reach for this hub module only when you specifically need the ML hub: prompt flow, managed compute,
> or fine-tuning flows that the hub uniquely supports.

## Overview

Azure AI Foundry **hubs** keyed by name, each with a nested map of **projects**. A hub is an Azure
Machine Learning workspace of kind Hub; it requires a Key Vault and a Storage account (and optionally
Application Insights and a container registry), and it provides the shared security, connections, and
compute that its projects inherit.

Secure defaults, all caller-overridable:

- **No public endpoint**: `public_network_access = "Disabled"`. Pair with a private endpoint, or set
  `managed_network` isolation.
- **System-assigned identity** on the hub and each project.
- **Customer-managed key** encryption and **managed network** isolation are exposed as optional blocks.

The resource group is passed by id and parsed. The Key Vault and Storage account are passed by id, so
provision them with the Libre DevOps `keyvault` and `storage-account` modules.

## Usage

```hcl
module "ai_foundry_hub" {
  source  = "libre-devops/ai-foundry-hub/azurerm"
  version = "~> 4.0"

  resource_group_id = module.rg.ids["rg-ldo-uks-prd-001"]
  location          = "uksouth"
  tags              = module.tags.tags

  ai_foundry_hubs = {
    "aifh-ldo-uks-prd-001" = {
      key_vault_id       = module.keyvault.ids["kv-ldo-uks-prd-001"]
      storage_account_id = module.storage.ids["stldouksprd001"]

      projects = {
        "aifp-ldo-uks-prd-001" = { friendly_name = "Research" }
      }
    }
  }
}
```

## Examples

- [`examples/minimal`](./examples/minimal) - one hub (with its Key Vault and Storage account) and a
  single project.
- [`examples/complete`](./examples/complete) - one hub with two projects and the public endpoint
  flagged on.

## Developing

Local work needs **PowerShell 7+** and **[`just`](https://github.com/casey/just)**, because the recipes
wrap the [LibreDevOpsHelpers](https://www.powershellgallery.com/packages/LibreDevOpsHelpers)
PowerShell module (the same engine the `libre-devops/terraform-azure` action runs in CI). Install
just with `brew install just`, or `uv tool add rust-just` then `uv run just <recipe>`.

Run `just` to list recipes: `just update-ldo-pwsh` (install or force-update LibreDevOpsHelpers from
PSGallery), `just validate`, `just scan` (Trivy only), `just pwsh-analyze` (PSScriptAnalyzer only),
`just plan`, `just apply`, `just destroy`, `just e2e`, `just test`, and `just docs` (the
plan/apply/destroy recipes mirror the action, including the storage firewall dance; `just e2e`
applies an example then always destroys it, defaulting to `minimal`, so nothing is left running).
Releasing is also `just`:
`just increment-release [patch|minor|major]` bumps, tags, and publishes a GitHub release, and the
Terraform Registry picks up the tag.

## Security scan exceptions

This module is scanned with [Trivy](https://github.com/aquasecurity/trivy); HIGH and CRITICAL
findings fail the build. Any waiver is a deliberate, reviewed decision, never a way to quiet a
finding that should be fixed. Waivers live in [`.trivyignore.yaml`](./.trivyignore.yaml) (the
machine-applied source of truth, passed to Trivy with `--ignorefile`) and are mirrored in the table
below so the reason is auditable.

| Trivy ID | Resource | Finding | Justification |
|----------|----------|---------|---------------|
| _None_   |          |         |               |

To add an exception: add an entry to `.trivyignore.yaml` (`id`, optional `paths` to scope it, and a
`statement` recording why), then add a matching row here. Where the finding is out of this module's
scope, point the justification at the Libre DevOps module that does address it (for example the
private-endpoint module). Both the file and this table are reviewed in the pull request.

## Reference

The Requirements, Providers, Inputs, Outputs, and Resources below are generated by `terraform-docs`.
