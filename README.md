# DevOps Engineer — Practical Test

Welcome.

This test simulates a small production-style DevOps codebase. It includes an application
service, Kubernetes deployment configuration, Terraform infrastructure code, and a Chef cookbook
used for host configuration.

The codebase intentionally contains a mix of broken configuration, deployment issues, validation
errors, and production-readiness concerns. Your goal is not only to make things work, but also to
show how you investigate problems, prioritise fixes, and communicate risks clearly.

> ⚠️ **Do not fork this repository.** Clone it and work in your own private copy — you'll submit a
> link to that clone when you're done (see **[Submission](#submission)** at the bottom).

The test is split into **three independent tasks**, one per top-level folder:

| Task | Folder | What you do |
|------|--------|-------------|
| 1. **Kubernetes** | [`kubernetes/`](./kubernetes/) | Fix the build/deploy issues and **deploy** the service into the sandbox cluster. |
| 2. **Terraform** | [`terraform/`](./terraform/) | Fix the issues in the plan and `terraform validate`. |
| 3. **Chef** | [`chef/`](./chef/) | Fix the issues in the cookbook **in code** |

**This codebase has problems** — some stop it from building or deploying, some are things you'd
never ship to production, and some are subtle. For every task: **review, debug, and fix** as much
as you can, then **write down everything you spot in [`FINDINGS.md`](./FINDINGS.md)** — even issues
you don't have time to fix. We score what you *find and understand*, not just what you fix.

> There is deliberately **more here than anyone can finish** in the time. Don't rush to "done" —
> prioritise, explain your reasoning, and flag risks. Breadth of detection and depth of
> understanding matter more than a green board.

---

## Task 1 — Kubernetes (fix & deploy)

The container build and the Kubernetes deployment of `api-service`. Everything for this task lives
under [`kubernetes/`](./kubernetes/):

- **`kubernetes/app/`** — the service itself + its `Dockerfile`.
- **`kubernetes/helm-charts/api-service/`** — a Helm chart for the workload.
- **`kubernetes/gitops/sandbox/`** — Kustomize that renders the chart for the sandbox, plus the
  MongoDB it talks to (already running in your cluster).

**Your goal:** get the service **building and deploying** into the sandbox cluster first, then
**harden** it.

Record your findings in [`FINDINGS.md`](./FINDINGS.md).

### Your sandbox (already set up on the VM)

- `docker`, `kind`, `kubectl`, `helm`, `kustomize`, `terraform` are installed.
- A multi-node `kind` cluster is running.
- MongoDB (a single-member replica set `rs0`) is running in the `data` namespace.
- An `apps` namespace exists for the workload.
- You build and load the `api-service` image yourself (see below) once the `Dockerfile` builds.

### Commands

```bash
# Make sure you're pointed at the local kind cluster (never a remote one):
kubectl config use-context kind-devops-test

# Build the image (after you fix the Dockerfile), then load it into kind:
docker build -t api-service:sandbox ./kubernetes/app
kind load docker-image api-service:sandbox --name devops-test

# Render + deploy the workload (the chart lives above the overlay, so allow that):
kubectl kustomize --enable-helm --load-restrictor LoadRestrictionsNone \
  kubernetes/gitops/sandbox/api-service | kubectl apply -f -
kubectl -n apps get pods
kubectl -n apps logs deploy/api-service

# Inspect or reset the cluster if needed:
kind get clusters                          # confirms the cluster exists
kind delete cluster --name devops-test     # removes the cluster AND its kubeconfig entries
```

---

## Task 2 — Terraform (fix & validate)

A module + sandbox config that would provision the MongoDB hosts in GCP. Everything for this task
lives under [`terraform/`](./terraform/):

- **`terraform/modules/mongodb-instance/`** — a reusable module for the MongoDB instances.
- **`terraform/sandbox/mongodb-api-service/`** — the sandbox config that calls the module.

**Your goal:** **review and fix** the issues in the configuration so it validates cleanly, and note
what else you'd change for production. You have **no cloud access** — get it to `validate`; you
**don't need to run `terraform apply`**. Record your findings in [`FINDINGS.md`](./FINDINGS.md).

### Commands

```bash
cd terraform/sandbox/mongodb-api-service
terraform init -backend=false
terraform validate
```

---

## Task 3 — Chef (fix in code — do not converge)

A configuration-management cookbook for the MongoDB hosts. Everything for this task lives under
[`chef/`](./chef/):

- **`chef/cookbooks/mongodb/`** — the cookbook that installs and configures MongoDB on the hosts.

**Your goal:** **review and fix** the cookbook **in code** — recipe, attributes, and template — and
explain what's wrong and why. There is **no live host**: **you don't need to run `chef-client` / converge**.
Fix in the files and record your findings in [`FINDINGS.md`](./FINDINGS.md).

---

## Submission

1. Submit the link to your **cloned** repo by replying to the email you received this test link from.

Good luck.
