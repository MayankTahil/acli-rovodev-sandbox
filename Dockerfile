# Use Ubuntu minimal as base image for better package management support
# Support both AMD64 and ARM64 architectures
FROM ubuntu:22.04

# Set environment variables to avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Create a non-root user for security
RUN groupadd -r rovodev && useradd -r -g rovodev -m -s /bin/bash rovodev

# Install essential packages and dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    unzip \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common \
    build-essential \
    python3 \
    python3-pip \
    nodejs \
    npm \
    jq \
    vim \
    nano \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Install acli (Atlassian CLI) with architecture detection
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
        ACLI_ARCH="amd64"; \
    elif [ "$ARCH" = "aarch64" ]; then \
        ACLI_ARCH="arm64"; \
    else \
        echo "Unsupported architecture: $ARCH" && exit 1; \
    fi && \
    echo "Downloading acli for architecture: $ACLI_ARCH" && \
    curl -LO "https://acli.atlassian.com/linux/latest/acli_linux_${ACLI_ARCH}/acli" && \
    chmod +x ./acli && \
    mv ./acli /usr/local/bin/acli && \
    echo "acli installed successfully for $ACLI_ARCH"

# Create workspace directory with proper permissions
RUN mkdir -p /workspace && chown rovodev:rovodev /workspace

# Create config directory for acli
RUN mkdir -p /home/rovodev/.config/acli && chown -R rovodev:rovodev /home/rovodev/.config

# Add rovodev user to sudoers for package installation
RUN echo "rovodev ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Switch to non-root user
USER rovodev

# Set working directory
WORKDIR /workspace

# Create entrypoint script for automatic authentication
RUN echo '#!/bin/bash' > /home/rovodev/entrypoint.sh && \
    echo '' >> /home/rovodev/entrypoint.sh && \
    echo '# Function to setup acli authentication' >> /home/rovodev/entrypoint.sh && \
    echo 'setup_acli_auth() {' >> /home/rovodev/entrypoint.sh && \
    echo '    if [ -n "$ATLASSIAN_API_TOKEN" ] && [ -n "$ATLASSIAN_USERNAME" ]; then' >> /home/rovodev/entrypoint.sh && \
    echo '        echo "Setting up acli authentication..."' >> /home/rovodev/entrypoint.sh && \
    echo '        mkdir -p /home/rovodev/.config/acli' >> /home/rovodev/entrypoint.sh && \
    echo '        echo "$ATLASSIAN_API_TOKEN" | acli rovodev auth login --email "$ATLASSIAN_USERNAME" --token' >> /home/rovodev/entrypoint.sh && \
    echo '        if [ $? -eq 0 ]; then' >> /home/rovodev/entrypoint.sh && \
    echo '            echo "✅ acli authentication successful!"' >> /home/rovodev/entrypoint.sh && \
    echo '        else' >> /home/rovodev/entrypoint.sh && \
    echo '            echo "❌ acli authentication failed. Please check your credentials."' >> /home/rovodev/entrypoint.sh && \
    echo '        fi' >> /home/rovodev/entrypoint.sh && \
    echo '    else' >> /home/rovodev/entrypoint.sh && \
    echo '        echo "⚠️  Authentication environment variables not set."' >> /home/rovodev/entrypoint.sh && \
    echo '        echo "Please set ATLASSIAN_API_TOKEN and ATLASSIAN_USERNAME"' >> /home/rovodev/entrypoint.sh && \
    echo '        echo "You can authenticate manually using: acli rovodev auth login"' >> /home/rovodev/entrypoint.sh && \
    echo '    fi' >> /home/rovodev/entrypoint.sh && \
    echo '}' >> /home/rovodev/entrypoint.sh && \
    echo '' >> /home/rovodev/entrypoint.sh && \
    echo '# Setup authentication on container start' >> /home/rovodev/entrypoint.sh && \
    echo 'setup_acli_auth' >> /home/rovodev/entrypoint.sh && \
    echo '' >> /home/rovodev/entrypoint.sh && \
    echo '# Check if rovodev command is available' >> /home/rovodev/entrypoint.sh && \
    echo 'if acli rovodev --help &> /dev/null; then' >> /home/rovodev/entrypoint.sh && \
    echo '    echo "✅ acli rovodev is available!"' >> /home/rovodev/entrypoint.sh && \
    echo '    echo "You can now use acli rovodev commands."' >> /home/rovodev/entrypoint.sh && \
    echo 'else' >> /home/rovodev/entrypoint.sh && \
    echo '    echo "⚠️  rovodev utility not found. Please ensure you have the latest acli version."' >> /home/rovodev/entrypoint.sh && \
    echo '    echo "Available acli commands:"' >> /home/rovodev/entrypoint.sh && \
    echo '    acli --help 2>/dev/null || echo "acli command not found"' >> /home/rovodev/entrypoint.sh && \
    echo 'fi' >> /home/rovodev/entrypoint.sh && \
    echo '' >> /home/rovodev/entrypoint.sh && \
    echo '# Execute the command passed to docker run, or start an interactive shell' >> /home/rovodev/entrypoint.sh && \
    echo 'if [ "$#" -eq 0 ]; then' >> /home/rovodev/entrypoint.sh && \
    echo '    echo "🚀 Starting interactive shell..."' >> /home/rovodev/entrypoint.sh && \
    echo '    echo "Current directory: $(pwd)"' >> /home/rovodev/entrypoint.sh && \
    echo '    echo "Available commands: acli, git, python3, node, npm, curl, wget, jq"' >> /home/rovodev/entrypoint.sh && \
    echo '    exec /bin/bash' >> /home/rovodev/entrypoint.sh && \
    echo 'else' >> /home/rovodev/entrypoint.sh && \
    echo '    exec "$@"' >> /home/rovodev/entrypoint.sh && \
    echo 'fi' >> /home/rovodev/entrypoint.sh

# Make entrypoint script executable and set proper ownership
RUN chmod +x /home/rovodev/entrypoint.sh && chown rovodev:rovodev /home/rovodev/entrypoint.sh

# Set entrypoint
ENTRYPOINT ["/home/rovodev/entrypoint.sh"]

# Default command (interactive shell)
CMD []

# Add labels for better container management
LABEL maintainer="rovodev-user"
LABEL description="Atlassian CLI with rovodev utility for ad-hoc development environments"
LABEL version="1.0"