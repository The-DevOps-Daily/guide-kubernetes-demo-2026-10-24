# Part 8: requests and limits, quotas, autoscaling and scheduling.
cluster
state_p07
settle app=podinfo

cap p08-ms-apply 'kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.9.0/components.yaml'
cap p08-ms-patch "kubectl -n kube-system patch deployment metrics-server --type=json -p '[{\"op\":\"add\",\"path\":\"/spec/template/spec/containers/0/args/-\",\"value\":\"--kubelet-insecure-tls\"}]'"
cap p08-ms-status 'kubectl -n kube-system rollout status deployment/metrics-server'
must 'for i in $(seq 1 40); do kubectl top pods >/dev/null 2>&1 && break; sleep 5; done'
cap p08-top-nodes 'kubectl top nodes'
cap p08-top-pods 'kubectl top pods'

cap p08-apply 'kubectl apply -f 08-resources/deployment.yaml'
cap p08-rollout 'kubectl rollout status deployment/podinfo'
settle app=podinfo
cap p08-qos 'kubectl get pods -o custom-columns=NAME:.metadata.name,QOS:.status.qosClass'
cap p08-allocated "kubectl describe node k8s-guide-worker | grep -A 9 'Allocated resources'"
cap p08-spread 'kubectl get pods -l app=podinfo -o wide'

cap p08-oom-apply 'kubectl apply -f 08-resources/oom-pod.yaml'
must 'for i in $(seq 1 40); do r=$(kubectl get pod memory-hog -o jsonpath="{.status.containerStatuses[0].lastState.terminated.reason}"); [ "$r" = OOMKilled ] && break; sleep 3; done'
cap p08-oom-get 'kubectl get pod memory-hog'
cap p08-oom-state "kubectl get pod memory-hog -o jsonpath='{.status.containerStatuses[0].lastState.terminated}' | jq"
cap p08-oom-delete 'kubectl delete pod memory-hog'

cap p08-resize-apply 'kubectl apply -f 08-resources/resize-pod.yaml'
must kubectl wait --for=condition=Ready pod/resize-demo --timeout=120s
cap p08-resize-cpu "kubectl patch pod resize-demo --subresource resize --patch '{\"spec\":{\"containers\":[{\"name\":\"podinfo\",\"resources\":{\"requests\":{\"cpu\":\"300m\"},\"limits\":{\"cpu\":\"500m\"}}}]}}'"
must sleep 5
cap p08-resize-status "kubectl get pod resize-demo -o jsonpath='{.status.containerStatuses[0].resources}{\"\\n\"}restarts: {.status.containerStatuses[0].restartCount}{\"\\n\"}'"
cap p08-resize-mem "kubectl patch pod resize-demo --subresource resize --patch '{\"spec\":{\"containers\":[{\"name\":\"podinfo\",\"resources\":{\"requests\":{\"memory\":\"128Mi\"},\"limits\":{\"memory\":\"256Mi\"}}}]}}'"
must sleep 10
cap p08-resize-status2 "kubectl get pod resize-demo -o jsonpath='{.status.containerStatuses[0].resources}{\"\\n\"}restarts: {.status.containerStatuses[0].restartCount}{\"\\n\"}'"
cap p08-resize-big "kubectl patch pod resize-demo --subresource resize --patch '{\"spec\":{\"containers\":[{\"name\":\"podinfo\",\"resources\":{\"requests\":{\"cpu\":\"64\"},\"limits\":{\"cpu\":\"64\"}}}]}}'"
cap p08-resize-delete 'kubectl delete pod resize-demo'

cap p08-limits-apply 'kubectl apply -f 08-resources/limitrange.yaml -f 08-resources/resourcequota.yaml'
cap p08-defaults-run 'kubectl run defaults --image=busybox:1.38.0 --restart=Never -- sleep 3600'
cap p08-defaults-show "kubectl get pod defaults -o jsonpath='{.spec.containers[0].resources}{\"\\n\"}'"
cap p08-quota 'kubectl describe resourcequota demo-quota'
cap p08-scale-many 'kubectl scale deployment podinfo --replicas=25'
must sleep 20
cap p08-scale-get 'kubectl get deployment podinfo'
cap p08-quota-events 'kubectl get events --field-selector reason=FailedCreate | tail -n 2'
cap p08-scale-back 'kubectl scale deployment podinfo --replicas=3'
must kubectl rollout status deployment/podinfo --timeout=180s
settle app=podinfo
cap p08-defaults-delete 'kubectl delete pod defaults'

cap p08-hpa-apply 'kubectl apply -f 08-resources/hpa.yaml'
must 'for i in $(seq 1 30); do t=$(kubectl get hpa podinfo -o jsonpath="{.status.currentMetrics[0].resource.current.averageUtilization}"); [ -n "$t" ] && break; sleep 5; done'
cap p08-hpa-get 'kubectl get hpa podinfo'
cap p08-load 'kubectl run loadgen --image=fortio/fortio:1.76.0 --restart=Never -- load -qps 0 -c 16 -t 3m -nocatchup http://podinfo/'
cap p08-hpa-watch 'kubectl get hpa podinfo --watch' 'timeout 420 kubectl get hpa podinfo --watch'
cap p08-hpa-describe "kubectl describe hpa podinfo | sed -n '/^Events:/,\$p'"
cap p08-loadgen-tail 'kubectl logs loadgen | tail -n 4'
cap p08-loadgen-delete 'kubectl delete pod loadgen'
must kubectl rollout status deployment/podinfo --timeout=180s
settle app=podinfo

cap p08-taint 'kubectl taint nodes k8s-guide-worker2 dedicated=batch:NoSchedule'
cap p08-label 'kubectl label nodes k8s-guide-worker2 workload=batch'
cap p08-restart 'kubectl rollout restart deployment/podinfo'
must kubectl rollout status deployment/podinfo --timeout=180s
settle app=podinfo
cap p08-after-taint 'kubectl get pods -l app=podinfo -o wide'
cap p08-batch-apply 'kubectl apply -f 08-resources/batch-pod.yaml'
must kubectl wait --for=condition=Ready pod/batch-task --timeout=120s
cap p08-batch-node "kubectl get pod batch-task -o jsonpath='{.spec.nodeName}{\"\\n\"}'"
cap p08-untaint 'kubectl taint nodes k8s-guide-worker2 dedicated=batch:NoSchedule-'
cap p08-batch-delete 'kubectl delete pod batch-task'
cap p08-restart2 'kubectl rollout restart deployment/podinfo'
must kubectl rollout status deployment/podinfo --timeout=180s
settle app=podinfo

cap p08-pdb-apply 'kubectl apply -f 08-resources/pdb.yaml'
cap p08-pdb-get 'kubectl get pdb podinfo'
cap p08-node-set "NODE=\$(kubectl get pod cache-0 -o jsonpath='{.spec.nodeName}'); echo \$NODE"
cap p08-pods-before 'kubectl get pods -o wide'
cap p08-drain 'kubectl drain $NODE --ignore-daemonsets --delete-emptydir-data --timeout=180s'
must sleep 10
cap p08-pods-after 'kubectl get pods -o wide'
cap p08-cache-pending 'kubectl events --for pod/cache-0 --types=Warning'
cap p08-uncordon 'kubectl uncordon $NODE'
cap p08-cache-back 'kubectl wait --for=condition=Ready pod/cache-0 --timeout=180s'
