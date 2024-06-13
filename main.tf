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

resource "azurerm_kubernetes_cluster" "aks" {
    name                = "pecarmoaks"
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    dns_prefix          = "pecarmoaks"
    kubernetes_version  = "1.19.7"

    default_node_pool {
        name       = "default"
        node_count = 1
        vm_size    = "Standard_DS2_v2"
    }

    identity {
        type = "SystemAssigned"
    }

    network_profile {
        network_plugin = "azure"
    }

    service_principal {
        client_id     = data.azurerm_client_config.current.client_id
        client_secret = data.azurerm_client_config.current.client_secret
    }
}