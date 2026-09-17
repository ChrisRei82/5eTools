# CLAUDE.md

Operational guide for working in this repo. For architecture and setup steps, see `README.md` - this file is about *how to safely make changes here*, distilled from mistakes already made and fixed while building it. Sibling project [`DevOpsHost`](https://dev.azure.com/cyberpunk2082/Projects/_git/DevOpsHost) has its own `CLAUDE.md` with a broader, still-relevant set of Terraform/Azure lessons (RBAC self-lockout races, SP vs. App Registration object IDs, state-lock handling, etc.) - read that one too if you're touching `infra/` here.

## What this repo is

Hosts the 5eTools static site on an Azure Storage Account's static-website feature, kept current by a GitHub Actions workflow (`.github/workflows/sync.yml`) instead of a VM. `infra/` reuses `DevOpsHost`'s existing remote state storage account - there's no separate `bootstrap/` here, this project is too small to need one.

## Hard rules

1. **Azure Static Web Apps was considered and rejected - don't reintroduce it without re-checking the numbers.** Free tier caps app size at 250MB (Standard: 500MB); 5eTools' actual content (mostly the `5etools-img` bestiary/item set) is ~13-15GB. Nothing short of self-hosted/Blob Storage fits.

2. **`shared_access_key_enabled = false` breaks `azurerm_storage_account_static_website` unless the provider is told to use AzureAD for storage data-plane calls.** Enabling the static website property is a data-plane (Blob Service Properties) call, not an ARM one - it 403s with "Key based authentication is not permitted on this storage account" otherwise. Fix already in `infra/providers.tf`: `provider "azurerm" { storage_use_azuread = true }`.

3. **Once `storage_use_azuread = true` is set, whoever runs `terraform apply` needs Storage Blob Data Contributor on the storage account itself, too** - not just the GitHub Actions service principal. That data-plane call now goes through the applying identity's own RBAC. See `azurerm_role_assignment.deployment_identities_blob_contributor` in `infra/main.tf` for the static/named-grant pattern (same rationale as `DevOpsHost/CLAUDE.md` rule 4 - no dynamic `data.azurerm_client_config.current` entries here either).

4. **Creating the GitHub OIDC `azuread_application` needs Entra ID directory rights** (Application Administrator/Developer, or a tenant that allows self-service app registration) - plain Azure RBAC (Contributor/Owner) on the subscription is not enough. The `deployment_spn` used elsewhere in this ecosystem only has the latter and will fail with `Authorization_RequestDenied: Insufficient privileges`. Apply as a real user account (`az login` as yourself) for this specific resource.

5. **GitHub's OIDC subject claim format depends on when the repo was created.** Repos created after 2026-07-15 default to the immutable-ID format: `repo:OWNER@OWNER_ID/REPO@REPO_ID:ref:refs/heads/BRANCH`, not the older `repo:OWNER/REPO:ref:refs/heads/BRANCH`. Get this wrong and `azure/login@v2` fails with `AADSTS700213: No matching federated identity record found` - the failed run's log prints the *actual* subject GitHub sent, which is the fastest way to get the right owner/repo IDs (or query `https://api.github.com/repos/<owner>/<repo>` for `.id`, and `.../users/<owner>` for the owner's `.id`). See `azuread_application_federated_identity_credential.github_actions` in `infra/main.tf`.

6. **The AVM storage account module has no dedicated `primary_web_endpoint`-style output.** Read it off the generic `resource.output.properties.primaryEndpoints.web` passthrough instead (confirmed present via `response_export_values`) - but that whole passthrough is treated as sensitive by Terraform, so the `site_url` output needs `sensitive = true` even though the URL itself isn't a secret.

7. **Don't add `data "azurerm_storage_account"` here either** - same `listKeys`-hang-on-key-disabled-accounts issue as `DevOpsHost/CLAUDE.md` rule 3. Build resource IDs from known values instead.

## Verification habits expected here

- After any `infra/` change: `terraform plan` locally, then again after apply to confirm `No changes`.
- After a workflow change: trigger it manually once (`workflow_dispatch`) rather than waiting for the next 03:00 UTC schedule run to find out it's broken.
- `az storage blob sync` mirrors deletions too - if upstream 5eTools removes a file, the next sync removes it from `$web` as well. That's intentional (matches the old VM's `git reset --hard` full-mirror behavior), not a bug.

## Where the full docs are

`README.md` has the architecture, cost rationale, and one-time setup steps (including which GitHub repository variables to set). This file is only the "don't repeat past mistakes" layer on top of that.
