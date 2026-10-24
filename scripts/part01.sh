# Part 1: architecture. Looks at the components of the cluster from Part 2.
cluster

cap p01-nodes 'kubectl get nodes -o wide'
cap p01-system-pods 'kubectl get pods -n kube-system -o wide'
cap p01-readyz "kubectl get --raw='/readyz?verbose'"
cap p01-proxy-mode "kubectl -n kube-system get configmap kube-proxy -o jsonpath='{.data.config\.conf}' | grep 'mode:'"
cap p01-api-resources 'kubectl api-resources --api-group=apps'
cap p01-explain 'kubectl explain deployment.spec.replicas'

cap p01-create 'kubectl create deployment hello --image=ghcr.io/stefanprodan/podinfo:6.15.0 --replicas=2'
must kubectl rollout status deployment/hello --timeout=180s
cap p01-events 'kubectl events'
cap p01-pods 'kubectl get pods -o wide'
cap p01-owners "kubectl get pods -o custom-columns=POD:.metadata.name,OWNER-KIND:.metadata.ownerReferences[0].kind,OWNER:.metadata.ownerReferences[0].name"
cap p01-delete 'kubectl delete deployment hello'
