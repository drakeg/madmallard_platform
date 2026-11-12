# Development Roadmap and Agile Working Agreement

Status: planning baseline (November 2026). This file describes **proposed** work; backlog items are not implemented merely because they appear here.

## Goal

Deliver a low-cost, multi-tenant Django platform for separately branded websites while preventing one tenant from accessing another tenant's non-public content or administration. Continue using local Docker Compose for development; AWS provisioning is a separate, explicit deployment decision.

## Working agreement

- Use short, reviewable PRs tied to a backlog item. Do not merge unless checks are green and the change has been reviewed.
- Use two-week planning sprints, adjusting scope based on actual capacity. Update this file when priorities change.
- Each code PR should include purpose, security impact, verification instructions, and rollback implications.
- Definition of done: relevant tests exist and pass; CI passes; migrations (if any) are reversible or documented; docs are updated; cross-tenant access is checked for data-bearing features.
- Prefer supported secure/LTS runtime and dependencies. Review major upgrades for compatibility rather than merging on CI green alone.
- Do not deploy to AWS, change DNS, or migrate production data through routine development PRs.

## Sprint 1 — Tenant isolation foundation (next)

| ID | Priority | Story | Acceptance criteria |
|---|---|---|---|
| TEN-01 | P0 | Identify tenant by configured domain | Known domain resolves the expected active tenant; missing/inactive tenants receive explicit safe treatment; tests cover host case and unknown host |
| TEN-02 | P0 | Protect tenant-bound content | Pages are always filtered by request tenant; requesting a page belonging to another tenant returns 404; tests exercise two tenants |
| TEN-03 | P0 | Validate administrative boundaries | Define staff/superuser access policy and enforce per-tenant visibility for Business, Domain, and Page; automated tests cover cross-tenant admin access |
| DEV-01 | P1 | Repeatable local verification | Document `docker compose up --build`, Django checks, migrations, and tests; ensure CI runs the suite |
| SEC-01 | P1 | Production configuration hardening | Document and validate secret key, allowed hosts, debug mode, HTTPS/proxy settings, and CSRF trusted origins |

**Sprint exit:** Tenant-bound public and administrative queries cannot inadvertently leak another tenant's records in tests, and local commands reproduce CI behavior.

## Sprint 2 — Content and administration

| ID | Priority | Story | Acceptance criteria |
|---|---|---|---|
| CMS-01 | P1 | Tenant-specific published pages | Published page lookup uses both tenant and slug; unpublished pages are not publicly visible |
| CMS-02 | P1 | Brand-specific site configuration | Theme/template selection is constrained to known templates; fallback is safe; tests cover missing configuration |
| CMS-03 | P2 | Domain management | Normalize and validate hostnames; prevent conflicting domains and ensure one coherent primary domain per business |

## Sprint 3 — Operational readiness

| ID | Priority | Story | Acceptance criteria |
|---|---|---|---|
| OPS-01 | P1 | Backup and restore drill | Document SQLite backup/restore and verify it in an isolated environment before production reliance |
| OPS-02 | P1 | Health and diagnostics | Add non-sensitive readiness/liveness endpoints; define monitoring and failure-handling expectations |
| OPS-03 | P2 | Deployment runbook | Record bootstrap, secrets, Caddy, SSM, DNS and rollback steps; deployment requires separate authorization |

## Backlog / later

- Tenant-aware permissions and invitations after explicit role requirements.
- PostgreSQL migration when SQLite limitations justify the cost.
- Background jobs and object storage only when there is a concrete requirement.
- Independent brand onboarding, billing, and analytics after the tenant security foundation is reliable.

## Current verification commands

From `app/`:

```sh
python manage.py check
python manage.py migrate --noinput
python manage.py test
```

With a configured `app/.env`, from `app/`:

```sh
docker compose up --build
```

Verify Docker image construction and Django behavior separately. Do not imply the Docker workflow is proven until it has been executed in a suitable environment.
