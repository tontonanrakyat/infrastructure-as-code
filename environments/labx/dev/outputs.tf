output "resource_group_id" {
  description = "ID dari Resource Group Utama"
  value       = module.rg_app.resource_group_id
}

output "vnet_id" {
  description = "ID dari Virtual Network LabX"
  value       = module.network.vnet_id
}

output "network_summary" {
  description = "Ringkasan Pemetaan Subnet dan NSG (Zero Trust Baseline)"
  value = {
    for name, id in module.network.subnet_ids : name => {
      subnet_id = id
      nsg_id    = module.nsg_core[name].nsg_id
      status    = "Locked-at-4096"
    }
  }
}