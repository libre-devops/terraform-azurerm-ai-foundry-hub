output "discovery_urls" {
  description = "Map of hub name to discovery URL."
  value       = module.ai_foundry_hub.discovery_urls
}

output "hub_ids" {
  description = "Map of hub name to resource id."
  value       = module.ai_foundry_hub.ids
}

output "project_ids" {
  description = "Map of \"<hub>/<project>\" to resource id."
  value       = module.ai_foundry_hub.project_ids
}
