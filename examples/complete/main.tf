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
