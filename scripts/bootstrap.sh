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

    print_step "[Prerequisite] Checking Helm Repositories"

    if ! helm repo list | grep -q "^ingress-nginx"; then
        helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
    fi

    if ! helm repo list | grep -q "^argo"; then
        helm repo add argo https://argoproj.github.io/argo-helm
    fi

    helm repo update

    print_success "Helm repositories are ready"
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

    print_step "[1/8] Creating Amazon ECR"

    cd "$ROOT_DIR/terraform-ecr"

    terraform init
    terraform apply -auto-approve

    print_success "Amazon ECR is ready"
}

###############################################
# Step 2 - Create Amazon EKS
###############################################

create_eks() {

    print_step "[2/8] Creating Amazon EKS Infrastructure"

    cd "$ROOT_DIR/terraform"

    terraform init
    terraform apply -auto-approve

    print_success "Amazon EKS is ready"
}

###############################################
# Step 3 - Configure kubeconfig
###############################################

configure_kubeconfig() {

    print_step "[3/8] Configuring kubeconfig"

    aws eks update-kubeconfig \
        --region "$AWS_REGION" \
        --name "$CLUSTER_NAME"

    print_success "kubeconfig configured"
}

###############################################
# Step 4 - Verify Cluster
###############################################

verify_cluster() {

    print_step "[4/8] Verifying Kubernetes Cluster"

    kubectl cluster-info
    kubectl get nodes

    print_success "Cluster connectivity verified"
}

###############################################
# Step 5 - Install NGINX Ingress
###############################################

install_ingress() {

    print_step "[5/8] Installing NGINX Ingress Controller"

    kubectl create namespace ingress-nginx \
        --dry-run=client -o yaml | kubectl apply -f -

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
# Step 7 - Install Argo CD
###############################################

install_argocd() {

    print_step "[7/8] Installing Argo CD"

    kubectl create namespace argocd \
        --dry-run=client -o yaml | kubectl apply -f -

    helm upgrade --install argocd argo/argo-cd \
        --namespace argocd

    print_success "Argo CD installed"
}

###############################################
# Step 8 - Wait for Argo CD
###############################################

wait_for_argocd() {

    print_step "[8/8] Waiting for Argo CD"

    kubectl rollout status deployment/argocd-server \
        -n argocd \
        --timeout=10m

    kubectl rollout status deployment/argocd-repo-server \
        -n argocd \
        --timeout=10m

    kubectl rollout status deployment/argocd-dex-server \
        -n argocd \
        --timeout=10m

    kubectl rollout status deployment/argocd-applicationset-controller \
        -n argocd \
        --timeout=10m

    kubectl rollout status deployment/argocd-notifications-controller \
        -n argocd \
        --timeout=10m

    kubectl rollout status statefulset/argocd-application-controller \
        -n argocd \
        --timeout=10m

    print_success "Argo CD is Ready"
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

install_argocd

wait_for_argocd

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
echo "✔ Argo CD installed"
echo "✔ Argo CD ready"
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