output "managed_identity_client_id" {
  value = azurerm_user_assigned_identity.missiontrack.client_id
}

output "managed_identity_principal_id" {
  value = azurerm_user_assigned_identity.missiontrack.principal_id
}

output "key_vault_id" {
  value = azurerm_key_vault.kv.id
}

output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}