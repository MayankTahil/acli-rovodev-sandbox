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
    echo "  --rebuild                  Force rebuild of Docker image"
    echo "  --persistence=MODE         Enable persistence (MODE: shared, instance)"
    echo "  --instance-id=ID           Set specific instance ID for instance persistence mode"
    echo "  --help                     Show this help message"
    echo ""
    echo "Examples:"
    echo "  ./run-rovodev.sh                           # Run with default settings"
    echo "  ./run-rovodev.sh --rebuild                 # Force rebuild Docker image"
    echo "  ./run-rovodev.sh --persistence=shared      # Use shared persistence"
    echo "  ./run-rovodev.sh --persistence=instance    # Use instance-specific persistence"
    echo ""
}

# Check for help flag
for arg in "$@"; do
    if [ "$arg" == "--help" ]; then
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

# Check if Dockerfile has been modified since last build
NEED_REBUILD=false
if [ "$REBUILD" = true ]; then
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
    
    # If hash calculation failed, use timestamp comparison as fallback
    if [[ "$CURRENT_DOCKERFILE_HASH" == "HASH_ERROR" ]]; then
        print_warning "Hash calculation failed. Falling back to timestamp comparison."
        
        # Get the last modification time of the Dockerfile
        DOCKERFILE_MTIME=$(stat -c %Y Dockerfile 2>/dev/null || stat -f %m Dockerfile)
        
        # Get the creation time of the Docker image - handle both Linux and macOS date formats
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            IMAGE_CREATED=$(docker inspect -f '{{.Created}}' rovodev:latest | xargs -I{} date -j -f "%Y-%m-%dT%H:%M:%S" "$(echo {} | cut -d. -f1)" +%s 2>/dev/null || echo "")
        else
            # Linux and others
            IMAGE_CREATED=$(docker inspect -f '{{.Created}}' rovodev:latest | xargs date +%s -d 2>/dev/null || echo "")
        fi
        
        # If stat command failed or IMAGE_CREATED is empty, force rebuild
        if [ -z "$DOCKERFILE_MTIME" ] || [ -z "$IMAGE_CREATED" ]; then
            print_warning "Could not determine modification times. Rebuilding to be safe."
            NEED_REBUILD=true
        elif [ "$DOCKERFILE_MTIME" -gt "$IMAGE_CREATED" ]; then
            print_status "Dockerfile has been modified since last build. Rebuilding image."
            NEED_REBUILD=true
        fi
    # Compare current hash with stored hash
    elif [ -z "$STORED_HASH" ] || [[ "$CURRENT_DOCKERFILE_HASH" != "$STORED_HASH" ]]; then
        print_status "Dockerfile has been modified since last build. Rebuilding image."
        NEED_REBUILD=true
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
    print_status "Using existing Docker image. Use --rebuild flag to force rebuild."
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
    ${PLATFORM} \
    --env-file .env \
    ${PERSISTENCE_ENV} \
    -v "${CURRENT_DIR}:/workspace" \
    ${PERSISTENCE_MOUNT} \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -w /workspace \
    rovodev:latest

print_status "Container ${CONTAINER_NAME} has exited."