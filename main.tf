data "azurerm_client_config" "current" {}
resource "azurerm_resource_group" "rg" {
    name     = "infra-rg-neu"
    location = "North Europe"
}

resource "azurerm_container_registry" "registry" {
    name                     = "pecarmoregistry"
    resource_group_name      = azurerm_resource_group.rg.name
    location                 = azurerm_resource_group.rg.location
    sku                      = "Basic"
    admin_enabled             = true
    public_network_access_enabled = true
}

resource "azurerm_key_vault" "keyvault" {
    name                = "pecarmokeyvault"
    resource_group_name = azurerm_resource_group.rg.name
    location            = azurerm_resource_group.rg.location
    tenant_id = data.azurerm_client_config.current.tenant_id
    sku_name            = "standard"
}

resource "azurerm_key_vault_access_policy" "keyvaultpolicypecarmo" {
    key_vault_id = azurerm_key_vault.keyvault.id

    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = "bffd9bac-f216-407d-9dac-e328b3944ef0"

    secret_permissions = [
        "get",
        "list",
        "set",
        "delete",
    ] 
}