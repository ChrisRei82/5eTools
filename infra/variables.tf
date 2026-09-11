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

variable "github_repo_owner" {
  description = "GitHub owner (user/org) name, used in the federated credential subject."
  type        = string
  default     = "ChrisRei82"
}

variable "github_repo_owner_id" {
  description = "GitHub owner's immutable numeric ID. This repo was created after 2026-07-15, so GitHub's OIDC subject claim uses the immutable-ID format rather than just the name - see the comment on azuread_application_federated_identity_credential.github_actions in main.tf. Find your own via: curl -s https://api.github.com/users/<owner> | jq .id"
  type        = string
  default     = "148950818"
}

variable "github_repo_name" {
  description = "GitHub repo name (without owner), used in the federated credential subject."
  type        = string
  default     = "5eTools"
}

variable "github_repo_id" {
  description = "GitHub repo's immutable numeric ID (same immutable-ID rationale as github_repo_owner_id). Find via: curl -s https://api.github.com/repos/<owner>/<repo> | jq .id"
  type        = string
  default     = "1364337146"
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
