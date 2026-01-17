output "subnet_ids" {
  description = "Mapping antara nama subnet dan ID aslinya dari Azure"
  # Kita menggunakan for loop untuk membuat object { "nama-subnet" = "id-subnet" }
  value = { for s in azurerm_subnet.tiers : s.name => s.id }
}
