# Part 5: Services, DNS, NodePort, LoadBalancer and Gateway API.
cluster
state_p04

cap p05-apply 'kubectl apply -f 05-networking/service.yaml'
cap p05-get 'kubectl get service podinfo'
cap p05-slices 'kubectl get endpointslices -l kubernetes.io/service-name=podinfo'
cap p05-endpoints 'kubectl get endpoints podinfo'
cap p05-client 'kubectl run client --image=curlimages/curl:8.23.0 --command -- sleep infinity'
cap p05-client-wait 'kubectl wait --for=condition=Ready pod/client'
cap p05-curl 'kubectl exec client -- curl -s http://podinfo/version'
cap p05-spread "kubectl exec client -- sh -c 'for i in \$(seq 1 30); do curl -s http://podinfo | grep hostname; done' | sort | uniq -c"
cap p05-dns 'kubectl exec client -- nslookup podinfo.demo.svc.cluster.local'
cap p05-dns-short 'kubectl exec client -- curl -s http://podinfo.demo/version'
cap p05-resolv 'kubectl exec client -- cat /etc/resolv.conf'

cap p05-np-apply 'kubectl apply -f 05-networking/service-nodeport.yaml'
cap p05-np-get 'kubectl get service podinfo-nodeport'
must 'for i in $(seq 1 30); do curl -sf -m 2 localhost:30080/version >/dev/null && break; sleep 2; done'
cap p05-np-curl 'curl -s localhost:30080/version'

cap p05-lb-apply 'kubectl apply -f 05-networking/service-lb.yaml'
cap p05-lb-pending 'kubectl get service podinfo-lb'
must docker pull -q registry.k8s.io/cloud-provider-kind/cloud-controller-manager:v0.12.0
cap p05-cpk 'docker run -d --name cloud-provider-kind --rm --network host -v /var/run/docker.sock:/var/run/docker.sock registry.k8s.io/cloud-provider-kind/cloud-controller-manager:v0.12.0'
must 'for i in $(seq 1 60); do ip=$(kubectl get service podinfo-lb -o jsonpath="{.status.loadBalancer.ingress[0].ip}"); [ -n "$ip" ] && break; sleep 2; done; [ -n "$ip" ]'
cap p05-lb-get 'kubectl get service podinfo-lb'
cap p05-lb-ip-set "LB_IP=\$(kubectl get service podinfo-lb -o jsonpath='{.status.loadBalancer.ingress[0].ip}')"
must 'for i in $(seq 1 30); do curl -sf -m 2 http://$LB_IP/version >/dev/null && break; sleep 2; done'
cap p05-lb-curl 'curl -s http://$LB_IP/version'

must 'for i in $(seq 1 60); do kubectl get gatewayclass cloud-provider-kind >/dev/null 2>&1 && break; sleep 2; done'
cap p05-gwclass 'kubectl get gatewayclass'
cap p05-crds 'kubectl api-resources --api-group=gateway.networking.k8s.io'
cap p05-gw-apply 'kubectl apply -f 05-networking/gateway.yaml'
cap p05-label 'kubectl label namespace demo gateway-access=true'
cap p05-route-apply 'kubectl apply -f 05-networking/httproute.yaml'
cap p05-gw-wait 'kubectl wait --for=condition=Programmed gateway/public -n gateway-infra --timeout=120s'
cap p05-gw-get 'kubectl get gateway -n gateway-infra'
cap p05-route-get 'kubectl get httproute'
cap p05-route-status "kubectl get httproute podinfo -o jsonpath='{range .status.parents[0].conditions[*]}{.type}={.status} ({.reason}){\"\\n\"}{end}'"
cap p05-gw-ip-set "GW_IP=\$(kubectl get gateway public -n gateway-infra -o jsonpath='{.status.addresses[0].value}')"
must 'for i in $(seq 1 30); do curl -sf -m 2 --resolve podinfo.k8s-guide.example:80:$GW_IP http://podinfo.k8s-guide.example/version >/dev/null && break; sleep 2; done'
cap p05-gw-curl 'curl -s --resolve podinfo.k8s-guide.example:80:$GW_IP http://podinfo.k8s-guide.example/version'
cap p05-gw-env 'curl -s -o /dev/null -w "%{http_code}\n" --resolve podinfo.k8s-guide.example:80:$GW_IP http://podinfo.k8s-guide.example/env'
cap p05-gw-404 'curl -s -o /dev/null -w "%{http_code}\n" --resolve other.k8s-guide.example:80:$GW_IP http://other.k8s-guide.example/'

cap p05-canary-apply 'kubectl apply -f 05-networking/canary.yaml'
must kubectl rollout status deployment/podinfo-canary --timeout=120s
cap p05-canary-route 'kubectl apply -f 05-networking/httproute-canary.yaml'
must sleep 10
cap p05-canary-count 'for i in $(seq 1 200); do curl -s --resolve podinfo.k8s-guide.example:80:$GW_IP http://podinfo.k8s-guide.example/ | jq -r .message; done | sort | uniq -c'

cap p05-ingress-dry 'kubectl apply -f 05-networking/ingress.yaml --dry-run=server'
cap p05-restore 'kubectl apply -f 05-networking/httproute.yaml'
cap p05-cleanup 'kubectl delete -f 05-networking/canary.yaml -f 05-networking/service-nodeport.yaml -f 05-networking/service-lb.yaml'
cap p05-client-delete 'kubectl delete pod client'
