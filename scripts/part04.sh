# Part 4: Deployments, ReplicaSets, rollouts and other controllers.
cluster

cap p04-apply 'kubectl apply -f 04-deployments/deployment.yaml'
cap p04-status 'kubectl rollout status deployment/podinfo'
cap p04-get 'kubectl get deployment podinfo'
cap p04-rs 'kubectl get replicasets'
cap p04-pods 'kubectl get pods -l app=podinfo -o wide'

cap p04-victim-set "POD=\$(kubectl get pods -l app=podinfo -o jsonpath='{.items[0].metadata.name}')"
cap p04-delete-pod 'kubectl delete pod $POD'
cap p04-pods-healed 'kubectl get pods -l app=podinfo'

cap p04-scale 'kubectl scale deployment podinfo --replicas=5'
must kubectl rollout status deployment/podinfo --timeout=120s
cap p04-get-scaled 'kubectl get deployment podinfo'

cap p04-annotate "kubectl annotate deployment/podinfo kubernetes.io/change-cause='Update podinfo to 6.15.0'"
cap p04-set-image 'kubectl set image deployment/podinfo podinfo=ghcr.io/stefanprodan/podinfo:6.15.0'
cap p04-rollout 'kubectl rollout status deployment/podinfo'
cap p04-rs-after 'kubectl get replicasets -o wide'
cap p04-history 'kubectl rollout history deployment/podinfo'

cap p04-annotate-bad "kubectl annotate deployment/podinfo --overwrite kubernetes.io/change-cause='Update podinfo to 6.99.0'"
cap p04-set-bad 'kubectl set image deployment/podinfo podinfo=ghcr.io/stefanprodan/podinfo:6.99.0'
cap p04-status-bad 'kubectl rollout status deployment/podinfo --timeout=60s'
cap p04-pods-bad 'kubectl get pods -l app=podinfo'
cap p04-get-bad 'kubectl get deployment podinfo'
# wait past progressDeadlineSeconds (120 s after the rollout started)
must sleep 75
cap p04-deadline 'kubectl rollout status deployment/podinfo'
cap p04-condition "kubectl get deployment podinfo -o jsonpath='{.status.conditions[?(@.type==\"Progressing\")].message}{\"\\n\"}'"
cap p04-undo 'kubectl rollout undo deployment/podinfo'
cap p04-undo-status 'kubectl rollout status deployment/podinfo'
cap p04-history-after 'kubectl rollout history deployment/podinfo'
cap p04-revision "kubectl rollout history deployment/podinfo --revision=4"
cap p04-image "kubectl get deployment podinfo -o jsonpath='{.spec.template.spec.containers[0].image}{\"\\n\"}'"
cap p04-scale-back 'kubectl scale deployment podinfo --replicas=3'
must kubectl rollout status deployment/podinfo --timeout=120s
cap p04-diff 'kubectl diff -f 04-deployments/deployment.yaml'

cap p04-restart 'kubectl rollout restart deployment/podinfo'
cap p04-restart-status 'kubectl rollout status deployment/podinfo'

cap p04-job-apply 'kubectl apply -f 04-deployments/job.yaml'
cap p04-job-wait 'kubectl wait --for=condition=Complete job/report --timeout=120s'
cap p04-job-get 'kubectl get jobs,pods -l job-name=report'
cap p04-job-logs 'kubectl logs job/report -c log-shipper'

cap p04-cron-apply 'kubectl apply -f 04-deployments/cronjob.yaml'
cap p04-cron-trigger 'kubectl create job cleanup-manual --from=cronjob/cleanup'
must kubectl wait --for=condition=Complete job/cleanup-manual --timeout=120s
cap p04-cron-get 'kubectl get cronjobs,jobs'
cap p04-cron-logs 'kubectl logs job/cleanup-manual'
cap p04-ds 'kubectl get daemonsets -n kube-system'
cap p04-cleanup 'kubectl delete -f 04-deployments/job.yaml -f 04-deployments/cronjob.yaml && kubectl delete job cleanup-manual'
