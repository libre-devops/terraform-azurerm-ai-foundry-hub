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
> [`ai-foundry-project`](https://registry.terraform.io/modules/libre-devops/ai-foundry-project/azapi/latest).
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

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0, < 2.0.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 4.0.0, < 5.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >= 4.0.0, < 5.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_ai_foundry.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/ai_foundry) | resource |
| [azurerm_ai_foundry_project.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/ai_foundry_project) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ai_foundry_hubs"></a> [ai\_foundry\_hubs](#input\_ai\_foundry\_hubs) | LEGACY: Azure AI Foundry hubs (Machine Learning workspace hubs) to create, keyed by hub name.<br/>Prefer the modern project-based Foundry (the cognitive-account + ai-foundry-project modules) unless<br/>you specifically need the ML hub. Each hub requires a Key Vault and a Storage account, and carries<br/>a nested map of projects.<br/><br/>Secure defaults, all overridable:<br/>  - public\_network\_access = Disabled   (pair with a private endpoint)<br/>  - identity.type = SystemAssigned<br/><br/>Per-hub fields:<br/>  key\_vault\_id                   Required. Key Vault backing the hub.<br/>  storage\_account\_id             Required. Storage account backing the hub.<br/>  application\_insights\_id        Optional. App Insights for the hub.<br/>  container\_registry\_id          Optional. ACR for the hub.<br/>  identity                       Managed identity (SystemAssigned by default).<br/>  description / friendly\_name    Optional metadata.<br/>  public\_network\_access          Enabled or Disabled (default Disabled).<br/>  high\_business\_impact\_enabled   HBI mode on the hub.<br/>  primary\_user\_assigned\_identity The default UAI for CMK / connections.<br/>  encryption                     Customer-managed key (key\_id + key\_vault\_id, optional UAI).<br/>  managed\_network                Managed VNet isolation (isolation\_mode).<br/>  projects                       Projects under the hub, keyed by project name. | <pre>map(object({<br/>    key_vault_id                   = string<br/>    storage_account_id             = string<br/>    application_insights_id        = optional(string)<br/>    container_registry_id          = optional(string)<br/>    description                    = optional(string)<br/>    friendly_name                  = optional(string)<br/>    public_network_access          = optional(string, "Disabled")<br/>    high_business_impact_enabled   = optional(bool)<br/>    primary_user_assigned_identity = optional(string)<br/><br/>    identity = optional(object({<br/>      type         = optional(string, "SystemAssigned")<br/>      identity_ids = optional(list(string))<br/>    }), {})<br/><br/>    encryption = optional(object({<br/>      key_id                    = string<br/>      key_vault_id              = string<br/>      user_assigned_identity_id = optional(string)<br/>    }))<br/><br/>    managed_network = optional(object({<br/>      isolation_mode = string<br/>    }))<br/><br/>    projects = optional(map(object({<br/>      description                    = optional(string)<br/>      friendly_name                  = optional(string)<br/>      high_business_impact_enabled   = optional(bool)<br/>      primary_user_assigned_identity = optional(string)<br/>      tags                           = optional(map(string))<br/>      identity = optional(object({<br/>        type         = optional(string, "SystemAssigned")<br/>        identity_ids = optional(list(string))<br/>      }), {})<br/>    })), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure region for the hubs and their projects. | `string` | n/a | yes |
| <a name="input_resource_group_id"></a> [resource\_group\_id](#input\_resource\_group\_id) | Resource id of the resource group to create the hubs in. The name and subscription are parsed from it (pass the rg module's ids output). | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to the hubs and their projects. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_discovery_urls"></a> [discovery\_urls](#output\_discovery\_urls) | Map of hub name to its discovery URL. |
| <a name="output_identities"></a> [identities](#output\_identities) | Map of hub name to its managed identity { principal\_id, tenant\_id }. |
| <a name="output_ids"></a> [ids](#output\_ids) | Map of hub name to its resource id. |
| <a name="output_ids_zipmap"></a> [ids\_zipmap](#output\_ids\_zipmap) | Map of hub name to a { name, id } object, for passing where both are needed together. |
| <a name="output_names"></a> [names](#output\_names) | The hub names. |
| <a name="output_project_ids"></a> [project\_ids](#output\_project\_ids) | Map of "<hub>/<project>" to the project resource id. |
| <a name="output_project_ids_zipmap"></a> [project\_ids\_zipmap](#output\_project\_ids\_zipmap) | Map of "<hub>/<project>" to a { name, id } object. |
| <a name="output_project_internal_ids"></a> [project\_internal\_ids](#output\_project\_internal\_ids) | Map of "<hub>/<project>" to its immutable project id. |
| <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name) | Resource group name parsed from resource\_group\_id. |
| <a name="output_subscription_id"></a> [subscription\_id](#output\_subscription\_id) | Subscription id parsed from resource\_group\_id. |
| <a name="output_tags"></a> [tags](#output\_tags) | The tags applied to the hubs. |
| <a name="output_workspace_ids"></a> [workspace\_ids](#output\_workspace\_ids) | Map of hub name to its immutable workspace id. |
<!-- END_TF_DOCS -->
