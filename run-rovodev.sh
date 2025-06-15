#!/bin/bash

# Script to run the rovodev Docker container with proper configuration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if .env file exists
if [ ! -f ".env" ]; then
    print_error ".env file not found!"
    if [ -f ".env.template" ]; then
        print_status "Creating .env from template..."
        cp .env.template .env
    else
        print_status "Creating .env template..."
        cat > .env << 'EOF'
# Atlassian CLI Authentication Environment Variables
ATLASSIAN_USERNAME=
ATLASSIAN_API_TOKEN=
CONTAINER_NAME=rovodev-workspace
EOF
    fi
    print_warning "Please edit .env file with your Atlassian credentials before running again."
    exit 1
fi

# Source environment variables
source .env

# Validate required environment variables
if [ -z "$ATLASSIAN_USERNAME" ] || [ -z "$ATLASSIAN_API_TOKEN" ]; then
    print_error "Missing required environment variables in .env file!"
    print_status "Please set ATLASSIAN_USERNAME and ATLASSIAN_API_TOKEN"
    exit 1
fi

# Set default container name if not provided
CONTAINER_NAME=${CONTAINER_NAME:-rovodev-workspace}

# Build the Docker image if it doesn't exist
if ! docker image inspect rovodev:latest >/dev/null 2>&1; then
    print_status "Building rovodev Docker image..."
    docker build -t rovodev:latest .
fi

# Stop and remove existing container if it exists
if docker ps -a --format 'table {{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    print_status "Stopping and removing existing container: ${CONTAINER_NAME}"
    docker stop "${CONTAINER_NAME}" >/dev/null 2>&1 || true
    docker rm "${CONTAINER_NAME}" >/dev/null 2>&1 || true
fi

# Get the current directory for mounting
CURRENT_DIR=$(pwd)

print_status "Starting rovodev container..."
print_status "Mounting current directory: ${CURRENT_DIR} -> /workspace"

# Run the container with environment variables and volume mount
docker run -it \
    --name "${CONTAINER_NAME}" \
    --env-file .env \
    -v "${CURRENT_DIR}:/workspace" \
    -w /workspace \
    rovodev:latest "$@"

print_status "Container ${CONTAINER_NAME} has exited."