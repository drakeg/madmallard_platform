# Mad Mallard Platform — Agile Delivery Plan

**Updated:** 2026-11-12  
**Status:** Active product plan, estimates are planning assumptions rather than commitments.  
**Product owner:** Repository owner (approves scope, merges and production deployments).  
**Engineering:** AI-assisted implementation with human PR review and acceptance.  
**Cadence:** Two-week sprints, small independently testable PRs, review/demo at each sprint boundary.

## 1. Product vision and boundaries

Build an affordable, secure multi-tenant website platform for Mad Mallards Adventures, Mad Mallard Personal Training, and Mad Mallard Solutions. They share a Django platform but present independent domains, designs, content, and eventually permissions and business workflows.

**In scope for the MVP:** branded responsive public sites, tenant-scoped pages, safe content administration, domain routing, local Docker workflow, automated tests, operational runbook.

**Out of scope until explicitly prioritized:** AWS deployment, purchases, DNS cutovers, payments, subscriber accounts, individual coaching bookings, customer data imports, AI-agent operations, bespoke CRM, multi-region high availability.

**Current tech:** Django, SQLite, Docker Compose, GitHub Actions, Terraform (AWS option, not part of local testing). SQLite is acceptable for early development but needs a backup/recovery policy prior to real customer data.

## 2. Roles and decision rights

| Responsibility | Owner | Exit evidence |
| --- | --- | --- |
| Prioritize backlog and define success | Product owner | Accepted sprint goal and story priority |
| Implement code and automated tests | Engineering | Reviewable PR with reproducible verification |
| Review tenant boundaries and security-sensitive changes | Engineering + product owner | Explicit review evidence and passing tests |
| Accept user-visible behavior | Product owner | Local demo feedback / approved PR |
| Merge and authorize AWS deployments | Product owner | Explicit decision; no implicit deploy-on-merge |

## 3. Workflow, ceremonies, and tracking

- **Backlog refinement (weekly):** verify acceptance criteria, identify dependencies, split stories over five estimated points, remove stale items.
- **Sprint planning (every two weeks):** set one outcome-focused goal, select only ready stories, capture scope and risks.
- **Daily async check-in (when work is active):** completed / next / blockers. No automatic messages or unattended execution are assumed.
- **Review and demo (sprint end):** show running Docker URLs and completed acceptance criteria; collect feedback.
- **Retrospective (sprint end):** record one improvement in code quality, CI reliability, or delivery flow.
- **Board columns:** Backlog → Ready → In Progress → In Review → Done; Blocked is an explicit flag, not an alternative to an owner.
- **PR convention:** `feat`, `fix`, `test`, `docs`, `chore`, linked story identifier in title/body.
- **Scope policy:** Only one primary in-progress implementation story unless there is an independent CI blocker. Major requirements changes go back through the backlog.

## 4. Prioritization and estimation

Priority P0 = security blocker / prerequisite; P1 = MVP critical; P2 = useful after MVP; P3 = optional. Story points are **relative complexity** (1, 2, 3, 5, 8), not time estimates. An 8-point item must be split before starting. Estimated sprint capacity is intentionally **not yet calibrated**; use actual throughput from Sprint 1 to plan later sprints.

A story is **Ready** when it has a user outcome, measurable acceptance criteria, a known tenant/data impact, an implementable approach, and a verification plan.

A story is **Done** only when code and docs are in a reviewed PR, all required CI is green, local Docker verification is recorded where relevant, cross-tenant data tests pass, migration/rollback implications are stated, and the product owner accepts/merges the PR. An opened PR is **In Review**, not Done.

## 5. Sprint calendar and committed goals

| Sprint | Planning dates | Goal | Proposed scope | Exit demonstration |
| --- | --- | --- | --- | --- |
| 1 — Tenant safety | Nov 12–25, 2026 | A visitor cannot discover another tenant's content; editing remains controlled | TEN-02, CMS-01, TEN-03 (if capacity), DEV-01 | Brand-specific page listing and detail on Docker; cross-tenant 404 tests; admin access policy reviewed |
| 2 — Content operations | Nov 26–Dec 9, 2026 | Site owner can safely manage useful page content and site identities | CMS-02, CMS-03, SEC-01, ADMIN-01 | Edit and publish page in admin; validate per-tenant domains, headers and error behavior |
| 3 — Launch readiness | Dec 10–23, 2026 | Repeatable release and recovery process | OPS-01, OPS-02, OPS-03, TEST-01 | Backup/restore exercise, readiness endpoint, documented rollback and deployment checklist |
| 4 — Business experience | Dec 24–Jan 6, 2027 (tentative) | First functional business-specific workflow | BRD-01 then business-approved feature | Demo a real data-backed experience; no simulated form submissions |

Future sprint scope and calendar must be reconfirmed after each review. Holiday capacity and velocity are unknown.

## 6. Prioritized product backlog

| ID | Priority | Points | Status | Story / testable acceptance |
| --- | --- | --- | --- | --- |
| TEN-01 | P0 | 2 | Done (PR #3) | Hostname resolves active tenant; query override development-only; tests cover fallback and inactive tenant |
| WEB-01 | P1 | 5 | In Review (PR #10) | Responsive, branded landing pages for all three sites; no false live-service claims |
| TEN-02 | P0 | 3 | In Review (recovered in current PR) | Page detail is filtered by both current tenant and publication status; foreign/unpublished slugs return 404 |
| CMS-01 | P1 | 3 | In Review (recovered in current PR) | Tenant-specific page index and detail; empty state, safe escaping, optional non-destructive local sample data |
| DEV-01 | P1 | 3 | In Progress | Compose recipe, CI suite, review instructions, isolated local test and teardown documented |
| TEN-03 | P0 | 5 | In Review (current PR) | Explicit BusinessMembership assignments; platform-wide Business/Domain/Membership administration is superuser-only; Page admin enforces Django permissions and membership, filters records and foreign-key choices; tests cover view/add/change/delete and reassignment |
| ADMIN-01 | P1 | 3 | Backlog | Editing/publishing pages in Django admin is discoverable, consistent and tested; no unauthorized exposure |
| CMS-02 | P1 | 3 | Backlog | Theme/template config is allowlisted, sane fallback and errors covered |
| CMS-03 | P1 | 5 | Backlog | Normalize domains, reject conflicts, enforce coherent primary-domain rule, validate host routing |
| SEC-01 | P0 | 5 | Backlog | Production secrets, allowed hosts, CSRF, reverse proxy/TLS controls and `check --deploy` documented/tested |
| TEST-01 | P1 | 3 | Backlog | CI checks run tests, static validation and compose build smoke tests |
| OPS-01 | P1 | 5 | Backlog | SQLite backup/restore runbook verified against a disposable copy; no data loss |
| OPS-02 | P1 | 3 | Backlog | Minimal health/readiness endpoint with appropriate privacy; monitoring instructions |
| OPS-03 | P1 | 5 | Backlog | Explicit production deployment/rollback guide, infrastructure change preview and DNS gate |
| BRD-01 | P1 | 3 | Backlog | Decide first business workflow using review feedback; define data model, privacy and integration constraints |
| ADV-01 | P2 | 5 | Backlog | Adventures: publish and categorize trips/videos with real sources and working links |
| PT-01 | P2 | 5 | Backlog | Training: service catalog and contact/intake requirements, with consent and access controls |
| SOL-01 | P2 | 3 | Backlog | Solutions: services and inquiry requirements, safe contact handling |
| AUTH-01 | P2 | 5 | Backlog | Define account/role model for multi-tenant editors and future business owners |
| DATA-01 | P2 | 5 | Backlog | Evaluate PostgreSQL migration based on concurrency, durability and costs |
| PAY-01 | P3 | — | Deferred | Payments/billing require a separate business and security design |

Backlog can be mirrored into GitHub Issues/Project after repository owner selects the tracking convention. This document is the authoritative current plan until that happens. **Do not equate a document row with an automatically created GitHub Issue.**

## 7. Sprint 1 execution board

| Story | State | Dependencies | Immediate next action |
| --- | --- | --- | --- |
| TEN-02 | In Review | TEN-01 | Verify PR CI, demo two tenants and foreign-slug 404 |
| CMS-01 | In Review | TEN-02 | Review editing experience; decide how much content must be seeded |
| DEV-01 | In Progress | Local Docker | Document preview commands, checks, seed behavior, teardown |
| TEN-03 | In Review | BusinessMembership assignment | Review scoped Page admin, restricted Business/Domain admin and cross-tenant security tests |
| WEB-01 | In Review | None | Review PR #10 and collect visual feedback |

**Exit criteria:** no publicly accessible cross-tenant pages; explicitly tested unpublished content; site links stay on correct tenant during development preview; all 3 branded pages and indexed samples work locally; admins do not cross tenant boundaries when the TEN-03 PR is approved and merged.

## 8. Risk register

| Risk | Impact | Mitigation / owner |
| --- | --- | --- |
| Tenant data leakage | Critical | Fail-closed queries; cross-tenant regression tests; owner approves model |
| Development query override accidentally exposed | High | DEBUG-only override and explicit production check |
| Django admin is globally privileged by default | High | TEN-03 before giving non-superusers access |
| SQLite data loss or concurrent writes | High | OPS-01 backup drill; migrate based on requirements |
| Sample content mistaken for published offerings | Medium | Label examples; avoid payment/booking/contact promises |
| Renovate major version drift | Medium | Compatibility review and feature tests; no blind auto-merge |
| AWS spend / external DNS risk | High | No AWS/DNS deployment without explicit approval |
| Uncontrolled PR pileup | Medium | Review one primary feature PR at a time; close stale branches |

## 9. Quality strategy and definition of release

- Unit and integration tests for middleware, page view filtering, admin permissions and publishing.
- Security regression checks: both matching and foreign slugs, published/draft, inactive tenants, user impersonation and hostile HTML.
- Local Docker Compose checks: build, migrate, seed, 3 homepages, each page index/detail, admin login redirect, browser mobile/responsive review.
- GitHub Actions must pass on the final proposed commit. Local success does not mean CI passed.
- Before release: verified data backup, secure settings, real domain mapping, TLS, monitoring and a rollback plan. A demo server using Django `runserver` must never be described as production ready.

## 10. Demo instructions

On the connected MacBook, in `~/madmallard-platform-local-test/app`:

```sh
docker compose -p madmallard-review -f compose.local-review.yml ps
docker compose -p madmallard-review -f compose.local-review.yml exec -T web python manage.py check
docker compose -p madmallard-review -f compose.local-review.yml exec -T web python manage.py test
# local demo only; does not overwrite existing pages:
docker compose -p madmallard-review -f compose.local-review.yml exec -T web python manage.py seed_demo_pages
```

Preview: `http://127.0.0.1:8020/pages/`, `?tenant=personal-training`, or `?tenant=solutions`. The file `compose.local-review.yml` and `.env` are local, not checked into Git. To stop only this review stack, run `docker compose -p madmallard-review -f compose.local-review.yml down`.

## 11. Sprint review template

- Sprint goal achieved? (yes/partial/no, with evidence)
- Story IDs accepted, PR links, and CI results
- Demo feedback: usability, accessibility, mobile, brand fit
- Defects/regressions and security concerns
- Actual delivered points and carryovers (no assumed velocity)
- One retrospective action with owner
- Product owner's decision on next sprint goal and production readiness

## Integration recovery note — November 12, 2026

PR #11 was merged into an already-merged feature branch, so its public CMS changes did not reach `main`. The active Sprint 1 PR reintroduces that commit onto current `main` and implements TEN-03 on top. Verify the PR base is `main` and confirm its files actually land on `main` before marking stories Done.

## Tenant editor setup (after TEN-03 merges)

1. A superuser creates a staff user in Django Admin, with an appropriate strong password and no superuser privilege.
2. The superuser grants only the required Django Page model permissions (`view_page`, `add_page`, `change_page`, and/or `delete_page`).
3. The superuser assigns one or more BusinessMembership records under the Businesses admin.
4. Editors see and modify Pages only for their active assigned businesses. Business, Domain, and membership configuration remain superuser-only. Unassigned staff cannot manage Pages.
5. Removing a membership removes that business's Page administration access.

**Important:** Django Admin itself is for authenticated staff, not a public customer CMS. No tenant editor accounts are created automatically. Local sample Pages are non-production test content.
