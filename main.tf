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
        "Get",
        "List",
        "Set",
        "Delete",
    ] 
}

resource "azurerm_key_vault_access_policy" "keyvaultpolicygithubauth" {
    key_vault_id = azurerm_key_vault.keyvault.id

    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
        "Get",
        "List",
        "Set",
        "Delete",
    ] 
}

resource "azurerm_user_assigned_identity" "identity" {
    resource_group_name = azurerm_resource_group.rg.name
    location            = azurerm_resource_group.rg.location
    name                = "aksidentity"
}

resource "azurerm_role_assignment" "managed_identity_operator" {
    scope                = azurerm_user_assigned_identity.identity.id
    role_definition_name = "Managed Identity Operator"
    principal_id         = azurerm_user_assigned_identity.identity.principal_id
}

resource "azurerm_kubernetes_cluster" "aks" {
    name                = "pecarmoaks"
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    dns_prefix          = "pecarmoaks"

    default_node_pool {
        name       = "default"
        node_count = 1
        vm_size    = "Standard_DS2_v2"
    }

    identity {
        type = "UserAssigned"
        identity_ids = [ azurerm_user_assigned_identity.identity.id ]
    }

    kubelet_identity {
        client_id = azurerm_user_assigned_identity.identity.client_id
        object_id = azurerm_user_assigned_identity.identity.principal_id
        user_assigned_identity_id = azurerm_user_assigned_identity.identity.id
    }
}

data "azurerm_subscription" "current" {}

resource "azurerm_role_assignment" "acr_pull" {
    scope                = azurerm_container_registry.registry.id
    role_definition_name = "AcrPull"
    principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity.0.object_id
    skip_service_principal_aad_check = true
}