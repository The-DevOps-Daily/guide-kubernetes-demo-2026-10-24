# Part 2: create the local cluster with kind and point kubectl at it.
cap p02-kind-version 'kind version'
cap p02-kubectl-client 'kubectl version --client'
cap p02-helm-version 'helm version'

cap p02-create 'kind create cluster --config kind-config.yaml'
cap p02-cluster-info 'kubectl cluster-info --context kind-k8s-guide'
cap p02-nodes 'kubectl get nodes'
cap p02-wait 'kubectl wait --for=condition=Ready nodes --all --timeout=120s'
cap p02-nodes-ready 'kubectl get nodes'
cap p02-nodes-wide 'kubectl get nodes -o wide'
cap p02-version 'kubectl version'
cap p02-docker-ps "docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Ports}}'"
cap p02-kind-get 'kind get clusters'
cap p02-contexts 'kubectl config get-contexts'

cap p02-ns-create 'kubectl create namespace demo'
cap p02-ns-set 'kubectl config set-context --current --namespace=demo'
cap p02-ns-show "kubectl config view --minify -o jsonpath='{..namespace}'"
cap p02-get-pods 'kubectl get pods'
cap p02-get-ns 'kubectl get namespaces'
cap p02-storageclass 'kubectl get storageclass'

cap p02-delete 'kind delete cluster --name k8s-guide'
