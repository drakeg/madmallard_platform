# Security Baseline via AWS Systems Manager

The EC2 security baseline is applied through Terraform-managed AWS Systems Manager (SSM) documents and State Manager associations.

## Why SSM instead of EC2 user_data?

`user_data` is best for first-boot bootstrap. SSM is better for repeatable operating-system configuration because the association can be re-run without rebuilding the instance.

## Cost

For this project, the SSM document and State Manager association are expected to add no meaningful monthly cost. We are using standard SSM capabilities against a small number of EC2 instances.

## Profiles

`security_profile = "minimal"`

Basic install path. Use only while troubleshooting.

`security_profile = "standard"`

Recommended default. Applies:

- fail2ban
- UFW on Ubuntu or firewalld on Amazon Linux 2023
- automatic security updates
- SSH hardening
- Docker log rotation
- Docker no-new-privileges daemon setting
- logrotate config
- auditd basics
- `/usr/local/bin/madmallard-audit`

`security_profile = "hardened"`

Everything from standard plus basic kernel/sysctl hardening.

## How it targets instances

The SSM association targets instances tagged:

```text
MadMallardPlatform = true
```

The EC2 module applies that tag automatically.

## Running the audit script

After SSM applies the baseline, connect with SSH or Session Manager and run:

```bash
sudo madmallard-audit
```

You can also check the SSM execution log:

```bash
sudo tail -n 200 /var/log/madmallard-security-baseline.log
```

## Re-applying changes

If you change the SSM document or `security_profile`, run:

```bash
make tf-apply ENV=prod
```

State Manager will apply the updated association to the tagged instance.
