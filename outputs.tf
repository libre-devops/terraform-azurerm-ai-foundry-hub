output "discovery_urls" {
  description = "Map of hub name to its discovery URL."
  value       = { for k, v in azurerm_ai_foundry.this : k => v.discovery_url }
}

output "identities" {
  description = "Map of hub name to its managed identity { principal_id, tenant_id }."
  value = {
    for k, v in azurerm_ai_foundry.this : k => try({
      principal_id = v.identity[0].principal_id
      tenant_id    = v.identity[0].tenant_id
    }, null)
  }
}

output "ids" {
  description = "Map of hub name to its resource id."
  value       = { for k, v in azurerm_ai_foundry.this : k => v.id }
}

output "ids_zipmap" {
  description = "Map of hub name to a { name, id } object, for passing where both are needed together."
  value       = { for k, v in azurerm_ai_foundry.this : k => { name = v.name, id = v.id } }
}

output "names" {
  description = "The hub names."
  value       = keys(azurerm_ai_foundry.this)
}

output "project_ids" {
  description = "Map of \"<hub>/<project>\" to the project resource id."
  value       = { for k, v in azurerm_ai_foundry_project.this : k => v.id }
}

output "project_ids_zipmap" {
  description = "Map of \"<hub>/<project>\" to a { name, id } object."
  value       = { for k, v in azurerm_ai_foundry_project.this : k => { name = v.name, id = v.id } }
}

output "project_internal_ids" {
  description = "Map of \"<hub>/<project>\" to its immutable project id."
  value       = { for k, v in azurerm_ai_foundry_project.this : k => v.project_id }
}

output "resource_group_name" {
  description = "Resource group name parsed from resource_group_id."
  value       = local.resource_group_name
}

output "subscription_id" {
  description = "Subscription id parsed from resource_group_id."
  value       = local.rg.subscription_id
}

output "tags" {
  description = "The tags applied to the hubs."
  value       = var.tags
}

output "workspace_ids" {
  description = "Map of hub name to its immutable workspace id."
  value       = { for k, v in azurerm_ai_foundry.this : k => v.workspace_id }
}
