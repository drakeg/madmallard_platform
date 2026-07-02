# Mad Mallard Platform

Low-cost AWS bootstrap for the Mad Mallard multi-tenant business platform.

This project is designed to start cheap on a single EC2 instance while keeping a migration path toward managed services later.

## Current architecture

```text
External DNS provider
  -> A record such as pill.madmallards.com
  -> EC2 public IP
  -> Caddy
  -> Django / SQLite / Docker
  -> S3 backups
```

The three business identities can share infrastructure and code while remaining publicly separate through tenant/domain/theme configuration.

## Approximate monthly cost

| Item | Approx. monthly cost |
|---|---:|
| EC2 Free Tier eligible instance | $0 if eligible |
| EC2 if not Free Tier | ~$8-15 |
| Public IPv4 / Elastic IP | ~$3.60 if used |
| EBS root volume | ~$1-3 |
| S3 backups/assets | <$1 initially |
| Caddy + Let's Encrypt TLS | $0 |
| SSM Documents/Association | ~$0 for this use case |

Expected bootstrap total: **~$5-8/month with EC2 Free Tier**, or **~$12-20/month without it**.

## Terraform layout

```text
terraform/
  environments/
    prod/       # the only AWS environment you need to deploy now
    dev/        # available for future use, but not required
  modules/
    ec2/
    iam/
    networking/
    s3/
    security/
    ssm/
```

You do **not** need to deploy `dev`. Local Docker is your development environment. AWS `prod` is the one live/test deployment.

## Configure Terraform

Copy the example tfvars:

```bash
cp terraform/environments/prod/terraform.tfvars.example terraform/environments/prod/terraform.tfvars
```

Edit:

```hcl
aws_region = "us-east-1"
name       = "madmallard-prod"

instance_type = "t3.micro"
ami_family    = "ubuntu-24.04"
ami_id        = ""

ssh_cidr   = "YOUR_PUBLIC_IP/32"
public_key = "ssh-ed25519 AAAA... greg@macbook"

web_server           = "caddy"
certificate_provider = "letsencrypt"
acme_email           = "you@example.com"

# Use a test/subdomain first. Do not point www/main business domains yet.
primary_domain = "pill.madmallards.com"
additional_domains = []

# Applied through AWS Systems Manager State Manager.
security_profile = "standard"
```

Supported AMI choices:

```hcl
ami_family = "ubuntu-24.04"
ami_family = "ubuntu-22.04"
ami_family = "amazon-linux-2023"
```

You may also pin a specific AMI:

```hcl
ami_id = "ami-0123456789abcdef0"
```

When `ami_id` is non-empty, it overrides `ami_family` lookup.

## Deploy

From the repo root:

```bash
make tf-init ENV=prod
make tf-plan ENV=prod
make tf-apply ENV=prod
make tf-output ENV=prod
```

## DNS

Because DNS is managed outside Route 53, create records at your DNS provider.

For a test URL:

```text
A record: pill.madmallards.com -> EC2 public IP
```

Use the IP from:

```bash
make tf-output ENV=prod
```

Do not point `www.madmallards.com` or any primary production site until you are ready.

## TLS

Default profile:

```hcl
web_server           = "caddy"
certificate_provider = "letsencrypt"
```

Caddy will request and renew certificates automatically once DNS points to the EC2 public IP.

Future profile is documented in `docs/tls-profiles.md` for AWS ACM ACME/exportable certificates.

## Security baseline

Security is applied via Terraform-created SSM document and State Manager association.

Default:

```hcl
security_profile = "standard"
```

See `docs/security-baseline.md`.

## Useful checks on EC2

```bash
sudo systemctl status caddy --no-pager
sudo journalctl -u caddy -n 100 --no-pager
sudo docker ps
sudo cloud-init status --long
sudo tail -n 100 /var/log/cloud-init-output.log
sudo tail -n 200 /var/log/madmallard-security-baseline.log
sudo madmallard-audit
```

## GitHub

Create a new GitHub repo, then from this folder:

```bash
git init
git add .
git commit -m "Initial Mad Mallard Platform scaffold"
git branch -M main
git remote add origin git@github.com:YOUR_USERNAME/YOUR_REPO.git
git push -u origin main
```

Never commit `terraform.tfvars`, private keys, `.env`, database files, or secrets.
