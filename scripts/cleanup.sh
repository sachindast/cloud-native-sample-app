#!/usr/bin/env bash

set -euo pipefail

###############################################
# Cloud Native DevOps Platform
# Cleanup Script
###############################################

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

###############################################
# Helper Functions
###############################################

print_header() {
    echo
    echo "======================================================="
    echo "      Cloud Native DevOps Platform Cleanup"
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

###############################################
# Confirmation
###############################################

confirm_cleanup() {

    echo
    echo "======================================================="
    echo "WARNING!"
    echo "======================================================="
    echo
    echo "This operation will permanently destroy:"
    echo
    echo "✔ Sample Node Application"
    echo "✔ NGINX Ingress Controller"
    echo "✔ Amazon EKS Cluster"
    echo "✔ Worker Nodes"
    echo "✔ VPC Resources"
    echo "✔ Amazon ECR Repository"
    echo
    read -rp "Type YES to continue: " CONFIRM

    if [[ "$CONFIRM" != "YES" ]]; then
        echo
        echo "Cleanup cancelled."
        exit 0
    fi
}

###############################################
# Step 1 - Remove Application
###############################################

remove_application() {

    print_step "[1/4] Removing Sample Node Application"

    if helm status sample-node-app >/dev/null 2>&1; then
        helm uninstall sample-node-app
        print_success "Application removed"
    else
        echo "Application not found. Skipping."
    fi
}

###############################################
# Step 2 - Remove NGINX Ingress
###############################################

remove_ingress() {

    print_step "[2/4] Removing NGINX Ingress Controller"

    if helm status ingress-nginx -n ingress-nginx >/dev/null 2>&1; then
        helm uninstall ingress-nginx -n ingress-nginx
        print_success "NGINX Ingress removed"
    else
        echo "NGINX Ingress not found. Skipping."
    fi
}

###############################################
# Step 3 - Destroy Amazon EKS
###############################################

destroy_eks() {

    print_step "[3/4] Destroying Amazon EKS Infrastructure"

    cd "$ROOT_DIR/terraform"

    terraform init
    terraform destroy -auto-approve

    print_success "Amazon EKS infrastructure destroyed"
}

###############################################
# Step 4 - Destroy Amazon ECR
###############################################

destroy_ecr() {

    print_step "[4/4] Destroying Amazon ECR"

    cd "$ROOT_DIR/terraform-ecr"

    terraform init
    terraform destroy -auto-approve

    print_success "Amazon ECR destroyed"
}

###############################################
# Main
###############################################

print_header

check_prerequisites

check_aws_login

confirm_cleanup

remove_application

remove_ingress

destroy_eks

destroy_ecr

echo
echo "======================================================="
echo " Platform Cleanup Completed Successfully"
echo "======================================================="
echo
echo "Resources Removed"
echo "-----------------"
echo "✔ Sample Node Application"
echo "✔ NGINX Ingress Controller"
echo "✔ Amazon EKS Infrastructure"
echo "✔ Amazon ECR Repository"
echo
echo "Happy Coding! 🚀"