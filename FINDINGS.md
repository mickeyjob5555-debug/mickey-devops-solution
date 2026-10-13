# DevOps Engineer Candidate Test - Findings

## Task 1 - Kubernetes

## Task 2 - Terraform

## Task 3 - Chef

### Task 1 - Helm chart, Kustomize, and deployment findings

Kustomize overlay (`kubernetes/gitops/sandbox/api-service/kustomization.yaml`):
- `chartHome: ../../../helm-chart` is a typo. The directory is `helm-charts` (plural). Kustomize cannot find the chart.
- `images: - name: api` does not match the chart's image name `api-service`. The override does nothing.
- The patch targets `kind: Deployment, name: api-svc`, but the release name is `api-service`. The resources patch never applies to anything.

Helm values (`kubernetes/helm-charts/api-service/values.yaml`):
- `image.pullPolicy: Always` with tag `latest`. In kind the image is loaded locally, so `Always` tries to pull from a registry and fails with `ErrImagePull`.
- `mongo.uri` points at `mongodb-0.mongodb.svc.cluster.local`, which resolves in the current namespace `apps`. MongoDB runs in `data`. Wrong DNS name.
- `mongo.uri` does not include `replicaSet=rs0`. The driver will refuse to connect to a replica set without it.
- `mongo.uri` embeds a password that does not exist in the sandbox (auth is off).
- `resources: {}` means the pod is `BestEffort` and first in line for eviction.
- `replicaCount: 1` and `pdb.enabled: false` mean no HA and no disruption budget.

Deployment template (`kubernetes/helm-charts/api-service/templates/deployment.yaml`):
- YAML is misindented. `ports`, `env`, `livenessProbe`, `readinessProbe`, and `resources` are siblings of `- name:` instead of members of the container. The rendered manifest is invalid.
- `livenessProbe` points at `/healthz`, which pings MongoDB. Liveness probes must not depend on external services. A DB hiccup would cause Kubernetes to restart the pod in a loop.
- No `startupProbe`.
- No `securityContext` at pod or container level.
- No anti-affinity or topology spread. Two replicas could land on the same node.

Secret (`kubernetes/helm-charts/api-service/templates/secret.yaml`):
- The Secret is created but never referenced by the Deployment. Dead code in the sandbox.
- The password is also in plaintext in `values.yaml`. In production this must be replaced with a secret reference (or external secret manager).

Service (`kubernetes/helm-charts/api-service/templates/service.yaml`):
- Looks correct. Port 80 to targetPort 3000, ClusterIP, selector matches the deployment.

## Task 2 - Terraform

Things I fixed to make validate pass:
- In modules/mongodb-instance/main.tf, the disk size line said var.disk_siz_gb but the variable is named disk_size_gb. It is a typo, so the module could not find the variable. Fixed.
- The module ignored its own zone variable and hardcoded us-central1-a instead. Now it uses var.zone, so the caller decides the zone, not the module.
- The zone variable had no type and no description. I added the string type and a description.
- The replica_count variable had no type. I added the number type. I also changed the default from 2 to 3, because a MongoDB replica set needs at least 3 members to have a proper quorum. With 2 members, if one goes down, the other cannot vote alone and the set cannot elect a primary.
- The internal_ips output had no description. I added one.

Other things I noticed but did not need to fix for validate to pass:
- The instance was on the default network and had access_config set, which gives the instance a public IP address. A database should never have a public IP. I removed the access_config block, but in a real setup the instance should live on a private subnet with firewall rules and no external address.
- The provider block in sandbox/mongodb-api-service/main.tf has no version constraint on the google provider. Pinning a version is safer, because a future provider release could break the config without warning.
- The GCP project is hardcoded as synthetic-sandbox. It should come from a variable, so the same config can be reused in different projects.
- The backend in state.tf is AWS S3, but the infrastructure is in GCP. That mix does not make sense. It should use a GCS backend instead, since GCS is the native option for GCP.
- The S3 backend has no DynamoDB lock table and no encryption. Without locking, two people running apply at the same time can corrupt the state. Without encryption, the state file is stored in plain text.
- The backend bucket name is hardcoded. It should come from a variable or be passed at init time, so the same config works in different environments.
- The instance has no service_account attached. In production you would attach a service account with least privilege, so the instance can talk to GCP services without keys.
- The instance has no deletion_protection set. That means a terraform destroy would wipe the database without any warning. For a database, deletion protection should be on.
- The image was debian-cloud/debian-11. Debian 11 is close to end of life. I changed it to debian-12.
