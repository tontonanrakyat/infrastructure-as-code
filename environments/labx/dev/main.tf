# 1. Terraform Configuration (Backend State)
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-infra-mgmt"
    storage_account_name = "staccveritas"
    container_name       = "tfstate"
    key                  = "dev.terraform.tfstate"
  }
}

# 2. Provider Configuration
provider "azurerm" {
  features {}
}

# 3. Test Resource (Resource Group Pertama via IaC)
resource "azurerm_resource_group" "rg_dev_app" {
  name     = "rg-labx-dev-app"
  location = "indonesiacentral"
  tags = {
    Environment = "Dev"
    ManagedBy   = "Terraform"
  }
}