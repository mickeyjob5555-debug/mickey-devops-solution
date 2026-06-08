#!/usr/bin/env bash
#
# Turnkey sandbox bootstrap for the DevOps practical test.
# Bakes the state the candidate starts from. Run once when building the VM image.
#
#   - creates a multi-node kind cluster
#   - pre-caches the terraform google provider (so `terraform validate` works offline)
#   - creates the `apps` namespace for the workload
#   - deploys a single-member MongoDB replica set (rs0) in the `data` namespace
#
# It does NOT build/deploy api-service — the candidate does that after fixing the repo.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CLUSTER_NAME="${CLUSTER_NAME:-devops-test}"
KCTX="kind-${CLUSTER_NAME}"

# SAFETY: every kubectl call below is pinned to the local kind context so this script
# can never touch a remote/production cluster, whatever the ambient kubeconfig context is.
kc() { kubectl --context "${KCTX}" "$@"; }

echo "==> Creating kind cluster '${CLUSTER_NAME}' (multi-node)"
kind create cluster --name "${CLUSTER_NAME}" --config "${REPO_ROOT}/kubernetes/vm-setup/kind-config.yaml"

# Hard fail if the kind context didn't get created (don't fall back to ambient context).
kubectl config get-contexts "${KCTX}" >/dev/null 2>&1 || {
  echo "ERROR: kind context '${KCTX}' not found; refusing to continue." >&2
  exit 1
}

echo "==> Pre-caching terraform provider plugins"
( cd "${REPO_ROOT}/terraform/sandbox/mongodb-api-service" && terraform init -backend=false -input=false ) || \
  echo "    (provider pre-cache failed — candidate can re-run 'terraform init -backend=false')"

echo "==> Creating 'apps' namespace"
kc create namespace apps --dry-run=client -o yaml | kc apply -f -

echo "==> Deploying MongoDB (single-member replica set rs0) in 'data'"
kc apply -f "${REPO_ROOT}/kubernetes/gitops/sandbox/mongodb/mongodb.yaml"
kc -n data rollout status statefulset/mongodb --timeout=180s

echo "==> Initiating the replica set"
kc -n data exec mongodb-0 -- mongosh --quiet --eval '
  try { rs.status() } catch (e) {
    rs.initiate({_id: "rs0", members: [{_id: 0, host: "mongodb-0.mongodb.data.svc.cluster.local:27017"}]})
  }'

echo "==> Sandbox ready. MongoDB is up in the 'data' namespace; inspect the cluster to wire it up."
