#!/usr/bin/env bash
# Sends every manifest in this repository to a real API server as a server-side dry run with
# strict field validation, after installing the CRDs that the examples use.
set -uo pipefail
cd "$(dirname "$0")/.."

kind create cluster --name validate --wait 180s || exit 1
kubectl create namespace demo
kubectl create namespace gateway-infra
kubectl config set-context --current --namespace=demo

crds=(
  https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.6.3/standard-install.yaml
  https://github.com/prometheus-operator/prometheus-operator/releases/download/v0.94.1/stripped-down-crds.yaml
  https://raw.githubusercontent.com/external-secrets/external-secrets/v2.14.0/deploy/crds/bundle.yaml
  https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/v8.7.0/client/config/crd/snapshot.storage.k8s.io_volumesnapshots.yaml
  https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/v8.7.0/client/config/crd/snapshot.storage.k8s.io_volumesnapshotclasses.yaml
  https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/v8.7.0/client/config/crd/snapshot.storage.k8s.io_volumesnapshotcontents.yaml
  https://raw.githubusercontent.com/kubernetes/autoscaler/vertical-pod-autoscaler-1.8.1/vertical-pod-autoscaler/deploy/vpa-v1-crd-gen.yaml
)
for url in "${crds[@]}"; do
  kubectl apply --server-side -f "$url" >/dev/null || { echo "::error::cannot install $url"; exit 1; }
done
kubectl wait --for=condition=Established crd --all --timeout=120s >/dev/null

failed=0
check() {
  local label=$1
  shift
  if out=$("$@" 2>&1); then
    echo "ok   $label"
  else
    echo "FAIL $label"
    echo "$out" | sed 's/^/     /'
    failed=1
  fi
}

while IFS= read -r f; do
  check "$f" kubectl apply --dry-run=server --validate=strict -f "$f"
done < <(find . -name '*.yaml' -not -path './.github/*' -not -path './06-config/kustomize/*' \
  -not -name kind-config.yaml -not -name monitoring-values.yaml | sort)

check 06-config/kustomize bash -c 'kubectl kustomize 06-config/kustomize | kubectl apply --dry-run=server --validate=strict -f -'
check 09-observability/monitoring-values.yaml bash -c 'helm template monitoring oci://ghcr.io/prometheus-community/charts/kube-prometheus-stack --version 92.11.0 --namespace monitoring --values 09-observability/monitoring-values.yaml > /dev/null'

exit "$failed"
