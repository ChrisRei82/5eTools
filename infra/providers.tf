terraform {
  required_version = ">= 1.9.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }
  }

  # Reuses the DevOpsHost project's existing remote state storage account
  # (created once via DevOpsHost/bootstrap) instead of standing up a
  # separate bootstrap stack for a project this small.
  backend "azurerm" {
    resource_group_name  = "rg-devops-tfstate"
    storage_account_name = "stdevopstfstate01"
    container_name       = "tfstate"
    key                  = "5etools-static.infra.tfstate"
    use_azuread_auth     = true
  }
}

provider "azurerm" {
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
  features {}

  # The storage account has shared_access_key_enabled = false, so any
  # storage data-plane call the provider makes (this resource's static
  # website property is a data-plane, not ARM, operation) must go over
  # Entra ID/OAuth instead of an account key - otherwise it 403s with
  # "Key based authentication is not permitted on this storage account."
  storage_use_azuread = true
}

provider "azuread" {
  tenant_id = var.tenant_id
}
