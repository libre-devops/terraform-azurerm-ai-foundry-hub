# LEGACY. Azure AI Foundry hubs (and their projects) built on Azure Machine Learning workspaces
# (azurerm_ai_foundry = kind Hub, azurerm_ai_foundry_project = kind Project). This is the older,
# hub-based Foundry: it requires a Key Vault and a Storage account per hub. Unless you specifically
# need the ML hub (prompt flow, managed compute, some fine-tuning), prefer the modern project-based
# Foundry: the cognitive-account module (an AIServices account) plus the ai-foundry-project module.
#
# Hubs are keyed by name; each carries a nested map of projects. The resource group is passed by id
# and parsed. Public network access defaults to Disabled (pair with a private endpoint).
locals {
  rg                  = provider::azurerm::parse_resource_id(var.resource_group_id)
  resource_group_name = local.rg.resource_group_name

  # Flatten hub projects to "<hub>/<project>" keys.
  projects = merge([
    for hub_name, h in var.ai_foundry_hubs : {
      for proj_name, p in h.projects : "${hub_name}/${proj_name}" => {
        hub_name                       = hub_name
        project_name                   = proj_name
        description                    = p.description
        friendly_name                  = p.friendly_name
        high_business_impact_enabled   = p.high_business_impact_enabled
        primary_user_assigned_identity = p.primary_user_assigned_identity
        identity                       = p.identity
        tags                           = p.tags
      }
    }
  ]...)
}

resource "azurerm_ai_foundry" "this" {
  for_each = var.ai_foundry_hubs

  resource_group_name = local.resource_group_name
  location            = var.location
  tags                = var.tags

  name               = each.key
  key_vault_id       = each.value.key_vault_id
  storage_account_id = each.value.storage_account_id

  application_insights_id        = each.value.application_insights_id
  container_registry_id          = each.value.container_registry_id
  description                    = each.value.description
  friendly_name                  = each.value.friendly_name
  high_business_impact_enabled   = each.value.high_business_impact_enabled
  primary_user_assigned_identity = each.value.primary_user_assigned_identity
  public_network_access          = each.value.public_network_access

  identity {
    type         = each.value.identity.type
    identity_ids = each.value.identity.identity_ids
  }

  dynamic "encryption" {
    for_each = each.value.encryption != null ? [each.value.encryption] : []

    content {
      key_id                    = encryption.value.key_id
      key_vault_id              = encryption.value.key_vault_id
      user_assigned_identity_id = encryption.value.user_assigned_identity_id
    }
  }

  dynamic "managed_network" {
    for_each = each.value.managed_network != null ? [each.value.managed_network] : []

    content {
      isolation_mode = managed_network.value.isolation_mode
    }
  }
}

resource "azurerm_ai_foundry_project" "this" {
  for_each = local.projects

  ai_services_hub_id = azurerm_ai_foundry.this[each.value.hub_name].id
  location           = var.location
  tags               = each.value.tags != null ? each.value.tags : var.tags

  name                           = each.value.project_name
  description                    = each.value.description
  friendly_name                  = each.value.friendly_name
  high_business_impact_enabled   = each.value.high_business_impact_enabled
  primary_user_assigned_identity = each.value.primary_user_assigned_identity

  dynamic "identity" {
    for_each = each.value.identity != null ? [each.value.identity] : []

    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }
}
