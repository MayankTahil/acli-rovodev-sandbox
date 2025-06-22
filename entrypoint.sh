#!/bin/bash

# Function to setup acli authentication
setup_acli_auth() {
    if [ -n "$ATLASSIAN_API_TOKEN" ] && [ -n "$ATLASSIAN_USERNAME" ]; then
        echo "Setting up acli authentication..."
        mkdir -p /home/rovodev/.config/acli
        echo "$ATLASSIAN_API_TOKEN" | acli rovodev auth login --email "$ATLASSIAN_USERNAME" --token
        if [ $? -eq 0 ]; then
            echo "✅ acli authentication successful!"
        else
            echo "❌ acli authentication failed. Please check your credentials."
        fi
    else
        echo "⚠️  Authentication environment variables not set."
        echo "Please set ATLASSIAN_API_TOKEN and ATLASSIAN_USERNAME"
        echo "You can authenticate manually using: acli rovodev auth login"
    fi
}

# Function to handle persistence
setup_persistence() {
    if [ -d "/persistence" ]; then
        echo "🧠 Persistence directory detected."
        
        # Check for persistence mode
        if [ -n "$PERSISTENCE_MODE" ]; then
            echo "🔄 Persistence mode: $PERSISTENCE_MODE"
            
            # Create necessary directories based on mode
            if [ "$PERSISTENCE_MODE" = "shared" ]; then
                mkdir -p /persistence/shared
                echo "📂 Using shared persistence storage"
                
                # Initialize if empty
                if [ ! -f "/persistence/shared/initialized" ]; then
                    echo "🔧 Initializing shared persistence storage"
                    echo "$(date)" > /persistence/shared/initialized
                    echo "creator: Mayank Tahilramani" >> /persistence/shared/initialized
                fi
                
                # Read any initialization files
                if [ -d "/persistence/shared" ] && [ "$(ls -A /persistence/shared)" ]; then
                    echo "📚 Loading shared persistence data..."
                    # Add specific loading logic here if needed
                fi
                
            elif [ "$PERSISTENCE_MODE" = "instance" ]; then
                # Get instance ID from env or generate one
                INSTANCE_ID=${INSTANCE_ID:-$(date +%s)}
                mkdir -p "/persistence/instance-${INSTANCE_ID}"
                echo "📂 Using instance-specific persistence storage (ID: ${INSTANCE_ID})"
                
                # Initialize if empty
                if [ ! -f "/persistence/instance-${INSTANCE_ID}/initialized" ]; then
                    echo "🔧 Initializing instance persistence storage"
                    echo "$(date)" > "/persistence/instance-${INSTANCE_ID}/initialized"
                    echo "instance_id: ${INSTANCE_ID}" >> "/persistence/instance-${INSTANCE_ID}/initialized"
                    echo "creator: Mayank Tahilramani" >> "/persistence/instance-${INSTANCE_ID}/initialized"
                fi
                
                # Read any initialization files
                if [ -d "/persistence/instance-${INSTANCE_ID}" ] && [ "$(ls -A /persistence/instance-${INSTANCE_ID})" ]; then
                    echo "📚 Loading instance persistence data..."
                    # Add specific loading logic here if needed
                fi
            fi
        else
            echo "⚠️ Persistence directory exists but no mode specified."
            echo "Available persistence modes: shared, instance"
            echo "Set PERSISTENCE_MODE environment variable to enable persistence."
        fi
    else
        echo "🧠 No persistence directory mounted. Starting with fresh state."
    fi
    
    # Always check for workspace persistence directory
    if [ -d "/workspace/persistence" ]; then
        echo "📂 Found workspace persistence directory"
        # Read README.md if it exists
        if [ -f "/workspace/persistence/README.md" ]; then
            echo "📄 Reading workspace persistence README.md"
            echo "----------------------------------------"
            cat "/workspace/persistence/README.md"
            echo "----------------------------------------"
        fi
    fi
}

# Setup authentication on container start
setup_acli_auth

# Check for Docker access
echo "🐳 Checking Docker access..."

# Try to get Docker info
if docker info > /dev/null 2>&1; then
    echo "✅ Docker access is working!"
    docker version | grep -E "Server:|Client:" || true
else
    # Check if Docker socket exists
    if [ -e /var/run/docker.sock ]; then
        echo "🔍 Docker socket found at /var/run/docker.sock"
        echo "Current permissions: $(ls -la /var/run/docker.sock 2>/dev/null || echo 'Cannot access permissions')"
        echo "Current user: $(whoami), groups: $(groups)"
        
        # Try to fix permissions
        echo "⚙️ Attempting to fix Docker socket permissions..."
        if sudo chmod 666 /var/run/docker.sock 2>/dev/null; then
            echo "✅ Docker socket permissions updated!"
            
            # Test Docker access again
            if docker info > /dev/null 2>&1; then
                echo "✅ Docker access successful after permission fix!"
            else
                echo "⚠️ Still having issues with Docker access."
            fi
        else
            echo "⚠️ Could not change socket permissions with sudo."
        fi
    else
        # Check for DOCKER_HOST environment variable
        if [ -n "$DOCKER_HOST" ]; then
            echo "🔄 Using DOCKER_HOST: $DOCKER_HOST"
            echo "⚠️ Docker daemon connection failed. Make sure Docker is running on the host."
        else
            echo "⚠️ Docker socket not found and DOCKER_HOST not set."
            echo "Docker functionality will not be available inside this container."
        fi
    fi
    
    # Print troubleshooting information
    echo ""
    echo "🔧 Docker Troubleshooting:"
    echo "1. Make sure Docker daemon is running on the host"
    echo "2. For macOS: Docker Desktop must be running with file sharing enabled"
    echo "3. Try restarting the container with '--privileged' flag"
    echo "4. Check Docker version compatibility between host and container"
    
    # Try to get system information for debugging
    echo ""
    echo "📊 System Information:"
    echo "OS: $(uname -a)"
    echo "Docker Client: $(docker --version 2>/dev/null || echo 'Not available')"
    echo "Container: $([ -f /etc/os-release ] && cat /etc/os-release | grep PRETTY_NAME || echo 'Unknown')"
fi

# Setup persistence
setup_persistence

# Setup Git credentials
echo "🔑 Setting up Git credentials..."
if [ -n "$GIT_USERNAME" ] && [ -n "$GIT_PASSWORD" ]; then
    git config --global credential.helper '!f() { echo "username=$GIT_USERNAME"; echo "password=$GIT_PASSWORD"; }; f'
    echo "✅ Git credentials configured successfully!"
else
    echo "⚠️  Git credentials not found in environment variables."
    echo "To use Git without password prompts, set GIT_USERNAME and GIT_PASSWORD in your .rovodev/.env file."
fi

# Set Git user information if provided
if [ -n "$GIT_USER_NAME" ]; then
    git config --global user.name "$GIT_USER_NAME"
    echo "👤 Git user.name set to: $GIT_USER_NAME"
fi

if [ -n "$GIT_USER_EMAIL" ]; then
    git config --global user.email "$GIT_USER_EMAIL"
    echo "📧 Git user.email set to: $GIT_USER_EMAIL"
fi

# Test Git credential configuration
echo "🔒 Using Git credentials from environment variables for authentication"
if [ -n "$GIT_USERNAME" ] && [ -n "$GIT_PASSWORD" ]; then
    # Test Git configuration
    if git config --global --get credential.helper | grep -q '!f()'; then
        echo "✅ Git credential helper is properly configured"
    else
        echo "⚠️  Git credential helper configuration issue. Please check the setup."
    fi
fi

# Function to start rovodev automatically
start_rovodev() {
    if acli rovodev --help &> /dev/null; then
        echo "✅ acli rovodev is available!"
        echo "🚀 Starting Rovo Dev..."
        echo "Current directory: $(pwd)"
        echo "Files in workspace:"
        ls -la
        echo ""
        echo "🤖 Launching Rovo Dev AI Assistant..."
        exec acli rovodev run
    else
        echo "⚠️  rovodev utility not found. Please ensure you have the latest acli version."
        echo "Available acli commands:"
        acli --help 2>/dev/null || echo "acli command not found"
        echo ""
        echo "🚀 Starting interactive shell instead..."
        exec /bin/bash
    fi
}

# Execute the command passed to docker run, or start rovodev automatically
if [ "$#" -eq 0 ]; then
    start_rovodev
else
    exec "$@"
fi