output "nsg_id" {
  description = "ID unik dari Network Security Group yang dibuat"
  value       = azurerm_network_security_group.this.id
}

output "nsg_name" {
  description = "Nama dari Network Security Group untuk keperluan audit"
  value       = azurerm_network_security_group.this.name
}

output "nsg_rules" {
  description = "Daftar security rules yang terpasang pada NSG ini"
  value       = azurerm_network_security_group.this.security_rule
}

output "association_id" {
  description = "ID dari asosiasi antara NSG dan Subnet"
  value       = azurerm_subnet_network_security_group_association.this.id
}