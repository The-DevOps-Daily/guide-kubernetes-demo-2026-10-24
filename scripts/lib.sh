# Helpers for the guide runs, sourced by scripts/run.sh.
#
# cap NAME 'command' ['command to run instead']
#   Runs the command in the current shell (so cd, variables and background jobs carry over),
#   saves its combined output to captures/NAME.txt and the command, exit code and time to
#   captures/NAME.json. The optional third argument is only used for commands that never end
#   on their own (watches), and the guide says so next to their output.
# must 'command'
#   A setup step that the guide does not show. The job fails if it fails.

CAP_DIR="${CAP_DIR:-$PWD/captures}"
mkdir -p "$CAP_DIR"

cap() {
  local name=$1 shown=$2 run=${3:-$2} rc started
  started=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  eval "$run" >"$CAP_DIR/$name.txt" 2>&1 </dev/null
  rc=$?
  jq -n --arg cmd "$shown" --arg run "$run" --argjson rc "$rc" --arg at "$started" \
    --arg run_id "${GITHUB_RUN_ID:-local}" \
    '{cmd: $cmd, run: $run, rc: $rc, at: $at, run_id: $run_id}' >"$CAP_DIR/$name.json"
  printf '::group::%s (exit %s)\n$ %s\n' "$name" "$rc" "$shown"
  cat "$CAP_DIR/$name.txt"
  echo '::endgroup::'
}

must() {
  echo "+ $*"
  if ! eval "$*"; then
    echo "::error::setup step failed: $*"
    exit 1
  fi
}

# A cluster like the one Part 2 creates, with the demo namespace selected.
cluster() {
  must kind create cluster --config kind-config.yaml --wait 180s
  must kubectl wait --for=condition=Ready nodes --all --timeout=180s
  must kubectl wait -n kube-system --for=condition=Ready pods --all --timeout=180s
  must kubectl create namespace demo
  must kubectl config set-context --current --namespace=demo
}

# Waits until no pod with this label selector is terminating.
settle() {
  local i
  for i in $(seq 1 90); do
    if [ -z "$(kubectl get pods -l "$1" -o jsonpath='{range .items[*]}{.metadata.deletionTimestamp}{end}')" ]; then
      return 0
    fi
    sleep 2
  done
  echo "::error::pods $1 are still terminating"
  exit 1
}

# The state at the end of Part 4: podinfo 6.15.0 with three replicas.
state_p04() {
  must kubectl apply -f 04-deployments/deployment.yaml
  must kubectl set image deployment/podinfo podinfo=ghcr.io/stefanprodan/podinfo:6.15.0
  must kubectl rollout status deployment/podinfo --timeout=180s
  settle app=podinfo
}

# The state at the end of Part 5: plus the podinfo Service.
state_p05() {
  state_p04
  must kubectl apply -f 05-networking/service.yaml
}

# The state at the end of Part 6: plus the cache, the TLS Secret and the configured podinfo.
state_p06() {
  state_p05
  must 'openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -nodes -days 30 -keyout tls.key -out tls.crt -subj "/CN=podinfo.demo.svc" -addext "subjectAltName=DNS:podinfo.demo.svc,DNS:localhost"'
  must kubectl create secret tls podinfo-tls --cert=tls.crt --key=tls.key
  must kubectl apply -f 06-config/cache.yaml -f 06-config/configmap.yaml -f 06-config/deployment.yaml
  must kubectl rollout status deployment/cache --timeout=180s
  must kubectl rollout status deployment/podinfo --timeout=180s
  settle app=podinfo
}

# The state at the end of Part 7: the cache runs as a StatefulSet with a volume.
state_p07() {
  state_p06
  must kubectl delete deployment cache
  must kubectl apply -f 07-storage/statefulset.yaml
  must kubectl rollout status statefulset/cache --timeout=180s
}

metrics_server() {
  must kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.9.0/components.yaml
  must "kubectl -n kube-system patch deployment metrics-server --type=json -p '[{\"op\":\"add\",\"path\":\"/spec/template/spec/containers/0/args/-\",\"value\":\"--kubelet-insecure-tls\"}]'"
  must kubectl -n kube-system rollout status deployment/metrics-server --timeout=180s
}

# The state at the end of Part 8: resources, quotas, autoscaling and metrics-server.
state_p08() {
  state_p07
  metrics_server
  must kubectl apply -f 08-resources/limitrange.yaml -f 08-resources/resourcequota.yaml
  must kubectl apply -f 08-resources/deployment.yaml -f 08-resources/hpa.yaml -f 08-resources/pdb.yaml
  must kubectl rollout status deployment/podinfo --timeout=180s
  settle app=podinfo
}
