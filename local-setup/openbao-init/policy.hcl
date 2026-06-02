# OpenBao policy for the openbao-operator.
# Grants the operator permissions to manage namespaces, policies, and auth methods
# needed to provision tenants.
#
# Paths are defined at two levels:
#   1. Root namespace — for creating/deleting tenant namespaces
#   2. Child namespaces (using + glob) — for managing resources inside tenant namespaces

# --- Root namespace operations ---

# Manage OpenBao namespaces (create/delete tenant namespaces)
path "sys/namespaces/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Manage policies in the root namespace
path "sys/policy/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Manage auth methods in the root namespace
path "sys/auth/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Configure auth method roles and settings in the root namespace
path "auth/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# --- Child namespace operations (one level deep) ---
# The + glob matches any single path segment (i.e., the child namespace name).
# This allows the operator to manage resources inside tenant namespaces.

# Manage policies inside child namespaces
path "+/sys/policy/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# Manage auth methods inside child namespaces
path "+/sys/auth/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Configure auth method roles and settings inside child namespaces
path "+/auth/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
