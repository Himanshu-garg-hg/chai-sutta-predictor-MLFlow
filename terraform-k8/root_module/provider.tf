terraform {
  backend "azurerm" {
    storage_account_name = "donotdeletestorage"
    resource_group_name  = "donotdelete"
    container_name       = "donotdeletecontainer"
    key                  = "terraform_modal.tfstate"

  }
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.64.0"
    }
  }
}
provider "azurerm" {
  features {}
  subscription_id = "a5e53954-5571-4fa4-9dd5-bfc7eda513a4"
}