#!/bin/bash

set -euo pipefail

# Error Team - Terraform Backend Initialization Script
# Initializes Terraform with Azure Storage backend for remote state

PREFIX="${PREFIX:-errorteam}"
LOCATION="${LOCATION:-eastus}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if we're in the terraform directory
if [[ ! -f "main.tf" ]]; then
    print_error "Please run this script from the terraform directory!"
    exit 1
fi

# Source Azure credentials if available
if [[ -f "../.azure-credentials" ]]; then
    source "../.azure-credentials"
    print_success "Loaded Azure credentials from .azure-credentials"
else
    print_warning "No .azure-credentials file found. Make sure setup-azure.sh has been run."
fi

# Validate required environment variables
if [[ -z "${ARM_CLIENT_ID:-}" ]] || [[ -z "${ARM_CLIENT_SECRET:-}" ]] || [[ -z "${ARM_TENANT_ID:-}" ]] || [[ -z "${ARM_SUBSCRIPTION_ID:-}" ]]; then
    print_error "Required Azure credentials not set. Please run setup-azure.sh first."
    exit 1
fi

print_status "Initializing Terraform with Azure remote backend..."
print_status "  Storage Account: ${PREFIX}tfstate"
print_status "  Resource Group: ${PREFIX}-tfstate (ISOLATED)"
print_status "  Container: ${PREFIX}-tfstate"

# Initialize Terraform
terraform init \
    -backend-config="resource_group_name=${PREFIX}-tfstate" \
    -backend-config="storage_account_name=${PREFIX}tfstate" \
    -backend-config="container_name=${PREFIX}-tfstate" \
    -backend-config="key=terraform.tfstate" \
    -backend-config="access_key=${STORAGE_KEY}"

if [[ $? -eq 0 ]]; then
    print_success "Terraform initialized successfully with remote backend!"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Remote State Configuration:"
    echo "  Resource Group: ${PREFIX}-tfstate"
    echo "  Storage Account: ${PREFIX}tfstate"
    echo "  Container: ${PREFIX}-tfstate"
    echo "  State File: terraform.tfstate"
    echo ""
    echo "Benefits:"
    echo "  ✓ State stored remotely in Azure Storage"
    echo "  ✓ State locking enabled (prevents concurrent modifications)"
    echo "  ✓ State isolated in separate resource group"
    echo "  ✓ Encrypted at rest"
    echo "  ✓ Team collaboration ready"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    print_status "Next Steps:"
    echo "  1. Review/edit terraform.tfvars"
    echo "  2. Run: terraform plan -out=tfplan"
    echo "  3. Run: terraform apply tfplan"
else
    print_error "Terraform initialization failed!"
    exit 1
fi
