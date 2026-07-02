# Architecture Notes

## Platform-first, not umbrella-brand-first

The platform is a shared engine. Public brands are isolated by hostname, theme, template, content, and settings.

## Tenant Resolution

1. Query parameter override for local development: `?tenant=adventures`.
2. Hostname lookup in the `Domain` table.
3. Fallback tenant from `DEFAULT_TENANT_SLUG`.

## Growth Path

| Trigger | Change |
|---|---|
| Need stronger DB/backups | SQLite → PostgreSQL/RDS |
| Need background jobs | Add Celery/Redis |
| Need CDN/static scale | Add CloudFront/S3 media storage |
| Need multiple app instances | Move Docker image to ECS/App Runner |
| Need separate access control | Add tenant-aware roles/groups |

## Cost Principle

Default to the cheapest option that does not block future growth. Avoid managed services until they solve a real business or operational problem.
