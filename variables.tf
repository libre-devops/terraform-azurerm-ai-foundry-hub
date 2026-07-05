variable "ai_foundry_hubs" {
  description = <<-EOT
    LEGACY: Azure AI Foundry hubs (Machine Learning workspace hubs) to create, keyed by hub name.
    Prefer the modern project-based Foundry (the cognitive-account + ai-foundry-project modules) unless
    you specifically need the ML hub. Each hub requires a Key Vault and a Storage account, and carries
    a nested map of projects.

    Secure defaults, all overridable:
      - public_network_access = Disabled   (pair with a private endpoint)
      - identity.type = SystemAssigned

    Per-hub fields:
      key_vault_id                   Required. Key Vault backing the hub.
      storage_account_id             Required. Storage account backing the hub.
      application_insights_id        Optional. App Insights for the hub.
      container_registry_id          Optional. ACR for the hub.
      identity                       Managed identity (SystemAssigned by default).
      description / friendly_name    Optional metadata.
      public_network_access          Enabled or Disabled (default Disabled).
      high_business_impact_enabled   HBI mode on the hub.
      primary_user_assigned_identity The default UAI for CMK / connections.
      encryption                     Customer-managed key (key_id + key_vault_id, optional UAI).
      managed_network                Managed VNet isolation (isolation_mode).
      projects                       Projects under the hub, keyed by project name.
  EOT
  type = map(object({
    key_vault_id                   = string
    storage_account_id             = string
    application_insights_id        = optional(string)
    container_registry_id          = optional(string)
    description                    = optional(string)
    friendly_name                  = optional(string)
    public_network_access          = optional(string, "Disabled")
    high_business_impact_enabled   = optional(bool)
    primary_user_assigned_identity = optional(string)

    identity = optional(object({
      type         = optional(string, "SystemAssigned")
      identity_ids = optional(list(string))
    }), {})

    encryption = optional(object({
      key_id                    = string
      key_vault_id              = string
      user_assigned_identity_id = optional(string)
    }))

    managed_network = optional(object({
      isolation_mode = string
    }))

    projects = optional(map(object({
      description                    = optional(string)
      friendly_name                  = optional(string)
      high_business_impact_enabled   = optional(bool)
      primary_user_assigned_identity = optional(string)
      tags                           = optional(map(string))
      identity = optional(object({
        type         = optional(string, "SystemAssigned")
        identity_ids = optional(list(string))
      }), {})
    })), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for h in values(var.ai_foundry_hubs) : contains(["Enabled", "Disabled"], h.public_network_access)
    ])
    error_message = "public_network_access must be Enabled or Disabled."
  }

  validation {
    condition = alltrue([
      for h in values(var.ai_foundry_hubs) :
      h.identity == null ? true : contains(["SystemAssigned", "UserAssigned", "SystemAssigned, UserAssigned"], h.identity.type)
    ])
    error_message = "identity.type must be SystemAssigned, UserAssigned, or \"SystemAssigned, UserAssigned\"."
  }

  validation {
    condition = alltrue([
      for h in values(var.ai_foundry_hubs) :
      h.managed_network == null ? true : contains(["Disabled", "AllowInternetOutbound", "AllowOnlyApprovedOutbound"], h.managed_network.isolation_mode)
    ])
    error_message = "managed_network.isolation_mode must be Disabled, AllowInternetOutbound, or AllowOnlyApprovedOutbound."
  }
}

variable "location" {
  description = "Azure region for the hubs and their projects."
  type        = string
}

variable "resource_group_id" {
  description = "Resource id of the resource group to create the hubs in. The name and subscription are parsed from it (pass the rg module's ids output)."
  type        = string

  validation {
    condition     = try(provider::azurerm::parse_resource_id(var.resource_group_id).resource_type, "") == "resourceGroups"
    error_message = "resource_group_id must be a resource group id of the form /subscriptions/<sub>/resourceGroups/<name>."
  }
}

variable "tags" {
  description = "Tags to apply to the hubs and their projects."
  type        = map(string)
  default     = {}
}
