resource "azurerm_resource_group" "main" {
  name     = "rg-missiontrack-dev"
  location = "East US"
}

data "azurerm_client_config" "current" {}

resource "azurerm_container_registry" "acr" {
  name                = "missiontrackacr001"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  sku           = "Basic"
  admin_enabled = false
}

resource "azurerm_key_vault" "kv" {
  name                = "missiontrackkv001"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tenant_id = data.azurerm_client_config.current.tenant_id
  sku_name  = "standard"

  purge_protection_enabled   = false
  soft_delete_retention_days = 7

  rbac_authorization_enabled = true

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"

    ip_rules = [
      "48.194.125.170/32"
    ]
  }
}
resource "azurerm_user_assigned_identity" "missiontrack" {
  name                = "missiontrack-identity"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
}

resource "azurerm_role_assignment" "kv_secrets_user" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.missiontrack.principal_id
}