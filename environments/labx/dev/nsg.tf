module "nsg_core" {
  source   = "../../../modules/azure-nsg"
  for_each = module.network.subnet_ids # Mengambil ID dari 13 subnet Anda

  subnet_name         = each.key
  subnet_id           = each.value
  location            = local.location
  resource_group_name = module.rg_app.resource_group_name

  tags = {
    Environment = local.environment
    ManagedBy   = "Terraform"
    Tier        = split("-", each.key)[0] # Mengambil T0, T1, dst dari nama
  }
}