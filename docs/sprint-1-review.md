# Sprint 1 — Tenant safety

**Period:** 2026-11-12 to 2026-11-25 (planning window; review not yet held)  
**Sprint goal:** Safe tenant-specific public pages with reproducible local review.  
**Status:** In progress. Nothing in this document indicates an unmerged PR is released.

## Stories in progress

- TEN-02 / CMS-01: tenant-scoped page list/detail, published-only data, safe escaping, sample data via explicit local command (current feature PR).
- DEV-01: local verification and repeatable test instructions.
- WEB-01: previously opened landing-page design PR #10, pending merge.
- TEN-03: scoped Django admin implementation is now in review, with BusinessMembership and security tests.

## Acceptance checklist

- [x] Every public page query is filtered by request tenant.
- [x] Unpublished and other-tenant page detail requests return 404 in automated tests.
- [x] Public HTML content is escaped by default.
- [x] Local preview selector is retained across page navigation.
- [x] Django tests pass in connected local Compose preview (20 tests on 2026-11-12; verify again after Django 6 rebuild).
- [x] Sample pages seeded for three brands via opt-in non-destructive command.
- [ ] Current PR checks green in GitHub.
- [x] Non-superuser admin cross-tenant access prevented and tested locally (TEN-03); PR review pending.
- [ ] Product owner accepts feature PR(s).
- [ ] Sprint review and retrospective completed.

## Local demo

- Adventures: http://127.0.0.1:8020/pages/
- Personal Training: http://127.0.0.1:8020/pages/?tenant=personal-training
- Solutions: http://127.0.0.1:8020/pages/?tenant=solutions

Examples are placeholder content for review, not a claim that these are real public offerings.

## Open decisions

1. Should site administrators manage one business each, or can some staff manage several?
2. Should public Page bodies remain plain text, use Markdown, or eventually support structured rich text?
3. Which business flow follows basic content management: Adventures content publishing, training services, or Solutions inquiries?

## Retrospective (fill after review)

- What went well:
- What slowed delivery:
- One measurable process improvement:
- Next sprint capacity from actual completed points:

## Integration and security update

PR #11 was merged to a feature branch after that branch was already merged into main. This feature PR restores TEN-02/CMS-01 and introduces TEN-03 directly on main. Business memberships allow one or more assigned businesses for each staff editor. Cross-tenant page editing is blocked, and business/domain configuration is reserved for superusers. No existing staff accounts are granted permissions by this migration.
