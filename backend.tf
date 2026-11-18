terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-storage-rg"
    storage_account_name = "tfstateaksbijoy01"
    container_name       = "tfstatefiles"
    key                  = "missiontrack.tfstate"
  }
}