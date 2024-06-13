data "azurerm_key_vault_secret" "appid" {
    name         = "aksauth-appid"
    key_vault_id = azurerm_key_vault.keyvault.id
}

data "azurerm_key_vault_secret" "secret" {
    name         = "aksauth-secret"
    key_vault_id = azurerm_key_vault.keyvault.id
}

output "principal_id" {
    value = azurerm_kubernetes_cluster.aks.identity.0.principal_id
}