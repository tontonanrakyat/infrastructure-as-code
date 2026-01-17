module "network" {
  source              = "../../../modules/azure-vnet"
  resource_group_name = module.rg_app.resource_group_name # Output dari modul RG
  location            = "indonesiacentral"

  subnets = {
    # [Boundary: Public vs Private]
    "T0-pub-edge-nw"  = { address_prefixes = ["172.22.0.0/24"] }
    "T1-dmz-web-nw"   = { address_prefixes = ["172.22.1.0/24"] }
    
    # [Boundary: Internal Microservices]
    "T2-app-core-nw"  = { address_prefixes = ["172.22.4.0/22"] }
    "T3-sec-iam-nw"   = { address_prefixes = ["172.22.8.0/24"] }
    "T4-data-db-nw"   = { address_prefixes = ["172.22.12.0/24"] }
    "T5-data-s3-nw"   = { address_prefixes = ["172.22.13.0/24"] }
    
    # [Boundary: Operations & Monitoring]
    "T6-ops-obs-nw"   = { address_prefixes = ["172.22.16.0/20"] }
    "T7-ops-cicd-nw"  = { address_prefixes = ["172.22.32.0/24"] }
    "T8-adm-mgt-nw"   = { address_prefixes = ["172.22.33.0/24"] }
    "T9-adm-lab-nw"   = { address_prefixes = ["172.22.34.0/24"] }
    
    # [Boundary: Infrastructure & Deep Security]
    "T-INF-core-nw"   = { address_prefixes = ["172.22.64.0/24"] }
    "TX-sov-mesh-nw"  = { address_prefixes = ["172.22.65.0/24"] }
    "TZ-sec-iso-nw"   = { address_prefixes = ["172.22.66.0/24"] }
  }
}