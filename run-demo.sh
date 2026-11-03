#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Open Cloud Agents: Interactive Live-Fire Drill Runner
# https://github.com/open-cloud-agents/demo
# ==============================================================================

echo "=============================================================================="
echo "☁️  Open Cloud Agents: Interactive Live-Fire Drill Showcase"
echo "=============================================================================="
echo "Select an operational scenario to run:"
echo ""
echo "  [1] ☸️  Kubernetes Outage Drill (KinD): SEV-2 Billing Pods (OOMKilled, 502, CrashLoop)"
echo "  [2] 🟧 AWS IaC PR Review: Pricing API Estate (ECS, ALB, RDS, Direct Ingress Bypass)"
echo "  [3] 🟦 GCP IaC PR Review: Secure Enclave (Cloud SQL Public IP, Ingress 0.0.0.0/0)"
echo "  [4] 🔷 Azure IaC PR Review: Enterprise Hub-Spoke (Storage State Destruction, NSG)"
echo "  [5] 🚀 Run Full Multi-Cloud Audit Suite"
echo "  [q] Quit"
echo "=============================================================================="
read -r -p "👉 Choose an option (1-5, or q): " choice
echo ""

run_k8s_drill() {
  CLUSTER_NAME="demo-incident-cluster"
  SCENARIO_DIR="scenarios/billing-service-outage"

  echo "=============================================================================="
  echo "🚨 Kubernetes Outage Drill: SEV-2 Billing Microservices Outage"
  echo "=============================================================================="

  for bin in docker kind kubectl; do
    if ! command -v "$bin" >/dev/null 2>&1; then
      echo "✖ Error: '$bin' is required on PATH to run KinD drills."
      echo "  Please install Docker Desktop and KinD (e.g., 'brew install kind kubectl')."
      return 1
    fi
  done

  if ! docker info >/dev/null 2>&1; then
    echo "✖ Error: Docker daemon is not running. Please start Docker and retry."
    return 1
  fi

  if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
    echo "ℹ Using existing KinD cluster '$CLUSTER_NAME'..."
  else
    echo "🚀 Creating ephemeral KinD sandbox cluster '$CLUSTER_NAME'..."
    cat << 'EOF' | kind create cluster --name "$CLUSTER_NAME" --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
  - role: worker
EOF
  fi

  kubectl cluster-info --context "kind-${CLUSTER_NAME}" >/dev/null

  echo "💥 Deploying broken billing microservices into 'demo-billing'..."
  kubectl apply -f "$SCENARIO_DIR/00-namespace.yaml"
  kubectl apply -f "$SCENARIO_DIR/01-billing-api.yaml"
  kubectl apply -f "$SCENARIO_DIR/02-billing-cache.yaml"
  kubectl apply -f "$SCENARIO_DIR/03-billing-worker.yaml"

  echo "⏳ Waiting 6 seconds for container runtime scheduling..."
  sleep 6

  echo ""
  echo "=============================================================================="
  echo "📊 Current Incident State (Failures Active):"
  echo "=============================================================================="
  kubectl get pods,svc,endpoints -n demo-billing
  echo ""
  echo "Active Failures Observed:"
  echo "  • billing-cache:   OOMKilled (Exit Code 137) - Memory quota exceeded"
  echo "  • billing-worker:  CreateContainerConfigError - Missing ConfigMap"
  echo "  • billing-api-svc: Empty Endpoints (<none>) - Mismatched label selector"
  echo "=============================================================================="
  echo ""
  read -r -p "👉 Press [Enter] to apply the automated solution patch (or Ctrl+C to abort)..." _

  echo ""
  echo "🛠️ Applying solution patch: $SCENARIO_DIR/solution-patch.yaml..."
  kubectl apply -f "$SCENARIO_DIR/solution-patch.yaml"

  echo "⏳ Waiting 6 seconds for rolling update recovery..."
  sleep 6

  echo ""
  echo "=============================================================================="
  echo "🎉 Cluster Recovered! Live Status:"
  echo "=============================================================================="
  kubectl get pods,svc,endpoints -n demo-billing
  echo "=============================================================================="
  echo ""
  read -r -p "🧹 Press [Enter] to teardown KinD cluster (or 'k' to keep): " k_choice
  if [[ "$k_choice" =~ ^[Kk]$ ]]; then
    echo "📌 Cluster '$CLUSTER_NAME' retained."
  else
    kind delete cluster --name "$CLUSTER_NAME"
    echo "✔ Teardown complete. Zero residual state on host."
  fi
}

run_aws_iac_audit() {
  echo "=============================================================================="
  echo "🟧 AWS IaC Audit: Pricing API Estate (ECS / ALB / RDS / Security Groups)"
  echo "Target PR: scenarios/iac-aws-pricing-api/pr-feature-https-listener"
  echo "=============================================================================="
  echo ""
  echo "🔍 Simulating DevSecOps Reviewer Agent Audit..."
  sleep 1
  echo ""
  echo "=== DEVSECOPS REVIEWER VERDICT: 🔴 BLOCKED (High Risk Traps Identified) ==="
  echo ""
  echo "1. [CRITICAL] Perimeter Bypass: Direct Public Ingress on Task"
  echo "   File: scenarios/iac-aws-pricing-api/pr-feature-https-listener/security-groups.tf"
  echo "   Risk: Ingress rule 'api_task_inbound_https' opens Fargate containers to 0.0.0.0/0:443."
  echo "   Impact: Bypasses the Application Load Balancer and WAF."
  echo ""
  echo "2. [HIGH] Insecure Cryptographic Policy"
  echo "   File: scenarios/iac-aws-pricing-api/pr-feature-https-listener/load-balancer.tf"
  echo "   Risk: ssl_policy = 'ELBSecurityPolicy-2016-08' permits obsolete TLS 1.0/1.1."
  echo "   Fix: Enforce ELBSecurityPolicy-TLS13-1-2-2021-06."
  echo ""
  echo "3. [HIGH] Audit Trail Data Loss"
  echo "   File: scenarios/iac-aws-pricing-api/pr-feature-https-listener/s3.tf"
  echo "   Risk: S3 access logs bucket deleted while ALB still attempts to push health logs."
  echo "=============================================================================="
}

run_gcp_iac_audit() {
  echo "=============================================================================="
  echo "🟦 GCP IaC Audit: Secure Enclave (Cloud SQL / VPC / Firewall / GCS)"
  echo "Target PR: scenarios/iac-gcp-secure-enclave/pr-developer-fast-track"
  echo "=============================================================================="
  echo ""
  echo "🔍 Simulating DevSecOps Reviewer Agent Audit..."
  sleep 1
  echo ""
  echo "=== DEVSECOPS REVIEWER VERDICT: 🔴 BLOCKED (Critical Perimeter Exposure) ==="
  echo ""
  echo "1. [CRITICAL] Unrestricted Database & SSH Firewall Rule"
  echo "   File: scenarios/iac-gcp-secure-enclave/pr-developer-fast-track/firewall.tf"
  echo "   Risk: Rule 'fw-enclave-allow-public-debug' allows 0.0.0.0/0 on ports 5432 and 22."
  echo ""
  echo "2. [CRITICAL] Cloud SQL Public IP & Weak SSL"
  echo "   File: scenarios/iac-gcp-secure-enclave/pr-developer-fast-track/cloud-sql.tf"
  echo "   Risk: ipv4_enabled = true with authorized_networks = 0.0.0.0/0."
  echo ""
  echo "3. [HIGH] Public Data Exfiltration on Storage Bucket"
  echo "   File: scenarios/iac-gcp-secure-enclave/pr-developer-fast-track/storage.tf"
  echo "   Risk: roles/storage.objectViewer granted to allUsers."
  echo "=============================================================================="
}

run_azure_iac_audit() {
  echo "=============================================================================="
  echo "🔷 Azure IaC Audit: Enterprise Hub-Spoke (Storage / Flexible Server / NSG)"
  echo "Target PR: scenarios/iac-azure-enterprise-hub-spoke/pr-developer-hotfix"
  echo "=============================================================================="
  echo ""
  echo "🔍 Simulating DevSecOps Reviewer Agent Audit..."
  sleep 1
  echo ""
  echo "=== DEVSECOPS REVIEWER VERDICT: 🔴 BLOCKED (State Destruction Traps) ==="
  echo ""
  echo "1. [CRITICAL] State Destruction Trap (forces replacement)"
  echo "   File: scenarios/iac-azure-enterprise-hub-spoke/pr-developer-hotfix/storage.tf"
  echo "   Risk: Renaming 'stpricingprodeu2' to 'stpricingprodeu2v2' deletes all customer blobs."
  echo ""
  echo "2. [CRITICAL] Management Port Exposure in NSG"
  echo "   File: scenarios/iac-azure-enterprise-hub-spoke/pr-developer-hotfix/networking.tf"
  echo "   Risk: Security rule 'AllowPublicRDPAndSSHDebug' allows 0.0.0.0/0 on ports 3389 and 22."
  echo ""
  echo "3. [HIGH] PostgreSQL Public Endpoint Bypass"
  echo "   File: scenarios/iac-azure-enterprise-hub-spoke/pr-developer-hotfix/database.tf"
  echo "   Risk: public_network_access_enabled = true bypasses Private DNS Zone."
  echo "=============================================================================="
}

case "$choice" in
  1) run_k8s_drill ;;
  2) run_aws_iac_audit ;;
  3) run_gcp_iac_audit ;;
  4) run_azure_iac_audit ;;
  5)
    run_aws_iac_audit
    echo ""
    run_gcp_iac_audit
    echo ""
    run_azure_iac_audit
    ;;
  [Qq]*)
    echo "Exiting demo."
    exit 0
    ;;
  *)
    echo "Invalid option. Exiting."
    exit 1
    ;;
esac
