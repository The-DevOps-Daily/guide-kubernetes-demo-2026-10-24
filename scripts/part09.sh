# Part 9: logs, events, debugging, metrics and alerts.
cluster
state_p08
settle app=podinfo

cap p09-logs 'kubectl logs deployment/podinfo --tail=3'
cap p09-logs-all 'kubectl logs -l app=podinfo --prefix --tail=1'
cap p09-pod-set "POD=\$(kubectl get pods -l app=podinfo -o jsonpath='{.items[0].metadata.name}')"
cap p09-panic 'kubectl exec $POD -- curl -s localhost:9898/panic'
must sleep 15
cap p09-restarted 'kubectl get pod $POD'
cap p09-previous 'kubectl logs $POD --previous --tail=2'
cap p09-last-state "kubectl get pod \$POD -o jsonpath='{.status.containerStatuses[0].lastState.terminated.exitCode}{\"\\n\"}'"

cap p09-broken-apply 'kubectl apply -f 09-observability/broken.yaml'
must sleep 60
cap p09-broken-get 'kubectl get pods -l lab=broken'
cap p09-image-describe "kubectl describe pod -l app=bad-image | sed -n '/^Events:/,\$p'"
cap p09-config-logs 'kubectl logs deployment/bad-config'
cap p09-config-describe "kubectl describe pod -l app=bad-config | grep -A 5 'Last State'"
cap p09-pending-describe "kubectl describe pod -l app=no-node | sed -n '/^Events:/,\$p'"
cap p09-broken-delete 'kubectl delete -f 09-observability/broken.yaml'

cap p09-ready-off 'kubectl exec $POD -- curl -s -X POST localhost:9898/readyz/disable'
must sleep 15
cap p09-ready-pods 'kubectl get pods -l app=podinfo'
cap p09-ready-slices "kubectl get endpointslices -l kubernetes.io/service-name=podinfo -o jsonpath='{range .items[*].endpoints[*]}{.targetRef.name}{\"\\t\"}ready={.conditions.ready}{\"\\n\"}{end}'"
cap p09-ready-on 'kubectl exec $POD -- curl -s -X POST localhost:9898/readyz/enable'

cap p09-debug 'kubectl debug $POD --image=busybox:1.38.0 --target=podinfo --container=debugger -- sh -c "ps; netstat -tln"'
must sleep 10
cap p09-debug-logs 'kubectl logs $POD -c debugger'
cap p09-debug-node 'kubectl debug node/k8s-guide-worker --image=busybox:1.38.0 --profile=general -- ls /host/var/log/pods'
must sleep 10
cap p09-debug-node-logs "kubectl logs \$(kubectl get pods -o name | grep node-debugger)"
cap p09-debug-cleanup "kubectl delete \$(kubectl get pods -o name | grep node-debugger)"
cap p09-top 'kubectl top pods --containers'

cap p09-helm 'helm install monitoring oci://ghcr.io/prometheus-community/charts/kube-prometheus-stack --version 92.11.0 --namespace monitoring --create-namespace --values 09-observability/monitoring-values.yaml --wait --timeout 10m'
cap p09-mon-pods 'kubectl get pods -n monitoring'
cap p09-sm-apply 'kubectl apply -f 09-observability/servicemonitor.yaml -f 09-observability/prometheusrule.yaml'
cap p09-pf 'kubectl port-forward -n monitoring service/monitoring-kube-prometheus-prometheus 9090:9090 > /dev/null 2>&1 & PF=$!'
must sleep 5
must 'for i in $(seq 1 40); do n=$(curl -s localhost:9090/api/v1/query --data-urlencode "query=up{job=\"podinfo\"}" | jq ".data.result | length"); [ "$n" -ge 3 ] && break; sleep 5; done'
cap p09-up "curl -s localhost:9090/api/v1/query --data-urlencode 'query=up{job=\"podinfo\"}' | jq -r '.data.result[] | \"\\(.metric.pod) up=\\(.value[1])\"'"
cap p09-errors-run "kubectl run errors --image=curlimages/curl:8.23.0 --restart=Never -- sh -c 'for i in \$(seq 1 400); do curl -s -o /dev/null http://podinfo/status/500; curl -s -o /dev/null http://podinfo/; sleep 0.5; done'"
must sleep 150
cap p09-rate "curl -s localhost:9090/api/v1/query --data-urlencode 'query=sum by (status) (rate(http_requests_total{job=\"podinfo\"}[2m]))' | jq -r '.data.result[] | \"\\(.metric.status) \\(.value[1])\"'"
must 'for i in $(seq 1 30); do s=$(curl -s localhost:9090/api/v1/alerts | jq -r ".data.alerts[] | select(.labels.alertname==\"PodinfoHighErrorRate\") | .state"); [ "$s" = firing ] && break; sleep 10; done'
cap p09-alerts "curl -s localhost:9090/api/v1/alerts | jq -r '.data.alerts[] | select(.labels.alertname==\"PodinfoHighErrorRate\") | \"\\(.state) \\(.annotations.description)\"'"
cap p09-cleanup 'kubectl delete pod errors'
cap p09-pf-stop 'kill $PF'
