#!/bin/bash

set -euo pipefail

# Error Team - Azure Infrastructure Setup Script
# This script creates ACR and Storage Account in a separate resource group

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

# Validate required environment variables
if [[ -z "${ARM_CLIENT_ID:-}" ]] || [[ -z "${ARM_CLIENT_SECRET:-}" ]] || [[ -z "${ARM_TENANT_ID:-}" ]]; then
    print_error "Required Azure credentials not set. Please set ARM_CLIENT_ID, ARM_CLIENT_SECRET, and ARM_TENANT_ID."
    exit 1
fi

print_status "Authenticating with Azure using service principal..."
az login --service-principal \
    --username "$ARM_CLIENT_ID" \
    --password "$ARM_CLIENT_SECRET" \
    --tenant "$ARM_TENANT_ID" \
    --output none
print_success "Successfully authenticated with Azure."

# Set subscription
if [[ -n "${ARM_SUBSCRIPTION_ID:-}" ]]; then
    print_status "Setting Azure subscription..."
    az account set --subscription "$ARM_SUBSCRIPTION_ID"
    print_success "Subscription set to $ARM_SUBSCRIPTION_ID"
fi

# Create solution resource group (empty, for Terraform to use)
print_status "Checking if resource group '${PREFIX}-final-solution' exists..."
if az group exists --name "${PREFIX}-final-solution"; then
    print_success "Resource group '${PREFIX}-final-solution' already exists."
else
    print_status "Creating resource group '${PREFIX}-final-solution'..."
    az group create --name "${PREFIX}-final-solution" --location "$LOCATION" --output none
    print_success "Resource group '${PREFIX}-final-solution' created."
fi

# Create isolated resource group for Terraform state (completely separate)
print_status "Checking if resource group '${PREFIX}-tfstate' exists..."
if az group exists --name "${PREFIX}-tfstate"; then
    print_success "Resource group '${PREFIX}-tfstate' already exists."
else
    print_status "Creating isolated resource group '${PREFIX}-tfstate' for Terraform state..."
    az group create --name "${PREFIX}-tfstate" --location "$LOCATION" --output none
    print_success "Resource group '${PREFIX}-tfstate' created."
fi

# Create infra resource group (for ACR only)
print_status "Checking if resource group '${PREFIX}-final-infra' exists..."
if az group exists --name "${PREFIX}-final-infra"; then
    print_success "Resource group '${PREFIX}-final-infra' already exists."
else
    print_status "Creating resource group '${PREFIX}-final-infra'..."
    az group create --name "${PREFIX}-final-infra" --location "$LOCATION" --output none
    print_success "Resource group '${PREFIX}-final-infra' created."
fi

# Create storage account for Terraform state in ISOLATED resource group
print_status "Checking if storage account '${PREFIX}tfstate' exists..."
if az storage account show --name "${PREFIX}tfstate" --resource-group "${PREFIX}-tfstate" &> /dev/null; then
    print_success "Storage account '${PREFIX}tfstate' already exists."
else
    print_status "Creating storage account '${PREFIX}tfstate' in isolated resource group..."
    az storage account create \
        --name "${PREFIX}tfstate" \
        --resource-group "${PREFIX}-tfstate" \
        --location "$LOCATION" \
        --sku Standard_LRS \
        --kind StorageV2 \
        --access-tier Hot \
        --allow-blob-public-access false \
        --min-tls-version TLS1_2 \
        --https-only true \
        --output none
    print_success "Storage account '${PREFIX}tfstate' created in isolated resource group."
fi

# Get storage account key
print_status "Retrieving storage account key..."
STORAGE_KEY=$(az storage account keys list \
    --resource-group "${PREFIX}-tfstate" \
    --account-name "${PREFIX}tfstate" \
    --query "[0].value" -o tsv)

# Create storage container for Terraform state
print_status "Checking if storage container '${PREFIX}-tfstate' exists..."
if az storage container show --name "${PREFIX}-tfstate" --account-name "${PREFIX}tfstate" --account-key "$STORAGE_KEY" &> /dev/null; then
    print_success "Storage container '${PREFIX}-tfstate' already exists."
else
    print_status "Creating storage container '${PREFIX}-tfstate'..."
    az storage container create \
        --name "${PREFIX}-tfstate" \
        --account-name "${PREFIX}tfstate" \
        --account-key "$STORAGE_KEY" \
        --output none
    print_success "Storage container '${PREFIX}-tfstate' created."
fi

# Create Azure Container Registry
ACR_NAME="${PREFIX}acr"
print_status "Checking if Azure Container Registry '${ACR_NAME}' exists..."
if az acr show --name "${ACR_NAME}" --resource-group "${PREFIX}-final-infra" &> /dev/null; then
    print_success "Azure Container Registry '${ACR_NAME}' already exists."
else
    print_status "Creating Azure Container Registry '${ACR_NAME}'..."
    az acr create \
        --name "${ACR_NAME}" \
        --resource-group "${PREFIX}-final-infra" \
        --location "$LOCATION" \
        --sku Basic \
        --admin-enabled true \
        --output none
    print_success "Azure Container Registry '${ACR_NAME}' created."
fi

# Get ACR credentials
print_status "Retrieving ACR credentials..."
ACR_LOGIN_SERVER=$(az acr show --name "${ACR_NAME}" --resource-group "${PREFIX}-final-infra" --query "loginServer" -o tsv)
ACR_USERNAME=$(az acr credential show --name "${ACR_NAME}" --query "username" -o tsv)
ACR_PASSWORD=$(az acr credential show --name "${ACR_NAME}" --query "passwords[0].value" -o tsv)

echo ""
echo ""
print_success "=== Deployment Summary ==="
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Team: Error Team"
echo "Prefix: ${PREFIX}"
echo "Location: ${LOCATION}"
echo ""
echo "Resource Groups:"
echo "  - Solution RG: ${PREFIX}-final-solution (empty - for Terraform)"
echo "  - Infra RG: ${PREFIX}-final-infra (ACR only)"
echo "  - TF State RG: ${PREFIX}-tfstate (ISOLATED - Storage only)"
echo ""
echo "Storage Account (Terraform State):"
echo "  - Name: ${PREFIX}tfstate"
echo "  - Container: ${PREFIX}-tfstate"
echo "  - Resource Group: ${PREFIX}-tfstate (ISOLATED)"
echo ""
echo "Azure Container Registry:"
echo "  - Name: ${ACR_NAME}"
echo "  - Login Server: ${ACR_LOGIN_SERVER}"
echo "  - Admin Username: ${ACR_USERNAME}"
echo ""
echo "Next Steps:"
echo "  1. Save ACR credentials securely"
echo "  2. Run push-images.sh to push Docker images to ACR"
echo "  3. Initialize Terraform with the created backend"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Save credentials to file
CREDS_FILE=".azure-credentials"
cat > "$CREDS_FILE" << EOF
# Azure Infrastructure Credentials - Error Team
# Generated: $(date)

export PREFIX="${PREFIX}"
export LOCATION="${LOCATION}"
export ACR_NAME="${ACR_NAME}"
export ACR_LOGIN_SERVER="${ACR_LOGIN_SERVER}"
export ACR_USERNAME="${ACR_USERNAME}"
export ACR_PASSWORD="${ACR_PASSWORD}"
export STORAGE_ACCOUNT="${PREFIX}tfstate"
export STORAGE_CONTAINER="${PREFIX}-tfstate"
export STORAGE_KEY="${STORAGE_KEY}"
EOF

chmod 600 "$CREDS_FILE"
print_success "Credentials saved to ${CREDS_FILE}"
print_warning "Keep this file secure and add it to .gitignore!"
