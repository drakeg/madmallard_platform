variable "name" {
  type = string
}

variable "security_profile" {
  type        = string
  default     = "standard"
  description = "Security baseline profile. Supported: minimal, standard, hardened."

  validation {
    condition     = contains(["minimal", "standard", "hardened"], var.security_profile)
    error_message = "security_profile must be one of: minimal, standard, hardened."
  }
}

variable "target_tag_key" {
  type    = string
  default = "MadMallardPlatform"
}

variable "target_tag_value" {
  type    = string
  default = "true"
}

resource "aws_ssm_document" "security_baseline" {
  name            = "${var.name}-security-baseline"
  document_type   = "Command"
  document_format = "YAML"

  content = <<-DOC
schemaVersion: '2.2'
description: Apply Mad Mallard Platform EC2 security baseline.
parameters:
  SecurityProfile:
    type: String
    description: Security profile to apply.
    default: standard
    allowedValues:
      - minimal
      - standard
      - hardened
mainSteps:
  - action: aws:runShellScript
    name: applySecurityBaseline
    inputs:
      timeoutSeconds: '900'
      runCommand:
        - |
          #!/usr/bin/env bash
          set -euo pipefail
          PROFILE="{{ SecurityProfile }}"
          LOG=/var/log/madmallard-security-baseline.log
          exec > >(tee -a "$LOG") 2>&1
          echo "[$(date -Is)] Applying Mad Mallard security baseline: $PROFILE"

          if [ -f /etc/os-release ]; then
            . /etc/os-release
          else
            echo "Cannot determine OS" >&2
            exit 1
          fi

          install_common_files() {
            mkdir -p /opt/madmallard-platform/security
            cat > /usr/local/bin/madmallard-audit <<'AUDIT'
          #!/usr/bin/env bash
          set -euo pipefail
          echo "Mad Mallard Platform audit - $(date -Is)"
          echo
          echo "== OS =="
          cat /etc/os-release | sed -n '1,6p'
          echo
          echo "== Uptime =="
          uptime || true
          echo
          echo "== Disk =="
          df -h / /opt 2>/dev/null || df -h /
          echo
          echo "== Listening ports =="
          ss -tulpn || true
          echo
          echo "== Docker =="
          systemctl is-active docker || true
          docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' 2>/dev/null || true
          echo
          echo "== Caddy =="
          systemctl is-active caddy 2>/dev/null || true
          journalctl -u caddy -n 20 --no-pager 2>/dev/null || true
          echo
          echo "== Fail2ban =="
          systemctl is-active fail2ban 2>/dev/null || true
          fail2ban-client status 2>/dev/null || true
          echo
          echo "== Firewall =="
          ufw status verbose 2>/dev/null || firewall-cmd --list-all 2>/dev/null || true
          echo
          echo "== SSM =="
          systemctl is-active amazon-ssm-agent 2>/dev/null || systemctl is-active snap.amazon-ssm-agent.amazon-ssm-agent 2>/dev/null || true
          AUDIT
            chmod +x /usr/local/bin/madmallard-audit

            cat > /etc/logrotate.d/madmallard-platform <<'ROTATE'
          /var/log/madmallard-*.log {
              weekly
              rotate 8
              compress
              missingok
              notifempty
          }
          ROTATE

            mkdir -p /etc/docker
            cat > /etc/docker/daemon.json <<'DOCKERJSON'
          {
            "log-driver": "json-file",
            "log-opts": {
              "max-size": "10m",
              "max-file": "5"
            },
            "no-new-privileges": true
          }
          DOCKERJSON
            systemctl restart docker 2>/dev/null || true
          }

          harden_ssh() {
            mkdir -p /etc/ssh/sshd_config.d
            cat > /etc/ssh/sshd_config.d/99-madmallard-hardening.conf <<'SSHCFG'
          PasswordAuthentication no
          PermitRootLogin no
          PubkeyAuthentication yes
          X11Forwarding no
          MaxAuthTries 4
          ClientAliveInterval 300
          ClientAliveCountMax 2
          SSHCFG
            if command -v sshd >/dev/null 2>&1; then sshd -t || true; fi
            systemctl reload ssh 2>/dev/null || systemctl reload sshd 2>/dev/null || true
          }

          configure_fail2ban() {
            mkdir -p /etc/fail2ban/jail.d
            cat > /etc/fail2ban/jail.d/madmallard-baseline.local <<'F2B'
          [DEFAULT]
          bantime = 24h
          findtime = 10m
          maxretry = 5
          backend = systemd

          [sshd]
          enabled = true
          port = ssh
          logpath = %(sshd_log)s
          F2B
            systemctl enable --now fail2ban || true
            systemctl restart fail2ban || true
          }

          if [[ "$ID" == "ubuntu" || "$ID_LIKE" == *"debian"* ]]; then
            export DEBIAN_FRONTEND=noninteractive
            apt-get update
            apt-get install -y fail2ban ufw unattended-upgrades apt-listchanges curl ca-certificates logrotate auditd
            systemctl enable --now auditd || true
            systemctl enable --now unattended-upgrades || true
            ufw --force reset
            ufw default deny incoming
            ufw default allow outgoing
            ufw allow 22/tcp
            ufw allow 80/tcp
            ufw allow 443/tcp
            ufw --force enable
          elif [[ "$ID" == "amzn" || "$ID" == "fedora" || "$ID_LIKE" == *"rhel"* ]]; then
            dnf install -y fail2ban firewalld dnf-automatic curl ca-certificates logrotate audit
            systemctl enable --now auditd || true
            systemctl enable --now firewalld || true
            firewall-cmd --permanent --add-service=ssh || true
            firewall-cmd --permanent --add-service=http || true
            firewall-cmd --permanent --add-service=https || true
            firewall-cmd --reload || true
            sed -i 's/^apply_updates.*/apply_updates = yes/' /etc/dnf/automatic.conf || true
            systemctl enable --now dnf-automatic.timer || true
          else
            echo "Unsupported OS ID=$ID ID_LIKE=${ID_LIKE:-}" >&2
            exit 1
          fi

          install_common_files
          harden_ssh
          configure_fail2ban

          if [[ "$PROFILE" == "hardened" ]]; then
            cat > /etc/sysctl.d/99-madmallard-hardening.conf <<'SYSCTL'
          net.ipv4.conf.all.rp_filter = 1
          net.ipv4.conf.default.rp_filter = 1
          net.ipv4.tcp_syncookies = 1
          net.ipv4.conf.all.accept_redirects = 0
          net.ipv4.conf.default.accept_redirects = 0
          net.ipv6.conf.all.accept_redirects = 0
          net.ipv6.conf.default.accept_redirects = 0
          net.ipv4.conf.all.send_redirects = 0
          net.ipv4.conf.default.send_redirects = 0
          kernel.randomize_va_space = 2
          SYSCTL
            sysctl --system || true
          fi

          echo "[$(date -Is)] Security baseline complete."
          /usr/local/bin/madmallard-audit || true
DOC
}

resource "aws_ssm_association" "security_baseline" {
  name = aws_ssm_document.security_baseline.name

  parameters = {
    SecurityProfile = var.security_profile
  }

  targets {
    key    = "tag:${var.target_tag_key}"
    values = [var.target_tag_value]
  }

  association_name = "${var.name}-security-baseline"
  compliance_severity = var.security_profile == "hardened" ? "HIGH" : "MEDIUM"
}

output "security_baseline_document_name" {
  value = aws_ssm_document.security_baseline.name
}

output "security_baseline_association_name" {
  value = aws_ssm_association.security_baseline.association_name
}
