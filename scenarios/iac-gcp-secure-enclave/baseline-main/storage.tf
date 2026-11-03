resource "google_storage_bucket" "audit_vault" {
  name                     = "bkt-enclave-audit-vault-${var.project_id}"
  location                 = var.region
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  retention_policy {
    is_locked        = false
    retention_period = 2592000 # 30 days
  }
}
