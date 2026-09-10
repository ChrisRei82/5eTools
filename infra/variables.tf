variable "subscription_id" {
  description = "Azure Subscription ID to deploy into."
  type        = string
  default     = "28031fde-5ca2-4307-8d3c-d0b6ffa8015f"
}

variable "tenant_id" {
  description = "Entra ID (Azure AD) tenant ID."
  type        = string
  default     = "a0337026-ddd7-493e-a706-da67b560d1e6"
}

variable "location" {
  description = "Azure region."
  type        = string
  default     = "germanywestcentral"
}

variable "resource_group_name" {
  description = "Resource group holding the 5eTools static site storage account."
  type        = string
  default     = "rg-5etools-static"
}

variable "storage_account_name" {
  description = "Globally unique storage account name (3-24 lowercase alphanumeric chars)."
  type        = string
  default     = "st5etoolsstatic01"
}

variable "github_repo" {
  description = "GitHub 'owner/repo' allowed to assume the OIDC-federated identity that writes to the static website container."
  type        = string
  default     = "ChrisRei82/5eTools"
}

variable "github_branch" {
  description = "Branch the federated credential trusts - scheduled/manually dispatched workflow runs execute against this branch."
  type        = string
  default     = "main"
}

variable "tags" {
  description = "Common tags applied to all resources."
  type        = map(string)
  default = {
    project   = "5etools-static"
    env       = "prod"
    managedBy = "terraform"
  }
}
