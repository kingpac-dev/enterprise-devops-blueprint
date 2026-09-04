# ==============================================================================
# Enterprise DevOps Blueprint — HashiCorp Vault Agent Configuration
# ==============================================================================
# This template demonstrates how a client service or host uses Vault Agent to:
# 1. Authenticate to HashiCorp Vault using AppRole
# 2. Automatically manage and renew Vault tokens
# 3. Retrieve dynamic secrets and render them into protected local files
# 4. Trigger service reload upon secret rotation
#
# References:
#   - docs/07-security/secrets-management.md
#   - templates/security/vault/vault-integration-guide.md
# ==============================================================================

pid_file = "/var/run/vault-agent.pid"

# Vault Server Address
vault {
  address = "https://vault.internal.devops.local:8200"
  ca_cert = "/etc/vault/ca.crt"
  retry {
    num_retries = 5
  }
}

# Auto-Authentication using AppRole
auto_auth {
  method {
    type = "approle"

    config = {
      role_id_file_path                   = "/etc/vault/role-id"
      secret_id_file_path                 = "/etc/vault/secret-id"
      remove_secret_id_file_after_reading = false
    }
  }

  sink {
    type = "file"
    config = {
      path = "/var/run/vault-token"
      mode = 0600
    }
  }
}

# Dynamic Secret Template Rendering
template {
  destination = "/opt/app/config/.env.runtime"
  perms       = "0600"

  # Render database credentials with automatic lease rotation
  contents = <<EOF
{{ with secret "database/creds/app-rw-role" }}
DB_USER="{{ .Data.username }}"
DB_PASSWORD="{{ .Data.password }}"
{{ end }}
{{ with secret "secret/data/production/api-keys" }}
EXTERNAL_API_KEY="{{ .Data.data.api_key }}"
{{ end }}
EOF

  # Command executed when the template changes (re-rendered due to lease rotation)
  # Example: reload Nginx or notify container
  exec {
    command = ["kill", "-HUP", "1"]
  }
}
