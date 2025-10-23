#!/bin/bash

set -euo pipefail

# Error Team - Docker Image Push Script
# Pushes existing Docker images to ACR and Docker Hub

# Source Azure credentials if available
if [[ -f ".azure-credentials" ]]; then
    source .azure-credentials
fi

PREFIX="${PREFIX:-errorteam}"
ACR_NAME="${ACR_NAME:-${PREFIX}acr}"
ACR_LOGIN_SERVER="${ACR_LOGIN_SERVER:-${ACR_NAME}.azurecr.io}"

BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
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

# Check if Docker is running
if ! docker info &> /dev/null; then
    print_error "Docker is not running. Please start Docker and try again."
    exit 1
fi

print_status "Starting image push process for Error Team..."
echo ""

# Login to ACR
if [[ -n "${ACR_USERNAME:-}" ]] && [[ -n "${ACR_PASSWORD:-}" ]]; then
    print_status "Logging into Azure Container Registry..."
    echo "$ACR_PASSWORD" | docker login "$ACR_LOGIN_SERVER" --username "$ACR_USERNAME" --password-stdin
    print_success "Logged into ACR successfully."
else
    print_status "Using Azure CLI for ACR login..."
    az acr login --name "$ACR_NAME"
    print_success "Logged into ACR using Azure CLI."
fi

# Login to Docker Hub
if [[ -n "${DOCKER_HUB_USERNAME:-}" ]] && [[ -n "${DOCKER_HUB_TOKEN:-}" ]]; then
    print_status "Logging into Docker Hub..."
    echo "$DOCKER_HUB_TOKEN" | docker login --username "$DOCKER_HUB_USERNAME" --password-stdin
    print_success "Logged into Docker Hub successfully."
else
    print_status "Skipping Docker Hub login (credentials not provided)."
fi

echo ""
print_status "Processing images..."
echo ""

# Function to tag and push image
push_image() {
    local local_image=$1
    local image_name=$2
    local version=${3:-latest}
    
    print_status "Processing ${image_name}..."
    
    # Tag for ACR
    local acr_tag="${ACR_LOGIN_SERVER}/${image_name}:${version}"
    docker tag "$local_image" "$acr_tag"
    print_status "  Tagged as ${acr_tag}"
    
    # Push to ACR
    docker push "$acr_tag"
    print_success "  Pushed to ACR: ${acr_tag}"
    
    # Tag and push to Docker Hub if credentials are available
    if [[ -n "${DOCKER_HUB_USERNAME:-}" ]]; then
        local hub_tag="${DOCKER_HUB_USERNAME}/${image_name}:${version}"
        docker tag "$local_image" "$hub_tag"
        docker push "$hub_tag"
        print_success "  Pushed to Docker Hub: ${hub_tag}"
    fi
    
    echo ""
}

# Push frontend image
if docker images frontimg:latest -q &> /dev/null; then
    push_image "frontimg:latest" "errorteam-frontend" "latest"
    push_image "frontimg:latest" "errorteam-frontend" "v1.0.0"
else
    print_error "Frontend image not found!"
fi

# Push backend image (check multiple possible names)
if docker images backend-test:latest -q &> /dev/null; then
    push_image "backend-test:latest" "errorteam-backend" "latest"
    push_image "backend-test:latest" "errorteam-backend" "v1.0.0"
elif docker images backimg:latest -q &> /dev/null; then
    push_image "backimg:latest" "errorteam-backend" "latest"
    push_image "backimg:latest" "errorteam-backend" "v1.0.0"
elif docker images final-project-5-backend:latest -q &> /dev/null; then
    push_image "final-project-5-backend:latest" "errorteam-backend" "latest"
    push_image "final-project-5-backend:latest" "errorteam-backend" "v1.0.0"
else
    print_error "Backend image not found!"
fi

# Push PostgreSQL (optional, for local testing)
if docker images postgres:15 -q &> /dev/null; then
    push_image "postgres:15" "errorteam-database" "15"
    print_success "Database image tagged (but using managed Azure PostgreSQL is recommended)"
fi

echo ""
print_success "=== Image Push Complete ==="
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Images pushed to ACR:"
echo "  - ${ACR_LOGIN_SERVER}/errorteam-frontend:latest"
echo "  - ${ACR_LOGIN_SERVER}/errorteam-frontend:v1.0.0"
echo "  - ${ACR_LOGIN_SERVER}/errorteam-backend:latest"
echo "  - ${ACR_LOGIN_SERVER}/errorteam-backend:v1.0.0"
echo ""
echo "ACR Repository List:"
az acr repository list --name "$ACR_NAME" --output table 2>/dev/null || echo "(Run 'az acr repository list --name $ACR_NAME' to see repositories)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
