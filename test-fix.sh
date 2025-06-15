#!/bin/bash

# Test script to verify the Apple Silicon fix

set -e

echo "🧪 Testing Apple Silicon fix for rovodev Docker container"
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're on Apple Silicon
if [[ $(uname -m) == "arm64" ]]; then
    print_status "Detected Apple Silicon (ARM64) - this fix should resolve your issue"
elif [[ $(uname -m) == "x86_64" ]]; then
    print_status "Detected Intel/AMD64 architecture"
else
    print_warning "Unknown architecture: $(uname -m)"
fi

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker and try again."
    exit 1
fi

print_status "Docker is running"

# Remove old image if it exists
if docker image inspect rovodev:latest >/dev/null 2>&1; then
    print_status "Removing old rovodev:latest image..."
    docker rmi rovodev:latest
fi

# Check if .env exists
if [ ! -f ".env" ]; then
    print_warning ".env file not found. Creating from template..."
    if [ -f ".env.template" ]; then
        cp .env.template .env
        print_warning "Please edit .env with your credentials before running the container"
    else
        print_error ".env.template not found"
        exit 1
    fi
fi

print_status "Ready to test! Run './run-rovodev.sh' to build and test the fixed container"
print_status "The container should now work without Rosetta errors on Apple Silicon"

echo ""
echo "🔧 What was fixed:"
echo "  - Architecture detection in Dockerfile"
echo "  - Automatic ARM64/AMD64 binary selection for acli"
echo "  - Platform-specific Docker build in run script"
echo "  - Updated documentation with troubleshooting steps"