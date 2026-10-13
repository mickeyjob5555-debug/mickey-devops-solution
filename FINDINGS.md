# Findings

Record of every issue I found. Severity tags: blocker (stops build or deploy), should-fix (production problem), nice-to-have (improvement).

## Task 1 - Kubernetes

| # | File / area | Issue | Severity | Fixed? | Notes |
|---|---|---|---|---|---|
| 1 | `kubernetes/app/Dockerfile` | Base image tag `node:18-slimm` is a typo, image will not build | blocker | yes | Changed to `node:18-slim` |
| 2 | `kubernetes/app/Dockerfile` | `MONGO_PASSWORD` hardcoded as env var, leaks via `docker inspect` | should-fix | yes | Removed. Should come from a K8s Secret at runtime |
| 3 | `kubernetes/app/Dockerfile` | `vim` and `build-essential` in runtime image, bloat and attack surface | nice-to-have | yes | Removed, kept only curl |
| 4 | `kubernetes/app/Dockerfile` | `apt-get install` without `--no-install-recommends`, no cleanup of `/var/lib/apt/lists` | nice-to-have | yes | Added flag and cleanup |
| 5 | `kubernetes/app/Dockerfile` | `COPY . .` before `npm install` breaks layer caching | should-fix | yes | Copy `package.json` first, install, then copy `server.js` |
| 6 | `kubernetes/app/Dockerfile` | No `USER`, container runs as root | should-fix | yes | Added `USER node` |
| 7 | `kubernetes/app/` | No `.dockerignore`, `COPY . .` copies `node_modules` and `.git` | nice-to-have | no | Would add `.dockerignore` |
| 8 | `kubernetes/app/Dockerfile` | Floating tag `node:18-slim` instead of digest | nice-to-have | no | Would pin to a digest for reproducibility |
| 9 | `kubernetes/helm-charts/api-service/values.yaml` | `pullPolicy: Always` with tag `latest`, fails in kind with `ErrImagePull` | blocker | yes | Changed to `IfNotPresent` and tag `sandbox` |
| 10 | `kubernetes/helm-charts/api-service/values.yaml` | Mongo URI points at `mongodb-0.mongodb.svc.cluster.local`, wrong namespace | blocker | yes | Changed to `mongodb-0.mongodb.data.svc.cluster.local` |
| 11 | `kubernetes/helm-charts/api-service/values.yaml` | Mongo URI missing `replicaSet=rs0` | blocker | yes | Added the parameter |
| 12 | `kubernetes/helm-charts/api-service/values.yaml` | Mongo URI contains a password but sandbox has no auth | should-fix | yes | Removed the password |
| 13 | `kubernetes/helm-charts/api-service/values.yaml` | No resource requests or limits, pod is BestEffort | should-fix | yes | Added requests and limits |
| 14 | `kubernetes/helm-charts/api-service/values.yaml` | `replicaCount: 1`, no HA | should-fix | yes | Set to 2 |
| 15 | `kubernetes/helm-charts/api-service/values.yaml` | PDB disabled | should-fix | yes | Enabled, `minAvailable: 1` |
| 16 | `kubernetes/helm-charts/api-service/templates/deployment.yaml` | YAML indentation wrong, `ports`/`env`/probes are siblings of container, manifest invalid | blocker | yes | Fixed indentation |
| 17 | `kubernetes/helm-charts/api-service/templates/deployment.yaml` | `livenessProbe` on `/healthz` depends on MongoDB, restart loop on DB hiccup | should-fix | yes | Liveness uses `/`, readiness stays on `/healthz` |
| 18 | `kubernetes/helm-charts/api-service/templates/deployment.yaml` | No `startupProbe`, slow start can be killed by liveness | should-fix | yes | Added startupProbe on `/` |
| 19 | `kubernetes/helm-charts/api-service/templates/deployment.yaml` | No `securityContext` at pod or container level | should-fix | yes | Added `runAsNonRoot`, `runAsUser`, `runAsGroup`, `fsGroup`, `allowPrivilegeEscalation: false`, drop ALL caps |
| 20 | `kubernetes/helm-charts/api-service/templates/deployment.yaml` | No anti-affinity, both replicas can land on same node | should-fix | yes | Added `podAntiAffinity` on hostname |
| 21 | `kubernetes/helm-charts/api-service/templates/secret.yaml` | Secret created but never used, dead code | should-fix | no | Would wire the Deployment to read from the Secret |
| 22 | `kubernetes/helm-charts/api-service/values.yaml` | `password` field in values.yaml encourages storing secrets in plain Helm values | should-fix | no | Would use external secret store or sealed secrets. Current value is empty because sandbox has no auth |
| 23 | `kubernetes/gitops/sandbox/api-service/kustomization.yaml` | `chartHome` points at `helm-chart` (singular), directory is `helm-charts` | blocker | yes | Fixed path |
| 24 | `kubernetes/gitops/sandbox/api-service/kustomization.yaml` | `images` block name `api` does not match chart image `api-service` | should-fix | yes | Removed broken block |
| 25 | `kubernetes/gitops/sandbox/api-service/kustomization.yaml` | Patch targets Deployment `api-svc`, real name is `api-service` | should-fix | yes | Removed broken patch |
| 26 | `kubernetes/gitops/sandbox/api-service/kustomization.yaml` | Top-level `namespace: apps` does not propagate to Helm-rendered resources, deployed to `default` | blocker | worked around | Applied with `-n apps`, cleaner fix is `metadata.namespace` in each template |
| 27 | `kubernetes/app/server.js` | Mongo driver does not reconnect after network blip or host suspend, readiness fails | nice-to-have | no | Would add reconnect logic or restart on broken connection |

## Task 2 - Terraform

| # | File / area | Issue | Severity | Fixed? | Notes |
|---|---|---|---|---|---|
| 1 | `terraform/modules/mongodb-instance/main.tf` | `var.disk_siz_gb` typo, variable is `disk_size_gb` | blocker | yes | Fixed name |
| 2 | `terraform/modules/mongodb-instance/main.tf` | Hardcoded zone `us-central1-a`, ignores `var.zone` | should-fix | yes | Uses `var.zone` |
| 3 | `terraform/modules/mongodb-instance/variables.tf` | `zone` has no type or description | nice-to-have | yes | Added both |
| 4 | `terraform/modules/mongodb-instance/variables.tf` | `replica_count` has no type | nice-to-have | yes | Added `number` |
| 5 | `terraform/modules/mongodb-instance/variables.tf` | `replica_count` default 2, replica set needs 3 for quorum | should-fix | yes | Changed to 3 |
| 6 | `terraform/modules/mongodb-instance/outputs.tf` | `internal_ips` has no description | nice-to-have | yes | Added one |
| 7 | `terraform/modules/mongodb-instance/main.tf` | `access_config {}` gives database a public IP | should-fix | yes | Removed, would use private subnet in production |
| 8 | `terraform/sandbox/mongodb-api-service/main.tf` | No provider version constraint on `hashicorp/google` | nice-to-have | no | Would pin a version |
| 9 | `terraform/sandbox/mongodb-api-service/main.tf` | GCP project hardcoded as `synthetic-sandbox` | should-fix | no | Would make it a variable |
| 10 | `terraform/sandbox/mongodb-api-service/state.tf` | S3 backend for GCP infrastructure, mismatch | should-fix | no | Would use GCS backend |
| 11 | `terraform/sandbox/mongodb-api-service/state.tf` | No DynamoDB lock table, no encryption | should-fix | no | Would add locking and encryption |
| 12 | `terraform/sandbox/mongodb-api-service/state.tf` | Bucket name hardcoded | nice-to-have | no | Would pass at init time |
| 13 | `terraform/modules/mongodb-instance/main.tf` | No `service_account` attached | should-fix | no | Would attach least-privilege SA |
| 14 | `terraform/modules/mongodb-instance/main.tf` | No `deletion_protection` | should-fix | no | Would enable for a database |
| 15 | `terraform/modules/mongodb-instance/main.tf` | Image `debian-11` close to end of life | nice-to-have | yes | Changed to `debian-12` |

## Task 3 - Chef

| # | File / area | Issue | Severity | Fixed? | Notes |
|---|---|---|---|---|---|
| 1 | `chef/cookbooks/mongodb/recipes/default.rb` | `rs.initiate()` runs before config written and before mongod started | blocker | yes | Reordered resources |
| 2 | `chef/cookbooks/mongodb/recipes/default.rb` | No MongoDB apt repository, `mongodb-org` install would fail | blocker | yes | Added `apt_repository` |
| 3 | `chef/cookbooks/mongodb/recipes/default.rb` | Package resource ignores the version attribute | should-fix | yes | Wired it up |
| 4 | `chef/cookbooks/mongodb/recipes/default.rb` | `execute 'enable-mongod'` runs every converge, does not notify | should-fix | yes | Replaced with `service` resource |
| 5 | `chef/cookbooks/mongodb/recipes/default.rb` | Replica set init not idempotent | should-fix | yes | Added `not_if` guard |
| 6 | `chef/cookbooks/mongodb/recipes/default.rb` | Uses `mongo` shell, removed in MongoDB 6 | blocker | yes | Changed to `mongosh` |
| 7 | `chef/cookbooks/mongodb/recipes/default.rb` | No wait for mongod before `rs.initiate()` | should-fix | yes | Added a wait step |
| 8 | `chef/cookbooks/mongodb/recipes/default.rb` | `service` only does `:start`, not `:enable` | should-fix | yes | Changed to `[:enable, :start]` |
| 9 | `chef/cookbooks/mongodb/recipes/default.rb` | Template does not notify service, config changes do not restart mongod | should-fix | yes | Added `notifies :restart` |
| 10 | `chef/cookbooks/mongodb/recipes/default.rb` | Data directory has no mode | nice-to-have | yes | Set to 0750 |
| 11 | `chef/cookbooks/mongodb/attributes/default.rb` | `bind_ip` set with `node.default` instead of `default` | nice-to-have | yes | Changed to `default` |
| 12 | `chef/cookbooks/mongodb/attributes/default.rb` | `bind_ip` attribute never used, template hardcodes `0.0.0.0` | should-fix | yes | Wired up, default `127.0.0.1` |
| 13 | `chef/cookbooks/mongodb/attributes/default.rb` | Admin password hardcoded `admin123` | should-fix | yes | Set to `nil`, would use Vault or data bag |
| 14 | `chef/cookbooks/mongodb/attributes/default.rb` | MongoDB version `4.2.0` EOL | should-fix | yes | Changed to `6.0` |
| 15 | `chef/cookbooks/mongodb/templates/mongod.conf.erb` | `bindIp` hardcoded `0.0.0.0` | should-fix | yes | Uses `node['mongodb']['bind_ip']` |
| 16 | `chef/cookbooks/mongodb/templates/mongod.conf.erb` | `authorization: disabled` | blocker | yes | Changed to `enabled` |
| 17 | `chef/cookbooks/mongodb/templates/mongod.conf.erb` | `setParameter` block for `adminUser` / `adminPassword` is not valid MongoDB config | blocker | yes | Removed, admin users created with `db.createUser` |
| 18 | `chef/cookbooks/mongodb/templates/mongod.conf.erb` | No log settings | nice-to-have | yes | Added `systemLog` |
| 19 | `chef/cookbooks/mongodb/templates/mongod.conf.erb` | No WiredTiger cache limit | nice-to-have | yes | Added `cacheSizeGB` |

## Anything I would do with more time

- Add a `.dockerignore` and pin the base image to a digest.
- Wire the Helm chart to actually use the Secret for `MONGO_URI` instead of putting it in `values.yaml`.
- Add a `NetworkPolicy` so only the `apps` namespace can reach MongoDB.
- Add integration tests that run on each push, so the kind deployment is verified automatically.
- Move the Terraform state to a GCS backend with locking and encryption.
- Add `deletion_protection` and a least-privilege `service_account` to the MongoDB instances.
- Replace the MongoDB connection in `server.js` with reconnect logic and add proper error handling.
- Add `livenessProbe`/`readinessProbe` tuning based on real traffic, not fixed numbers.
