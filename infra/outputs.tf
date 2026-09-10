output "storage_account_name" {
  value = module.storage_account.name
}

# The module has no dedicated primary_web_endpoint output, but (unlike
# `data "azurerm_storage_account"`, which would hit the listKeys-hang bug
# documented in DevOpsHost/CLAUDE.md) its generic `resource` passthrough -
# the raw azapi response body - does carry it, since
# response_export_values includes "properties.primaryEndpoints".
output "site_url" {
  description = "Public URL of the 5eTools static site. Marked sensitive only because it's read off the storage account's whole `resource` passthrough output (which Terraform taints wholesale) - the URL itself isn't a secret. Retrieve with `terraform output -raw site_url`."
  value       = module.storage_account.resource.output.properties.primaryEndpoints.web
  sensitive   = true
}

output "github_actions_client_id" {
  description = "Set as the AZURE_CLIENT_ID repository variable in ChrisRei82/5eTools (Settings > Secrets and variables > Actions > Variables)."
  value       = azuread_application.github_actions.client_id
}

output "github_actions_tenant_id" {
  description = "Set as the AZURE_TENANT_ID repository variable."
  value       = var.tenant_id
}

output "github_actions_subscription_id" {
  description = "Set as the AZURE_SUBSCRIPTION_ID repository variable."
  value       = var.subscription_id
}
