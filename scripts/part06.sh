# Part 6: ConfigMaps, Secrets and Kustomize generators.
cluster
state_p05

cap p06-cm-apply 'kubectl apply -f 06-config/configmap.yaml'
cap p06-cm-describe 'kubectl describe configmap podinfo-config'

cap p06-tls-create 'openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -nodes -days 30 -keyout tls.key -out tls.crt -subj "/CN=podinfo.demo.svc" -addext "subjectAltName=DNS:podinfo.demo.svc,DNS:localhost"'
cap p06-secret-create 'kubectl create secret tls podinfo-tls --cert=tls.crt --key=tls.key'
cap p06-secret-get 'kubectl get secret podinfo-tls'
cap p06-secret-describe 'kubectl describe secret podinfo-tls'
cap p06-secret-yaml 'kubectl get secret podinfo-tls -o yaml | head -n 6'
cap p06-secret-decode "kubectl get secret podinfo-tls -o jsonpath='{.data.tls\\.crt}' | base64 -d | openssl x509 -noout -subject -enddate"

cap p06-token-create 'kubectl create secret generic api-token --from-literal=token="$(openssl rand -hex 16)"'
cap p06-leak-apply 'kubectl apply -f 06-config/env-leak-pod.yaml'
must kubectl wait --for=condition=Ready pod/env-leak --timeout=120s
cap p06-leak-env "kubectl exec env-leak -- curl -s localhost:9898/env | jq -r '.[] | select(startswith(\"API_TOKEN\"))'"
cap p06-token-decode "kubectl get secret api-token -o jsonpath='{.data.token}' | base64 -d; echo"
cap p06-leak-delete 'kubectl delete pod env-leak && kubectl delete secret api-token'

cap p06-cache-apply 'kubectl apply -f 06-config/cache.yaml'
cap p06-deploy-apply 'kubectl apply -f 06-config/deployment.yaml'
cap p06-rollout 'kubectl rollout status deployment/podinfo'
must kubectl rollout status deployment/cache --timeout=120s

cap p06-pf 'kubectl port-forward service/podinfo 8080:80 > /dev/null 2>&1 &'
cap p06-pf-tls 'kubectl port-forward deployment/podinfo 8443:8443 > /dev/null 2>&1 &'
must sleep 3
cap p06-message 'curl -s localhost:8080 | jq -r .message'
cap p06-configs 'curl -s localhost:8080/configs'
cap p06-env 'kubectl exec deploy/podinfo -- printenv PODINFO_UI_MESSAGE PODINFO_LEVEL'
cap p06-files 'kubectl exec deploy/podinfo -- ls -l /podinfo/config /podinfo/tls'
cap p06-https 'curl -s --cacert tls.crt https://localhost:8443/version'
cap p06-cache-write 'curl -s -X POST -d "hello from the cache" localhost:8080/cache/greeting'
cap p06-cache-read 'curl -s localhost:8080/cache/greeting'
cap p06-cache-cli 'kubectl exec deploy/cache -- valkey-cli CONFIG GET maxmemory-policy'

must "sed -i 's/Hello from a ConfigMap/Hello again/; s/newCheckout: false/newCheckout: true/; s/Autumn sale/Winter sale/' 06-config/configmap.yaml"
cap p06-cm-diff 'kubectl diff -f 06-config/configmap.yaml'
cap p06-cm-apply2 'kubectl apply -f 06-config/configmap.yaml'
cap p06-propagation "time (until curl -s localhost:8080/configs | grep -q 'Winter sale'; do sleep 5; done)"
cap p06-configs-after 'curl -s localhost:8080/configs'
cap p06-message-after 'curl -s localhost:8080 | jq -r .message'
cap p06-restart 'kubectl rollout restart deployment/podinfo'
cap p06-restart-status 'kubectl rollout status deployment/podinfo'
cap p06-pf-restart 'kill %1 %2; kubectl port-forward service/podinfo 8080:80 > /dev/null 2>&1 &'
must sleep 3
cap p06-message-new 'curl -s localhost:8080 | jq -r .message'

cap p06-tls-serial-old 'openssl x509 -in tls.crt -noout -serial'
cap p06-tls-renew 'openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -nodes -days 30 -keyout tls.key -out tls.crt -subj "/CN=podinfo.demo.svc" -addext "subjectAltName=DNS:podinfo.demo.svc,DNS:localhost"'
cap p06-tls-update 'kubectl create secret tls podinfo-tls --cert=tls.crt --key=tls.key --dry-run=client -o yaml | kubectl apply -f -'
cap p06-tls-serial-new 'openssl x509 -in tls.crt -noout -serial'
cap p06-tls-restart 'kubectl rollout restart deployment/podinfo'
must kubectl rollout status deployment/podinfo --timeout=180s
cap p06-pf-tls2 'kubectl port-forward deployment/podinfo 8443:8443 > /dev/null 2>&1 &'
must sleep 3
cap p06-tls-served 'openssl s_client -connect localhost:8443 < /dev/null 2>/dev/null | openssl x509 -noout -serial'

cap p06-immutable-apply 'kubectl apply -f 06-config/release-info.yaml'
cap p06-immutable-patch "kubectl patch configmap release-info -p '{\"data\":{\"version\":\"2026.11\"}}'"

cap p06-kustomize 'kubectl kustomize 06-config/kustomize | head -n 12'
cap p06-kustomize-refs 'kubectl kustomize 06-config/kustomize | grep "name: podinfo-config"'
must "sed -i 's/Hello from Kustomize/Hello again from Kustomize/' 06-config/kustomize/kustomization.yaml"
cap p06-kustomize-refs2 'kubectl kustomize 06-config/kustomize | grep "name: podinfo-config"'
cap p06-pf-stop 'kill %1 %2'
