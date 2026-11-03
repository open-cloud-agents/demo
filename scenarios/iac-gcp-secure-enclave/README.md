# 🌐 GCP IaC Scenario: Secure Enclave & Private Cloud SQL

This scenario models an enterprise Google Cloud Platform (GCP) private environment managed by Terraform.

---

## 📋 Scenario Overview

* **Cloud Provider:** Google Cloud Platform (GCP)
* **Architecture:**
  * **VPC Network:** Custom VPC with Private Google Access, Cloud Router, and Cloud NAT for zero-external-IP internet egress.
  * **Database:** Private Cloud SQL PostgreSQL with private IP peering (`servicenetworking.googleapis.com`) and strictly enforced TLS.
  * **Storage:** Immutable Audit Vault bucket with Uniform Bucket-Level Access and 30-day retention.
  * **Firewall:** Strict internal subnet rules restricting database ports to internal service ranges.

---

## 🔍 The Pull Request (`pr-developer-fast-track`)

A developer submitted a PR aiming to speed up developer testing with temporary external access.

Compare:
* [`baseline-main/`](baseline-main/): Hardened zero-trust baseline.
* [`pr-developer-fast-track/`](pr-developer-fast-track/): The proposed PR.

### Critical Invariants Flagged by Open Cloud Agents:

| File | Severity | Invariant / Finding | Impact |
|---|---|---|---|
| `firewall.tf` | **CRITICAL** | **Unrestricted Perimeter Exposure:** `allow_public_debug` exposes PostgreSQL (port 5432) and SSH (port 22) to `0.0.0.0/0`. | Directly exposes internal database cluster to unauthenticated internet scanning and brute-force attacks. |
| `cloud-sql.tf` | **CRITICAL** | **Database Public IP & Unencrypted Mode:** Assigned `ipv4_enabled = true`, authorized `0.0.0.0/0`, and relaxed `ssl_mode`. | Bypasses VPC private service peering and allows plaintext credentials over the public web. |
| `storage.tf` | **HIGH** | **Public Data Exfiltration:** IAM member grants `roles/storage.objectViewer` to `allUsers`. | Makes private audit logs and database exports publicly readable without authentication. |

---

## 🤖 Running Autonomous DevSecOps Audit

```bash
ocagents run --task "Audit Terraform PR in scenarios/iac-gcp-secure-enclave/pr-developer-fast-track for security perimeter bypass and IAM leaks"
```
