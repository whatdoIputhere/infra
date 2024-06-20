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
    enable_rbac_authorization = true
}

resource "azurerm_role_assignment" "keyvault_secrets_officer_gitauth" {
    scope                = azurerm_key_vault.keyvault.id
    role_definition_name = "Key Vault Secrets Officer"
    principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "keyvault_secrets_officer_pecarmo" {
    scope                = azurerm_key_vault.keyvault.id
    role_definition_name = "Key Vault Secrets Officer"
    principal_id         = "bffd9bac-f216-407d-9dac-e328b3944ef0"
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
    depends_on = [ azurerm_role_assignment.managed_identity_operator ]

    default_node_pool {
        name       = "default"
        node_count = 1
        vm_size    = "Standard_B2ms"
        os_sku = "Ubuntu"
        os_disk_size_gb = "32"

        upgrade_settings {
            drain_timeout_in_minutes      = 0
            max_surge                     = "10%"
            node_soak_duration_in_minutes = 0
        }

        temporary_name_for_rotation = "temp"
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