# 🛡️ DevSecOps Reviewer Audit Report

**Target:** `scenarios/iac-aws-pricing-api/pr-feature-https-listener` (`feature/https-listener`)  
**Scope:** HTTPS listener, HTTP redirect, and related infrastructure changes  
**DevOps Domains:** IaC State Safety, Perimeter Security, Cryptography  
**Verdict:** 🛑 **REQUEST CHANGES (DO NOT MERGE)**

---

## 1. Executive Summary

The DevSecOps Reviewer conducted a comprehensive pre-merge audit on the proposed Terraform infrastructure changes. The PR introduces critical operational and security risks:

* **Critical Data Destruction Trap:** Changing `db_name` on the RDS instance forces database replacement while `skip_final_snapshot = true` is set, risking irreversible production data loss.
* **Logging Disruption:** Removing the managed access-log bucket (`s3.tf`) conflicts with ALB logging, which remains enabled.
* **Deployment Race Condition:** ECS service depends on the redirecting HTTP listener rather than the forwarding HTTPS listener.
* **Perimeter Security Bypass:** The task security group permits direct public ingress on port 443, bypassing the Application Load Balancer and WAF.

---

## 2. Categorized Detailed Findings

### 🚨 Critical: RDS Database Name Change Forces Production Data Destruction
* **Affected Area:** `rds.tf:16`
* **Finding:** The PR modifies `db_name` from `"pricing"` to `"pricing_api"`. In AWS RDS, changing the database name forces replacement of the database instance. Combined with `skip_final_snapshot = true`, this destroys existing tables with zero backup.
* **Remediation:** Revert the `db_name` change. Add `lifecycle { prevent_destroy = true }`.

### ⚠️ High: Access Logging References Deleted S3 Bucket
* **Affected Area:** `load-balancer.tf:8`, `load-balancer.tf:14`; PR deletes `s3.tf`.
* **Finding:** ALB access and health-check logging remain enabled, but the PR deletes the Terraform-managed bucket and IAM delivery policy.
* **Impact:** Deployment failure during apply, or immediate loss of ALB compliance audit trails.
* **Remediation:** Restore `s3.tf` and ensure the bucket policy grants delivery for both `alb` and `health` prefixes.

### ⚠️ High: ECS Deployment Race Condition with ALB Listener
* **Affected Area:** `ecs.tf:105`, `load-balancer.tf:97`
* **Finding:** `aws_ecs_service` depends on `aws_lb_listener.http`, which now only performs an HTTP 301 redirect. It does not depend on `aws_lb_listener.https`, which associates the target group.
* **Impact:** ECS may attempt target registration before the target group is associated with an active listener, causing initial deployment failure.
* **Remediation:** Update dependency to `depends_on = [aws_lb_listener.https]`.

### ⚠️ Medium: Direct Public Ingress Bypass on Task ENIs
* **Affected Area:** `security-groups.tf:77`
* **Finding:** Rule `api_task_inbound_https` permits `0.0.0.0/0:443` directly into ECS tasks.
* **Impact:** In AWS Fargate with public IPs, this allows clients to bypass the ALB, ACM certificates, WAF filtering, and access logging.
* **Remediation:** Remove `api_task_inbound_https`. Retain strictly internal ingress from the ALB security group.

### 🟡 Low: Outdated Cryptographic TLS Security Policy
* **Affected Area:** `load-balancer.tf:102`
* **Finding:** Configured with `ELBSecurityPolicy-2016-08`.
* **Impact:** Permits deprecated TLS 1.0/1.1 protocols and weak CBC/SHA-1 ciphers, violating PCI-DSS and SOC 2.
* **Remediation:** Upgrade to `ELBSecurityPolicy-TLS13-1-2-2021-06`.

---

## 3. Surgical Remediation Diffs

### 1. `rds.tf` (Prevent Data Destruction)
```diff
-  db_name           = "pricing_api"
+  db_name           = "pricing"

+  lifecycle {
+    prevent_destroy = true
+  }
```

### 2. `ecs.tf` (Fix Dependency Ordering)
```diff
-  depends_on = [aws_lb_listener.http]
+  depends_on = [aws_lb_listener.https]
```

### 3. `security-groups.tf` (Eliminate Public Ingress Bypass)
```diff
- resource "aws_vpc_security_group_ingress_rule" "api_task_inbound_https" {
-   security_group_id = aws_security_group.api_task.id
-   cidr_ipv4         = "0.0.0.0/0"
-   ip_protocol       = "tcp"
-   from_port         = 443
-   to_port           = 443
- }
```

### 4. `load-balancer.tf` (Modernize TLS Policy)
```diff
-  ssl_policy        = "ELBSecurityPolicy-2016-08"
+  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
```
