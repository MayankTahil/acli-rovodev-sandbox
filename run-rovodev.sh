#!/bin/bash

# Script to run the rovodev Docker container with proper configuration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

print_feature() {
    echo -e "${BLUE}[FEATURE]${NC} $1"
}

# Display help information
show_help() {
    echo "Usage: ./run-rovodev.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --rebuild                  Rebuild Docker image (only rebuilds when this flag is set)"
    echo "  --persistence=MODE         Enable persistence (MODE: shared, instance)"
    echo "  --instance-id=ID           Set specific instance ID for instance persistence mode"
    echo "  -h, --help                 Show this help message"
    echo ""
    echo "Features:"
    echo "  • SSH Agent Forwarding     Automatically enabled when SSH_AUTH_SOCK is set"
    echo "                             Compatible with 1Password SSH agent"
    echo ""
    echo "Examples:"
    echo "  ./run-rovodev.sh                           # Run with default settings"
    echo "  ./run-rovodev.sh -h                        # Show help message"
    echo "  ./run-rovodev.sh --rebuild                 # Rebuild Docker image"
    echo "  ./run-rovodev.sh --persistence=shared      # Use shared persistence"
    echo "  ./run-rovodev.sh --persistence=instance    # Use instance-specific persistence"
    echo ""
}

# Check for help flag
for arg in "$@"; do
    if [ "$arg" == "--help" ] || [ "$arg" == "-h" ]; then
        show_help
        exit 0
    fi
done

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

# Detect platform architecture
PLATFORM=""
if [[ $(uname -m) == "arm64" ]] || [[ $(uname -m) == "aarch64" ]]; then
    PLATFORM="--platform linux/arm64"
    print_status "Detected ARM64 architecture (Apple Silicon)"
elif [[ $(uname -m) == "x86_64" ]]; then
    PLATFORM="--platform linux/amd64"
    print_status "Detected AMD64 architecture"
fi

# Initialize persistence variables
PERSISTENCE_MODE=""
INSTANCE_ID=""
PERSISTENCE_MOUNT=""
PERSISTENCE_ENV=""

# Check for flags
REBUILD=false
for arg in "$@"; do
    case "$arg" in
        --rebuild)
            REBUILD=true
            print_status "Force rebuild flag detected. Will rebuild Docker image."
            ;;
        --persistence=*)
            PERSISTENCE_MODE="${arg#*=}"
            if [ "$PERSISTENCE_MODE" != "shared" ] && [ "$PERSISTENCE_MODE" != "instance" ]; then
                print_error "Invalid persistence mode: $PERSISTENCE_MODE"
                print_status "Valid modes are: shared, instance"
                exit 1
            fi
            print_feature "Persistence mode: $PERSISTENCE_MODE"
            ;;
        --instance-id=*)
            INSTANCE_ID="${arg#*=}"
            print_feature "Using instance ID: $INSTANCE_ID"
            ;;
        *)
            # Keep other arguments for passing to the container
            ;;
    esac
done

# Setup persistence if enabled
if [ -n "$PERSISTENCE_MODE" ]; then
    # Create persistence directory if it doesn't exist
    PERSISTENCE_DIR="./.rovodev/persistence"
    mkdir -p "$PERSISTENCE_DIR"
    
    # Set up persistence mount and environment variables
    PERSISTENCE_MOUNT="-v ${PERSISTENCE_DIR}:/persistence"
    PERSISTENCE_ENV="-e PERSISTENCE_MODE=${PERSISTENCE_MODE}"
    
    # Add instance ID if specified
    if [ -n "$INSTANCE_ID" ] && [ "$PERSISTENCE_MODE" = "instance" ]; then
        PERSISTENCE_ENV="${PERSISTENCE_ENV} -e INSTANCE_ID=${INSTANCE_ID}"
    fi
    
    print_feature "Persistence directory: ${PERSISTENCE_DIR}"
fi

# Check if we need to rebuild the Docker image
NEED_REBUILD=false
if [ "$REBUILD" = true ]; then
    print_status "Force rebuild flag detected. Will rebuild Docker image."
    NEED_REBUILD=true
elif ! docker image inspect rovodev:latest >/dev/null 2>&1; then
    print_status "Docker image doesn't exist. Will build it."
    NEED_REBUILD=true
else
    # Calculate hash of current Dockerfile
    CURRENT_DOCKERFILE_HASH=$(sha256sum Dockerfile 2>/dev/null || shasum -a 256 Dockerfile 2>/dev/null || echo "HASH_ERROR")
    
    # Check if we have a stored hash from previous build
    HASH_FILE=".dockerfile_hash"
    STORED_HASH=""
    if [ -f "$HASH_FILE" ]; then
        STORED_HASH=$(cat "$HASH_FILE")
    fi
    
    # Check if Dockerfile has been modified
    if [[ "$CURRENT_DOCKERFILE_HASH" != "HASH_ERROR" ]] && [ -n "$STORED_HASH" ] && [[ "$CURRENT_DOCKERFILE_HASH" != "$STORED_HASH" ]]; then
        print_warning "Dockerfile has been modified since last build."
        print_warning "Use --rebuild flag to rebuild the Docker image with these changes."
    fi
fi

# Build the Docker image if needed
if [ "$NEED_REBUILD" = true ]; then
    print_status "Building rovodev Docker image for $(uname -m) architecture..."
    docker build ${PLATFORM} -t rovodev:latest .
    
    # Save the current Dockerfile hash for future comparison
    if [[ "$CURRENT_DOCKERFILE_HASH" != "HASH_ERROR" ]]; then
        echo "$CURRENT_DOCKERFILE_HASH" > .dockerfile_hash
        print_status "Saved Dockerfile hash for future comparison."
    fi
else
    print_status "Using existing Docker image."
    print_status "Use --rebuild flag if you want to rebuild the image."
fi

# Stop and remove existing container if it exists
if docker ps -a --format 'table {{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    print_status "Stopping and removing existing container: ${CONTAINER_NAME}"
    docker stop "${CONTAINER_NAME}" >/dev/null 2>&1 || true
    docker rm "${CONTAINER_NAME}" >/dev/null 2>&1 || true
fi

# Get the current directory for mounting
CURRENT_DIR=$(pwd)

# Using environment variables for Git authentication instead of SSH agent forwarding
print_feature "Using environment variables for Git authentication"
print_status "Make sure GIT_USERNAME and GIT_PASSWORD are set in your .env file"

print_status "Starting rovodev container..."
print_status "Mounting current directory: ${CURRENT_DIR} -> /workspace"

# Run the container with environment variables and volume mount
docker run -it \
    --name "${CONTAINER_NAME}" \
    ${PLATFORM} \
    --env-file .env \
    ${PERSISTENCE_ENV} \
    -v "${CURRENT_DIR}:/workspace" \
    ${PERSISTENCE_MOUNT} \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -w /workspace \
    rovodev:latest

print_status "Container ${CONTAINER_NAME} has exited."