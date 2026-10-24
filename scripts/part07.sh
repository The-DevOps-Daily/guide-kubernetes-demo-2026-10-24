# Part 7: volumes, PersistentVolumeClaims, StorageClasses and StatefulSets.
cluster
state_p06

# Waits until podinfo can write to and read from the cache again.
cache_ready() {
  must 'for i in $(seq 1 40); do curl -s -X POST -d ok localhost:8080/cache/check >/dev/null; [ "$(curl -s localhost:8080/cache/check)" = ok ] && break; sleep 3; done; [ "$(curl -s localhost:8080/cache/check)" = ok ]'
}

cap p07-pf 'kubectl port-forward service/podinfo 8080:80 > /dev/null 2>&1 &'
must sleep 3
cache_ready
cap p07-write 'curl -s -X POST -d "hello from the cache" localhost:8080/cache/greeting'
cap p07-read "curl -s -w ' [%{http_code}]\n' localhost:8080/cache/greeting"
cap p07-delete-cache 'kubectl delete pod -l app=cache'
must kubectl rollout status deployment/cache --timeout=120s
cache_ready
cap p07-read-lost "curl -s -w ' [%{http_code}]\n' localhost:8080/cache/greeting"

cap p07-sc 'kubectl get storageclass'
cap p07-pvc-apply 'kubectl apply -f 07-storage/pvc.yaml'
cap p07-pvc-pending 'kubectl get pvc scratch'
cap p07-pvc-events 'kubectl events --for pvc/scratch'
cap p07-pod-apply 'kubectl apply -f 07-storage/pvc-pod.yaml'
cap p07-pod-wait 'kubectl wait --for=condition=Ready pod/writer --timeout=120s'
cap p07-pvc-bound 'kubectl get pvc scratch'
cap p07-pv 'kubectl get pv'
cap p07-pv-describe 'kubectl describe pv $(kubectl get pvc scratch -o jsonpath={.spec.volumeName})'
cap p07-read-file 'kubectl exec writer -- cat /data/created-at.txt'
cap p07-scratch-delete 'kubectl delete -f 07-storage/pvc-pod.yaml -f 07-storage/pvc.yaml'
must sleep 5
cap p07-pv-gone 'kubectl get pv'

cap p07-delete-deploy 'kubectl delete deployment cache'
cap p07-sts-apply 'kubectl apply -f 07-storage/statefulset.yaml'
cap p07-sts-status 'kubectl rollout status statefulset/cache'
cap p07-sts-get 'kubectl get statefulset,pods,pvc -l app=cache'
cache_ready
cap p07-sts-write 'curl -s -X POST -d "survives restarts" localhost:8080/cache/greeting'
cap p07-sts-delete-pod 'kubectl delete pod cache-0'
cap p07-sts-wait 'kubectl wait --for=condition=Ready pod/cache-0 --timeout=120s'
cache_ready
cap p07-sts-read "curl -s -w ' [%{http_code}]\n' localhost:8080/cache/greeting"
cap p07-sts-aof 'kubectl exec cache-0 -- ls -l /data/appendonlydir'
cap p07-sts-cli 'kubectl exec cache-0 -- valkey-cli GET greeting'
cap p07-dns 'kubectl exec deploy/podinfo -- nslookup cache-0.cache-headless.demo.svc.cluster.local'
cap p07-expand "kubectl patch pvc data-cache-0 -p '{\"spec\":{\"resources\":{\"requests\":{\"storage\":\"2Gi\"}}}}'"
cap p07-scale-zero 'kubectl scale statefulset cache --replicas=0'
must 'kubectl wait --for=delete pod/cache-0 --timeout=120s'
cap p07-pvc-kept 'kubectl get pvc'
cap p07-scale-one 'kubectl scale statefulset cache --replicas=1'
must kubectl rollout status statefulset/cache --timeout=120s
cache_ready
cap p07-read-again "curl -s -w ' [%{http_code}]\n' localhost:8080/cache/greeting"
cap p07-node "kubectl get pod cache-0 -o jsonpath='{.spec.nodeName}{\"\\n\"}'"
cap p07-pf-stop 'kill %1'
