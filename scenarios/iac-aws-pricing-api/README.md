# ☁️ AWS IaC Scenario: Pricing API Estate (ECS, ALB, RDS, VPC)

This scenario contains a real-world enterprise AWS infrastructure codebase managed by Terraform.

---

## 📋 Scenario Overview

* **Cloud Provider:** Amazon Web Services (AWS)
* **Workload:** High-Throughput Pricing API
* **Architecture:**
  * **Networking:** VPC (`10.20.0.0/22`), public & private subnets fanned across availability zones, Internet Gateway, and Route Tables.
  * **Compute:** ECS Cluster with AWS Fargate serverless tasks running the containerized API.
  * **Load Balancing:** Application Load Balancer (ALB) with HTTP and HTTPS listeners, Route 53 DNS validation, and ACM certificates.
  * **Data Tier:** AWS RDS PostgreSQL instance with automated password rotation and dedicated DB subnet groups.
  * **Security:** Layered security groups isolating ALB ingress from ECS task ingress.

---

## 🔍 The Pull Request (`feature/https-listener`)

A developer submitted a pull request titled *"Serve pricing API over HTTPS and redirect HTTP traffic"*.

Compare the two directories:
* [`baseline-main/`](baseline-main/): The stable, production-approved baseline.
* [`pr-feature-https-listener/`](pr-feature-https-listener/): The developer's proposed PR branch.

### Critical Invariants Flagged by Open Cloud Agents:

| File | Severity | Invariant / Finding | Impact |
|---|---|---|---|
| `security-groups.tf` | **CRITICAL** | **Direct Ingress Bypass:** Ingress rule `api_task_inbound_https` exposes Fargate containers to `0.0.0.0/0:443`. | Bypasses the Application Load Balancer, exposing the API directly to the public internet without WAF or DDoS protection. |
| `load-balancer.tf` | **HIGH** | **Insecure Cryptographic Policy:** Configured with `ELBSecurityPolicy-2016-08`. | Allows obsolete TLS 1.0/1.1 protocols and weak CBC/SHA-1 ciphers. Violates SOC 2 & PCI-DSS. |
| `s3.tf` | **HIGH** | **Audit Trail State Deletion:** S3 access log bucket file was deleted. | Destroys the ALB access logging bucket while `load-balancer.tf` still attempts to write health logs. |
| `rds.tf` | **MEDIUM** | **Database Renaming:** Changed `db_name` from `pricing` to `pricing_api`. | Modifying database name on existing RDS instances triggers downtime and potential replacement. |

---

## 🤖 Running Autonomous DevSecOps Audit

Run the Open Cloud Agents audit directly from your terminal:

```bash
ocagents run --task "Audit Terraform PR in scenarios/iac-aws-pricing-api/pr-feature-https-listener for security vulnerabilities, perimeter bypass, and state destruction risks"
```

### LocalStack Emulation (Optional)

If you wish to plan or apply this infrastructure locally without an AWS account:

```bash
# 1. Start LocalStack:
cd scenarios/iac-aws-pricing-api/localstack
docker compose up -d

# 2. Use tflocal (or standard terraform configured with http://localhost:4566):
cd ../baseline-main
tflocal init
tflocal plan
```
