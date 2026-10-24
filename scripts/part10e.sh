# Part 10, encryption at rest: a separate one-node cluster whose API server encrypts Secrets.
cap p10e-key "sed \"s|ENCRYPTION_KEY|\$(head -c 32 /dev/urandom | base64)|\" 10-security/encryption/encryption-config.template.yaml > 10-security/encryption/encryption-config.yaml"
cap p10e-create 'kind create cluster --config 10-security/encryption/kind-config.yaml'
must kubectl wait --for=condition=Ready nodes --all --timeout=180s
must kubectl wait -n kube-system --for=condition=Ready pods --all --timeout=180s
cap p10e-secret 'kubectl create secret generic demo-secret --from-literal=password=not-in-plain-text'
cap p10e-etcd 'kubectl -n kube-system exec etcd-k8s-guide-enc-control-plane -- etcdctl --endpoints=https://127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key get /registry/secrets/default/demo-secret --print-value-only | head -c 26; echo'
cap p10e-grep 'kubectl -n kube-system exec etcd-k8s-guide-enc-control-plane -- etcdctl --endpoints=https://127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key get /registry/secrets/default/demo-secret --print-value-only | grep -c not-in-plain-text'
cap p10e-read "kubectl get secret demo-secret -o jsonpath='{.data.password}' | base64 -d; echo"
cap p10e-delete 'kind delete cluster --name k8s-guide-enc'
