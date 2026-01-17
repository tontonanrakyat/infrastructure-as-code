module "rg_app" {
  source              = "../../../modules/azure-resource-group"
  resource_group_name = "rg-labx-dev-app"
  location            = local.location
  
  tags = {
    Environment = local.environment
    Project     = "LabX"
    ManagedBy   = "Terraform-Module"
  }
}