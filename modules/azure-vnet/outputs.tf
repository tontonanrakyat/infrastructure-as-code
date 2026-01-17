output "subnet_ids" {
  description = "Mapping antara nama subnet dan ID aslinya dari Azure"
  # Kita menggunakan for loop untuk membuat object { "nama-subnet" = "id-subnet" }
  value = { for s in azurerm_subnet.tiers : s.name => s.id }
}

output "vnet_id" {
  description = "ID unik dari Virtual Network yang baru dibuat"
  value       = azurerm_virtual_network.this.id # Pastikan nama resource VNet Anda adalah "this"
}