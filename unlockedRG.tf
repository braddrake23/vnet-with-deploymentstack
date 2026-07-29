resource "azurerm_resource_group" "unlocked" {
  name     = "unlocked-rg"
  location = "uksouth"
}

resource "azurerm_virtual_network" "example" {
  name                = "unlocked-vnet"
  resource_group_name = azurerm_resource_group.unlocked.name
  location            = azurerm_resource_group.unlocked.location
  address_space       = ["192.168.0.0/16"]

}
