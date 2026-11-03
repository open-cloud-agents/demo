# 🚀 Open Cloud Agents: Live-Fire Incident & Triage Sandbox

[![KinD CI Matrix](https://github.com/open-cloud-agents/demo/actions/workflows/kind-matrix.yml/badge.svg)](https://github.com/open-cloud-agents/demo/actions/workflows/kind-matrix.yml)
[![Cloud Guardrails](https://github.com/open-cloud-agents/demo/actions/workflows/guardrails.yml/badge.svg)](https://github.com/open-cloud-agents/demo/actions/workflows/guardrails.yml)
[![Open Cloud Agents](https://img.shields.io/badge/Orchestrator-Open%20Cloud%20Agents%20v1.3-00e5ff)](https://github.com/open-cloud-agents/ocagents)
[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)

Welcome to the official **interactive demo sandbox** for [Open Cloud Agents](https://github.com/open-cloud-agents/ocagents). 

This repository allows platform engineers, SREs, and cloud architects to experience **autonomous multi-agent incident triage and remediation** live on real Kubernetes clusters without modifying production systems.

---

## ⚡ 60-Second Fast Track (Interactive Drill)

You don't need cloud credentials or a remote cluster. All you need is **Docker** and **KinD**.

```bash
# 1. Clone this demo repository:
git clone https://github.com/open-cloud-agents/demo.git
cd demo

# 2. Run the interactive live-fire incident drill:
./run-demo.sh
```

The script will automatically:
1. Boot an ephemeral multi-node Kubernetes cluster via KinD.
2. Deploy a deliberately broken multi-service payment workload into namespace `demo-billing`.
3. Highlight active failures (`OOMKilled`, `CrashLoopBackOff`, and `502 Bad Gateway`).
4. Guide you through agent triage and apply the verified solution patch.
5. Tear down the cluster cleanly with zero host residue.

---

## 🔬 Featured Incident Drill: SEV-2 Billing Outage

This scenario simulates a production cascade failure across three microservices in `demo-billing`, mapped directly to our **25-Point Kubernetes Production Failure Matrix**:

```
                              [ Ingress Controller ]
                                         │
                                   HTTP 502 (Empty)
                                         ▼
                             [ billing-api-service ]
                           (Mismatched Label Selector)
                                    ✖       ✖
                   ┌────────────────┴───────┴────────────────┐
                   ▼                                         ▼
          [ billing-cache ]                         [ billing-worker ]
      (OOMKilled - Exit Code 137)               (CreateContainerConfigError)
    Heap: 30MiB | Cgroup Limit: 16MiB            Missing 'billing-worker-config'
```

### The 3 Injected Failure States:

| Microservice | Failure State | Matrix Code | Root Cause & Diagnostics |
|---|---|---|---|
| **`billing-api-svc`** | `Service has no endpoints` | **State 17** | Service selector `app: billing-api-v2` mismatches pod label `app: billing-api`. Ingress yields `HTTP 502 Bad Gateway`. |
| **`billing-cache`** | `OOMKilled (Exit Code 137)` | **State 02** | Workload allocates 30MiB while container memory limit is capped at 16MiB, triggering cgroup SIGKILL. |
| **`billing-worker`** | `CreateContainerConfigError` | **State 09** | Pod references environment variable `BATCH_SIZE` from non-existent ConfigMap `billing-worker-config`. |

---

## 🤖 Running Autonomous Agent Triage

If you have the [`ocagents`](https://github.com/open-cloud-agents/ocagents) CLI installed:

```bash
# 1. Boot the scenario into a dedicated KinD sandbox:
ocagents sandbox --scenario scenarios/billing-service-outage/ --keep-cluster

# 2. Trigger the autonomous SRE triage pipeline:
ocagents run --task "Diagnose and resolve all failing pods and ingress 502s in namespace demo-billing"
```

### What happens behind the scenes:
1. **SRE Reliability Engineer Persona:**
   - Detects `Exit Code 137` and references `skills/devops/kubernetes/k8s-pod-troubleshooting`.
   - Identifies container memory limits vs. heap allocation.
   - Diagnoses empty endpoints on `billing-api-service`.
2. **DevSecOps Reviewer Persona:**
   - Audits proposed manifest changes against zero-trust invariants and resource quotas.
   - Emits surgical fix [`solution-patch.yaml`](scenarios/billing-service-outage/solution-patch.yaml).
3. **Recovery Verification:**
   - Applying `kubectl apply -f scenarios/billing-service-outage/solution-patch.yaml` immediately restores all pods to `Running (1/1)` and populates active endpoints.

---

## 🛡️ Multi-Version KinD CI Pipeline

This demo repository includes automated GitHub Actions testing across a Kubernetes version matrix:

* **Kubernetes `v1.31.0`**
* **Kubernetes `v1.30.2`**
* **Kubernetes `v1.29.4`**

Check the live status under [`.github/workflows/kind-matrix.yml`](.github/workflows/kind-matrix.yml).

---

## 📚 Ecosystem & References

* **Core Framework:** [open-cloud-agents/ocagents](https://github.com/open-cloud-agents/ocagents)
* **Official Documentation:** [open-cloud-agents.github.io/ocagents](https://open-cloud-agents.github.io/ocagents/)
* **Reusable Actions:** [open-cloud-agents/pipelines](https://github.com/open-cloud-agents/pipelines)
* **Author:** Ibrahim Jimoh ([LinkedIn](https://www.linkedin.com/in/ijimoh))
* **License:** Apache 2.0

