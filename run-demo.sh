#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Open Cloud Agents: Interactive Live-Fire Incident Drill
# https://github.com/open-cloud-agents/demo
# ==============================================================================

CLUSTER_NAME="demo-incident-cluster"
SCENARIO_DIR="scenarios/billing-service-outage"

echo "=============================================================================="
echo "🚨 Open Cloud Agents: Live-Fire Incident Response Drill"
echo "=============================================================================="
echo "Scenario: SEV-2 Billing Outage (OOMKilled, CrashLoop, 502 Bad Gateway)"
echo "Target Namespace: demo-billing"
echo "=============================================================================="
echo ""

# 1. Check prerequisites
for bin in docker kind kubectl; do
  if ! command -v "$bin" >/dev/null 2>&1; then
    echo "✖ Error: '$bin' is required on PATH to run this demo."
    echo "  Please install Docker Desktop and KinD (e.g., 'brew install kind kubectl')."
    exit 1
  fi
done

if ! docker info >/dev/null 2>&1; then
  echo "✖ Error: Docker daemon is not running. Please start Docker and retry."
  exit 1
fi

# 2. Check if cluster already exists
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

# Ensure kubeconfig is pointed to demo cluster
kubectl cluster-info --context "kind-${CLUSTER_NAME}" >/dev/null

# 3. Deploy broken scenario
echo ""
echo "💥 Deploying broken billing microservices into 'demo-billing'..."
kubectl apply -f "$SCENARIO_DIR/00-namespace.yaml"
kubectl apply -f "$SCENARIO_DIR/01-billing-api.yaml"
kubectl apply -f "$SCENARIO_DIR/02-billing-cache.yaml"
kubectl apply -f "$SCENARIO_DIR/03-billing-worker.yaml"

echo ""
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
echo "🤖 Run Autonomous SRE Agent Triage:"
echo "   ocagents run --task \"Diagnose and resolve all failing pods in namespace demo-billing\""
echo ""
read -r -p "👉 Press [Enter] to apply the automated solution patch (or Ctrl+C to abort)..." _

echo ""
echo "🛠️ Applying solution patch: $SCENARIO_DIR/solution-patch.yaml..."
kubectl apply -f "$SCENARIO_DIR/solution-patch.yaml"

echo ""
echo "⏳ Waiting 6 seconds for rolling update recovery..."
sleep 6

echo ""
echo "=============================================================================="
echo "🎉 Cluster Recovered! Live Status:"
echo "=============================================================================="
kubectl get pods,svc,endpoints -n demo-billing
echo "=============================================================================="
echo ""
read -r -p "🧹 Press [Enter] to teardown and delete the KinD sandbox (or 'k' to keep): " choice
if [[ "$choice" =~ ^[Kk]$ ]]; then
  echo "📌 Cluster '$CLUSTER_NAME' retained. Run 'kind delete cluster --name $CLUSTER_NAME' when done."
else
  echo "🧹 Deleting KinD cluster '$CLUSTER_NAME'..."
  kind delete cluster --name "$CLUSTER_NAME"
  echo "✔ Teardown complete. Zero residual state on host."
fi
