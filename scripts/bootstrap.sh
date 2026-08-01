#!/usr/bin/env bash

set -euo pipefail

###############################################
# Cloud Native DevOps Platform
# Bootstrap Script
###############################################

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

AWS_REGION="ap-south-1"
CLUSTER_NAME="devops-platform"

###############################################
# Helper Functions
###############################################

print_header() {
    echo
    echo "======================================================="
    echo "      Cloud Native DevOps Platform Bootstrap"
    echo "======================================================="
    echo
}

check_prerequisites() {

    print_step "[Prerequisite] Checking required tools"

    local tools=("terraform" "kubectl" "helm" "aws")

    for tool in "${tools[@]}"; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            echo "✖ Error: '$tool' is not installed."
            exit 1
        fi
    done

    print_success "Required tools are installed"
}

check_aws_login() {

    print_step "[Prerequisite] Checking AWS Authentication"

    aws sts get-caller-identity >/dev/null

    print_success "AWS authentication verified"
}

setup_helm_repo() {

    print_step "[Prerequisite] Checking Helm Repository"

    if ! helm repo list | grep -q ingress-nginx; then
        helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
    fi

    helm repo update

    print_success "Helm repository ready"
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

###############################################
# Step 1 - Create Amazon ECR
###############################################

create_ecr() {

    print_step "[1/6] Creating Amazon ECR"

    cd "$ROOT_DIR/terraform-ecr"

    terraform init
    terraform apply -auto-approve

    print_success "Amazon ECR is ready"
}

###############################################
# Step 2 - Create Amazon EKS
###############################################

create_eks() {

    print_step "[2/6] Creating Amazon EKS Infrastructure"

    cd "$ROOT_DIR/terraform"

    terraform init
    terraform apply -auto-approve

    print_success "Amazon EKS is ready"
}

###############################################
# Step 3 - Configure kubeconfig
###############################################

configure_kubeconfig() {

    print_step "[3/6] Configuring kubeconfig"

    aws eks update-kubeconfig \
        --region "$AWS_REGION" \
        --name "$CLUSTER_NAME"

    print_success "kubeconfig configured"
}

###############################################
# Step 4 - Verify Cluster
###############################################

verify_cluster() {

    print_step "[4/6] Verifying Kubernetes Cluster"

    kubectl cluster-info
    kubectl get nodes

    print_success "Cluster connectivity verified"
}

###############################################
# Step 5 - Install NGINX Ingress
###############################################

install_ingress() {

    print_step "[5/6] Installing NGINX Ingress Controller"

    kubectl create namespace ingress-nginx \
        --dry-run=client -o yaml | kubectl apply -f -

    helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx >/dev/null 2>&1 || true

    helm repo update

    helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
        --namespace ingress-nginx

    print_success "NGINX Ingress installed"
}

###############################################
# Step 6 - Wait for Ingress
###############################################

wait_for_ingress() {

    print_step "[6/6] Waiting for Ingress Controller"

    kubectl rollout status deployment/ingress-nginx-controller \
        -n ingress-nginx \
        --timeout=10m

    echo
    echo "Waiting for AWS LoadBalancer..."

    kubectl get svc -n ingress-nginx

    print_success "Ingress Controller is Ready"
}

###############################################
# Main
###############################################

print_header

check_prerequisites

check_aws_login

setup_helm_repo

create_ecr

create_eks

configure_kubeconfig

verify_cluster

install_ingress

wait_for_ingress

echo
echo "======================================================="
echo " Platform Bootstrap Completed Successfully"
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