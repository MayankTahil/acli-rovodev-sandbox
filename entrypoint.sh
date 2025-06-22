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

# Setup persistence
setup_persistence

# Check SSH agent forwarding
if [ -n "$SSH_AUTH_SOCK" ]; then
    echo "🔑 SSH agent forwarding detected at: $SSH_AUTH_SOCK"
    # Test SSH agent connection
    if ssh-add -l &>/dev/null; then
        echo "✅ SSH agent connection successful!"
        echo "Available SSH keys:"
        ssh-add -l
    else
        echo "⚠️  SSH agent detected but connection failed. Error code: $?"
        echo "This might be due to the 1Password app not being unlocked or SSH agent not running."
    fi
else
    echo "⚠️  No SSH agent forwarding detected. SSH operations might require password authentication."
    echo "To use 1Password SSH agent, ensure it's running and SSH_AUTH_SOCK is set on the host."
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