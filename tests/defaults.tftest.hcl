# Plan-time tests for the module. The azurerm provider is mocked, so no credentials, no
# features block, and no cloud calls are needed:
#   terraform init -backend=false && terraform test

mock_provider "azurerm" {}

variables {
  location          = "uksouth"
  resource_group_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-ldo-uks-tst-01"

  ai_foundry_hubs = {
    "aifh-ldo-uks-tst-01" = {
      key_vault_id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-ldo-uks-tst-01/providers/Microsoft.KeyVault/vaults/kv-ldo-uks-tst-01"
      storage_account_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-ldo-uks-tst-01/providers/Microsoft.Storage/storageAccounts/saldouksts01"

      projects = {
        "aifp-ldo-uks-tst-01" = {
          friendly_name = "Test project"
        }
      }
    }
  }
}

# The hub is created with its Key Vault and Storage account, public access disabled by default, and a
# system-assigned identity; its project is attached to it.
run "creates_hub_and_project" {
  command = plan

  assert {
    condition     = azurerm_ai_foundry.this["aifh-ldo-uks-tst-01"].public_network_access == "Disabled"
    error_message = "Hubs should default to public_network_access = Disabled."
  }

  assert {
    condition     = azurerm_ai_foundry.this["aifh-ldo-uks-tst-01"].identity[0].type == "SystemAssigned"
    error_message = "The hub should get a system-assigned identity by default."
  }

  assert {
    condition     = endswith(azurerm_ai_foundry.this["aifh-ldo-uks-tst-01"].key_vault_id, "kv-ldo-uks-tst-01")
    error_message = "The hub should reference the supplied Key Vault."
  }

  assert {
    condition     = length(azurerm_ai_foundry_project.this) == 1
    error_message = "One project should be created per nested map entry."
  }

  assert {
    condition     = azurerm_ai_foundry_project.this["aifh-ldo-uks-tst-01/aifp-ldo-uks-tst-01"].name == "aifp-ldo-uks-tst-01"
    error_message = "The project should be keyed as <hub>/<project> and named for the nested map key."
  }
}

# Validation: an invalid public_network_access value is rejected.
run "rejects_invalid_public_network_access" {
  command = plan

  variables {
    ai_foundry_hubs = {
      "aifh-ldo-uks-tst-01" = {
        key_vault_id          = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-ldo-uks-tst-01/providers/Microsoft.KeyVault/vaults/kv-ldo-uks-tst-01"
        storage_account_id    = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-ldo-uks-tst-01/providers/Microsoft.Storage/storageAccounts/saldouksts01"
        public_network_access = "Sometimes"
      }
    }
  }

  expect_failures = [var.ai_foundry_hubs]
}

# Validation: an invalid managed_network isolation_mode is rejected.
run "rejects_invalid_isolation_mode" {
  command = plan

  variables {
    ai_foundry_hubs = {
      "aifh-ldo-uks-tst-01" = {
        key_vault_id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-ldo-uks-tst-01/providers/Microsoft.KeyVault/vaults/kv-ldo-uks-tst-01"
        storage_account_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-ldo-uks-tst-01/providers/Microsoft.Storage/storageAccounts/saldouksts01"
        managed_network    = { isolation_mode = "AllTheThings" }
      }
    }
  }

  expect_failures = [var.ai_foundry_hubs]
}
