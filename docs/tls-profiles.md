# TLS Deployment Profiles

The platform supports a deployment-profile approach so TLS can start cheap and simple, then move to AWS-native certificate management later.

## Recommended bootstrap profile

```hcl
web_server           = "caddy"
certificate_provider = "letsencrypt"
```

This is the default because it is free, simple, and works with DNS hosted outside Route 53.

External DNS provider requirements:

1. Deploy Terraform and get `public_ip`.
2. In your external DNS provider, create A records for each business domain pointing to that EC2 public IP.
3. Set `primary_domain` and `additional_domains` in `terraform.tfvars`.
4. Run `make tf-apply ENV=prod` again to render the EC2 Caddyfile.
5. Caddy requests and renews certificates automatically.

## AWS ACM ACME profile

```hcl
web_server           = "nginx"
certificate_provider = "aws-acm-acme"
```

This profile is reserved for the AWS ACM ACME/exportable public certificate path. It is useful when you want certificate inventory and issuance controlled through AWS/IAM while still installing certificates on EC2.

This is not the default because the free/cheapest path is still Caddy + Let's Encrypt. AWS ACM exportable public certificates may add per-certificate cost, and the ACME client integration should be wired carefully once the desired domains and renewal approach are finalized.

Implementation notes for the future:

- Use an ACME client that supports custom ACME directory endpoints.
- Store certificate material under `/etc/ssl/madmallard/`.
- Configure Nginx to use the tenant-specific certificate chain/key.
- Use systemd timers for renewal and reload Nginx after renewal.
- Keep certificate provider choice in Terraform variables, not app code.

## No TLS profile

```hcl
web_server           = "caddy"
certificate_provider = "none"
primary_domain       = ""
```

Use only for temporary first boot or private testing by IP address. Public sites should use HTTPS.
