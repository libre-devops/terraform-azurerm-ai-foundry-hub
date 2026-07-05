locals {
  location  = lookup(var.regions, var.loc, "uksouth")
  rg_name   = "rg-${var.short}-${var.loc}-${terraform.workspace}-001"
  kv_name   = "kv-${var.short}-${var.loc}-${terraform.workspace}-001"
  sa_name   = "st${var.short}${var.loc}${terraform.workspace}001"
  hub_name  = "aifh-${var.short}-${var.loc}-${terraform.workspace}-001"
  proj_name = "aifp-${var.short}-${var.loc}-${terraform.workspace}-001"
}

module "tags" {
  source  = "libre-devops/tags/azurerm"
  version = "~> 4.0"

  cost_centre     = "1888/67"
  owner           = "platform@example.com"
  deployed_branch = var.deployed_branch
  deployed_repo   = var.deployed_repo
}

module "rg" {
  source  = "libre-devops/rg/azurerm"
  version = "~> 4.0"

  resource_groups = [{ name = local.rg_name, location = local.location, tags = module.tags.tags }]
}

# The Key Vault and Storage account the hub requires. purge_protection is off so this disposable
# example vault can be torn down.
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

# Minimal call: one legacy AI Foundry hub (ML workspace hub) and a single project on it.
module "ai_foundry_hub" {
  source = "../../"

  resource_group_id = module.rg.ids[local.rg_name]
  location          = local.location
  tags              = module.tags.tags

  ai_foundry_hubs = {
    (local.hub_name) = {
      key_vault_id       = module.keyvault.ids[local.kv_name]
      storage_account_id = module.storage.ids[local.sa_name]

      projects = {
        (local.proj_name) = { friendly_name = "Minimal project" }
      }
    }
  }
}
