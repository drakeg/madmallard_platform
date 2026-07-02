# Mad Mallard Platform

A low-cost, growth-friendly AWS/Django platform for separate Mad Mallard business identities.

The goal is **shared infrastructure and shared code**, but **separate public identities** for:

- Mad Mallards Adventures
- Mad Mallard Personal Training
- Mad Mallard Solutions

The businesses can share the platform engine while keeping domains, branding, templates, email identity, public pages, and customer-facing experiences separate.

---

## Current architecture

Bootstrap deployment:

```text
AWS
├── VPC
├── Public subnet
├── Security group
├── EC2 instance
│   ├── Docker
│   ├── Nginx
│   ├── Django
│   └── SQLite initially
├── S3 assets/backups bucket
└── IAM role for S3 backup access
```

This is intentionally small and cheap. Later we can migrate SQLite to PostgreSQL/RDS, move workloads to ECS/App Runner, add CloudFront, add SES, and add background workers.

---

## Approximate monthly cost

Free Tier eligible account:

| Service | Purpose | Approx. monthly cost |
|---|---|---:|
| EC2 t3.micro/t4g.micro | App host | $0 if Free Tier eligible |
| EBS gp3 20GB | Root disk | ~$1.60–$2.00 |
| S3 | Backups/assets | <$1 initially |
| Data transfer | Light traffic | Usually <$1 initially |
| Route 53 | DNS, when added | ~$0.50/hosted zone |

Estimated starting total: **$0–5/month if EC2 Free Tier applies**, or roughly **$10–15/month without Free Tier**.

---

## Repo layout

```text
app/                       Django app
terraform/modules/          Reusable Terraform modules
terraform/environments/dev/ Dev environment
terraform/environments/prod/ Prod environment placeholder
scripts/                   Deploy/backup helper scripts
deploy/nginx/              Nginx config
.github/workflows/         CI validation
Makefile                   Root-level helper commands
```

---

## SSH key configuration

Terraform creates an EC2 key pair using the public key you provide.

The variable is defined here:

```text
terraform/environments/dev/variables.tf
```

Relevant variables:

```hcl
variable "public_key" {
  type        = string
  description = "SSH public key contents"
}

variable "ssh_cidr" {
  type        = string
  description = "Your IP CIDR for SSH, e.g. 1.2.3.4/32"
}
```

You provide the value here:

```text
terraform/environments/dev/terraform.tfvars
```

Create it from the example:

```bash
cp terraform/environments/dev/terraform.tfvars.example terraform/environments/dev/terraform.tfvars
```

Example `terraform.tfvars`:

```hcl
aws_region    = "us-east-1"
ssh_cidr      = "YOUR_PUBLIC_IP/32"
public_key    = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA... greg@mac"
ami_family    = "ubuntu-24.04"
ami_id        = ""
instance_type = "t3.micro"
```

To get your public SSH key from your Mac:

```bash
cat ~/.ssh/id_ed25519.pub
```

If you do not have one yet:

```bash
ssh-keygen -t ed25519 -C "greg@madmallard"
cat ~/.ssh/id_ed25519.pub
```

To get your current public IP for `ssh_cidr`:

```bash
curl https://checkip.amazonaws.com
```

Then use:

```hcl
ssh_cidr = "YOUR_IP_HERE/32"
```

Do **not** put your private key in Terraform. Only paste the `.pub` key.

---

## AMI selection

The scaffold now supports both automatic AMI discovery and pinned AMI IDs.

Default behavior uses the latest AMI for the selected `ami_family`:

```hcl
ami_family = "ubuntu-24.04"
ami_id     = ""
```

Supported `ami_family` values:

```text
ubuntu-24.04
ubuntu-22.04
amazon-linux-2023
```

If you need a specific AMI, set `ami_id` and it overrides automatic lookup:

```hcl
ami_family = "ubuntu-24.04"
ami_id     = "ami-0123456789abcdef0"
```

Recommended starter options:

```hcl
# Free-tier-friendly x86 starter
instance_type = "t3.micro"
ami_family    = "ubuntu-24.04"
ami_id        = ""
```

Or:

```hcl
# Amazon Linux 2023 starter
instance_type = "t3.micro"
ami_family    = "amazon-linux-2023"
ami_id        = ""
```

Notes:

- The automatic lookup currently selects x86_64 AMIs because `t3.micro` is the safest Free Tier-style starting point.
- If we switch to `t4g.micro`, we should also add ARM64 AMI lookup support.
- Terraform output includes `ami_id`, `ami_family`, and `ssh_user` so you can see exactly what was selected.

## Do I need to go into every folder manually?

No. Terraform itself runs from a specific environment directory, but the repo now includes a root `Makefile` so you can run common commands from the repo root.

From the repo root:

```bash
make tf-init ENV=dev
make tf-plan ENV=dev
make tf-apply ENV=dev
make tf-output ENV=dev
```

For prod later:

```bash
make tf-plan ENV=prod
```

You only need to edit files under the environment you are working with, usually:

```text
terraform/environments/dev/terraform.tfvars
```

---

## First-time AWS deployment flow

1. Configure AWS credentials locally:

```bash
aws configure
```

2. Create your dev tfvars file:

```bash
cp terraform/environments/dev/terraform.tfvars.example terraform/environments/dev/terraform.tfvars
```

3. Edit:

```text
terraform/environments/dev/terraform.tfvars
```

Set:

- `aws_region`
- `ssh_cidr`
- `public_key`
- `ami_family` or optional pinned `ami_id`
- `instance_type`

4. Initialize Terraform:

```bash
make tf-init ENV=dev
```

5. Review the plan:

```bash
make tf-plan ENV=dev
```

6. Apply:

```bash
make tf-apply ENV=dev
```

7. Get the EC2 public IP:

```bash
make tf-output ENV=dev
```

8. SSH to the instance:

```bash
ssh ubuntu@EC2_PUBLIC_IP
```

---

## Local Django development

From the repo root:

```bash
make app-build
make app-up
```

Then open:

```text
http://localhost:8000
```

Seed initial business tenants:

```bash
cd app
docker compose exec web python manage.py migrate
docker compose exec web python manage.py seed_tenants
```

---

## GitHub setup

Create an empty GitHub repo, then from this project root:

```bash
git init
git add .
git commit -m "Initial Mad Mallard platform scaffold"
git branch -M main
git remote add origin git@github.com:YOUR_USERNAME/madmallard-platform.git
git push -u origin main
```

---

## Important next improvements

Recommended before treating this as production:

1. Add Terraform remote state in S3 with DynamoDB locking.
2. Add domain/Route 53 module.
3. Add CloudFront only when traffic or caching needs justify it.
4. Add SES for separate business email identities.
5. Add automatic EC2 deploy from GitHub Actions.
6. Add encrypted app secrets via SSM Parameter Store.
7. Add scheduled SQLite backups to S3.
8. Add optional ARM64 AMI lookup for Graviton/t4g instances.

---

## Business identity separation

The platform should never publicly present these businesses as one umbrella unless you explicitly choose to do that.

Shared internally:

- codebase
- Terraform modules
- database engine
- admin patterns
- backup strategy

Separate publicly:

- domains
- themes
- templates
- logos
- color palettes
- copywriting voice
- email from/reply-to identity
- analytics views
- customer-facing navigation
