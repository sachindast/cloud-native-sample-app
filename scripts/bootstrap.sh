#!/usr/bin/env bash
set -x

set -euo pipefail

###############################################
# Cloud Native DevOps Platform
# Bootstrap Script
###############################################

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

print_header() {
    echo
    echo "======================================================="
    echo "      Cloud Native DevOps Platform Bootstrap"
    echo "======================================================="
    echo
}

print_step() {
    echo
    echo "-------------------------------------------------------"
    echo "$1"
    echo "-------------------------------------------------------"
}

print_success() {
    echo "✔ $1"
}

print_header

###############################################
# Step 1 - Create Amazon ECR
###############################################

print_step "[1/6] Creating Amazon ECR"

cd "$ROOT_DIR/terraform-ecr"

terraform init
terraform apply -auto-approve

print_success "Amazon ECR created"

###############################################
# Step 2 - Create EKS Infrastructure
###############################################

print_step "[2/6] Creating Amazon EKS Infrastructure"

cd "$ROOT_DIR/terraform"

terraform init
terraform apply -auto-approve

print_success "Amazon EKS infrastructure created"

###############################################
# Step 3 - Configure kubeconfig
###############################################

print_step "[3/6] Configuring kubeconfig"

aws eks update-kubeconfig \
    --region ap-south-1 \
    --name devops-platform

print_success "kubeconfig updated"

###############################################
# Step 4 - Verify Kubernetes Connectivity
###############################################

print_step "[4/6] Verifying Kubernetes Cluster"

kubectl cluster-info
kubectl get nodes

print_success "Cluster is reachable"

###############################################
# Step 5 - Install NGINX Ingress Controller
###############################################

print_step "[5/6] Installing NGINX Ingress Controller"

kubectl create namespace ingress-nginx \
    --dry-run=client -o yaml | kubectl apply -f -

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx >/dev/null 2>&1 || true
helm repo update

helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
    --namespace ingress-nginx

print_success "NGINX Ingress installed"

###############################################
# Step 6 - Wait for Ingress Controller
###############################################

print_step "[6/6] Waiting for Ingress Controller"

kubectl rollout status deployment/ingress-nginx-controller \
    -n ingress-nginx \
    --timeout=10m

print_success "Ingress Controller is Ready"

###############################################
# Bootstrap Complete
###############################################

echo
echo "======================================================="
echo "        Platform Bootstrap Completed Successfully"
echo "======================================================="
echo
echo "Platform Status"
echo "---------------"
echo "✔ Amazon ECR"
echo "✔ Amazon EKS"
echo "✔ kubeconfig configured"
echo "✔ Kubernetes cluster reachable"
echo "✔ NGINX Ingress installed"
echo "✔ Ingress Controller ready"
echo
echo "Next Steps"
echo "----------"
echo "1. Run Azure DevOps EKS CI Pipeline"
echo "   (Build application and push image to Amazon ECR)"
echo
echo "2. Deploy the application"
echo
echo "   cd helm/sample-node-app"
echo "   helm install sample-node-app ."
echo
echo "Happy Deploying! 🚀"