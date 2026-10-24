# Part 6: ConfigMaps, Secrets and Kustomize generators.
cluster
state_p05

cap p06-secret-create 'kubectl create secret generic cache-auth --from-literal=password="$(openssl rand -hex 16)"'
cap p06-secret-get 'kubectl get secret cache-auth'
cap p06-secret-yaml 'kubectl get secret cache-auth -o yaml'
cap p06-secret-decode "kubectl get secret cache-auth -o jsonpath='{.data.password}' | base64 -d; echo"
cap p06-cache-apply 'kubectl apply -f 06-config/cache.yaml'
cap p06-cm-apply 'kubectl apply -f 06-config/configmap.yaml'
cap p06-cm-describe 'kubectl describe configmap podinfo-config'
cap p06-deploy-apply 'kubectl apply -f 06-config/deployment.yaml'
cap p06-rollout 'kubectl rollout status deployment/podinfo'
must kubectl rollout status deployment/cache --timeout=120s

cap p06-pf 'kubectl port-forward service/podinfo 8080:80 > /dev/null 2>&1 &'
must sleep 3
cap p06-message 'curl -s localhost:8080 | jq -r .message'
cap p06-configs 'curl -s localhost:8080/configs'
cap p06-env 'kubectl exec deploy/podinfo -- printenv PODINFO_UI_MESSAGE PODINFO_LEVEL'
cap p06-files 'kubectl exec deploy/podinfo -- ls -la /podinfo/config'
cap p06-cache-write 'curl -s -X POST -d "hello from the cache" localhost:8080/cache/greeting'
cap p06-cache-read 'curl -s localhost:8080/cache/greeting'

must "sed -i 's/Hello from a ConfigMap/Hello again/; s/newCheckout: false/newCheckout: true/; s/Autumn sale/Winter sale/' 06-config/configmap.yaml"
cap p06-cm-diff 'kubectl diff -f 06-config/configmap.yaml'
cap p06-cm-apply2 'kubectl apply -f 06-config/configmap.yaml'
cap p06-propagation "time (until curl -s localhost:8080/configs | grep -q 'Winter sale'; do sleep 5; done)"
cap p06-configs-after 'curl -s localhost:8080/configs'
cap p06-message-after 'curl -s localhost:8080 | jq -r .message'
cap p06-restart 'kubectl rollout restart deployment/podinfo'
cap p06-restart-status 'kubectl rollout status deployment/podinfo'
cap p06-pf-restart 'kill %1; kubectl port-forward service/podinfo 8080:80 > /dev/null 2>&1 &'
must sleep 3
cap p06-message-new 'curl -s localhost:8080 | jq -r .message'

cap p06-rotate 'kubectl create secret generic cache-auth --from-literal=password="$(openssl rand -hex 16)" --dry-run=client -o yaml | kubectl apply -f -'
cap p06-rotate-restart 'kubectl rollout restart deployment/cache deployment/podinfo'
must kubectl rollout status deployment/cache --timeout=120s
must kubectl rollout status deployment/podinfo --timeout=180s
cap p06-pf-restart2 'kill %1; kubectl port-forward service/podinfo 8080:80 > /dev/null 2>&1 &'
must sleep 3
cap p06-cache-after-rotate 'curl -s -o /dev/null -w "%{http_code}\n" localhost:8080/cache/greeting'
cap p06-cache-write2 'curl -s -X POST -d "hello again" localhost:8080/cache/greeting'
cap p06-cache-read2 'curl -s localhost:8080/cache/greeting'

cap p06-immutable-apply 'kubectl apply -f 06-config/release-info.yaml'
cap p06-immutable-patch "kubectl patch configmap release-info -p '{\"data\":{\"version\":\"2026.11\"}}'"

cap p06-kustomize 'kubectl kustomize 06-config/kustomize | head -n 12'
cap p06-kustomize-refs 'kubectl kustomize 06-config/kustomize | grep "name: podinfo-config"'
must "sed -i 's/Hello from Kustomize/Hello again from Kustomize/' 06-config/kustomize/kustomization.yaml"
cap p06-kustomize-refs2 'kubectl kustomize 06-config/kustomize | grep "name: podinfo-config"'
cap p06-pf-stop 'kill %1'
