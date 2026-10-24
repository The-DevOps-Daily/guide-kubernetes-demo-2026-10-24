# Part 3: pods.
cluster

cap p03-apply 'kubectl apply -f 03-pods/pod.yaml'
cap p03-get-early 'kubectl get pods'
cap p03-wait 'kubectl wait --for=condition=Ready pod/podinfo --timeout=120s'
cap p03-get 'kubectl get pods -o wide'
cap p03-create-again 'kubectl create -f 03-pods/pod.yaml'
cap p03-describe 'kubectl describe pod podinfo'
cap p03-conditions "kubectl get pod podinfo -o jsonpath='{range .status.conditions[*]}{.type}={.status}{\"\\n\"}{end}'"
cap p03-events 'kubectl events --for pod/podinfo'
cap p03-logs 'kubectl logs podinfo'

cap p03-pf 'kubectl port-forward pod/podinfo 9898:9898 > /dev/null 2>&1 & PF=$!'
cap p03-curl 'curl -s --retry 5 --retry-connrefused --retry-delay 1 localhost:9898'
cap p03-pf-stop 'kill $PF'

cap p03-exec-id 'kubectl exec podinfo -- id'
cap p03-exec-ps 'kubectl exec podinfo -- ps'
cap p03-pod-ip-set "POD_IP=\$(kubectl get pod podinfo -o jsonpath='{.status.podIP}')"
cap p03-pod-ip 'echo $POD_IP'
cap p03-client 'kubectl run client --image=curlimages/curl:8.23.0 --command -- sleep infinity'
cap p03-client-wait 'kubectl wait --for=condition=Ready pod/client'
cap p03-client-curl 'kubectl exec client -- curl -s http://$POD_IP:9898/version'

cap p03-sidecar-apply 'kubectl apply -f 03-pods/pod-sidecar.yaml'
cap p03-sidecar-get-init 'kubectl get pod podinfo-sidecar'
cap p03-sidecar-wait 'kubectl wait --for=condition=Ready pod/podinfo-sidecar --timeout=120s'
cap p03-sidecar-get 'kubectl get pod podinfo-sidecar'
cap p03-sidecar-sleep 'sleep 10'
cap p03-sidecar-logs 'kubectl logs podinfo-sidecar -c health-reporter'
cap p03-sidecar-message 'kubectl exec podinfo-sidecar -c podinfo -- curl -s localhost:9898'

cap p03-fail-run "kubectl run fail --image=busybox:1.38.0 --restart=Never -- sh -c 'echo starting; exit 3'"
cap p03-fail-wait "kubectl wait --for=jsonpath='{.status.phase}'=Failed pod/fail --timeout=60s"
cap p03-fail-get 'kubectl get pod fail'
cap p03-fail-exit "kubectl get pod fail -o jsonpath='{.status.containerStatuses[0].state.terminated.exitCode}{\"\\n\"}'"
cap p03-fail-logs 'kubectl logs fail'

cap p03-delete 'kubectl delete pod podinfo podinfo-sidecar fail client'
