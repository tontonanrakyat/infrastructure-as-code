resource "azurerm_virtual_network" "this" {
  name                = "vnet-veritas-core"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.vnet_address_space

  tags = {
    Environment = "Dev"
    Tier        = "Infrastructure"
    Protocol    = "172.22-Standard"
  }
}

resource "azurerm_subnet" "tiers" {
  for_each             = var.subnets
  name                 = each.key
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = each.value.address_prefixes
}