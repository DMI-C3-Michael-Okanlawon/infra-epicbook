terraform {
  backend "azurerm" {
    resource_group_name  = "week-10-epicbook-state-rg"
    storage_account_name = "stepicbook1888420792"
    container_name       = "tfstate"
    key                  = "epicbook.tfstate"
    use_azuread_auth     = true
  }
}
