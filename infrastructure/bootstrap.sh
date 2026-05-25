#!/bin/bash

set -x

echo "Creating kind cluster"

kind create cluster --config infrastructure/kind-config.yaml

echo "Installing ingress controller"

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

sleep 30

echo "Waiting for ingress controller"

kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s

echo "Bootstrap completed"