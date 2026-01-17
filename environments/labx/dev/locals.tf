locals {
  # Pusat Kendali Regional & Konvensi Penamaan
  location      = "indonesiacentral"
  project_name  = "veritas"
  environment   = "dev"

  # Standar Metadata (Prinsip DevOps: Observability)
  common_tags = {
    Project     = local.project_name
    Environment = local.environment
    ManagedBy   = "Terraform"
    Owner       = "CTO-Office"
    StrictSec   = "Enabled" # Menandakan Zero Trust aktif
  }
}