# Azure architecture for NFBoot

## Target cloud stack

- Azure Database for PostgreSQL
- Azure App Service or Azure Container Apps
- Azure Key Vault
- Azure Blob Storage
- Azure Monitor and Application Insights
- Optional Azure Front Door / API Management
- Optional Azure Redis Cache

## Deployment order

1. Create PostgreSQL server and database
2. Create the backend app service or container app
3. Add Key Vault and managed identity
4. Add Blob Storage containers for videos, images, and user files
5. Configure monitoring and alerts
6. Add API gateway with WAF if needed
7. Add Redis for caching and rate limiting

## Security checklist

- Use TLS 1.2+
- Restrict database firewall to app service or private endpoint
- Force private access for Blob Storage when possible
- Store secrets only in Key Vault
- Enable managed identity instead of secrets in code
- Set up audit logs and error alerts

## Suggested resource layout

- App: `nfboot-api-prod`
- Database: `nfboot-postgres-prod`
- Storage: `nfbootstorageprod`
- Key Vault: `nfboot-kv-prod`
- App Insights: `nfboot-insights-prod`

## Example environment variables

```bash
POSTGRES_HOST=...
POSTGRES_DB=nfboot
POSTGRES_USER=nfboot_user
AZURE_KEY_VAULT_URL=https://nfboot-kv-prod.vault.azure.net/
BLOB_STORAGE_URL=https://nfbootstorageprod.blob.core.windows.net/
JWT_SIGNING_KEY=managed-by-key-vault
```

## Production hardening

- Require HTTPS only
- Rotate secrets regularly
- Set up deployment slots for staging and production
- Add rate limiting on auth and AI endpoints
- Monitor unusual login and data access patterns
