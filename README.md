# Introduction to Kubernetes: companion repository

The manifests for the [Introduction to Kubernetes](https://devops-daily.com/guides/introduction-to-kubernetes) guide on DevOps Daily, one directory per part.

```bash
git clone https://github.com/The-DevOps-Daily/guide-kubernetes-demo-2026-10-24.git
cd guide-kubernetes-demo-2026-10-24
kind create cluster --config kind-config.yaml
kubectl create namespace demo
kubectl config set-context --current --namespace=demo
kubectl apply -f 03-pods/pod.yaml
```

| Directory           | Part                                                    |
| ------------------- | ------------------------------------------------------- |
| `kind-config.yaml`  | 2. A local cluster with kind                            |
| `03-pods/`          | 3. Pods, probes, init containers and sidecars           |
| `04-deployments/`   | 4. Deployments, rollouts, Jobs and CronJobs             |
| `05-networking/`    | 5. Services, DNS and Gateway API                        |
| `06-config/`        | 6. ConfigMaps, Secrets and Kustomize                    |
| `07-storage/`       | 7. PersistentVolumeClaims and StatefulSets              |
| `08-resources/`     | 8. Requests, limits, quotas, autoscaling and scheduling |
| `09-observability/` | 9. Logs, debugging, Prometheus and alerts               |
| `10-security/`      | 10. Pod Security, RBAC, NetworkPolicy and admission     |

The example app is [podinfo](https://github.com/stefanprodan/podinfo) 6.15.0 with a [Valkey](https://valkey.io/) 9.1 cache.

## How the guide's output was made

The workflow in `.github/workflows/guide.yml` runs every part on a fresh kind cluster (kind v0.33.0, Kubernetes v1.37.0, kubectl v1.37.1, Helm v4.3.1) on a GitHub-hosted runner, with the commands in `scripts/partNN.sh`. Each command's output is saved as an artifact, and the guide shows that output. A second job sends every manifest to the API server as a server-side dry run with strict field validation.

Run a part yourself with `scripts/run.sh 05` on a Linux machine with Docker, kind, kubectl, helm and jq. It creates a cluster named `k8s-guide`; delete it afterwards with `kind delete cluster --name k8s-guide`.
