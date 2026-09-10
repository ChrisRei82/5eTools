# 5eTools - Static Hosting via Azure Blob Storage + GitHub Actions

Hosts the [5eTools](https://wiki.tercept.net/en/5eTools/InstallGuide) static site on Azure Blob Storage's static website feature, kept up to date by a GitHub Actions workflow instead of a VM.

## Why not a VM, and why not Azure Static Web Apps

This site previously ran on its own VM (`my5eTools` project), then briefly on the `DevOpsHost`/`apphost` VM under `/dnd5e/`. Both were replaced because that VM is being switched to start-on-demand (a public webhook) plus an automatic evening shutdown, to save cost on a host that's meant to run only for pipeline jobs - a VM that's off most of the time can't also serve an always-on public website.

**Azure Static Web Apps was considered and ruled out**: its Free plan caps app size at 250MB (Standard: 500MB, the retired Dedicated plan: 2GB). 5eTools' actual content - mostly the `5etools-img` bestiary/item image set - is **~13-15GB**, 50-60x over even the largest of those limits. Blob Storage has no such cap.

## Architecture

- **Storage Account** (`infra/`, Terraform, Azure Verified Modules) with static website hosting enabled, serving the `$web` container directly over its own public HTTPS endpoint. RBAC-only (`shared_access_key_enabled = false`) - no account key exists to leak.
- **GitHub Actions** (`.github/workflows/sync.yml`) clones the upstream [5etools-src](https://github.com/5etools-mirror-3/5etools-src)/[5etools-img](https://github.com/5etools-mirror-3/5etools-img) mirrors daily (03:00 UTC) and mirrors them into `$web` via `az storage blob sync` (deletes stale files too, same as the old VM's `git reset --hard` approach).
- **Auth**: OpenID Connect federation between this repo and an Entra ID App Registration (`infra/main.tf`) - no client secret or storage account key stored in GitHub anywhere. The federated credential's `subject` is pinned to `repo:ChrisRei82/5eTools:ref:refs/heads/main`, so only workflow runs against this exact repo/branch can authenticate as it.

## One-time setup

### 1. Apply the Terraform (locally, `az login` as an identity with Contributor + Application Administrator/Application Developer rights on the tenant - creating an App Registration needs the latter)

```bash
cd infra
terraform init
terraform apply
```

### 2. Get the site URL

```bash
terraform output -raw site_url
```

### 3. Set these as **repository variables** (not secrets - none of them are sensitive on their own without the federated-credential's repo/branch restriction) in `ChrisRei82/5eTools` → Settings → Secrets and variables → Actions → Variables:

| Variable | Value |
|---|---|
| `AZURE_CLIENT_ID` | `terraform output github_actions_client_id` |
| `AZURE_TENANT_ID` | `terraform output github_actions_tenant_id` |
| `AZURE_SUBSCRIPTION_ID` | `terraform output github_actions_subscription_id` |
| `AZURE_STORAGE_ACCOUNT` | `terraform output storage_account_name` |

### 4. Trigger the workflow once manually (Actions tab → "Sync 5eTools content to Azure Blob Storage" → Run workflow) to populate the site immediately instead of waiting for the next 03:00 UTC run.

## Known limitations

- The public URL is the auto-generated `https://<account>.z##.web.core.windows.net/` endpoint, not a custom domain - putting a real domain (or matching the old `/dnd5e/` path people may have bookmarked) in front of it would need Azure CDN or Front Door, which costs more than the storage itself does. Not set up; revisit if that matters later.
- `az storage blob sync` only mirrors file content - it doesn't set per-file `Content-Type`/cache headers the way the old VM's nginx config did. Azure infers content type from file extension reasonably well by default; if something renders wrong (e.g. served as `application/octet-stream`), that's the first thing to check.
