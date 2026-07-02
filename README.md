# Mad Mallard Platform

A low-cost, AWS-first, multi-tenant platform for separate Mad Mallard businesses.

## Goals

- Start on the cheapest practical AWS footprint, including Free Tier EC2 when eligible.
- Keep Mad Mallards Adventures, Mad Mallard Personal Training, and Mad Mallard Solutions publicly separate.
- Share infrastructure, deployment, authentication, admin tooling, and reusable modules.
- Avoid cookie-cutter public sites by supporting separate domains, themes, templates, and settings.
- Make future migration simple: SQLite → PostgreSQL, single EC2 → ECS/App Runner, local jobs → managed workers.

## Initial Architecture

```text
Internet
  -> Route 53 / DNS
  -> EC2 Free Tier or low-cost t4g.micro/t3.micro
  -> Nginx
  -> Docker Compose
      -> Django + Gunicorn
      -> SQLite
  -> S3 backups/assets later
```

## Approximate Monthly Cost

Assuming Free Tier EC2 eligibility:

| Service | Purpose | Approx. Monthly Cost |
|---|---|---:|
| EC2 t2.micro/t3.micro/t4g.micro | App host | $0 if Free Tier eligible, otherwise ~$7-9 |
| EBS 20GB | Server disk | Usually free if Free Tier eligible, otherwise ~$2 |
| S3 | Backups/assets | <$1 initially |
| Route 53 hosted zone | DNS | ~$0.50 per hosted zone |
| CloudFront | Optional later CDN | $0-3 initially |
| SES | Optional email | <$1 initially |

Bootstrap target: **$0-3/month if Free Tier applies**, or **~$10-15/month without Free Tier**.

## Repo Layout

```text
app/                 Django application
terraform/           AWS infrastructure
terraform/modules/   Reusable Terraform modules
terraform/environments/dev/  Low-cost dev environment
.github/workflows/   CI checks
scripts/             Deploy/backup helpers
docs/                Architecture notes
```

## Tenant Separation Model

The businesses share the platform but remain publicly separate:

- Separate domains
- Separate themes
- Separate templates
- Separate navigation
- Separate email identities
- Separate analytics views
- Separate enabled modules

The database can store all tenants, but every public request resolves to one tenant by hostname.

## Local Development

```bash
cd app
cp .env.example .env
docker compose up --build
```

Then open:

- http://localhost:8000/?tenant=adventures
- http://localhost:8000/?tenant=personal-training
- http://localhost:8000/?tenant=solutions

## Terraform Dev Deploy

```bash
cd terraform/environments/dev
terraform init
terraform plan
terraform apply
```

## GitHub Setup

```bash
git init
git add .
git commit -m "Initial Mad Mallard Platform scaffold"
git branch -M main
git remote add origin git@github.com:<YOUR_USERNAME>/madmallard-platform.git
git push -u origin main
```

## Important Next Steps

1. Create a GitHub repo.
2. Choose AWS region.
3. Confirm whether your AWS account still has EC2 Free Tier eligibility.
4. Add your SSH public key to Terraform variable `public_key`.
5. Add real domains when ready.
# madmallard_platform
