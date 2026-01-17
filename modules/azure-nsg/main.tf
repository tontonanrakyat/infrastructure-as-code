resource "azurerm_network_security_group" "this" {
  name                = "nsg-${var.subnet_name}"
  location            = var.location
  resource_group_name = var.resource_group_name

  # Baseline Security: Deny All Inbound (Override Azure Default)
  security_rule {
    name                       = "DenyAllInboundCustom"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = var.tags
}

# Menghubungkan NSG ke Subnet secara otomatis
resource "azurerm_subnet_network_security_group_association" "this" {
  subnet_id                 = var.subnet_id
  network_security_group_id = azurerm_network_security_group.this.id
}