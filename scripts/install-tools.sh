#!/usr/bin/env bash
# Installs pinned kind, kubectl and helm for linux/amd64 and checks their SHA-256 sums.
set -euo pipefail

KIND_VERSION=v0.33.0
KUBECTL_VERSION=v1.37.1
HELM_VERSION=v4.3.1

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
cd "$tmp"

curl -fsSLo kind "https://github.com/kubernetes-sigs/kind/releases/download/$KIND_VERSION/kind-linux-amd64"
echo "$(curl -fsSL "https://github.com/kubernetes-sigs/kind/releases/download/$KIND_VERSION/kind-linux-amd64.sha256sum" | awk '{print $1}')  kind" | sha256sum -c

curl -fsSLo kubectl "https://dl.k8s.io/release/$KUBECTL_VERSION/bin/linux/amd64/kubectl"
echo "$(curl -fsSL "https://dl.k8s.io/release/$KUBECTL_VERSION/bin/linux/amd64/kubectl.sha256")  kubectl" | sha256sum -c

curl -fsSLO "https://get.helm.sh/helm-$HELM_VERSION-linux-amd64.tar.gz"
echo "$(curl -fsSL "https://get.helm.sh/helm-$HELM_VERSION-linux-amd64.tar.gz.sha256sum" | awk '{print $1}')  helm-$HELM_VERSION-linux-amd64.tar.gz" | sha256sum -c
tar -xzf "helm-$HELM_VERSION-linux-amd64.tar.gz" linux-amd64/helm

sudo install -m 0755 kind kubectl linux-amd64/helm /usr/local/bin/
kind version
kubectl version --client
helm version
