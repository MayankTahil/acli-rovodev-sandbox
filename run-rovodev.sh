#!/bin/bash

# Script to run the rovodev Docker container with proper configuration

set -e

# Get the directory where the script is located, regardless of where it's called from
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

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

print_help() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --persistence=MODE   Enable persistence (shared or instance)"
    echo "  --instance-id=ID     Set instance ID for instance persistence mode"
    echo ""
    echo "Examples:"
    echo "  $0 --persistence=shared"
    echo "  $0 --persistence=instance --instance-id=my-instance"
}

# Display help information
show_help() {
    echo "Usage: ./run-rovodev.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --persistence=MODE         Enable persistence (MODE: shared, instance)"
    echo "  --instance-id=ID           Set specific instance ID for instance persistence mode"
    echo "  -h, --help                 Show this help message"
    echo ""
    echo "Features:"
    echo "  • Completely standalone    This script works independently with no additional files"
    echo "                             Uses pre-built Docker images (local or official)"
    echo "  • Run from any directory   Script can be run from any directory on your system"
    echo "                             The current directory will be mounted as the workspace"
    echo "  • Auto-configuration       Creates .rovodev/.env file if needed and checks for Docker images"
    echo "  • SSH Agent Forwarding     Automatically enabled when SSH_AUTH_SOCK is set"
    echo "                             Compatible with 1Password SSH agent"
    echo ""
    echo "Examples:"
    echo "  ./run-rovodev.sh                           # Run with default settings"
    echo "  ./run-rovodev.sh -h                        # Show help message"
    echo "  ./run-rovodev.sh --persistence=shared      # Use shared persistence"
    echo "  ./run-rovodev.sh --persistence=instance    # Use instance-specific persistence"
    echo "  cd /path/to/your/project && /path/to/run-rovodev.sh  # Run in a different directory"
    echo ""
}

# Check for help flag
for arg in "$@"; do
    if [ "$arg" == "--help" ] || [ "$arg" == "-h" ]; then
        show_help
        exit 0
    fi
done

# Set standalone mode by default - we don't need any other files
STANDALONE_MODE=true
USE_PREBUILT_IMAGE=true

# Function to check for Docker image
check_docker_image() {
    # Determine architecture
    ARCH=$(uname -m)
    if [[ "$ARCH" == "arm64" ]] || [[ "$ARCH" == "aarch64" ]]; then
        ARCH_TAG="arm64"
    elif [[ "$ARCH" == "x86_64" ]]; then
        ARCH_TAG="x86_64"
    else
        print_warning "Unsupported architecture: $ARCH"
        ARCH_TAG="x86_64"  # Default to x86_64
    fi
    
    # Check if rovodev:latest exists locally
    if docker image inspect rovodev:latest >/dev/null 2>&1; then
        print_status "Found local Docker image: rovodev:latest"
        DOCKER_IMAGE="rovodev:latest"
        return 0
    fi
    
    # Check if architecture-specific image exists locally
    if docker image inspect rovodev:$ARCH_TAG >/dev/null 2>&1; then
        print_status "Found local Docker image: rovodev:$ARCH_TAG"
        DOCKER_IMAGE="rovodev:$ARCH_TAG"
        return 0
    fi
    
    # Check if atlassian/rovodev:latest exists locally
    if docker image inspect atlassian/rovodev:latest >/dev/null 2>&1; then
        print_status "Found local Docker image: atlassian/rovodev:latest"
        DOCKER_IMAGE="atlassian/rovodev:latest"
        return 0
    fi
    
    # Check if mayankt/rovodev-$ARCH_TAG:latest exists locally
    if docker image inspect mayankt/rovodev-$ARCH_TAG:latest >/dev/null 2>&1; then
        print_status "Found local Docker image: mayankt/rovodev-$ARCH_TAG:latest"
        DOCKER_IMAGE="mayankt/rovodev-$ARCH_TAG:latest"
        return 0
    fi
    
    # No local images found, ask what to do
    print_warning "No local rovodev Docker images found."
    echo ""
    echo "Options:"
    echo "1. Pull the architecture-specific Docker image (mayankt/rovodev-$ARCH_TAG:latest)"
    echo "2. Build from source using Dockerfile in current directory"
    echo "3. Exit"
    echo ""
    read -p "Please choose an option (1-3): " choice
    
    case $choice in
        1)
            print_status "Pulling architecture-specific Docker image for $ARCH_TAG..."
            if docker pull mayankt/rovodev-$ARCH_TAG:latest; then
                print_status "Successfully pulled mayankt/rovodev-$ARCH_TAG:latest"
                DOCKER_IMAGE="mayankt/rovodev-$ARCH_TAG:latest"
                return 0
            else
                print_error "Failed to pull Docker image."
                print_error "Please check your internet connection and try again."
                exit 1
            fi
            ;;
        2)
            print_status "Building Docker image from source..."
            
            # Check if Dockerfile exists
            if [ ! -f "Dockerfile" ]; then
                print_error "Dockerfile not found in current directory."
                exit 1
            fi
            
            # Check for .env variables for build
            BUILD_PLATFORM=""
            BUILD_TAG="${DOCKER_IMAGE_TAG:-latest}"
            
            # Use DOCKER_BUILD_PLATFORM from .env if available, otherwise use detected architecture
            if [ -n "$DOCKER_BUILD_PLATFORM" ]; then
                BUILD_PLATFORM="--platform $DOCKER_BUILD_PLATFORM"
                print_status "Using build platform from .env: $DOCKER_BUILD_PLATFORM"
            else
                if [[ "$ARCH_TAG" == "arm64" ]]; then
                    BUILD_PLATFORM="--platform linux/arm64"
                elif [[ "$ARCH_TAG" == "x86_64" ]]; then
                    BUILD_PLATFORM="--platform linux/amd64"
                fi
                print_status "Using detected build platform: ${BUILD_PLATFORM#--platform }"
            fi
            
            # Build the Docker image
            print_status "Building Docker image for $ARCH_TAG architecture with tag $BUILD_TAG..."
            if docker build $BUILD_PLATFORM -t rovodev:$ARCH_TAG -t rovodev:$BUILD_TAG .; then
                print_status "Successfully built Docker image: rovodev:$ARCH_TAG (also tagged as rovodev:$BUILD_TAG)"
                DOCKER_IMAGE="rovodev:$ARCH_TAG"
                return 0
            else
                print_error "Failed to build Docker image."
                exit 1
            fi
            ;;
        3)
            print_status "Exiting"
            exit 0
            ;;
        *)
            print_error "Invalid option"
            exit 1
            ;;
    esac
}

# Determine architecture for default Docker image name
ARCH=$(uname -m)
if [[ "$ARCH" == "arm64" ]] || [[ "$ARCH" == "aarch64" ]]; then
    ARCH_TAG="arm64"
elif [[ "$ARCH" == "x86_64" ]]; then
    ARCH_TAG="x86_64"
else
    print_warning "Unsupported architecture: $ARCH"
    ARCH_TAG="x86_64"  # Default to x86_64
fi

# Set default Docker image name based on architecture
DOCKER_IMAGE="rovodev:$ARCH_TAG"

# Check for Docker image
check_docker_image

# Initialize persistence variables
PERSISTENCE_MODE=""
INSTANCE_ID=""
PERSISTENCE_MOUNT=""
PERSISTENCE_ENV=""

# Get the current directory for configuration
CURRENT_DIR=$(pwd)
ROVODEV_DIR="${CURRENT_DIR}/.rovodev"
ENV_FILE="${ROVODEV_DIR}/.env"

# Create .rovodev directory if it doesn't exist
if [ ! -d "$ROVODEV_DIR" ]; then
    print_status "Creating .rovodev directory in ${CURRENT_DIR}..."
    if ! mkdir -p "$ROVODEV_DIR" 2>/dev/null; then
        print_error "Failed to create .rovodev directory: ${ROVODEV_DIR}"
        print_error "Please check if you have write permissions in the current directory."
        exit 1
    fi
    print_status ".rovodev directory created successfully"
fi

# Check if .env file exists in the .rovodev directory
if [ ! -f "${ENV_FILE}" ]; then
    print_warning ".env file not found in ${ROVODEV_DIR}!"
    
    # Create a default .env file
    print_status "Creating default .env file in ${ROVODEV_DIR}..."
    cat > "${ENV_FILE}" << 'EOF'
# Atlassian CLI Authentication Environment Variables
ATLASSIAN_USERNAME=
ATLASSIAN_API_TOKEN=
CONTAINER_NAME=rovodev-workspace

# Git credentials (optional)
GIT_USERNAME=
GIT_PASSWORD=
GIT_USER_NAME=
GIT_USER_EMAIL=

# Persistence settings
# PERSISTENCE_MODE=shared     # Options: shared, instance
# INSTANCE_ID=my-instance-1   # Only used with instance mode

# Docker build settings (used when building from source)
# DOCKER_BUILD_PLATFORM=linux/amd64    # Options: linux/amd64, linux/arm64
# DOCKER_IMAGE_TAG=latest              # Tag for the built Docker image
EOF
fi
print_warning "Please edit .rovodev/.env file with your Atlassian credentials before running again."
print_status "You can edit it with: nano ${ENV_FILE}"
exit 1

# Source environment variables
source "${ENV_FILE}"

# Print debug info about persistence settings from .env
if [ -n "$PERSISTENCE_MODE" ]; then
    print_status "Loaded from .rovodev/.env: PERSISTENCE_MODE=$PERSISTENCE_MODE"
fi
if [ -n "$INSTANCE_ID" ]; then
    print_status "Loaded from .rovodev/.env: INSTANCE_ID=$INSTANCE_ID"
fi

# Validate required environment variables
if [ -z "$ATLASSIAN_USERNAME" ] || [ -z "$ATLASSIAN_API_TOKEN" ]; then
    print_error "Missing required environment variables in .rovodev/.env file!"
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

# Check for flags
REBUILD=false
for arg in "$@"; do
    case "$arg" in
        --rebuild)
            REBUILD=true
            print_warning "The --rebuild flag is ignored in standard mode."
            print_warning "This script by default uses pre-built Docker images only."
            ;;
        --persistence=*)
            # Command line arguments override .env file settings
            PERSISTENCE_MODE="${arg#*=}"
            if [ "$PERSISTENCE_MODE" != "shared" ] && [ "$PERSISTENCE_MODE" != "instance" ]; then
                print_error "Invalid persistence mode: $PERSISTENCE_MODE"
                print_status "Valid modes are: shared, instance"
                exit 1
            fi
            print_feature "Persistence mode (from command line): $PERSISTENCE_MODE"
            ;;
        --instance-id=*)
            # Command line arguments override .env file settings
            INSTANCE_ID="${arg#*=}"
            print_feature "Using instance ID (from command line): $INSTANCE_ID"
            ;;
        *)
            # Keep other arguments for passing to the container
            ;;
    esac
done

# Validate persistence mode if set
if [ -n "$PERSISTENCE_MODE" ] && [ "$PERSISTENCE_MODE" != "shared" ] && [ "$PERSISTENCE_MODE" != "instance" ]; then
    print_error "Invalid persistence mode in .rovodev/.env file: $PERSISTENCE_MODE"
    print_status "Valid modes are: shared, instance"
    exit 1
fi

# Setup persistence if enabled
if [ -n "$PERSISTENCE_MODE" ]; then
    print_feature "Persistence enabled: ${PERSISTENCE_MODE} mode"
    
    # Get the current directory for persistence
    CURRENT_DIR=$(pwd)
    
    # Specifically create .rovodev/persistence directory in the current working directory
    PERSISTENCE_DIR="${CURRENT_DIR}/.rovodev/persistence"
    
    # Check if the directory already exists
    if [ -d "$PERSISTENCE_DIR" ]; then
        print_status "Using existing persistence directory: ${PERSISTENCE_DIR}"
    else
        print_status "Creating persistence directory: ${PERSISTENCE_DIR}"
        if ! mkdir -p "$PERSISTENCE_DIR" 2>/dev/null; then
            print_error "Failed to create persistence directory: ${PERSISTENCE_DIR}"
            print_error "Please check if you have write permissions in the current directory."
            exit 1
        fi
        print_status "Persistence directory created successfully"
    fi
    
    # Verify the directory is writable
    if [ ! -w "$PERSISTENCE_DIR" ]; then
        print_error "Persistence directory is not writable: ${PERSISTENCE_DIR}"
        print_error "Please check your permissions."
        exit 1
    fi
    
    # Set up persistence mount and environment variables
    PERSISTENCE_MOUNT="-v ${PERSISTENCE_DIR}:/persistence"
    PERSISTENCE_ENV="-e PERSISTENCE_MODE=${PERSISTENCE_MODE}"
    
    # Add instance ID if specified
    if [ -n "$INSTANCE_ID" ] && [ "$PERSISTENCE_MODE" = "instance" ]; then
        PERSISTENCE_ENV="${PERSISTENCE_ENV} -e INSTANCE_ID=${INSTANCE_ID}"
    fi
    
    print_feature "Persistence directory: ${PERSISTENCE_DIR}"
    print_status "This directory will be mounted to /persistence inside the container"
    
    # Create a README file in the persistence directory if it doesn't exist
    if [ ! -f "${PERSISTENCE_DIR}/README.md" ]; then
        print_status "Creating README.md in persistence directory"
        cat > "${PERSISTENCE_DIR}/README.md" << EOF
# Persistence Directory

This directory is used by rovodev to store persistent data across container runs.

- **Mode**: ${PERSISTENCE_MODE}
$([ -n "$INSTANCE_ID" ] && echo "- **Instance ID**: ${INSTANCE_ID}" || echo "")
- **Created**: $(date)

Do not delete this directory if you want to maintain persistence.
EOF
    fi
else
    print_status "Persistence is disabled. No data will be saved between container runs."
    print_status "To enable persistence, set PERSISTENCE_MODE in .rovodev/.env file or use --persistence=shared|instance"
fi

# We're using a pre-built Docker image, so no build step is needed
print_status "Using Docker image: ${DOCKER_IMAGE}"

# Stop and remove existing container if it exists
if docker ps -a --format 'table {{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    print_status "Stopping and removing existing container: ${CONTAINER_NAME}"
    docker stop "${CONTAINER_NAME}" >/dev/null 2>&1 || true
    docker rm "${CONTAINER_NAME}" >/dev/null 2>&1 || true
fi

# Set current directory if not already set
if [ -z "$CURRENT_DIR" ]; then
    CURRENT_DIR=$(pwd)
fi

# Using environment variables for Git authentication instead of SSH agent forwarding
print_feature "Using environment variables for Git authentication"
print_status "Make sure GIT_USERNAME and GIT_PASSWORD are set in your .rovodev/.env file"

print_status "Starting rovodev container..."
print_status "Mounting current directory: ${CURRENT_DIR} -> /workspace"
print_status "Using configuration from: ${SCRIPT_DIR}"

# Log whether we're running from the script directory or elsewhere
if [ "$CURRENT_DIR" = "$SCRIPT_DIR" ]; then
    print_status "Running from the script directory"
else
    print_status "Running from a different directory: ${CURRENT_DIR}"
    print_status "Using configuration from: ${SCRIPT_DIR}"
fi

# Check if Docker is running
if docker info >/dev/null 2>&1; then
    print_status "Docker daemon is running and accessible"
    
    # Determine OS type
    OS_TYPE=$(uname -s)
    
    # Set Docker mount options based on OS
    if [ "$OS_TYPE" = "Darwin" ]; then
        # macOS specific handling
        print_status "Detected macOS system"
        
        # For macOS, we'll use the Docker CLI from the host instead of socket mounting
        # This is more reliable on macOS with Docker Desktop
        DOCKER_MOUNT="--privileged -e DOCKER_HOST=unix:///var/run/docker.sock -v /var/run/docker.sock:/var/run/docker.sock"
        print_status "Using Docker-in-Docker configuration for macOS"
        
    elif [ -e "/var/run/docker.sock" ]; then
        # Linux standard Docker socket
        print_status "Using standard Docker socket at /var/run/docker.sock"
        DOCKER_MOUNT="-v /var/run/docker.sock:/var/run/docker.sock"
    else
        print_warning "Docker socket not found at standard location"
        print_warning "Docker functionality inside the container may not work"
        DOCKER_MOUNT=""
    fi
else
    print_warning "Docker daemon is not running or not accessible"
    print_warning "Make sure Docker is installed and running on your host"
    DOCKER_MOUNT=""
fi

# Run the container with environment variables and volume mount
docker run -it \
    --name "${CONTAINER_NAME}" \
    ${PLATFORM} \
    --env-file "${ENV_FILE}" \
    ${PERSISTENCE_ENV} \
    -v "${CURRENT_DIR}:/workspace" \
    ${PERSISTENCE_MOUNT} \
    ${DOCKER_MOUNT} \
    -w /workspace \
    ${DOCKER_IMAGE}

print_status "Container ${CONTAINER_NAME} has exited."