module "resource_group" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "~> 0.4"

  name             = var.resource_group_name
  location         = var.location
  enable_telemetry = false
  tags             = var.tags
}

# Static site storage. RBAC-only (no shared key) - GitHub Actions writes via
# an OIDC-federated service principal below, never a stored access key.
# No size cap unlike Azure Static Web Apps' Free tier (250MB) - 5eTools'
# actual content is ~13-15GB, almost entirely its bestiary/item image set,
# which is why Static Web Apps isn't usable here at any tier below Standard
# (500MB) or the retired Dedicated plan (2GB) - neither is close to enough.
module "storage_account" {
  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "~> 0.7"

  name             = var.storage_account_name
  parent_id        = module.resource_group.resource_id
  location         = var.location
  enable_telemetry = false

  account_kind                  = "StorageV2"
  account_sku_name              = "Standard_LRS"
  access_tier                   = "Hot"
  min_tls_version               = "TLS1_2"
  https_traffic_only_enabled    = true
  shared_access_key_enabled     = false
  public_network_access_enabled = true
  network_rules                 = null

  tags = var.tags
}

# Enabling static website hosting is a data-plane (Blob Service Properties)
# call, not an ARM one - with shared_access_key_enabled = false it goes over
# Entra ID/OAuth (provider's storage_use_azuread = true), so whoever runs
# `terraform apply` needs Storage Blob Data Contributor here too, same
# static/named-grant pattern as DevOpsHost (see its CLAUDE.md) - no dynamic
# data.azurerm_client_config.current entry.
resource "azurerm_role_assignment" "deployment_identities_blob_contributor" {
  for_each = {
    creich         = "62328995-d018-4475-af4d-44553bf5b8e3"
    deployment_spn = "3d5554c5-be98-4bde-ba64-1100e9acb5fe"
  }

  scope                = module.storage_account.resource_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = each.value
}

# Static website hosting serves the special `$web` container over its own
# public endpoint - independent of shared_access_key_enabled, but (per the
# role assignment above) not of RBAC once storage_use_azuread is in play.
resource "azurerm_storage_account_static_website" "this" {
  storage_account_id = module.storage_account.resource_id
  index_document     = "index.html"
  error_404_document = "404.html"

  depends_on = [azurerm_role_assignment.deployment_identities_blob_contributor]
}

# --- GitHub Actions OIDC federation - no stored secrets ---

resource "azuread_application" "github_actions" {
  display_name = "gh-actions-5etools-sync"
}

resource "azuread_service_principal" "github_actions" {
  client_id = azuread_application.github_actions.client_id
}

resource "azuread_application_federated_identity_credential" "github_actions" {
  application_id = azuread_application.github_actions.id
  display_name   = "github-actions-${replace(var.github_repo, "/", "-")}-${var.github_branch}"
  issuer         = "https://token.actions.githubusercontent.com"
  # Matches the subject GitHub puts in the OIDC token for scheduled/manually
  # dispatched runs against a specific branch (not a pull_request run - that
  # uses a different subject shape and would need its own credential).
  subject   = "repo:${var.github_repo}:ref:refs/heads/${var.github_branch}"
  audiences = ["api://AzureADTokenExchange"]
}

# Data-plane write access to the $web container - scoped to just this
# storage account, nothing broader.
resource "azurerm_role_assignment" "github_actions_blob_contributor" {
  scope                = module.storage_account.resource_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.github_actions.object_id
}
