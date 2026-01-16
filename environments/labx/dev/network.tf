module "network" {
  source              = "../../../modules/azure-vnet"
  resource_group_name = module.rg_app.resource_group_name # Output dari modul RG
  location            = "indonesiacentral"

  subnets = {
    "T0-pub-edge-nw"  = { address_prefixes = ["172.22.0.0/24"] }
    "T1-dmz-web-nw"   = { address_prefixes = ["172.22.1.0/24"] }
    "T2-app-core-nw"  = { address_prefixes = ["172.22.4.0/22"] }
    "T3-sec-iam-nw"   = { address_prefixes = ["172.22.8.0/24"] }
    "T4-data-db-nw"   = { address_prefixes = ["172.22.12.0/24"] }
    "T8-adm-mgt-nw"   = { address_prefixes = ["172.22.33.0/24"] }
  }
}