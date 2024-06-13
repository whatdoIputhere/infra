provider "azurerm" {
  features {}

}

terraform {
  backend "azurerm" {
    resource_group_name   = "statestoragerg"
    storage_account_name  = "statestacc19910"
    container_name        = "statestoragecontainer"
    key                   = "terraform.tfstate"
  }
}