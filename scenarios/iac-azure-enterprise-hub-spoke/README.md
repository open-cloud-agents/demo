# 🔷 Azure IaC Scenario: Enterprise Hub-Spoke & Flexible PostgreSQL

This scenario models an enterprise Microsoft Azure Hub-Spoke infrastructure estate managed with Terraform (`azurerm`).

---

## 📋 Scenario Overview

* **Cloud Provider:** Microsoft Azure
* **Architecture:**
  * **Networking:** Hub VNet with delegated subnet (`Microsoft.DBforPostgreSQL/flexibleServers`) and Network Security Group (NSG) isolation.
  * **Database:** Azure Database for PostgreSQL Flexible Server integrated with Private DNS Zone (`privatelink.postgres.database.azure.com`).
  * **Storage:** Enterprise Storage Account with TLS 1.2 minimum, ZRS replication, and zero public access.

---

## 🔍 The Pull Request (`pr-developer-hotfix`)

A developer submitted a PR aiming to connect a remote monitoring utility and add temporary debug access.

Compare:
* [`baseline-main/`](baseline-main/): Hardened zero-trust baseline.
* [`pr-developer-hotfix/`](pr-developer-hotfix/): The proposed PR.

### Critical Invariants Flagged by Open Cloud Agents:

| File | Severity | Invariant / Finding | Impact |
|---|---|---|---|
| `storage.tf` | **CRITICAL** | **State Destruction Trap:** Renamed `name` from `stpricingprodeu2` to `stpricingprodeu2v2`. | In Terraform, changing `storage_account_name` triggers `forces replacement`, permanently destroying the storage account and all customer data. |
| `networking.tf` | **CRITICAL** | **Management Port Exposure:** Added NSG rule exposing RDP (3389) and SSH (22) to `0.0.0.0/0`. | Opens administrative ports across the database subnet to brute-force credential stuffing and ransomware attacks. |
| `database.tf` | **HIGH** | **Database Public Network Exposure:** Set `public_network_access_enabled = true`. | Bypasses Private DNS zone resolution and exposes database listener to the public internet. |

---

## 🤖 Running Autonomous DevSecOps Audit

```bash
ocagents run --task "Audit Terraform PR in scenarios/iac-azure-enterprise-hub-spoke/pr-developer-hotfix for state destruction traps and network security violations"
```
