# Part 10: security. Pod Security Admission, RBAC, NetworkPolicy, admission policies, secrets and images.
cluster
state_p08
must kubectl delete hpa podinfo
must kubectl scale deployment podinfo --replicas=3
must kubectl rollout status deployment/podinfo --timeout=180s
# The Gateway from Part 5, to see how the NetworkPolicies affect it
must 'docker run -d --name cloud-provider-kind --rm --network host -v /var/run/docker.sock:/var/run/docker.sock registry.k8s.io/cloud-provider-kind/cloud-controller-manager:v0.12.0'
must 'for i in $(seq 1 60); do kubectl get gatewayclass cloud-provider-kind >/dev/null 2>&1 && break; sleep 2; done'
must kubectl apply -f 05-networking/gateway.yaml
must kubectl label namespace demo gateway-access=true
must kubectl apply -f 05-networking/httproute.yaml
must kubectl wait --for=condition=Programmed gateway/public -n gateway-infra --timeout=120s
must "GW_IP=\$(kubectl get gateway public -n gateway-infra -o jsonpath='{.status.addresses[0].value}')"
must 'for i in $(seq 1 30); do curl -sf -m 2 --resolve podinfo.k8s-guide.example:80:$GW_IP http://podinfo.k8s-guide.example/version >/dev/null && break; sleep 2; done'

cap p10-whoami 'kubectl auth whoami'
cap p10-psa-dry 'kubectl label --dry-run=server --overwrite namespace demo pod-security.kubernetes.io/enforce=restricted'
cap p10-psa-warn 'kubectl label --overwrite namespace demo pod-security.kubernetes.io/warn=restricted pod-security.kubernetes.io/audit=restricted'
cap p10-warn-run 'kubectl run test --image=busybox:1.38.0 --dry-run=server -- sleep 60'

cap p10-nonroot-apply 'kubectl apply -f 10-security/nonroot-test.yaml'
must sleep 15
cap p10-nonroot-get 'kubectl get pod nonroot-test'
cap p10-nonroot-events 'kubectl events --for pod/nonroot-test --types=Warning'
cap p10-nonroot-delete 'kubectl delete pod nonroot-test'
cap p10-image-user "kubectl exec deploy/podinfo -- id"

cap p10-rbac-apply 'kubectl apply -f 10-security/rbac.yaml'
cap p10-deploy-apply 'kubectl apply -f 10-security/deployment.yaml'
cap p10-deploy-status 'kubectl rollout status deployment/podinfo'
cap p10-sts-apply 'kubectl apply -f 10-security/statefulset.yaml'
cap p10-sts-status 'kubectl rollout status statefulset/cache'
cap p10-id-after 'kubectl exec deploy/podinfo -- id'
cap p10-ro-root 'kubectl exec deploy/podinfo -- touch /home/app/test'
cap p10-no-token 'kubectl exec deploy/podinfo -- ls /var/run/secrets/kubernetes.io/serviceaccount'
cap p10-tls-perms 'kubectl exec deploy/podinfo -- ls -lL /podinfo/tls'
settle app=podinfo
cap p10-enforce 'kubectl label --overwrite namespace demo pod-security.kubernetes.io/enforce=restricted'
cap p10-run-blocked 'kubectl run curl --image=curlimages/curl:8.23.0 --rm -i --restart=Never -- curl -s http://podinfo/version'

cap p10-can-i-1 'kubectl auth can-i patch deployments --as=system:serviceaccount:demo:deployer'
cap p10-can-i-2 'kubectl auth can-i get secrets --as=system:serviceaccount:demo:deployer'
cap p10-can-i-3 'kubectl auth can-i list pods --as=system:serviceaccount:demo:podinfo'
cap p10-can-i-list 'kubectl auth can-i --list --as=system:serviceaccount:demo:deployer'
cap p10-token 'kubectl create token deployer --duration=10m | cut -c1-40'

cap p10-client-apply 'kubectl apply -f 10-security/client.yaml'
must kubectl wait --for=condition=Ready pod/client --timeout=120s
cap p10-before-podinfo 'kubectl exec client -- curl -s -m 3 http://podinfo/version'
cap p10-before-cache 'kubectl exec client -- nc -z -v -w 3 cache 6379'
cap p10-np-apply 'kubectl apply -f 10-security/networkpolicy.yaml'
must sleep 5
cap p10-after-podinfo 'kubectl exec client -- curl -s -m 3 http://podinfo/version'
cap p10-after-cache 'kubectl exec client -- nc -z -v -w 3 cache 6379'
cap p10-after-app-cache 'kubectl exec deploy/podinfo -- nc -z -v -w 3 cache 6379'
cap p10-after-gateway 'curl -s -m 5 --resolve podinfo.k8s-guide.example:80:$GW_IP http://podinfo.k8s-guide.example/version; echo "curl exit code: $?"'
cap p10-kind-subnet "docker network inspect kind --format '{{range .IPAM.Config}}{{.Subnet}} {{end}}'"
cap p10-np-kind 'kubectl apply -f 10-security/networkpolicy-kind-gateway.yaml'
must sleep 5
cap p10-after-kind-np 'curl -s -m 5 --resolve podinfo.k8s-guide.example:80:$GW_IP http://podinfo.k8s-guide.example/version; echo "curl exit code: $?"'
cap p10-np-get 'kubectl get networkpolicy'

cap p10-vap-apply 'kubectl apply -f 10-security/admission-policy.yaml'
must sleep 5
cap p10-vap-deny 'kubectl apply -f 10-security/latest-tag-pod.yaml'
cap p10-vap-allow 'kubectl apply -f 10-security/client.yaml --dry-run=server'

cap p10-etcd 'kubectl -n kube-system exec etcd-k8s-guide-control-plane -- etcdctl --endpoints=https://127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key get /registry/secrets/demo/podinfo-tls --print-value-only | strings | grep "PRIVATE KEY"'

cap p10-image-id "kubectl get pods -l app=podinfo -o jsonpath='{.items[0].status.containerStatuses[0].imageID}{\"\\n\"}'"
cap p10-cosign 'cosign verify ghcr.io/stefanprodan/podinfo:6.15.0 --certificate-identity=https://github.com/stefanprodan/podinfo/.github/workflows/release.yml@refs/tags/6.15.0 --certificate-oidc-issuer=https://token.actions.githubusercontent.com > /dev/null'

cap p10-bench-apply 'kubectl apply -n default -f https://raw.githubusercontent.com/aquasecurity/kube-bench/v0.16.0/job.yaml'
cap p10-bench-wait 'kubectl wait -n default --for=condition=Complete job/kube-bench --timeout=300s'
cap p10-bench-summary "kubectl logs -n default job/kube-bench | grep -A 4 '== Summary total =='"
cap p10-bench-fails "kubectl logs -n default job/kube-bench | grep -E '^\\[FAIL\\]' | head -n 8"
