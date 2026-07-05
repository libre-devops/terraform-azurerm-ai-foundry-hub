<!--
  Header for the complete example README. Edit this file, then run `just docs`
  (or ./Sort-LdoTerraform.ps1 -IncludeExamples) to regenerate the section between the markers.
  The example's main.tf is embedded into the README automatically (see .terraform-docs.yml).
-->
<div align="center">
  <a href="https://libredevops.org">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://libredevops.org/assets/libre-devops-white.png">
      <img alt="Libre DevOps" src="https://libredevops.org/assets/libre-devops-black.png" width="200">
    </picture>
  </a>
</div>

# Complete example

Exercises the fuller surface of this module. The environment comes from the Terraform workspace
(`terraform.workspace`), not a variable. Run it with `just e2e complete`, which applies the stack
then always destroys it.

[![Terraform Registry](https://img.shields.io/badge/registry-libre--devops-7B42BC?logo=terraform&logoColor=white)](https://registry.terraform.io/namespaces/libre-devops)

<!-- BEGIN_TF_DOCS -->
## Example configuration

```hcl
locals {
  location  = lookup(var.regions, var.loc, "uksouth")
  rg_name   = "rg-${var.short}-${var.loc}-${terraform.workspace}-002"
  kv_name   = "kv-${var.short}-${var.loc}-${terraform.workspace}-002"
  sa_name   = "st${var.short}${var.loc}${terraform.workspace}002"
  hub_name  = "aifh-${var.short}-${var.loc}-${terraform.workspace}-002"
  proj_res  = "aifp-${var.short}-${var.loc}-${terraform.workspace}-002"
  proj_eval = "aifp-${var.short}-${var.loc}-${terraform.workspace}-003"
}

module "tags" {
  source  = "libre-devops/tags/azurerm"
  version = "~> 4.0"

  environment     = "prd"
  cost_centre     = "1888/67"
  owner           = "platform@example.com"
  deployed_branch = var.deployed_branch
  deployed_repo   = var.deployed_repo
  additional_tags = { Application = "terraform-azurerm-ai-foundry-hub" }
}

module "rg" {
  source  = "libre-devops/rg/azurerm"
  version = "~> 4.0"

  resource_groups = [{ name = local.rg_name, location = local.location, tags = module.tags.tags }]
}

module "keyvault" {
  source  = "libre-devops/keyvault/azurerm"
  version = "~> 4.0"

  resource_group_id = module.rg.ids[local.rg_name]
  location          = local.location
  tags              = module.tags.tags

  key_vaults = {
    (local.kv_name) = {
      purge_protection_enabled = false
    }
  }
}

module "storage" {
  source  = "libre-devops/storage-account/azurerm"
  version = "~> 4.0"

  resource_group_id = module.rg.ids[local.rg_name]
  location          = local.location
  tags              = module.tags.tags

  storage_accounts = {
    (local.sa_name) = {}
  }
}

# Complete call: one legacy AI Foundry hub with two projects. The public endpoint is flagged on (the
# module default is Disabled; the examples turn it on so the behaviour is demonstrable).
module "ai_foundry_hub" {
  source = "../../"

  resource_group_id = module.rg.ids[local.rg_name]
  location          = local.location
  tags              = module.tags.tags

  ai_foundry_hubs = {
    (local.hub_name) = {
      key_vault_id                 = module.keyvault.ids[local.kv_name]
      storage_account_id           = module.storage.ids[local.sa_name]
      friendly_name                = "Research hub"
      description                  = "Legacy ML-hub Foundry for research workloads."
      public_network_access        = "Enabled"
      high_business_impact_enabled = true

      projects = {
        (local.proj_res)  = { friendly_name = "Research", description = "Research project." }
        (local.proj_eval) = { friendly_name = "Evaluations", description = "Evaluation project." }
      }
    }
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0, < 2.0.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 4.0.0, < 5.0.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_ai_foundry_hub"></a> [ai\_foundry\_hub](#module\_ai\_foundry\_hub) | ../../ | n/a |
| <a name="module_keyvault"></a> [keyvault](#module\_keyvault) | libre-devops/keyvault/azurerm | ~> 4.0 |
| <a name="module_rg"></a> [rg](#module\_rg) | libre-devops/rg/azurerm | ~> 4.0 |
| <a name="module_storage"></a> [storage](#module\_storage) | libre-devops/storage-account/azurerm | ~> 4.0 |
| <a name="module_tags"></a> [tags](#module\_tags) | libre-devops/tags/azurerm | ~> 4.0 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_deployed_branch"></a> [deployed\_branch](#input\_deployed\_branch) | Git branch the deployment came from. Auto-filled in CI from TF\_VAR\_deployed\_branch. | `string` | `""` | no |
| <a name="input_deployed_repo"></a> [deployed\_repo](#input\_deployed\_repo) | Repository URL the deployment came from. Auto-filled in CI from TF\_VAR\_deployed\_repo. | `string` | `""` | no |
| <a name="input_loc"></a> [loc](#input\_loc) | Outfix: short Azure region code used in resource names (for example uks). | `string` | `"uks"` | no |
| <a name="input_regions"></a> [regions](#input\_regions) | Map of short region codes to Azure region slugs. | `map(string)` | <pre>{<br/>  "eus": "eastus",<br/>  "euw": "westeurope",<br/>  "uks": "uksouth",<br/>  "ukw": "ukwest"<br/>}</pre> | no |
| <a name="input_short"></a> [short](#input\_short) | Infix: short product code used in resource names. | `string` | `"ldo"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_discovery_urls"></a> [discovery\_urls](#output\_discovery\_urls) | Map of hub name to discovery URL. |
| <a name="output_hub_ids"></a> [hub\_ids](#output\_hub\_ids) | Map of hub name to resource id. |
| <a name="output_project_ids"></a> [project\_ids](#output\_project\_ids) | Map of "<hub>/<project>" to resource id. |
<!-- END_TF_DOCS -->
